import Observation
import NFCLocatorCore

struct HomeUiState {
    var isLoading = true
    var displayModel = ""
    var displayManufacturer = ""
    var antennaState: AntennaLocatorUIState = .loading
}

@MainActor
@Observable
final class HomeViewModel {
    private(set) var uiState = HomeUiState()

    func resolveCurrent(env: AppEnvironment) async {
        uiState.isLoading = true
        let settings = env.settingsStore.settings
        let signals = env.activeDeviceSignalsProvider.signals(for: settings)
        let profile = await env.resolveAntennaLocation(signals)
        uiState = HomeUiState(
            isLoading: false,
            displayModel: friendlyDeviceName(manufacturer: profile.manufacturer, model: profile.model),
            displayManufacturer: profile.manufacturer.friendlyManufacturerName(),
            antennaState: profile.toUIState()
        )
    }
}
