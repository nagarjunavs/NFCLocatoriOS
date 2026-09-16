import XCTest
import NFCLocatorCore
@testable import TapSense

private final class FakeLogger: NFCLocatorLogger {
    func d(tag: String, message: String) {}
    func w(tag: String, message: String, error: Error?) {}
    func e(tag: String, message: String, error: Error?) {}
}

/// Fixed, in-memory catalog fixtures — deliberately not the real bundled seed catalog, so these
/// tests don't depend on which real devices happen to be in `seed_catalog.json`. Two Apple, two
/// Android entries, with model names chosen so a search for "pixel" or "iphone" is unambiguous.
private struct StubCatalogRemoteAPI: CatalogRemoteAPI {
    func fetchCatalog(sinceVersion: Int) async throws -> CatalogResponseDTO {
        let entries = [
            CatalogEntryDTO(
                manufacturer: "apple", model: "iphone15,2", formFactor: "BAR",
                silhouetteTemplateID: DeviceAntennaProfile.templateBar,
                zoneX: 0.3, zoneY: 0.1, zoneWidth: 0.4, zoneHeight: 0.1,
                catalogVersion: 1, lastVerifiedAtEpochMillis: nil, verified: true
            ),
            CatalogEntryDTO(
                manufacturer: "apple", model: "iphone14,5", formFactor: "BAR",
                silhouetteTemplateID: DeviceAntennaProfile.templateBar,
                zoneX: 0.3, zoneY: 0.1, zoneWidth: 0.4, zoneHeight: 0.1,
                catalogVersion: 1, lastVerifiedAtEpochMillis: nil, verified: true
            ),
            CatalogEntryDTO(
                manufacturer: "google", model: "pixel_8", formFactor: "BAR",
                silhouetteTemplateID: DeviceAntennaProfile.templateBar,
                zoneX: 0.3, zoneY: 0.2, zoneWidth: 0.4, zoneHeight: 0.1,
                catalogVersion: 1, lastVerifiedAtEpochMillis: nil, verified: false
            ),
            CatalogEntryDTO(
                manufacturer: "samsung", model: "sm-s911", formFactor: "BAR",
                silhouetteTemplateID: DeviceAntennaProfile.templateBar,
                zoneX: 0.3, zoneY: 0.2, zoneWidth: 0.4, zoneHeight: 0.1,
                catalogVersion: 1, lastVerifiedAtEpochMillis: nil, verified: false
            ),
        ]
        return CatalogResponseDTO(catalogVersion: 1, entries: entries)
    }
}

/// `PhoneSelectionViewModel.applyFilters()`'s documented contract (see its own doc comment and
/// `TapSense/DECISIONS.md`'s "Phone Selection: Android/Apple platform filter" entry): the
/// platform filter and the search query combine — switching platforms re-scopes an in-progress
/// search instead of clearing it, and a search never surfaces a result from the platform the
/// user isn't currently browsing.
@MainActor
final class PhoneSelectionViewModelTests: XCTestCase {
    private func makeRepository() -> PhoneCatalogRepository {
        // A bundle with no `seed_catalog.json` resource — `BundledSeedCatalogLoader` treats a
        // missing/unparsable asset as an empty catalog (never throws), so `allProfiles` in these
        // tests is driven entirely by `StubCatalogRemoteAPI`'s fixtures above, not the real
        // bundled seed catalog.
        let seedLoader = BundledSeedCatalogLoader(logger: FakeLogger(), bundle: Bundle(for: PhoneSelectionViewModelTests.self))
        return PhoneCatalogRepository(seedLoader: seedLoader, remoteAPI: StubCatalogRemoteAPI())
    }

    private func makeLoadedViewModel() async -> PhoneSelectionViewModel {
        let viewModel = PhoneSelectionViewModel()
        await viewModel.load(catalogRepository: makeRepository())
        return viewModel
    }

    func testDefaultPlatformFilterIsAndroidAndShowsOnlyAndroidResults() async {
        let viewModel = await makeLoadedViewModel()
        XCTAssertEqual(viewModel.uiState.platformFilter, .android)
        XCTAssertEqual(Set(viewModel.uiState.results.map(\.manufacturer)), ["google", "samsung"])
    }

    func testSwitchingToAppleShowsOnlyAppleResults() async {
        let viewModel = await makeLoadedViewModel()
        viewModel.onPlatformFilterChange(.apple)
        XCTAssertEqual(Set(viewModel.uiState.results.map(\.manufacturer)), ["apple"])
        XCTAssertEqual(viewModel.uiState.results.count, 2)
    }

    func testSearchNeverSurfacesAResultFromTheOtherPlatform() async {
        let viewModel = await makeLoadedViewModel()
        // Default platform is .android; searching for an Apple-only model must return nothing.
        viewModel.onQueryChange("iphone")
        XCTAssertTrue(viewModel.uiState.results.isEmpty)
    }

    func testSearchMatchesWithinCurrentPlatform() async {
        let viewModel = await makeLoadedViewModel()
        viewModel.onQueryChange("pixel")
        XCTAssertEqual(viewModel.uiState.results.map(\.model), ["pixel_8"])
    }

    func testSwitchingPlatformPreservesAndRescopesAnInProgressSearch() async {
        let viewModel = await makeLoadedViewModel()
        viewModel.onQueryChange("iphone")
        XCTAssertTrue(viewModel.uiState.results.isEmpty, "iphone shouldn't match under the default .android filter")

        viewModel.onPlatformFilterChange(.apple)
        XCTAssertEqual(viewModel.uiState.query, "iphone", "the query itself must survive the platform switch")
        XCTAssertEqual(Set(viewModel.uiState.results.map(\.model)), ["iphone15,2", "iphone14,5"])
    }

    func testResultsAreSortedByManufacturerThenModel() async {
        let viewModel = await makeLoadedViewModel()
        viewModel.onPlatformFilterChange(.apple)
        XCTAssertEqual(viewModel.uiState.results.map(\.model), ["iphone14,5", "iphone15,2"])
    }
}
