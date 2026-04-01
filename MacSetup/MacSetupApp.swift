import SwiftUI

@main
struct MacSetupApp: App {
    @State private var installManager = InstallManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(installManager)
                .frame(minWidth: 900, minHeight: 580)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}
