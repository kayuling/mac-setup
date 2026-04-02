import SwiftUI

struct ContentView: View {
    @Environment(InstallManager.self) private var installManager
    @State private var selectedCategory: AppCategory? = .all
    @State private var showBrewOnboarding = false
    @State private var searchText = ""

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedCategory: $selectedCategory)
        } detail: {
            AppListView(selectedCategory: selectedCategory ?? .all, searchText: searchText)
                .searchable(text: $searchText, placement: .toolbar, prompt: "Search curated apps...")
        }
        .task {
            if !BrewChecker.isBrewInstalled {
                withAnimation { showBrewOnboarding = true }
            } else {
                await installManager.checkAlreadyInstalled(AppCatalog.all)
            }
        }
        .sheet(isPresented: $showBrewOnboarding) {
            BrewOnboardingView {
                withAnimation { showBrewOnboarding = false }
                Task { await installManager.checkAlreadyInstalled(AppCatalog.all) }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .sheet(isPresented: Bindable(installManager).showProgress) {
            InstallProgressView()
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
        .alert("Homebrew Not Found", isPresented: Bindable(installManager).showBrewMissingAlert) {
            Button("Install Homebrew") { showBrewOnboarding = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Homebrew is the engine behind MacSetup. Please install it to continue.")
        }
    }
}
