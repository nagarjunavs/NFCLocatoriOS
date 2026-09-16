import SwiftUI

/// A fixed 1100ms minimum visible time, then hands off to Onboarding or Home depending on
/// `onboardingCompleted`. Always dark background regardless of app theme, by design.
struct SplashScreen: View {
    let reducedMotion: Bool
    let onFinished: () -> Void

    private static let minVisibleDuration: Duration = .milliseconds(1100)

    var body: some View {
        ZStack {
            TapSensePalette.darkBg.ignoresSafeArea()
            VStack(spacing: 0) {
                TapSenseLogo(color: TapSensePalette.aqua, pulsing: true, reducedMotion: reducedMotion)
                Spacer().frame(height: 24)
                Text("app.name", bundle: .main)
                    .tapSenseStyle(TapSenseType.headlineLarge, color: TapSensePalette.textLight)
                Text("app.tagline", bundle: .main)
                    .tapSenseStyle(TapSenseType.bodyMedium, color: TapSensePalette.textLightSecondary)
            }
        }
        .task {
            try? await Task.sleep(for: Self.minVisibleDuration)
            onFinished()
        }
    }
}
