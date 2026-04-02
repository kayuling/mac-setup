import SwiftUI

struct AppRowProgressView: View {
    let item: AppItem
    let isSelected: Bool
    @Environment(InstallManager.self) private var installManager

    private var status: InstallStatus { installManager.session.status(for: item) }

    var body: some View {
        HStack(spacing: 12) {
            statusIndicator
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                
                if case .installing = status {
                    Text("Installing...")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                } else if case .done = status {
                    Text("Completed")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.green.opacity(0.8))
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accentColor.opacity(0.1))
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                }
            }
        )
        .contentShape(Rectangle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: status)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        ZStack {
            switch status {
            case .pending:
                Circle()
                    .stroke(.quaternary, lineWidth: 2)
            case .installing:
                Circle()
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 2)
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        AngularGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.1)], center: .center),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .rotationEffect(.degrees(installingRotation))
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            installingRotation = 360
                        }
                    }
            case .done:
                Circle()
                    .fill(.green)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
            case .failed:
                Circle()
                    .fill(.red)
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
            default:
                Circle()
                    .stroke(.quaternary, lineWidth: 1)
            }
        }
    }

    @State private var installingRotation: Double = 0
}
