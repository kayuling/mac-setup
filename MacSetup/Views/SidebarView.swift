import SwiftUI

struct SidebarView: View {
    @Binding var selectedCategory: AppCategory?
    @Environment(InstallManager.self) private var installManager

    var body: some View {
        VStack(spacing: 0) {
            // Branding
            brandingHeader
            
            // Categories
            List(AppCategory.allCases, selection: $selectedCategory) { category in
                CategoryRow(
                    category: category,
                    totalCount: totalCount(for: category),
                    selectedCount: selectedCount(for: category),
                    isSelected: selectedCategory == category
                )
                .tag(category)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)

            Spacer()

            // Status Footer
            statusFooter
        }
        .navigationSplitViewColumnWidth(min: 240, ideal: 260)
        .background(.ultraThinMaterial)
    }

    // MARK: - Components

    private var brandingHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "bolt.fill")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text("MacSetup")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("PROVISIONING TOOL")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.secondary)
                    .tracking(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 24)
    }

    private var statusFooter: some View {
        VStack(spacing: 16) {
            let installed = AppCatalog.all.filter { installManager.session.status(for: $0) == .alreadyInstalled }.count
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("System Status")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(installed)/\(AppCatalog.all.count)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.accentColor)
                }

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
            
            if installManager.isRunning {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 12, height: 12)
                    Text("FORGING IN PROGRESS")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color.accentColor)
                        .tracking(0.5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.1), in: Capsule())
            }
        }
        .padding(24)
        .background(
            Rectangle()
                .fill(.primary.opacity(0.02))
                .ignoresSafeArea()
        )
    }
}

// MARK: - Category Row

private struct CategoryRow: View {
    let category: AppCategory
    let totalCount: Int
    let selectedCount: Int
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? category.iconColor : category.iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: category.systemImage)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isSelected ? .white : category.iconColor)
            }
            
            Text(category.rawValue)
                .font(.system(size: 14, weight: isSelected ? .bold : .semibold, design: .rounded))
                .foregroundStyle(isSelected ? .primary : .secondary)
            
            Spacer()
            
            if selectedCount > 0 {
                Text("\(selectedCount)")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(isSelected ? Color.white.opacity(0.2) : Color.accentColor, in: Capsule())
            } else {
                Text("\(totalCount)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            isSelected ? Color.primary.opacity(0.05) : Color.clear,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
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
