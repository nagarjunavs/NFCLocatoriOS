import Foundation
@testable import NFCLocatorCore

struct StubSource: AntennaLocationSource {
    let result: DeviceAntennaProfile?
    let onCalled: (@Sendable () -> Void)?

    init(result: DeviceAntennaProfile?, onCalled: (@Sendable () -> Void)? = nil) {
        self.result = result
        self.onCalled = onCalled
    }

    func resolve(signals: DeviceIdentitySignals) async -> DeviceAntennaProfile? {
        onCalled?()
        return result
    }
}

final class CallCountingSource: AntennaLocationSource, @unchecked Sendable {
    let result: DeviceAntennaProfile?
    private(set) var callCount = 0

    init(result: DeviceAntennaProfile?) {
        self.result = result
    }

    func resolve(signals: DeviceIdentitySignals) async -> DeviceAntennaProfile? {
        callCount += 1
        return result
    }
}

final class RecordingAnalytics: NFCLocatorAnalytics, @unchecked Sendable {
    private(set) var events: [String] = []

    func guidanceShown(confidence: Confidence, source: DataSource, formFactor: String) {
        events.append("guidanceShown(\(confidence),\(source),\(formFactor))")
    }
    func guidanceDismissed(confidence: Confidence, timeVisibleMillis: Int64) {
        events.append("guidanceDismissed")
    }
    func unknownDeviceDetected(manufacturer: String, formFactorGuess: String) {
        events.append("unknownDeviceDetected(\(manufacturer),\(formFactorGuess))")
    }
    func catalogMatchFound(confidence: Confidence, source: DataSource, catalogVersion: Int) {
        events.append("catalogMatchFound(\(confidence),\(source),\(catalogVersion))")
    }
    func android14AntennaDetected(antennaCount: Int) {
        events.append("android14AntennaDetected")
    }
    func retryGuidanceShown(attemptNumber: Int, confidence: Confidence) {
        events.append("retryGuidanceShown")
    }
}

struct NoOpLogger: NFCLocatorLogger {
    func d(tag: String, message: String) {}
    func w(tag: String, message: String, error: Error?) {}
    func e(tag: String, message: String, error: Error?) {}
}

actor InMemoryCatalogCache: CatalogCache {
    private var storage: [String: DeviceAntennaProfile] = [:]
    private var version = 0

    func find(lookupKeys: [String]) -> DeviceAntennaProfile? {
        for key in lookupKeys {
            if let hit = storage[key] { return hit }
        }
        return nil
    }

    func upsertAll(_ entries: [(key: String, profile: DeviceAntennaProfile)]) {
        for (key, profile) in entries {
            storage[key] = profile
            version = max(version, profile.catalogVersion)
        }
    }

    func latestCachedVersion() -> Int { version }
    func listAll() -> [DeviceAntennaProfile] { Array(storage.values) }
}

struct FakeCatalogRemoteAPI: CatalogRemoteAPI {
    enum FakeError: Error { case simulatedFailure }

    let response: CatalogResponseDTO?

    func fetchCatalog(sinceVersion: Int) async throws -> CatalogResponseDTO {
        guard let response else { throw FakeError.simulatedFailure }
        return response
    }
}

enum TestFixtures {
    // DeviceFingerprint fields are expected pre-normalized by producers (see
    // DeviceFingerprint.normalize) — "pixel 8" the display name becomes "pixel_8" the key.
    static let signals = DeviceIdentitySignals(
        fingerprint: DeviceFingerprint(manufacturer: "google", brand: "google", model: "pixel_8", device: "pixel_8", product: "pixel_8"),
        formFactor: .bar,
        foldState: .notApplicable,
        screenSizeClass: .compact
    )

    static func profile(
        confidence: Confidence = .approximate,
        source: DataSource = .seedCatalog,
        lastVerifiedAt: Date? = nil
    ) -> DeviceAntennaProfile {
        DeviceAntennaProfile(
            manufacturer: "google",
            model: "pixel 8",
            formFactor: .bar,
            silhouetteTemplateID: DeviceAntennaProfile.templateBar,
            antennaZone: .centeredSquare(centerX: 0.5, centerY: 0.2, side: 0.3),
            confidence: confidence,
            source: source,
            catalogVersion: 1,
            lastVerifiedAt: lastVerifiedAt
        )
    }
}
