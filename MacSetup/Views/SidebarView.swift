import SwiftUI

struct SidebarView: View {
    @Binding var selectedCategory: AppCategory?
    @Environment(InstallManager.self) private var installManager

    var body: some View {
        VStack(spacing: 0) {
            // App branding header
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(LinearGradient(colors: [.accentColor, .accentColor.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "laptopcomputer.and.arrow.down")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("MacSetup")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Text("Personal Curator")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)

            List(AppCategory.allCases, selection: $selectedCategory) { category in
                CategoryRow(
                    category: category,
                    totalCount: totalCount(for: category),
                    selectedCount: selectedCount(for: category),
                    isSelected: selectedCategory == category
                )
                .tag(category)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 10))
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)

            Spacer()

            // Quick stats footer
            VStack(spacing: 12) {
                let installed = AppCatalog.all.filter { installManager.session.status(for: $0) == .alreadyInstalled }.count
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(installed) Apps Installed")
                            .font(.system(size: 11, weight: .semibold))
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.05))
                                    .frame(height: 4)
                                
                                Capsule()
                                    .fill(LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geo.size.width * CGFloat(installed) / CGFloat(max(1, AppCatalog.all.count)), height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }
                
                if installManager.isRunning {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 12, height: 12)
                        Text("Installing...")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.primary.opacity(0.05), in: Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .navigationSplitViewColumnWidth(min: 220, ideal: 240)
    }
}

// MARK: - Category Row

private struct CategoryRow: View {
    let category: AppCategory
    let totalCount: Int
    let selectedCount: Int
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? category.iconColor : category.iconColor.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                Image(systemName: category.systemImage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? .white : category.iconColor)
            }
            
            Text(category.rawValue)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
            
            Spacer()
            
            if selectedCount > 0 {
                Text("\(selectedCount)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color.accentColor, in: Capsule())
            } else {
                Text("\(totalCount)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary.opacity(0.5))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
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
