import Foundation

/// The UI-shaped projection of a resolved (or in-flight) profile. Produced from a
/// ``DeviceAntennaProfile`` via `toUIState()` (see `AntennaLocatorUIStateMapper.swift`) —
/// never constructed with a mismatched confidence, which the two payload types' initializers
/// enforce at runtime via `precondition`.
public enum AntennaLocatorUIState: Sendable, Equatable {
    case loading
    case error
    case resolvedMarker(ResolvedMarker)
    case fallbackGuidance(FallbackGuidance)

    /// A confident (or previously-confident-but-stale) result: a solid marker, or — if stale —
    /// a marker paired with a sweep hint.
    public struct ResolvedMarker: Sendable, Equatable {
        public let formFactor: FormFactor
        public let silhouetteTemplateID: String
        public let antennaZone: NormalizedRect
        public let confidence: Confidence
        public let source: DataSource
        public let isStale: Bool
        public let aspectRatio: Float?

        /// - Precondition: `confidence` must be `.exact` or `.approximate`. This is the
        ///   runtime enforcement of "never show a confident marker for a guess" — the single
        ///   most important invariant in this file. Constructing this with `.generic` or
        ///   `.unknown` is a programmer error and traps, exactly as the Kotlin `require` does.
        public init(
            formFactor: FormFactor,
            silhouetteTemplateID: String,
            antennaZone: NormalizedRect,
            confidence: Confidence,
            source: DataSource,
            isStale: Bool,
            aspectRatio: Float? = nil
        ) {
            precondition(
                confidence == .exact || confidence == .approximate,
                "ResolvedMarker requires .exact or .approximate confidence, got \(confidence)"
            )
            self.formFactor = formFactor
            self.silhouetteTemplateID = silhouetteTemplateID
            self.antennaZone = antennaZone
            self.confidence = confidence
            self.source = source
            self.isStale = isStale
            self.aspectRatio = aspectRatio
        }
    }

    /// A guess: a dashed sweeping highlight, never a solid marker.
    public struct FallbackGuidance: Sendable, Equatable {
        public let formFactor: FormFactor
        public let silhouetteTemplateID: String
        public let approximateZone: NormalizedRect
        public let confidence: Confidence
        public let tipTextKey: String
        public let aspectRatio: Float?

        /// - Precondition: `confidence` must be `.generic` or `.unknown`.
        public init(
            formFactor: FormFactor,
            silhouetteTemplateID: String,
            approximateZone: NormalizedRect,
            confidence: Confidence,
            tipTextKey: String,
            aspectRatio: Float? = nil
        ) {
            precondition(
                confidence == .generic || confidence == .unknown,
                "FallbackGuidance requires .generic or .unknown confidence, got \(confidence)"
            )
            self.formFactor = formFactor
            self.silhouetteTemplateID = silhouetteTemplateID
            self.approximateZone = approximateZone
            self.confidence = confidence
            self.tipTextKey = tipTextKey
            self.aspectRatio = aspectRatio
        }
    }

    /// `true` for a `.fallbackGuidance`, or a `.resolvedMarker` that's stale.
    public var isGuidedSweep: Bool {
        switch self {
        case .fallbackGuidance:
            return true
        case .resolvedMarker(let marker):
            return marker.isStale
        case .loading, .error:
            return false
        }
    }
}
