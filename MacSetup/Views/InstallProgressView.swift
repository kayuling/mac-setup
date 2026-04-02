import SwiftUI
import AppKit

struct InstallProgressView: View {
    @Environment(InstallManager.self) private var installManager
    @State private var selectedLogID: UUID?
    @State private var animateIn = false

    private var selectedItems: [AppItem] {
        AppCatalog.all.filter { installManager.selectedIDs.contains($0.id) }
    }

    private var doneCount: Int {
        selectedItems.filter { installManager.session.status(for: $0) == .done }.count
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
        ZStack {
            // Background: Dark Mesh
            ForgeBackground()
                .ignoresSafeArea()
            
            HStack(spacing: 0) {
                // Left Panel: Progress Overview
                VStack(alignment: .leading, spacing: 0) {
                    progressHeader
                    
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(selectedItems) { item in
                                AppRowProgressView(
                                    item: item,
                                    isSelected: displayedItem?.id == item.id
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedLogID = item.id
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
                .frame(width: 320)
                .background(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    Rectangle()
                        .fill(.white.opacity(0.05))
                        .frame(width: 1)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                )

                // Right Panel: Details & Terminal
                VStack(spacing: 0) {
                    if let item = displayedItem {
                        ForgeTerminalView(
                            item: item,
                            logs: installManager.session.logs(for: item),
                            status: installManager.session.status(for: item)
                        )
                    } else {
                        emptyForge
                    }
                }
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .colorScheme(.dark)
        .onAppear {
            animateIn = true
        }
        .onChange(of: installManager.session.currentlyInstallingID) { _, newID in
            if selectedLogID == nil || selectedLogID == installManager.session.currentlyInstallingID {
                withAnimation { selectedLogID = newID }
            }
        }
    }

    // MARK: - Header

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(installManager.session.isComplete ? "Forge Complete" : "Building Your Mac")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                    
                    Text("\(doneCount) of \(selectedItems.count) apps forged")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if installManager.session.isComplete {
                    Button {
                        withAnimation { installManager.showProgress = false }
                    } label: {
                        Text("Finish")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.accentColor, in: Capsule())
                            .shadow(color: Color.accentColor.opacity(0.5), radius: 10, y: 5)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            ForgeProgressBar(pct: Double(doneCount) / Double(max(selectedItems.count, 1)))
        }
        .padding(24)
    }

    private var emptyForge: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 1)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "hammer.fill")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(.quaternary)
                    .rotationEffect(.degrees(animateIn ? 0 : -20))
                    .animation(.spring(response: 1, dampingFraction: 0.5).repeatForever(autoreverses: true), value: animateIn)
            }
            Text("Select an app to inspect the forge")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Forge Components

struct ForgeProgressBar: View {
    let pct: Double

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.05))
                    
                    Capsule()
                        .fill(
                            LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geo.size.width * CGFloat(pct))
                        .shadow(color: Color.accentColor.opacity(0.5), radius: 10, x: 0, y: 0)
                }
            }
            .frame(height: 6)
            
            HStack {
                Text("PROVISIONING ENGINE")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(.tertiary)
                    .tracking(1)
                Spacer()
                Text("\(Int(pct * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}

private struct ForgeTerminalView: View {
    let item: AppItem
    let logs: [String]
    let status: InstallStatus

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 20) {
                AppIconView(item: item)
                    .scaleEffect(0.6)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                        Text(statusLabel)
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(statusColor)
                            .tracking(1)
                    }
                }
                
                Spacer()
                
                if !logs.isEmpty {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(logs.joined(separator: "\n"), forType: .string)
                    } label: {
                        Label("Copy Output", systemImage: "terminal.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.05), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .background(.ultraThinMaterial.opacity(0.3))

            Divider().opacity(0.1)

            ForgeLogOutput(logs: logs, isInstalling: status == .installing)
        }
    }

    private var statusLabel: String {
        switch status {
        case .pending: return "PENDING"
        case .installing: return "FORGING..."
        case .done: return "STABILIZED"
        case .failed: return "CRITICAL ERROR"
        case .alreadyInstalled: return "VERIFIED"
        case .notInstalled: return "IDLE"
        }
    }

    private var statusColor: Color {
        switch status {
        case .pending: return .secondary
        case .installing: return Color.accentColor
        case .done: return .green
        case .failed: return .red
        case .alreadyInstalled: return .green
        case .notInstalled: return .secondary
        }
    }
}

struct ForgeLogOutput: View {
    let logs: [String]
    let isInstalling: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(logs.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(lineColor(line))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if isInstalling {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: 8, height: 14)
                                .opacity(0.8)
                            Text("EXECUTING TASK...")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(Color.accentColor.opacity(0.6))
                        }
                        .padding(.top, 4)
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(32)
            }
            .onChange(of: logs.count) {
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }

    private func lineColor(_ line: String) -> Color {
        let lower = line.lowercased()
        if lower.contains("error:") || lower.contains("failed") { return .red.opacity(0.8) }
        if lower.contains("warning:") { return .orange.opacity(0.8) }
        if line.hasPrefix("==>") { return Color.accentColor }
        return .white.opacity(0.6)
    }
}

struct ForgeBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.02, blue: 0.04)
            
            Circle()
                .fill(Color.accentColor.opacity(0.1))
                .frame(width: 800, height: 800)
                .blur(radius: 150)
                .offset(x: 200, y: -200)
            
            Circle()
                .fill(Color.purple.opacity(0.05))
                .frame(width: 600, height: 600)
                .blur(radius: 120)
                .offset(x: -300, y: 300)
        }
    }
}

