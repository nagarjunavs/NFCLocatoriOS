import XCTest
@testable import NFCLocatorCore

final class BundledSeedCatalogSourceTests: XCTestCase {
    func testMatchesRealBundledSeedCatalogEntry() async {
        let loader = BundledSeedCatalogLoader(logger: NoOpLogger())
        let source = BundledSeedCatalogSource(loader: loader, logger: NoOpLogger())

        // Pre-normalized, as a real provider would produce: "iphone15,2" -> "iphone15_2".
        let fp = DeviceFingerprint(manufacturer: "apple", brand: "apple", model: "iphone15_2", device: "iphone15_2", product: "iphone15_2")
        let signals = DeviceIdentitySignals(fingerprint: fp, formFactor: .bar, foldState: .notApplicable, screenSizeClass: .compact)

        let result = await source.resolve(signals: signals)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.manufacturer, "apple")
        XCTAssertEqual(result?.source, .seedCatalog)
    }

    func testUnknownDeviceReturnsNil() async {
        let loader = BundledSeedCatalogLoader(logger: NoOpLogger())
        let source = BundledSeedCatalogSource(loader: loader, logger: NoOpLogger())

        let fp = DeviceFingerprint(manufacturer: "nokia", brand: "nokia", model: "totally-unknown-phone", device: "x", product: "y")
        let signals = DeviceIdentitySignals(fingerprint: fp, formFactor: .bar, foldState: .notApplicable, screenSizeClass: .compact)

        let result = await source.resolve(signals: signals)
        XCTAssertNil(result)
    }
}
