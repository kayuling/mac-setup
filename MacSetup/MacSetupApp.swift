import SwiftUI

@main
struct MacSetupApp: App {
    @State private var installManager = InstallManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(installManager)
                .frame(minWidth: 960, minHeight: 640)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
    }
}
