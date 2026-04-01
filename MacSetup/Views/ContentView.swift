import SwiftUI

struct ContentView: View {
    @Environment(InstallManager.self) private var installManager
    @State private var selectedCategory: AppCategory? = .all
    @State private var showBrewOnboarding = false

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedCategory: $selectedCategory)
        } detail: {
            AppListView(selectedCategory: selectedCategory ?? .all)
        }
        .task {
            // Show Homebrew onboarding if not installed
            if !BrewChecker.isBrewInstalled {
                showBrewOnboarding = true
            } else {
                await installManager.checkAlreadyInstalled(AppCatalog.all)
            }
        }
        .sheet(isPresented: $showBrewOnboarding) {
            BrewOnboardingView {
                showBrewOnboarding = false
                // Re-check installed apps once brew is confirmed
                Task { await installManager.checkAlreadyInstalled(AppCatalog.all) }
            }
        }
        .sheet(isPresented: Bindable(installManager).showProgress) {
            InstallProgressView()
        }
        .alert("Homebrew Not Found", isPresented: Bindable(installManager).showBrewMissingAlert) {
            Button("Install Homebrew") { showBrewOnboarding = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Homebrew is required to install brew packages.")
        }
    }
}
