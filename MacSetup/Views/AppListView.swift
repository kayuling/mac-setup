import SwiftUI

struct AppListView: View {
    let selectedCategory: AppCategory
    let searchText: String
    @Environment(InstallManager.self) private var installManager

    private var items: [AppItem] {
        let base = AppCatalog.items(for: selectedCategory)
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var installedCount: Int {
        AppCatalog.all.filter { installManager.session.status(for: $0) == .alreadyInstalled }.count
    }

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 240), spacing: 12)
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    
                    if items.isEmpty {
                        emptyState
                            .padding(.top, 100)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(items) { item in
                                AppRowView(item: item)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 100)
            }
            .background(Color(nsColor: .windowBackgroundColor))
            
            installBar
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                HStack(spacing: 12) {
                    Button {
                        installManager.selectAll(in: items)
                    } label: {
                        Label("Select All", systemImage: "checkmark.circle")
                    }
                    .disabled(installManager.isRunning)

                    Button {
                        installManager.deselectAll(in: items)
                    } label: {
                        Label("Deselect All", systemImage: "circle")
                    }
                    .disabled(installManager.isRunning)

                    Divider()

                    Button {
                        Task { await installManager.checkAlreadyInstalled(AppCatalog.all) }
                    } label: {
                        if installManager.isCheckingInstalled {
                            ProgressView().scaleEffect(0.6).frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .help("Refresh installed status")
                    .disabled(installManager.isRunning || installManager.isCheckingInstalled)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(selectedCategory.rawValue)
                .font(.system(size: 28, weight: .black, design: .rounded))
            
            Text("\(items.count) applications available in this category")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.03))
                    .frame(width: 80, height: 80)
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.quaternary)
            }
            
            VStack(spacing: 4) {
                Text("No Apps Found")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text(searchText.isEmpty ? "This category is currently empty." : "Try adjusting your search for \"\(searchText)\"")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bottom Install Bar

    private var installBar: some View {
        Group {
            if installManager.selectedCount > 0 || installManager.isRunning {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(installManager.selectedCount) App\(installManager.selectedCount == 1 ? "" : "s") Ready")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        
                        Text("Selected for installation")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        Task { await installManager.installSelected(from: AppCatalog.all) }
                    } label: {
                        HStack(spacing: 8) {
                            if installManager.isRunning {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .frame(width: 14, height: 14)
                                    .brightness(1)
                                Text("Executing Setup...")
                            } else {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 12))
                                Text("Start Installation")
                            }
                        }
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [.accentColor, .accentColor.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                        )
                        .foregroundStyle(.white)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 10, y: 5)
                    }
                    .buttonStyle(.plain)
                    .disabled(installManager.selectedCount == 0 || installManager.isRunning)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
                )
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: installManager.selectedCount)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: installManager.isRunning)
    }
}
