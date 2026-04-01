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
        HStack(spacing: 0) {
            // Left Panel: Progress Overview
            VStack(alignment: .leading, spacing: 0) {
                progressHeader
                
                Divider()
                
                ScrollView {
                    VStack(spacing: 1) {
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
                    .padding(.vertical, 8)
                }
            }
            .frame(width: 300)
            .background(.ultraThinMaterial)

            Divider()

            // Right Panel: Details & Terminal
            VStack(spacing: 0) {
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
        .frame(minWidth: 900, minHeight: 600)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: installManager.session.currentlyInstallingID) { _, newID in
            if selectedLogID == nil || selectedLogID == installManager.session.currentlyInstallingID {
                selectedLogID = newID
            }
        }
    }

    // MARK: - Header

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            progressHeaderTitle
            progressBarSection
        }
        .padding(24)
    }

    @ViewBuilder
    private var progressHeaderTitle: some View {
        HStack {
            let title = installManager.session.isComplete ? "Setup Complete" : "Installing Your Mac"
            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
            Spacer()
            if installManager.session.isComplete {
                Button {
                    installManager.showProgress = false
                } label: {
                    Text("Done")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.accentColor, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var progressBarSection: some View {
        let pct = Int(Double(doneCount) / Double(max(selectedItems.count, 1)) * 100)
        VStack(spacing: 8) {
            HStack {
                Text("\(doneCount) of \(selectedItems.count) apps installed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(pct)%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.accentColor)
            }
            GeometryReader { geo in
                let fillWidth = geo.size.width * CGFloat(doneCount) / CGFloat(max(selectedItems.count, 1))
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.05))
                    Capsule()
                        .fill(LinearGradient(colors: [.accentColor, .accentColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: fillWidth)
                }
            }
            .frame(height: 6)
        }
    }

    private var emptyTerminal: some View {
        VStack(spacing: 16) {
            Image(systemName: "terminal")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(.quaternary)
            Text("Select an app to view logs")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.05, green: 0.05, blue: 0.07))
    }
}

// MARK: - Terminal Log Panel

private struct TerminalLogView: View {
    let item: AppItem
    let logs: [String]
    let status: InstallStatus

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 16) {
                AppIconView(item: item)
                    .scaleEffect(0.6)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Text(statusLabel)
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(statusColor)
                }
                
                Spacer()
                
                if !logs.isEmpty {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(logs.joined(separator: "\n"), forType: .string)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.clipboard.fill")
                            Text("Copy Logs")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.05), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(red: 0.08, green: 0.08, blue: 0.10))

            Divider().opacity(0.1)

            logOutput
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.07))
    }

    private var logOutput: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(logs.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(lineColor(line))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if case .installing = status {
                        BlinkingCursor()
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(24)
            }
            .onChange(of: logs.count) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
            .onAppear {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }

    private var statusLabel: String {
        switch status {
        case .pending: return "WAITING..."
        case .installing: return "INSTALLING..."
        case .done: return "COMPLETED"
        case .failed: return "FAILED"
        case .alreadyInstalled: return "ALREADY INSTALLED"
        case .notInstalled: return "NOT INSTALLED"
        }
    }

    private var statusColor: Color {
        switch status {
        case .pending: return .secondary
        case .installing: return .accentColor
        case .done: return .green
        case .failed: return .red
        case .alreadyInstalled: return .green
        case .notInstalled: return .secondary
        }
    }

    private func lineColor(_ line: String) -> Color {
        let lower = line.lowercased()
        if lower.contains("error:") || lower.contains("failed") || lower.contains("abort") {
            return Color(red: 1.0, green: 0.4, blue: 0.4)
        } else if lower.contains("warning:") || lower.contains("warn:") {
            return Color(red: 1.0, green: 0.8, blue: 0.3)
        } else if line.hasPrefix("==>") {
            return .accentColor
        }
        return Color(white: 0.7)
    }
}

private struct BlinkingCursor: View {
    @State private var visible = true

    var body: some View {
        Rectangle()
            .fill(Color.accentColor)
            .frame(width: 8, height: 14)
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                    visible = false
                }
            }
    }
}

