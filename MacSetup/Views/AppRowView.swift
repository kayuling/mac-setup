import SwiftUI
import AppKit

struct AppRowView: View {
    let item: AppItem
    @Environment(InstallManager.self) private var installManager
    @State private var isHovering = false

    private var status: InstallStatus { installManager.session.status(for: item) }
    private var isSelected: Bool { installManager.selectedIDs.contains(item.id) }
    private var isInstalled: Bool { status == .alreadyInstalled }
    private var isDisabled: Bool { isInstalled || installManager.isRunning }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top: icon + installed badge
            HStack(alignment: .top) {
                AppIconView(item: item)
                    .scaleEffect(isHovering && !isDisabled ? 1.06 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)

                Spacer()

                if isInstalled {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.green.opacity(0.85))
                } else {
                    selectionToggle
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)

            // Middle: name + website
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(isInstalled ? .secondary : .primary)
                        .lineLimit(1)

                    if let website = item.website {
                        Button {
                            NSWorkspace.shared.open(website)
                        } label: {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                        .opacity(isHovering ? 1 : 0)
                        .onHover { inside in
                            if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                        }
                    }
                }

                if isInstalled {
                    Text("INSTALLED")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(.green.opacity(0.1), in: Capsule())
                } else {
                    InstallMethodBadge(method: item.method)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.background)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.06) : Color.clear)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.accentColor.opacity(0.3) : (isHovering ? Color.primary.opacity(0.08) : Color.clear),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: .black.opacity(isHovering ? 0.07 : 0.03), radius: isHovering ? 8 : 3, y: isHovering ? 3 : 1)
        .contentShape(Rectangle())
        .onTapGesture { if !isDisabled { installManager.toggle(item) } }
        .onHover { isHovering = $0 }
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovering)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isSelected)
    }

    private var selectionToggle: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.06))
                .frame(width: 26, height: 26)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .disabled(installManager.isRunning)
        .onTapGesture { if !installManager.isRunning { installManager.toggle(item) } }
    }
}

// MARK: - AppIconView

struct AppIconView: View {
    let item: AppItem
    @State private var icon: NSImage? = nil

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .padding(4)
            } else {
                Text(String(item.name.prefix(1)))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(item.method.badgeColor)
            }
        }
        .frame(width: 48, height: 48)
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
                .font(.system(size: 9, weight: .bold))
            Text(method.badgeLabel.uppercased())
                .font(.system(size: 9, weight: .black))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(method.badgeColor.opacity(0.12))
        .foregroundStyle(method.badgeColor)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
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
