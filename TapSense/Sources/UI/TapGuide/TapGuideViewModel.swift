import Observation
import NFCLocatorCore

struct TapGuideUiState {
    var antennaState: AntennaLocatorUIState?
    var reduceMotion = false
}

@MainActor
@Observable
final class TapGuideViewModel {
    private(set) var uiState = TapGuideUiState()

    // The walkthrough always ends in a real physical tap test, which needs live NFC hardware
    // regardless of which phone is being previewed — so unlike Home/My Phone's marker display,
    // there's no manual-override exemption here (see TapGuideScreen's redirect).
    func load(env: AppEnvironment) async {
        let settings = env.settingsStore.settings
        uiState.reduceMotion = settings.reduceMotion
        let signals = env.activeDeviceSignalsProvider.signals(for: settings)
        let profile = await env.resolveAntennaLocation(signals)
        uiState.antennaState = profile.toUIState()
    }
}
