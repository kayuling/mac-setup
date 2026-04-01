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

        // Gather all installed IDs before touching any observable state.
        var installedIDs: Set<UUID> = []
        let fm = FileManager.default

        // Check /Applications
        for item in catalog {
            if let bundleName = item.bundleName,
               fm.fileExists(atPath: "/Applications/\(bundleName).app") {
                installedIDs.insert(item.id)
            }
        }

        // Check brew formulas (await happens here — no observable state has been touched yet)
        if BrewChecker.isBrewInstalled {
            let formulas = await BrewChecker.installedFormulas()
            for item in catalog {
                guard case .brewFormula(let name) = item.method,
                      formulas.contains(name) else { continue }
                installedIDs.insert(item.id)
            }
        }

        // Build the new status map and selection set, then assign once.
        var newStatusMap = session.statusMap
        var newSelectedIDs = selectedIDs

        for item in catalog {
            if installedIDs.contains(item.id) {
                newStatusMap[item.id] = .alreadyInstalled
                newSelectedIDs.remove(item.id)
            } else if newStatusMap[item.id] == .alreadyInstalled {
                newStatusMap.removeValue(forKey: item.id)
            }
        }

        // Single assignment — one observation event, no flicker.
        session.statusMap = newStatusMap
        selectedIDs = newSelectedIDs
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
                await runBrew(item: item, arguments: ["reinstall", "--cask", name])
            case .brewFormula(let name):
                await runBrew(item: item, arguments: ["reinstall", name])
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
