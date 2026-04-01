import SwiftUI

struct SidebarView: View {
    @Binding var selectedCategory: AppCategory?
    @Environment(InstallManager.self) private var installManager

    var body: some View {
        List(AppCategory.allCases, selection: $selectedCategory) { category in
            Label {
                CategoryRowLabel(
                    category: category,
                    totalCount: totalCount(for: category),
                    selectedCount: selectedCount(for: category)
                )
            } icon: {
                Image(systemName: category.systemImage)
            }
            .tag(category)
        }
        .navigationTitle("MacSetup")
        .navigationSplitViewColumnWidth(min: 190, ideal: 210)
    }

}

// Extracted so `let` bindings work cleanly in ViewBuilder
private struct CategoryRowLabel: View {
    let category: AppCategory
    let totalCount: Int
    let selectedCount: Int

    var body: some View {
        HStack {
            Text(category.rawValue)
            Spacer()
            if selectedCount > 0 {
                Text("\(selectedCount)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor, in: Capsule())
                    .transition(.scale.combined(with: .opacity))
            } else {
                Text("\(totalCount)")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
                    .monospacedDigit()
            }
        }
        .animation(.spring(response: 0.25), value: selectedCount)
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
