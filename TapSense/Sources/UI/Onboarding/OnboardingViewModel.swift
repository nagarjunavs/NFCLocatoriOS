import Observation
import NFCLocatorCore

@MainActor
@Observable
final class OnboardingViewModel {
    /// Real resolution preview for page 3 ("TapSense already recognized this device") — nil
    /// while loading.
    private(set) var autoDetectedProfile: DeviceAntennaProfile?

    func load(env: AppEnvironment) async {
        let signals = env.deviceIdentitySignalsProvider.current()
        autoDetectedProfile = await env.resolveAntennaLocation(signals)
    }

    func completeOnboarding(env: AppEnvironment, onDone: () -> Void) {
        env.settingsStore.setOnboardingCompleted(true)
        onDone()
    }
}
