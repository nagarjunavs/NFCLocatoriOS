import Foundation

/// How trustworthy a resolved ``DeviceAntennaProfile`` is, ordered strongest to weakest.
///
/// Always carried alongside the resolved zone — never hidden from the UI. `exact` and
/// `approximate` earn a solid marker; `generic` and `unknown` earn a dashed, sweeping
/// highlight instead. See `AntennaSilhouette`'s `isConfident` parameter.
public enum Confidence: String, Codable, Sendable, CaseIterable {
    /// Vendor/community-verified for this exact model — a catalog entry with `verified == true`.
    /// (On Android this could also come from the OS-reported antenna hardware API; iOS has no
    /// such API, so on this platform `exact` is reachable only via a verified catalog entry.)
    case exact = "EXACT"
    /// An unverified catalog match — a model-specific lookup, but not vendor-confirmed.
    case approximate = "APPROXIMATE"
    /// A form-factor heuristic guess. Always succeeds; never fails.
    case generic = "GENERIC"
    /// Nothing resolved at all.
    case unknown = "UNKNOWN"
}
