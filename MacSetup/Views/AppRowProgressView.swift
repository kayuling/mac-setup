import SwiftUI

struct AppRowProgressView: View {
    let item: AppItem
    let isSelected: Bool
    @Environment(InstallManager.self) private var installManager

    private var status: InstallStatus { installManager.session.status(for: item) }

    var body: some View {
        HStack(spacing: 10) {
            statusIcon
                .frame(width: 18, height: 18)

            Text(item.name)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .lineLimit(1)
                .foregroundStyle(rowTextColor)

            Spacer()

            if case .failed = status {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            } else if case .done = status {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .contentShape(Rectangle())
    }

    private var rowTextColor: Color {
        switch status {
        case .failed:   return .red
        case .done:     return .primary
        case .pending:  return .secondary
        default:        return .primary
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .pending:
            Image(systemName: "circle")
                .foregroundStyle(.tertiary)
                .font(.system(size: 12))
        case .installing:
            ProgressView()
                .scaleEffect(0.55)
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 13))
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.system(size: 13))
        case .alreadyInstalled:
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.quaternary)
                .font(.system(size: 12))
        default:
            Image(systemName: "circle")
                .foregroundStyle(.quaternary)
                .font(.system(size: 12))
        }
    }
}
