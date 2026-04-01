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

    var body: some View {
        Group {
            if items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(items) { item in
                            AppRowView(item: item)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 80)
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            installBar
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Select All") {
                    installManager.selectAll(in: items)
                }
                .disabled(installManager.isRunning)

                Button("Deselect All") {
                    installManager.deselectAll(in: items)
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
        .navigationTitle(selectedCategory.rawValue)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.quaternary)
            Text("No apps found")
                .font(.headline)
                .foregroundStyle(.secondary)
            if !searchText.isEmpty {
                Text("Try a different search term")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Bottom Install Bar

    private var installBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    if installManager.selectedCount > 0 {
                        Text("\(installManager.selectedCount) app\(installManager.selectedCount == 1 ? "" : "s") selected")
                            .font(.system(size: 13, weight: .semibold))
                            .transition(.opacity)
                    } else {
                        Text("No apps selected")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    Text("\(installedCount) of \(AppCatalog.all.count) already installed")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                .animation(.easeInOut(duration: 0.15), value: installManager.selectedCount)

                Spacer()

                Button {
                    Task { await installManager.installSelected(from: AppCatalog.all) }
                } label: {
                    if installManager.isRunning {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.65)
                                .frame(width: 14, height: 14)
                            Text("Installing...")
                        }
                        .frame(minWidth: 150)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 13))
                            Text(installManager.selectedCount > 0
                                 ? "Install \(installManager.selectedCount) App\(installManager.selectedCount == 1 ? "" : "s")"
                                 : "Install")
                        }
                        .fontWeight(.semibold)
                        .frame(minWidth: 150)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(installManager.selectedCount == 0 || installManager.isRunning)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
        }
    }
}
