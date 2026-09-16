import XCTest
@testable import NFCLocatorCore

final class BundledSeedCatalogLoaderTests: XCTestCase {
    func testLoadsRealBundledSeedCatalog() async {
        let loader = BundledSeedCatalogLoader(logger: NoOpLogger())
        let catalog = await loader.load()

        XCTAssertEqual(catalog.catalogVersion, 2)
        XCTAssertEqual(catalog.entries.count, 43)
        XCTAssertTrue(catalog.entries.contains { $0.manufacturer == "apple" && $0.model == "iphone15,2" })
        XCTAssertTrue(catalog.entries.contains { $0.manufacturer == "apple" && $0.model == "iphone13,2" })
        XCTAssertTrue(catalog.entries.contains { $0.manufacturer == "samsung" && $0.model == "sm-s928b" })
        XCTAssertTrue(catalog.entries.contains { $0.manufacturer == "google" && $0.model == "pixel 9 pro" })
    }

    func testSecondLoadReturnsCachedInstance() async {
        let loader = BundledSeedCatalogLoader(logger: NoOpLogger())
        let first = await loader.load()
        let second = await loader.load()
        XCTAssertEqual(first, second)
    }

    func testMissingResourceFallsBackToEmptyCatalogInsteadOfCrashing() async {
        // An empty bundle has no seed_catalog.json — the loader must degrade gracefully.
        let loader = BundledSeedCatalogLoader(logger: NoOpLogger(), bundle: Bundle(for: NoOpMarker.self))
        let catalog = await loader.load()
        XCTAssertEqual(catalog.catalogVersion, 0)
        XCTAssertTrue(catalog.entries.isEmpty)
    }
}

private final class NoOpMarker {}
