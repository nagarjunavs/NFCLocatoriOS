import XCTest
@testable import NFCLocatorCore

final class DeviceFingerprintTests: XCTestCase {
    func testNormalizeLowercasesAndCollapsesNonAlphanumerics() {
        XCTAssertEqual(DeviceFingerprint.normalize("SM-S918B"), "sm_s918b")
        XCTAssertEqual(DeviceFingerprint.normalize("--Pixel--Fold--"), "pixel_fold")
        XCTAssertEqual(DeviceFingerprint.normalize("iPhone15,2"), "iphone15_2")
        XCTAssertEqual(DeviceFingerprint.normalize("  spaced out  "), "spaced_out")
    }

    func testLookupKeysMostSpecificFirstWithSKU() {
        let fp = DeviceFingerprint(manufacturer: "apple", brand: "apple", model: "iphone15,2", device: "iphone15,2", product: "iphone15,2", sku: "a2896")
        XCTAssertEqual(fp.lookupKeys(), [
            "apple:iphone15,2:a2896",
            "apple:iphone15,2",
        ])
    }

    func testLookupKeysWithoutSKUOmitsSKUVariantAndDeduplicates() {
        let fp = DeviceFingerprint(manufacturer: "google", brand: "google", model: "pixel 8", device: "pixel 8", product: "pixel 8", sku: nil)
        XCTAssertEqual(fp.lookupKeys(), ["google:pixel 8"])
    }

    func testLookupKeysBlankSKUTreatedAsAbsent() {
        let fp = DeviceFingerprint(manufacturer: "google", brand: "google", model: "pixel 8", device: "p8", product: "p8prod", sku: "   ")
        XCTAssertEqual(fp.lookupKeys(), ["google:pixel 8", "google:p8", "google:p8prod"])
    }
}
