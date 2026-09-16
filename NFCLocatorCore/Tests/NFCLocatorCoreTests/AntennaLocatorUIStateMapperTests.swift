import XCTest
@testable import NFCLocatorCore

final class AntennaLocatorUIStateMapperTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_704_067_200) // 2024-01-01

    func testExactNeverStaleRegardlessOfAge() {
        let old = now.addingTimeInterval(-400 * 86400)
        let profile = TestFixtures.profile(confidence: .exact, source: .seedCatalog, lastVerifiedAt: old)
        XCTAssertFalse(profile.isStale(now: now))
    }

    func testApproximateWithNoTimestampIsStale() {
        let profile = TestFixtures.profile(confidence: .approximate, lastVerifiedAt: nil)
        XCTAssertTrue(profile.isStale(now: now))
    }

    func testApproximateExactly180DaysIsNotStale() {
        let boundary = now.addingTimeInterval(-180 * 86400)
        let profile = TestFixtures.profile(confidence: .approximate, lastVerifiedAt: boundary)
        XCTAssertFalse(profile.isStale(now: now))
    }

    func testApproximate200DaysIsStale() {
        let old = now.addingTimeInterval(-200 * 86400)
        let profile = TestFixtures.profile(confidence: .approximate, lastVerifiedAt: old)
        XCTAssertTrue(profile.isStale(now: now))
    }

    func testExactAndApproximateMapToResolvedMarker() {
        let profile = TestFixtures.profile(confidence: .exact, lastVerifiedAt: now)
        guard case .resolvedMarker = profile.toUIState(now: now) else {
            return XCTFail("expected .resolvedMarker")
        }
    }

    func testGenericAndUnknownMapToFallbackGuidance() {
        let profile = TestFixtures.profile(confidence: .generic, source: .heuristic)
        guard case .fallbackGuidance = profile.toUIState(now: now) else {
            return XCTFail("expected .fallbackGuidance")
        }
    }

    func testStaleApproximateSetsIsStaleOnResolvedMarker() {
        let old = now.addingTimeInterval(-200 * 86400)
        let profile = TestFixtures.profile(confidence: .approximate, lastVerifiedAt: old)
        guard case .resolvedMarker(let marker) = profile.toUIState(now: now) else {
            return XCTFail("expected .resolvedMarker")
        }
        XCTAssertTrue(marker.isStale)
        XCTAssertTrue(profile.toUIState(now: now).isGuidedSweep)
    }

    func testTipTextKeyVariesByFormFactorForGeneric() {
        let bar = DeviceAntennaProfile(
            manufacturer: "m", model: "x", formFactor: .bar, silhouetteTemplateID: DeviceAntennaProfile.templateBar,
            antennaZone: .centeredSquare(centerX: 0.5, centerY: 0.2, side: 0.3),
            confidence: .generic, source: .heuristic, catalogVersion: 0, lastVerifiedAt: nil
        )
        let tablet = DeviceAntennaProfile(
            manufacturer: "m", model: "x", formFactor: .tablet, silhouetteTemplateID: DeviceAntennaProfile.templateTablet,
            antennaZone: .centeredSquare(centerX: 0.5, centerY: 0.45, side: 0.34),
            confidence: .generic, source: .heuristic, catalogVersion: 0, lastVerifiedAt: nil
        )
        guard case .fallbackGuidance(let barState) = bar.toUIState(now: now),
              case .fallbackGuidance(let tabletState) = tablet.toUIState(now: now)
        else { return XCTFail("expected .fallbackGuidance") }

        XCTAssertEqual(barState.tipTextKey, "nfc_locator.sweep.bar_tip")
        XCTAssertEqual(tabletState.tipTextKey, "nfc_locator.sweep.tablet_tip")
    }

    func testUnknownConfidenceUsesUnknownTipRegardlessOfFormFactor() {
        let profile = DeviceAntennaProfile(
            manufacturer: "m", model: "x", formFactor: .tablet, silhouetteTemplateID: DeviceAntennaProfile.templateTablet,
            antennaZone: .centeredSquare(centerX: 0.5, centerY: 0.45, side: 0.34),
            confidence: .unknown, source: .heuristic, catalogVersion: 0, lastVerifiedAt: nil
        )
        guard case .fallbackGuidance(let state) = profile.toUIState(now: now) else {
            return XCTFail("expected .fallbackGuidance")
        }
        XCTAssertEqual(state.tipTextKey, "nfc_locator.sweep.unknown_tip")
    }
}
