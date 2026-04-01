import Foundation
import Observation
import AppKit

@Observable
@MainActor
final class InstallManager {
    var session = InstallSession()
    var selectedIDs: Set<UUID> = []
    var isRunning = false
    var showProgress = false
    var showBrewMissingAlert = false

    var selectedCount: Int { selectedIDs.count }

    func toggle(_ item: AppItem) {
        if selectedIDs.contains(item.id) {
            selectedIDs.remove(item.id)
        } else if session.status(for: item) != .alreadyInstalled {
            selectedIDs.insert(item.id)
        }
    }

    func selectAll(in items: [AppItem]) {
        for item in items where session.status(for: item) != .alreadyInstalled {
            selectedIDs.insert(item.id)
        }
    }

    func deselectAll(in items: [AppItem]) {
        items.forEach { selectedIDs.remove($0.id) }
    }

    var isCheckingInstalled = false

    // MARK: - Already-installed check

    func checkAlreadyInstalled(_ catalog: [AppItem]) async {
        isCheckingInstalled = true
        defer { isCheckingInstalled = false }

        let fm = FileManager.default

        // Clear any stale .alreadyInstalled statuses so uninstalled apps are re-enabled
        for item in catalog where session.statusMap[item.id] == .alreadyInstalled {
            session.statusMap.removeValue(forKey: item.id)
        }

        // Check /Applications — catches apps installed any way (direct download, brew, App Store, etc.)
        for item in catalog {
            if let bundleName = item.bundleName,
               fm.fileExists(atPath: "/Applications/\(bundleName).app") {
                session.statusMap[item.id] = .alreadyInstalled
                selectedIDs.remove(item.id)
            }
        }

        // Check brew list for CLI formulas (no .app bundle to detect)
        guard BrewChecker.isBrewInstalled else { return }

        let formulas = await BrewChecker.installedFormulas()
        for item in catalog {
            guard case .brewFormula(let name) = item.method,
                  formulas.contains(name),
                  session.statusMap[item.id] != .alreadyInstalled else { continue }
            session.statusMap[item.id] = .alreadyInstalled
            selectedIDs.remove(item.id)
        }
    }

    // MARK: - Install

    func installSelected(from catalog: [AppItem]) async {
        let items = catalog.filter { selectedIDs.contains($0.id) }
        guard !items.isEmpty else { return }

        let needsBrew = items.contains {
            switch $0.method {
            case .brewCask, .brewFormula: return true
            default: return false
            }
        }

        if needsBrew && !BrewChecker.isBrewInstalled {
            showBrewMissingAlert = true
            return
        }

        // Reset session and mark all selected as pending
        session = InstallSession()
        for item in items {
            session.statusMap[item.id] = .pending
        }

        isRunning = true
        showProgress = true

        for item in items {
            session.statusMap[item.id] = .installing
            session.currentlyInstallingID = item.id

            switch item.method {
            case .brewCask(let name):
                await runBrew(item: item, arguments: ["install", "--cask", name])
            case .brewFormula(let name):
                await runBrew(item: item, arguments: ["install", name])
            case .appStore(let url):
                NSWorkspace.shared.open(url)
                session.statusMap[item.id] = .done
            case .manual(let url):
                NSWorkspace.shared.open(url)
                session.statusMap[item.id] = .done
            }
        }

        isRunning = false
        session.isComplete = true
        session.currentlyInstallingID = nil
    }

    private func runBrew(item: AppItem, arguments: [String]) async {
        for await event in ShellRunner.stream(command: "brew", arguments: arguments) {
            switch event {
            case .output(let line):
                session.appendLog(line, for: item)
            case .completed(let code):
                if code == 0 {
                    session.statusMap[item.id] = .done
                } else {
                    session.statusMap[item.id] = .failed("Exit code \(code)")
                }
            }
        }
    }
}
