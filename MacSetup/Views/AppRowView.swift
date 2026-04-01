import SwiftUI
import AppKit

struct AppRowView: View {
    let item: AppItem
    @Environment(InstallManager.self) private var installManager

    private var status: InstallStatus { installManager.session.status(for: item) }
    private var isSelected: Bool { installManager.selectedIDs.contains(item.id) }
    private var isDisabled: Bool { status == .alreadyInstalled || installManager.isRunning }

    var body: some View {
        HStack(spacing: 12) {
            selectionIndicator

            AppIconView(item: item)
                .opacity(isDisabled ? 0.5 : 1)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(item.name)
                        .foregroundStyle(isDisabled ? .tertiary : .primary)

                    if let website = item.website {
                        Button {
                            NSWorkspace.shared.open(website)
                        } label: {
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                        .help(website.scheme == "macappstore" ? "Open in App Store" : (website.host() ?? "Open website"))
                    }
                }

                if status == .alreadyInstalled {
                    Text("Installed")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }
            }

            Spacer()

            InstallMethodBadge(method: item.method)
                .opacity(isDisabled ? 0.4 : 1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isDisabled else { return }
            installManager.toggle(item)
        }
    }

    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .stroke(
                    isSelected ? Color.accentColor : Color.secondary.opacity(0.28),
                    lineWidth: 1.5
                )
                .frame(width: 18, height: 18)

            if status == .alreadyInstalled {
                Circle()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 18, height: 18)
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.secondary)
            } else if isSelected {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 18, height: 18)
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .animation(.spring(response: 0.18, dampingFraction: 0.65), value: isSelected)
    }
}

// MARK: - AppIconView

private struct AppIconView: View {
    let item: AppItem
    @State private var icon: NSImage? = nil

    var body: some View {
        Group {
            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 28, height: 28)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(item.method.badgeColor.opacity(0.18))
                    Text(String(item.name.prefix(1)))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(item.method.badgeColor)
                }
                .frame(width: 28, height: 28)
            }
        }
        .task(id: item.id) {
            guard icon == nil else { return }
            // Prefer local /Applications icon (one-time disk check)
            if let bundleName = item.bundleName {
                let path = "/Applications/\(bundleName).app"
                if FileManager.default.fileExists(atPath: path) {
                    icon = NSWorkspace.shared.icon(forFile: path)
                    return
                }
            }
            // Fall back to remote icon
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
        Text(method.badgeLabel)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(method.badgeColor.opacity(0.12))
            .foregroundStyle(method.badgeColor)
            .clipShape(Capsule())
    }
}
