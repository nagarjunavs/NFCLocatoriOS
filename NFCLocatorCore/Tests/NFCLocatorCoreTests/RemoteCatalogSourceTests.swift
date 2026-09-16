import XCTest
@testable import NFCLocatorCore

final class RemoteCatalogSourceTests: XCTestCase {
    func testCacheHitSkipsNetworkEntirely() async {
        let cache = InMemoryCatalogCache()
        await cache.upsertAll([("google:pixel_8", TestFixtures.profile(source: .remoteCatalog))])
        // A remote API that always throws — proves the cache hit short-circuits before it's called.
        let source = RemoteCatalogSource(remoteAPI: FakeCatalogRemoteAPI(response: nil), cache: cache, logger: NoOpLogger())

        let result = await source.resolve(signals: TestFixtures.signals)
        XCTAssertNotNil(result)
    }

    func testCacheMissRefreshesFromRemoteAndReturnsFreshEntry() async {
        let cache = InMemoryCatalogCache()
        let entry = CatalogEntryDTO(
            manufacturer: "google", model: "pixel 8", formFactor: "BAR",
            silhouetteTemplateID: DeviceAntennaProfile.templateBar,
            zoneX: 0.3, zoneY: 0.16, zoneWidth: 0.4, zoneHeight: 0.14,
            catalogVersion: 1, verified: true
        )
        let api = FakeCatalogRemoteAPI(response: CatalogResponseDTO(catalogVersion: 1, entries: [entry]))
        let source = RemoteCatalogSource(remoteAPI: api, cache: cache, logger: NoOpLogger())

        let result = await source.resolve(signals: TestFixtures.signals)
        XCTAssertEqual(result?.confidence, .exact)
        XCTAssertEqual(result?.source, .remoteCatalog)
    }

    func testRemoteFailureReturnsNilWithoutThrowing() async {
        let cache = InMemoryCatalogCache()
        let source = RemoteCatalogSource(remoteAPI: FakeCatalogRemoteAPI(response: nil), cache: cache, logger: NoOpLogger())

        let result = await source.resolve(signals: TestFixtures.signals)
        XCTAssertNil(result)
    }

    func testRemoteSuccessButDeviceNotInResponseReturnsNil() async {
        let cache = InMemoryCatalogCache()
        let otherEntry = CatalogEntryDTO(
            manufacturer: "samsung", model: "sm-s918b", formFactor: "BAR",
            silhouetteTemplateID: DeviceAntennaProfile.templateBar,
            zoneX: 0.3, zoneY: 0.3, zoneWidth: 0.4, zoneHeight: 0.14,
            catalogVersion: 1
        )
        let api = FakeCatalogRemoteAPI(response: CatalogResponseDTO(catalogVersion: 1, entries: [otherEntry]))
        let source = RemoteCatalogSource(remoteAPI: api, cache: cache, logger: NoOpLogger())

        let result = await source.resolve(signals: TestFixtures.signals)
        XCTAssertNil(result)
    }
}
