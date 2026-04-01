import SwiftUI

struct AppListView: View {
    let selectedCategory: AppCategory
    @Environment(InstallManager.self) private var installManager

    private var items: [AppItem] {
        AppCatalog.items(for: selectedCategory)
    }

    private var installedCount: Int {
        AppCatalog.all.filter { installManager.session.status(for: $0) == .alreadyInstalled }.count
    }

    var body: some View {
        List(items) { item in
            AppRowView(item: item)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
        }
        .listStyle(.plain)
        .navigationTitle(selectedCategory.rawValue)
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
    }

    // MARK: - Bottom Install Bar

    private var installBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 16) {
                // Stats
                VStack(alignment: .leading, spacing: 2) {
                    if installManager.selectedCount > 0 {
                        Text("\(installManager.selectedCount) app\(installManager.selectedCount == 1 ? "" : "s") selected")
                            .fontWeight(.medium)
                            .transition(.opacity)
                    } else {
                        Text("No apps selected")
                            .foregroundStyle(.secondary)
                    }
                    Text("\(installedCount) of \(AppCatalog.all.count) already installed")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .animation(.easeInOut(duration: 0.15), value: installManager.selectedCount)

                Spacer()

                // Install button
                Button {
                    Task { await installManager.installSelected(from: AppCatalog.all) }
                } label: {
                    if installManager.isRunning {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 14, height: 14)
                            Text("Installing…")
                        }
                        .frame(minWidth: 140)
                    } else {
                        Text(installManager.selectedCount > 0
                             ? "Install \(installManager.selectedCount) App\(installManager.selectedCount == 1 ? "" : "s")"
                             : "Install")
                        .fontWeight(.semibold)
                        .frame(minWidth: 140)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(installManager.selectedCount == 0 || installManager.isRunning)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.bar)
        }
    }
}
