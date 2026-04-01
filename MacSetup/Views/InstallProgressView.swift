import SwiftUI
import AppKit

struct InstallProgressView: View {
    @Environment(InstallManager.self) private var installManager
    @State private var selectedLogID: UUID?

    private var selectedItems: [AppItem] {
        AppCatalog.all.filter { installManager.selectedIDs.contains($0.id) }
    }

    private var doneCount: Int {
        selectedItems.filter { installManager.session.status(for: $0) == .done }.count
    }

    private var failedCount: Int {
        selectedItems.filter {
            if case .failed = installManager.session.status(for: $0) { return true }
            return false
        }.count
    }

    // The item whose logs are displayed — follows active install, or user selection
    private var displayedItem: AppItem? {
        if let id = selectedLogID, let item = selectedItems.first(where: { $0.id == id }) {
            return item
        }
        if let id = installManager.session.currentlyInstallingID {
            return selectedItems.first { $0.id == id }
        }
        return selectedItems.last
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──────────────────────────────────────────────────────
            headerBar

            Divider()

            // ── Split: app list | terminal ───────────────────────────────
            HStack(spacing: 0) {
                // Left — app list
                appList

                Divider()

                // Right — terminal log
                if let item = displayedItem {
                    TerminalLogView(
                        item: item,
                        logs: installManager.session.logs(for: item),
                        status: installManager.session.status(for: item)
                    )
                } else {
                    emptyTerminal
                }
            }
        }
        .frame(minWidth: 760, minHeight: 500)
        // Auto-follow the currently installing item unless user manually selected one
        .onChange(of: installManager.session.currentlyInstallingID) { _, newID in
            if selectedLogID == nil {
                selectedLogID = newID
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerBar: some View {
        if installManager.session.isComplete {
            HStack(spacing: 14) {
                Image(systemName: failedCount == 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(failedCount == 0 ? .green : .orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(failedCount == 0 ? "All done!" : "Completed with issues")
                        .font(.headline)
                    Text(completionSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Close") {
                    installManager.showProgress = false
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background((failedCount == 0 ? Color.green : Color.orange).opacity(0.07))
        } else {
            VStack(spacing: 7) {
                ProgressView(value: Double(doneCount), total: Double(max(selectedItems.count, 1)))
                    .tint(.accentColor)
                HStack {
                    Text("\(doneCount) of \(selectedItems.count) complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let id = installManager.session.currentlyInstallingID,
                       let item = selectedItems.first(where: { $0.id == id }) {
                        HStack(spacing: 5) {
                            ProgressView().scaleEffect(0.55).frame(width: 12, height: 12)
                            Text("Installing \(item.name)…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor))
        }
    }

    // MARK: - App List (left panel)

    private var appList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(selectedItems) { item in
                    AppRowProgressView(
                        item: item,
                        isSelected: displayedItem?.id == item.id
                    )
                    .onTapGesture {
                        selectedLogID = item.id
                    }
                }
            }
            .padding(8)
        }
        .frame(width: 220)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var emptyTerminal: some View {
        Color(red: 0.09, green: 0.09, blue: 0.11)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var completionSubtitle: String {
        var parts: [String] = []
        if doneCount > 0       { parts.append("\(doneCount) installed") }
        if failedCount > 0     { parts.append("\(failedCount) failed") }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Terminal Log Panel

private struct TerminalLogView: View {
    let item: AppItem
    let logs: [String]
    let status: InstallStatus

    var body: some View {
        VStack(spacing: 0) {
            // Terminal title bar
            HStack(spacing: 8) {
                // Traffic light dots (decorative)
                Circle().fill(Color(red: 1, green: 0.37, blue: 0.34)).frame(width: 10, height: 10)
                Circle().fill(Color(red: 1, green: 0.73, blue: 0.18)).frame(width: 10, height: 10)
                Circle().fill(Color(red: 0.22, green: 0.80, blue: 0.36)).frame(width: 10, height: 10)

                Spacer()

                Text("brew install \(brewArg)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color(white: 0.5))

                Spacer()

                if !logs.isEmpty {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(logs.joined(separator: "\n"), forType: .string)
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color(white: 0.45))
                    .help("Copy all logs")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(red: 0.15, green: 0.15, blue: 0.17))

            // Log output
            if logs.isEmpty {
                emptyState
            } else {
                logOutput
            }
        }
        .background(Color(red: 0.09, green: 0.09, blue: 0.11))
    }

    private var logOutput: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(Array(logs.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 11.5, design: .monospaced))
                            .foregroundStyle(lineColor(line))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Blinking cursor while installing
                    if case .installing = status {
                        BlinkingCursor()
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(14)
            }
            .onChange(of: logs.count) {
                withAnimation(.easeOut(duration: 0.08)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onAppear {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            if case .pending = status {
                Text("Waiting to install…")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color(white: 0.35))
            } else if case .installing = status {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.7).colorScheme(.dark)
                    Text("Starting…")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Color(white: 0.5))
                }
            } else {
                Text("No output")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color(white: 0.3))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var brewArg: String {
        switch item.method {
        case .brewCask(let name):    return "reinstall --cask \(name)"
        case .brewFormula(let name): return "reinstall \(name)"
        default:                     return item.name
        }
    }

    private func lineColor(_ line: String) -> Color {
        let lower = line.lowercased()
        if lower.contains("error:") || lower.contains("failed") || lower.contains("abort") {
            return Color(red: 1.0, green: 0.42, blue: 0.42)
        } else if lower.contains("warning:") || lower.contains("warn:") {
            return Color(red: 1.0, green: 0.78, blue: 0.28)
        } else if line.hasPrefix("==>") {
            return Color(red: 0.38, green: 0.85, blue: 0.56)
        } else if line.hasPrefix("  ") || line.hasPrefix("\t") {
            return Color(white: 0.55)
        }
        return Color(white: 0.82)
    }
}

// MARK: - Blinking Cursor

private struct BlinkingCursor: View {
    @State private var visible = true

    var body: some View {
        Rectangle()
            .fill(Color(white: 0.7))
            .frame(width: 7, height: 13)
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.55).repeatForever()) {
                    visible = false
                }
            }
    }
}
