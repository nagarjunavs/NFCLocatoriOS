import Observation
import NFCLocatorCore

@MainActor
@Observable
final class PhoneConfirmedViewModel {
    private(set) var confirmedProfile: DeviceAntennaProfile?

    func load(env: AppEnvironment) async {
        let settings = env.settingsStore.settings
        let signals = env.activeDeviceSignalsProvider.signals(for: settings)
        confirmedProfile = await env.resolveAntennaLocation(signals)
    }

    /// Marks onboarding complete (idempotent) before leaving — this screen is reachable both
    /// from onboarding's optional "choose a different phone" detour and from Home/Settings'
    /// "Change phone" path, and only the former needs this, but it's harmless either way.
    func goHome(env: AppEnvironment, onDone: () -> Void) {
        env.settingsStore.setOnboardingCompleted(true)
        onDone()
    }
}
