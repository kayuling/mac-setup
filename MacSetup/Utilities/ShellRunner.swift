import Foundation

enum ShellEvent: Sendable {
    case output(String)
    case completed(Int32)
}

struct ShellRunner {
    /// Streams output lines and a final completion event from the given command.
    static func stream(command: String, arguments: [String]) -> AsyncStream<ShellEvent> {
        AsyncStream { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [command] + arguments
            process.environment = enrichedEnvironment()

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            let fileHandle = pipe.fileHandleForReading

            fileHandle.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                if let text = String(data: data, encoding: .utf8) {
                    for line in text.components(separatedBy: "\n") where !line.trimmingCharacters(in: .whitespaces).isEmpty {
                        continuation.yield(.output(line))
                    }
                }
            }

            process.terminationHandler = { p in
                // Drain any remaining buffered data
                let remaining = fileHandle.readDataToEndOfFile()
                if !remaining.isEmpty, let text = String(data: remaining, encoding: .utf8) {
                    for line in text.components(separatedBy: "\n") where !line.trimmingCharacters(in: .whitespaces).isEmpty {
                        continuation.yield(.output(line))
                    }
                }
                fileHandle.readabilityHandler = nil
                continuation.yield(.completed(p.terminationStatus))
                continuation.finish()
            }

            do {
                try process.run()
            } catch {
                continuation.yield(.output("Error launching \(command): \(error.localizedDescription)"))
                continuation.yield(.completed(-1))
                continuation.finish()
            }
        }
    }

    /// Runs a command silently and returns only the exit code. Used for install checks.
    static func runQuiet(command: String, arguments: [String]) async -> Int32 {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [command] + arguments
            process.environment = enrichedEnvironment()
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice

            process.terminationHandler = { p in
                continuation.resume(returning: p.terminationStatus)
            }

            do {
                try process.run()
            } catch {
                continuation.resume(returning: -1)
            }
        }
    }

    /// Runs a command and collects all output lines + exit code.
    static func runAndCollect(command: String, arguments: [String]) async -> (output: [String], exitCode: Int32) {
        var lines: [String] = []
        var exitCode: Int32 = 0
        for await event in stream(command: command, arguments: arguments) {
            switch event {
            case .output(let line): lines.append(line)
            case .completed(let code): exitCode = code
            }
        }
        return (lines, exitCode)
    }

    // Injects Homebrew paths into PATH since macOS GUI apps don't inherit shell PATH.
    private static let enrichedEnv: [String: String] = {
        var env = ProcessInfo.processInfo.environment
        let extra = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        env["PATH"] = extra + ":" + (env["PATH"] ?? "")
        return env
    }()

    static func enrichedEnvironment() -> [String: String] { enrichedEnv }
}
