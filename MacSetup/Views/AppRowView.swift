import SwiftUI
import AppKit

struct AppRowView: View {
    let item: AppItem
    @Environment(InstallManager.self) private var installManager
    @State private var isHovering = false

    private var status: InstallStatus { installManager.session.status(for: item) }
    private var isSelected: Bool { installManager.selectedIDs.contains(item.id) }
    private var isDisabled: Bool { status == .alreadyInstalled || installManager.isRunning }

    var body: some View {
        HStack(spacing: 14) {
            // Selection checkbox
            selectionIndicator

            // App icon
            AppIconView(item: item)
                .opacity(isDisabled ? 0.45 : 1)

            // App info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isDisabled ? .tertiary : .primary)

                    if let website = item.website {
                        Button {
                            NSWorkspace.shared.open(website)
                        } label: {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.tertiary)
                                .padding(3)
                                .background(
                                    Circle()
                                        .fill(Color.primary.opacity(0.05))
                                )
                        }
                        .buttonStyle(.plain)
                        .opacity(isHovering ? 1 : 0)
                        .help(website.scheme == "macappstore" ? "Open in App Store" : (website.host() ?? "Open website"))
                    }
                }

                if status == .alreadyInstalled {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.green.opacity(0.7))
                        Text("Installed")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Install method badge
            InstallMethodBadge(method: item.method)
                .opacity(isDisabled ? 0.35 : 0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(rowBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture {
            guard !isDisabled else { return }
            installManager.toggle(item)
        }
    }

    private var rowBackground: Color {
        if isSelected {
            return Color.accentColor.opacity(0.08)
        } else if isHovering && !isDisabled {
            return Color.primary.opacity(0.03)
        }
        return .clear
    }

    private var selectionIndicator: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(
                    isSelected ? Color.accentColor : Color.secondary.opacity(0.25),
                    lineWidth: 1.5
                )
                .frame(width: 20, height: 20)

            if status == .alreadyInstalled {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))
                    .frame(width: 20, height: 20)
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.quaternary)
            } else if isSelected {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.accentColor)
                    .frame(width: 20, height: 20)
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .animation(.spring(response: 0.18, dampingFraction: 0.65), value: isSelected)
    }
}

// MARK: - AppIconView

struct AppIconView: View {
    let item: AppItem
    @State private var icon: NSImage? = nil

    var body: some View {
        Group {
            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [item.method.badgeColor.opacity(0.2), item.method.badgeColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text(String(item.name.prefix(1)))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(item.method.badgeColor)
                }
                .frame(width: 36, height: 36)
            }
        }
        .task(id: item.id) {
            guard icon == nil else { return }
            if let bundleName = item.bundleName {
                let path = "/Applications/\(bundleName).app"
                if FileManager.default.fileExists(atPath: path) {
                    icon = NSWorkspace.shared.icon(forFile: path)
                    return
                }
            }
            if let cached = RemoteIconCache.shared.cachedIcon(for: item) {
                icon = cached
            } else {
                icon = await RemoteIconCache.shared.fetchIcon(for: item)
            }
        }
    }
}

// MARK: - InstallMethodBadge

struct InstallMethodBadge: View {
    let method: InstallMethod

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: method.badgeIcon)
                .font(.system(size: 8, weight: .semibold))
            Text(method.badgeLabel)
                .font(.system(size: 10, weight: .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(method.badgeColor.opacity(0.08))
        .foregroundStyle(method.badgeColor)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

extension InstallMethod {
    var badgeIcon: String {
        switch self {
        case .brewCask:    return "shippingbox"
        case .brewFormula: return "terminal"
        case .appStore:    return "apple.logo"
        case .manual:      return "arrow.down.to.line"
        }
    }
}
