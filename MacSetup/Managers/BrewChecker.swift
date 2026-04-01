import Foundation

struct BrewChecker {
    static var isBrewInstalled: Bool {
        FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew") ||
        FileManager.default.fileExists(atPath: "/usr/local/bin/brew")
    }

    /// Returns the set of installed cask names (runs `brew list --cask` once).
    static func installedCasks() async -> Set<String> {
        let (output, _) = await ShellRunner.runAndCollect(command: "brew", arguments: ["list", "--cask"])
        return Set(output.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
    }

    /// Returns the set of installed formula names (runs `brew list --formula` once).
    static func installedFormulas() async -> Set<String> {
        let (output, _) = await ShellRunner.runAndCollect(command: "brew", arguments: ["list", "--formula"])
        return Set(output.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
    }
}
