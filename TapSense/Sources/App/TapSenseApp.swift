import SwiftUI

@main
struct TapSenseApp: App {
    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            TapSenseRootView()
                .environment(\.appEnvironment, environment)
                .tapSenseTheme(appearanceMode: environment.settingsStore.settings.appearanceMode)
        }
    }
}
