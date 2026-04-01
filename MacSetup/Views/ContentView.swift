import SwiftUI

struct ContentView: View {
    @Environment(InstallManager.self) private var installManager
    @State private var selectedCategory: AppCategory? = .all

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedCategory: $selectedCategory)
        } detail: {
            AppListView(selectedCategory: selectedCategory ?? .all)
        }
        .task {
            await installManager.checkAlreadyInstalled(AppCatalog.all)
        }
        .sheet(isPresented: Bindable(installManager).showProgress) {
            InstallProgressView()
        }
        .alert("Homebrew Not Found", isPresented: Bindable(installManager).showBrewMissingAlert) {
            Button("OK") {}
        } message: {
            Text("Homebrew is required to install brew packages.\n\nInstall it by running this in Terminal:\n\n/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"")
        }
    }
}
