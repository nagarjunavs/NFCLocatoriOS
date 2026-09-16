import Observation
import NFCLocatorCore

/// Which side of the catalog to browse. The seed/remote catalog only ever carries Apple and
/// Android-OEM entries (Samsung/Google/OnePlus/Xiaomi/Motorola/Sony, ...), so this is a plain
/// binary split on `manufacturer`, not a whitelist that needs extending as new Android OEMs are
/// added to the catalog — "not Apple" is the whole rule for `.android`.
enum PhoneSelectionPlatform: String, CaseIterable, Equatable {
    case android
    case apple
}

struct PhoneSelectionUiState {
    var query = ""
    var platformFilter: PhoneSelectionPlatform = .android
    var isLoading = true
    var results: [DeviceAntennaProfile] = []
}

@MainActor
@Observable
final class PhoneSelectionViewModel {
    private(set) var uiState = PhoneSelectionUiState()
    private var allProfiles: [DeviceAntennaProfile] = []

    func load(env: AppEnvironment) async {
        allProfiles = await env.phoneCatalogRepository.listAll()
        uiState.isLoading = false
        applyFilters()
    }

    func onQueryChange(_ query: String) {
        uiState.query = query
        applyFilters()
    }

    func onPlatformFilterChange(_ platform: PhoneSelectionPlatform) {
        guard uiState.platformFilter != platform else { return }
        uiState.platformFilter = platform
        applyFilters()
    }

    func selectPhone(_ profile: DeviceAntennaProfile, env: AppEnvironment, onSelected: () -> Void) {
        env.settingsStore.setSelectedPhone(manufacturer: profile.manufacturer, model: profile.model, formFactor: profile.formFactor)
        onSelected()
    }

    func useMyPhoneAutomatically(env: AppEnvironment, onDone: () -> Void) {
        env.settingsStore.clearSelectedPhone()
        onDone()
    }

    /// Applies the platform filter first, then the search query on top of that result — so
    /// searching always searches *within* the selected platform, matching the design's intent
    /// (the two controls narrow together, neither one resets the other).
    private func applyFilters() {
        let onPlatform = allProfiles.filter { profile in
            let isApple = profile.manufacturer.lowercased() == "apple"
            return uiState.platformFilter == .apple ? isApple : !isApple
        }
        let needle = uiState.query.trimmingCharacters(in: .whitespaces).lowercased()
        uiState.results = needle.isEmpty
            ? onPlatform
            : onPlatform.filter { $0.manufacturer.lowercased().contains(needle) || $0.model.lowercased().contains(needle) }
    }
}
