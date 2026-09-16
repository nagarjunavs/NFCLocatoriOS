import XCTest
import SwiftData
@testable import NFCLocatorCore

final class SwiftDataCatalogCacheTests: XCTestCase {
    private func makeInMemoryCache() throws -> SwiftDataCatalogCache {
        let container = try SwiftDataCatalogCache.makeModelContainer(inMemoryOnly: true)
        return SwiftDataCatalogCache(modelContainer: container)
    }

    func testUpsertThenFindRoundTrips() async throws {
        let cache = try makeInMemoryCache()
        let profile = TestFixtures.profile(confidence: .exact, source: .remoteCatalog)

        await cache.upsertAll([("google:pixel 8", profile)])
        let found = await cache.find(lookupKeys: ["google:pixel 8"])

        XCTAssertEqual(found, profile)
    }

    func testFindTriesKeysInOrder() async throws {
        let cache = try makeInMemoryCache()
        let specific = TestFixtures.profile(confidence: .exact, source: .remoteCatalog)
        await cache.upsertAll([("google:pixel 8", specific)])

        let found = await cache.find(lookupKeys: ["nonexistent:key", "google:pixel 8"])
        XCTAssertEqual(found, specific)
    }

    func testUpsertReplacesExistingRowForSameKey() async throws {
        let cache = try makeInMemoryCache()
        await cache.upsertAll([("google:pixel 8", TestFixtures.profile(confidence: .approximate))])
        await cache.upsertAll([("google:pixel 8", TestFixtures.profile(confidence: .exact))])

        let found = await cache.find(lookupKeys: ["google:pixel 8"])
        XCTAssertEqual(found?.confidence, .exact)
        let all = await cache.listAll()
        XCTAssertEqual(all.count, 1)
    }

    func testLatestCachedVersionReflectsHighestVersionSeen() async throws {
        let cache = try makeInMemoryCache()
        let initialVersion = await cache.latestCachedVersion()
        XCTAssertEqual(initialVersion, 0)

        await cache.upsertAll([
            ("a:b", TestFixtures.profile()),
            ("c:d", DeviceAntennaProfile(
                manufacturer: "c", model: "d", formFactor: .bar, silhouetteTemplateID: DeviceAntennaProfile.templateBar,
                antennaZone: .centeredSquare(centerX: 0.5, centerY: 0.2, side: 0.3),
                confidence: .approximate, source: .remoteCatalog, catalogVersion: 5, lastVerifiedAt: nil
            )),
        ])

        let updatedVersion = await cache.latestCachedVersion()
        XCTAssertEqual(updatedVersion, 5)
    }

    func testListAllSortedByManufacturerThenModel() async throws {
        let cache = try makeInMemoryCache()
        await cache.upsertAll([
            ("samsung:z", DeviceAntennaProfile(manufacturer: "samsung", model: "z", formFactor: .bar, silhouetteTemplateID: DeviceAntennaProfile.templateBar, antennaZone: .centeredSquare(centerX: 0.5, centerY: 0.2, side: 0.3), confidence: .approximate, source: .seedCatalog, catalogVersion: 1, lastVerifiedAt: nil)),
            ("apple:a", DeviceAntennaProfile(manufacturer: "apple", model: "a", formFactor: .bar, silhouetteTemplateID: DeviceAntennaProfile.templateBar, antennaZone: .centeredSquare(centerX: 0.5, centerY: 0.2, side: 0.3), confidence: .approximate, source: .seedCatalog, catalogVersion: 1, lastVerifiedAt: nil)),
        ])

        let all = await cache.listAll()
        XCTAssertEqual(all.map(\.manufacturer), ["apple", "samsung"])
    }
}
