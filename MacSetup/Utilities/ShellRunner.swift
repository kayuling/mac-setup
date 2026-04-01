import Foundation

enum ShellEvent: Sendable {
    case output(String)
    case completed(Int32)
}

struct ShellRunner {
    /// Streams output lines and a final completion event from the given command.
    /// Used for real-time display (e.g. install progress terminal).
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
            let buffer = LineBuffer()

            // Read on a background thread to avoid the readabilityHandler/terminationHandler
            // race condition where both compete to read from the same file handle.
            let readTask = DispatchWorkItem {
                while true {
                    let data = fileHandle.availableData
                    if data.isEmpty { break } // EOF — pipe closed
                    if let text = String(data: data, encoding: .utf8) {
                        for line in buffer.append(text) {
                            continuation.yield(.output(line))
                        }
                    }
                }
                // Flush any trailing partial line
                if let trailing = buffer.flush() {
                    continuation.yield(.output(trailing))
                }
            }

            process.terminationHandler = { p in
                // Wait for the read loop to finish draining the pipe before
                // yielding the completion event, so all output arrives first.
                readTask.wait()
                continuation.yield(.completed(p.terminationStatus))
                continuation.finish()
            }

            DispatchQueue.global(qos: .userInitiated).async(execute: readTask)

            do {
                try process.run()
            } catch {
                readTask.cancel()
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

    /// Runs a command and collects all stdout lines + exit code.
    /// Uses a separate pipe for stderr so stdout is never corrupted by warnings.
    static func runAndCollect(command: String, arguments: [String]) async -> (output: [String], exitCode: Int32) {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [command] + arguments
            process.environment = enrichedEnvironment()

            let stdoutPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = FileHandle.nullDevice // discard stderr for clean parsing

            process.terminationHandler = { p in
                let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                var lines: [String] = []
                if let text = String(data: data, encoding: .utf8) {
                    lines = text.components(separatedBy: "\n")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                }
                continuation.resume(returning: (lines, p.terminationStatus))
            }

            do {
                try process.run()
            } catch {
                continuation.resume(returning: ([], -1))
            }
        }
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

// MARK: - Line Buffer

/// Buffers partial lines from chunked pipe reads so that lines split across
/// two data chunks are reassembled before being yielded.
private final class LineBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var partial: String = ""

    /// Appends raw text from a data chunk, returns complete lines.
    func append(_ text: String) -> [String] {
        lock.lock()
        defer { lock.unlock() }

        let combined = partial + text
        var lines = combined.components(separatedBy: "\n")

        // Last element is either "" (if text ended with \n) or an incomplete line.
        partial = lines.removeLast()

        return lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    /// Returns any remaining partial line (call after process exits).
    func flush() -> String? {
        lock.lock()
        defer { lock.unlock() }

        let remainder = partial
        partial = ""
        return remainder.trimmingCharacters(in: .whitespaces).isEmpty ? nil : remainder
    }
}
