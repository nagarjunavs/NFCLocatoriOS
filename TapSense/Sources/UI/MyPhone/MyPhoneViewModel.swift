import Observation
import NFCLocatorCore

struct MyPhoneUiState {
    var isLoading = true
    var displayModel = ""
    var displayManufacturer = ""
    var antennaState: AntennaLocatorUIState = .loading
}

@MainActor
@Observable
final class MyPhoneViewModel {
    private(set) var uiState = MyPhoneUiState()

    func resolveCurrent(env: AppEnvironment) async {
        uiState.isLoading = true
        let settings = env.settingsStore.settings
        let signals = env.activeDeviceSignalsProvider.signals(for: settings)
        let profile = await env.resolveAntennaLocation(signals)
        uiState.isLoading = false
        uiState.displayModel = profile.model.friendlyModelName()
        uiState.displayManufacturer = profile.manufacturer.friendlyManufacturerName()
        uiState.antennaState = profile.toUIState()
    }
}
