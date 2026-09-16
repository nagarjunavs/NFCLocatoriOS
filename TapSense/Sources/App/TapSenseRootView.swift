import SwiftUI

/// The app shell: a Splash gate, then a single flat `NavigationStack` shared by every other
/// screen with a bottom bar shown/hidden per-route.
struct TapSenseRootView: View {
    @Environment(\.appEnvironment) private var env
    @State private var router = Router()
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashScreen(reducedMotion: env?.settingsStore.settings.reduceMotion ?? false) {
                    let onboarded = env?.settingsStore.settings.onboardingCompleted ?? false
                    router.finishSplash(onboardingCompleted: onboarded)
                    showSplash = false
                }
            } else {
                mainStack
            }
        }
        .environment(router)
    }

    private var mainStack: some View {
        NavigationStack(path: $router.path) {
            rootContent
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if Route.bottomBarRoutes.contains(router.current) {
                TapSenseBottomBar(
                    currentRoute: router.current,
                    onHomeClick: { router.navigateTopLevel(.home) },
                    onMyPhoneClick: { router.navigateTopLevel(.myPhone) },
                    onTapGuideClick: { router.push(.tapGuide) },
                    onSettingsClick: { router.navigateTopLevel(.settings) }
                )
            }
        }
    }

    // No screen in this design shows a system-style top app bar with a "Back" label —
    // screens carry their own in-content headline, and back navigation is a system gesture. The
    // root/tab screens (never pushed) get no back button at all. Pushed screens keep the
    // *default* back button (required — `navigationBarBackButtonHidden(true)` also disables the
    // interactive swipe-back gesture, a known SwiftUI/UIKit coupling, confirmed by testing this
    // screen in the Simulator: hiding the button left swipe-back completely non-functional) but
    // with an empty title, so iOS renders it as a bare chevron with no text, and a transparent
    // bar background so no visible bar surface competes with the in-content headline.
    @ViewBuilder
    private var rootContent: some View {
        Group {
            switch router.root {
            case .onboarding: OnboardingScreen()
            case .home: HomeScreen()
            case .myPhone: MyPhoneScreen()
            case .settings: SettingsScreen()
            default: HomeScreen()
            }
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        Group {
            switch route {
            case .onboarding: OnboardingScreen()
            case .home: HomeScreen()
            case .myPhone: MyPhoneScreen()
            case .settings: SettingsScreen()
            case .phoneSelection: PhoneSelectionScreen()
            case .phoneConfirmed: PhoneConfirmedScreen()
            case .tapGuide: TapGuideScreen()
            case .tapTest: TapTestScreen()
            case .troubleshoot: TroubleshootScreen()
            case .education: EducationScreen()
            case .privacy: PrivacyScreen()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        // Tap Guide already has its own explicit close (X) button, matching the design exactly
        // — a second, default back chevron would be a redundant, conflicting affordance, so
        // it's the one screen where hiding the default back button (and losing swipe-back,
        // per the note above) is the right trade: the X is guaranteed to work either way.
        .navigationBarBackButtonHidden(route == .tapGuide)
    }
}
