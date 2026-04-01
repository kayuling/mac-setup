import SwiftUI

struct SidebarView: View {
    @Binding var selectedCategory: AppCategory?
    @Environment(InstallManager.self) private var installManager

    var body: some View {
        VStack(spacing: 0) {
            // App branding header
            HStack(spacing: 10) {
                Image(systemName: "laptopcomputer.and.arrow.down")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                Text("MacSetup")
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 14)

            Divider()
                .padding(.horizontal, 12)

            List(AppCategory.allCases, selection: $selectedCategory) { category in
                CategoryRow(
                    category: category,
                    totalCount: totalCount(for: category),
                    selectedCount: selectedCount(for: category)
                )
                .tag(category)
            }
            .listStyle(.sidebar)

            Divider()
                .padding(.horizontal, 12)

            // Quick stats footer
            VStack(spacing: 4) {
                let installed = AppCatalog.all.filter { installManager.session.status(for: $0) == .alreadyInstalled }.count
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                    Text("\(installed) of \(AppCatalog.all.count) installed")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 220)
    }
}

// MARK: - Category Row

private struct CategoryRow: View {
    let category: AppCategory
    let totalCount: Int
    let selectedCount: Int

    var body: some View {
        Label {
            HStack {
                Text(category.rawValue)
                Spacer()
                if selectedCount > 0 {
                    Text("\(selectedCount)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor, in: Capsule())
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("\(totalCount)")
                        .foregroundStyle(.tertiary)
                        .font(.system(size: 11, design: .rounded))
                        .monospacedDigit()
                }
            }
            .animation(.spring(response: 0.25), value: selectedCount)
        } icon: {
            Image(systemName: category.systemImage)
                .font(.system(size: 12))
                .foregroundStyle(category.iconColor)
        }
    }
}

// MARK: - Category Icon Colors

extension AppCategory {
    var iconColor: Color {
        switch self {
        case .all:          return .accentColor
        case .browsers:     return .blue
        case .dev:          return .purple
        case .ai:           return .pink
        case .productivity: return .orange
        case .media:        return .red
        case .utilities:    return .gray
        case .cli:          return .green
        }
    }
}

private extension SidebarView {
    func totalCount(for category: AppCategory) -> Int {
        AppCatalog.items(for: category).count
    }

    func selectedCount(for category: AppCategory) -> Int {
        AppCatalog.items(for: category).filter { installManager.selectedIDs.contains($0.id) }.count
    }
}
