import Foundation

/// One of the library's three host seams. The library performs no analytics of its own — the
/// host app implements this against its existing pipeline (or a no-op stub).
///
/// Per-method firing contract:
/// - `guidanceShown` fires every time ``ResolveAntennaLocationUseCase`` produces a winning
///   profile.
/// - `guidanceDismissed` is **not called by the library** — it's host-invoked when the user
///   backs out of a guidance screen before completing a tap, carrying dwell time.
/// - `unknownDeviceDetected` fires only when the winning `source == .heuristic`.
/// - `catalogMatchFound` fires only when `source` is `.remoteCatalog` or `.seedCatalog`.
/// - `android14AntennaDetected` — **never fires on iOS**. Kept in the protocol so a host
///   reporting to one shared analytics backend across multiple client platforms can implement
///   a single handler without special-casing per platform; iOS has no OS-reported antenna
///   hardware source.
/// - `retryGuidanceShown` is also host-invoked, paired with ``RetryGuidanceBanner``.
public protocol NFCLocatorAnalytics: Sendable {
    func guidanceShown(confidence: Confidence, source: DataSource, formFactor: FormFactor)
    func guidanceDismissed(confidence: Confidence, timeVisibleMillis: Int64)
    func unknownDeviceDetected(manufacturer: String, formFactorGuess: FormFactor)
    func catalogMatchFound(confidence: Confidence, source: DataSource, catalogVersion: Int)
    func android14AntennaDetected(antennaCount: Int)
    func retryGuidanceShown(attemptNumber: Int, confidence: Confidence)
}
