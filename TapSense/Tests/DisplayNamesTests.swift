import XCTest
@testable import TapSense

final class DisplayNamesTests: XCTestCase {
    func testToDisplayDeviceNameCapitalizesAfterEveryDelimiter() {
        XCTAssertEqual("sdk_gphone64_arm64".toDisplayDeviceName(), "Sdk Gphone64 Arm64")
        XCTAssertEqual("moto g power".toDisplayDeviceName(), "Moto G Power")
        XCTAssertEqual("sm-a546b".toDisplayDeviceName(), "Sm-A546b")
    }

    func testToDisplayDeviceNameCapitalizesFirstLetterEvenAfterLeadingDigits() {
        // `capitalizeNext` starts `true` and is only ever reset by a space/hyphen, never by a
        // digit — so the first letter of an all-digit-prefixed SKU still gets capitalized. This
        // isn't a "real" marketing name (no canonical casing exists for a bare SKU without a
        // device-name dictionary), just this fallback's deterministic, slightly odd output —
        // matches the Kotlin original's identical algorithm exactly.
        XCTAssertEqual("24031pn0dc".toDisplayDeviceName(), "24031Pn0dc")
    }

    func testFriendlyModelNameUsesKnownTableEntry() {
        XCTAssertEqual("sm-s918b".friendlyModelName(), "Galaxy S23 Ultra")
        XCTAssertEqual("iphone15,2".friendlyModelName(), "iPhone 14 Pro")
        XCTAssertEqual("pixel 8 pro".friendlyModelName(), "Pixel 8 Pro")
    }

    func testFriendlyModelNameIsCaseAndWhitespaceInsensitive() {
        XCTAssertEqual("  SM-S918B  ".friendlyModelName(), "Galaxy S23 Ultra")
    }

    func testFriendlyModelNameFallsBackToDisplayNameForUnknownModel() {
        XCTAssertEqual("totally_unknown_model".friendlyModelName(), "Totally Unknown Model")
    }

    /// Regression test for a real-device bug: `TapSenseDeviceFingerprintProvider` normalizes
    /// the raw `hw.machine` sysctl string (comma-separated, e.g. `"iPhone13,2"`) via
    /// `DeviceFingerprint.normalize` *before* it ever reaches `friendlyModelName()`, arriving as
    /// `"iphone13_2"` — but the lookup table used to be keyed on the catalog's raw comma format
    /// (`"iphone15,2"`), which a normalized underscore-separated string can never match. On a
    /// real iPhone 12 this meant the correct table entry was unreachable via the actual runtime
    /// path and the device fell through to generic capitalization, displaying a mangled name
    /// instead of "iPhone 12". Covers both the already-normalized real-device form and the raw
    /// catalog-authored form, since both must resolve to the same result.
    func testFriendlyModelNameResolvesRealDeviceIPhone12() {
        XCTAssertEqual("iphone13_2".friendlyModelName(), "iPhone 12")
        XCTAssertEqual("iPhone13,2".friendlyModelName(), "iPhone 12")
        XCTAssertEqual("iphone13,2".friendlyModelName(), "iPhone 12")
    }

    func testFriendlyModelNameResolvesOtherRealDeviceIPhones() {
        XCTAssertEqual("iphone14_5".friendlyModelName(), "iPhone 13")
        XCTAssertEqual("iphone16_2".friendlyModelName(), "iPhone 15 Pro Max")
        XCTAssertEqual("iphone12_8".friendlyModelName(), "iPhone SE (2nd generation)")
    }

    func testFriendlyManufacturerNameUsesKnownTableEntry() {
        XCTAssertEqual("samsung".friendlyManufacturerName(), "Samsung")
        XCTAssertEqual("apple".friendlyManufacturerName(), "Apple")
    }

    func testFriendlyManufacturerNameFallsBackForUnknownManufacturer() {
        XCTAssertEqual("acme_corp".friendlyManufacturerName(), "Acme Corp")
    }

    func testFriendlyDeviceNameCombinesBoth() {
        XCTAssertEqual(friendlyDeviceName(manufacturer: "google", model: "pixel 8 pro"), "Google Pixel 8 Pro")
        XCTAssertEqual(friendlyDeviceName(manufacturer: "apple", model: "iphone15,2"), "Apple iPhone 14 Pro")
    }
}
