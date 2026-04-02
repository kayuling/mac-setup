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

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 280), spacing: 20)
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    headerSection
                    
                    if items.isEmpty {
                        emptyState
                            .padding(.top, 100)
                    } else {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(items) { item in
                                AppRowView(item: item)
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 40)
                .padding(.bottom, 140)
            }
            .background(Color(nsColor: .windowBackgroundColor))
            
            installBar
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                HStack(spacing: 12) {
                    secondaryToolbarButtons
                    Divider()
                    refreshButton
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(selectedCategory.rawValue)
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.primary, .primary.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    )
                
                Spacer()
                
                Text("\(items.count) Apps")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(.primary.opacity(0.05), lineWidth: 1))
            }
            
            Text("Carefully selected tools for your \(selectedCategory.rawValue.lowercased()) workflow.")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var secondaryToolbarButtons: some View {
        Button {
            withAnimation { installManager.selectAll(in: items) }
        } label: {
            Label("Select All", systemImage: "checkmark.circle.fill")
        }
        .help("Select all visible apps")
        .disabled(installManager.isRunning)

        Button {
            withAnimation { installManager.deselectAll(in: items) }
        } label: {
            Label("Deselect All", systemImage: "circle")
        }
        .help("Deselect all visible apps")
        .disabled(installManager.isRunning)
    }

    @ViewBuilder
    private var refreshButton: some View {
        Button {
            Task { await installManager.checkAlreadyInstalled(AppCatalog.all) }
        } label: {
            if installManager.isCheckingInstalled {
                ProgressView().scaleEffect(0.6).frame(width: 14, height: 14)
            } else {
                Image(systemName: "arrow.clockwise")
            }
        }
        .help("Refresh installation status")
        .disabled(installManager.isRunning || installManager.isCheckingInstalled)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(.quaternary)
            }
            
            VStack(spacing: 8) {
                Text("Nothing Here Yet")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text(searchText.isEmpty ? "We're still curating this list." : "No results for \"\(searchText)\"")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bottom Install Bar

    private var installBar: some View {
        Group {
            if installManager.selectedCount > 0 || installManager.isRunning {
                HStack(spacing: 24) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 40, height: 40)
                            
                            Text("\(installManager.selectedCount)")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Setup Ready")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Text("Total Selection")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Divider().frame(height: 32)
                    
                    Spacer()
                    
                    Button {
                        Task { await installManager.installSelected(from: AppCatalog.all) }
                    } label: {
                        HStack(spacing: 12) {
                            if installManager.isRunning {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .brightness(1)
                                Text("Building Your Mac...")
                            } else {
                                Image(systemName: "bolt.fill")
                                Text("Start Installation")
                            }
                        }
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                        .foregroundStyle(.white)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 15, y: 10)
                    }
                    .buttonStyle(.plain)
                    .disabled(installManager.selectedCount == 0 || installManager.isRunning)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 20)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .shadow(color: .black.opacity(0.15), radius: 30, y: 15)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: installManager.selectedCount)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: installManager.isRunning)
    }
}
