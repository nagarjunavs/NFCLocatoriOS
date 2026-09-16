import XCTest
import NFCLocatorCore
@testable import TapSense

private final class FakeLogger: NFCLocatorLogger {
    func d(tag: String, message: String) {}
    func w(tag: String, message: String, error: Error?) {}
    func e(tag: String, message: String, error: Error?) {}
}

/// `TapSenseSettingsStore` is the component `DECISIONS.md` calls out as privacy-load-bearing —
/// it's what keeps a restored backup from silently reintroducing a completed-onboarding flag
/// after a genuine reinstall (see the store's own doc comment). These tests exercise it against
/// a throwaway temp directory rather than the real `Application Support`.
@MainActor
final class TapSenseSettingsStoreTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        super.tearDown()
    }

    private func makeStore() -> TapSenseSettingsStore {
        TapSenseSettingsStore(logger: FakeLogger(), directory: tempDirectory)
    }

    func testDefaultsWhenNoFileExistsYet() {
        let store = makeStore()
        XCTAssertEqual(store.settings, TapSenseSettings())
    }

    func testSetOnboardingCompletedPersistsAcrossInstances() {
        let store = makeStore()
        store.setOnboardingCompleted(true)

        let reloaded = makeStore()
        XCTAssertTrue(reloaded.settings.onboardingCompleted)
    }

    func testSetOnboardingCompletedIsANoOpWhenValueUnchanged() {
        let store = makeStore()
        store.setOnboardingCompleted(false)
        XCTAssertFalse(store.settings.onboardingCompleted)
        // Guarded by `guard settings.onboardingCompleted != completed else { return }` — this
        // exercises the early-return path without observing internal persist() call counts,
        // since no I/O should occur when the value doesn't change.
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("tapsense_settings.json").path))
    }

    func testSetSelectedPhoneRoundTrips() {
        let store = makeStore()
        store.setSelectedPhone(manufacturer: "google", model: "pixel_8", formFactor: .bar)

        let reloaded = makeStore()
        XCTAssertEqual(reloaded.settings.manufacturer, "google")
        XCTAssertEqual(reloaded.settings.model, "pixel_8")
        XCTAssertEqual(reloaded.settings.formFactor, .bar)
        XCTAssertTrue(reloaded.settings.hasManualPhoneOverride)
    }

    func testClearSelectedPhoneRemovesOverride() {
        let store = makeStore()
        store.setSelectedPhone(manufacturer: "google", model: "pixel_8", formFactor: .bar)
        store.clearSelectedPhone()

        let reloaded = makeStore()
        XCTAssertNil(reloaded.settings.manufacturer)
        XCTAssertNil(reloaded.settings.model)
        XCTAssertNil(reloaded.settings.formFactor)
        XCTAssertFalse(reloaded.settings.hasManualPhoneOverride)
    }

    func testHapticsReduceMotionAndAppearanceModeRoundTrip() {
        let store = makeStore()
        store.setHapticsEnabled(false)
        store.setReduceMotion(true)
        store.setAppearanceMode(.dark)

        let reloaded = makeStore()
        XCTAssertFalse(reloaded.settings.hapticsEnabled)
        XCTAssertTrue(reloaded.settings.reduceMotion)
        XCTAssertEqual(reloaded.settings.appearanceMode, .dark)
    }

    func testSettingsFileIsExcludedFromBackup() throws {
        let store = makeStore()
        store.setHapticsEnabled(false)

        let fileURL = tempDirectory.appendingPathComponent("tapsense_settings.json")
        let values = try fileURL.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(values.isExcludedFromBackup, true)
    }
}
