import Foundation
import Observation

@Observable
final class InstallSession {
    var statusMap: [UUID: InstallStatus] = [:]
    var logMap: [UUID: [String]] = [:]
    var currentlyInstallingID: UUID? = nil
    var isComplete = false

    func status(for item: AppItem) -> InstallStatus {
        statusMap[item.id] ?? .notInstalled
    }

    func appendLog(_ line: String, for item: AppItem) {
        logMap[item.id, default: []].append(line)
    }

    func logs(for item: AppItem) -> [String] {
        logMap[item.id] ?? []
    }
}
