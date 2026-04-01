import SwiftUI

struct AppRowProgressView: View {
    let item: AppItem
    let isSelected: Bool
    @Environment(InstallManager.self) private var installManager

    private var status: InstallStatus { installManager.session.status(for: item) }

    var body: some View {
        HStack(spacing: 9) {
            statusIcon
                .frame(width: 16, height: 16)

            Text(item.name)
                .font(.callout)
                .lineLimit(1)
                .foregroundStyle(rowTextColor)

            Spacer()

            if case .failed = status {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
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
            Image(systemName: "clock")
                .foregroundStyle(.tertiary)
                .font(.caption)
        case .installing:
            ProgressView()
                .scaleEffect(0.6)
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        case .alreadyInstalled:
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.quaternary)
        default:
            Image(systemName: "circle")
                .foregroundStyle(.quaternary)
        }
    }
}
