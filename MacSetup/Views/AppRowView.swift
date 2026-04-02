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
            // Top Section: Icon & Toggle
            HStack(alignment: .top) {
                AppIconView(item: item)
                    .scaleEffect(isHovering && !isDisabled ? 1.05 : 1.0)
                    .rotationEffect(.degrees(isHovering && !isDisabled ? 2 : 0))
                    .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : .black.opacity(0.1), radius: isHovering ? 12 : 6, y: isHovering ? 6 : 3)

                Spacer()

                if isInstalled {
                    StatusBadge(text: "INSTALLED", color: .green, icon: "checkmark.circle.fill")
                } else {
                    SelectionIndicator(isSelected: isSelected, isDisabled: installManager.isRunning)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Spacer(minLength: 16)

            // Bottom Section: Name & Method
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(isInstalled ? .secondary : .primary)
                        .lineLimit(1)
                    
                    if let website = item.website {
                        LinkIcon(url: website, isVisible: isHovering)
                    }
                }

                if !isInstalled {
                    InstallMethodBadge(method: item.method)
                } else {
                    Text("Ready to use")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(height: 140)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.accentColor.opacity(0.08))
                    
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(colors: [Color.accentColor.opacity(0.5), Color.accentColor.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 2
                        )
                } else {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(isHovering ? Color.primary.opacity(0.1) : Color.primary.opacity(0.03), lineWidth: 1)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(isHovering ? 0.12 : 0.05), radius: isHovering ? 20 : 10, y: isHovering ? 10 : 5)
        .scaleEffect(isHovering && !isDisabled ? 1.02 : 1.0)
        .onTapGesture { if !isDisabled { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { installManager.toggle(item) } } }
        .onHover { isHovering = $0 }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Subviews

private struct StatusBadge: View {
    let text: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.system(size: 9, weight: .black))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

private struct SelectionIndicator: View {
    let isSelected: Bool
    let isDisabled: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.05))
                .frame(width: 24, height: 24)
            
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
            }
        }
        .opacity(isDisabled ? 0.3 : 1)
    }
}

private struct LinkIcon: View {
    let url: URL
    let isVisible: Bool

    var body: some View {
        Button {
            NSWorkspace.shared.open(url)
        } label: {
            Image(systemName: "arrow.up.right.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
        .opacity(isVisible ? 1 : 0)
        .onHover { inside in
            if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}

struct AppIconView: View {
    let item: AppItem
    @State private var icon: NSImage? = nil

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white)
            
            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .padding(6)
            } else {
                Text(String(item.name.prefix(1)))
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(item.method.badgeColor)
            }
        }
        .frame(width: 52, height: 52)
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
