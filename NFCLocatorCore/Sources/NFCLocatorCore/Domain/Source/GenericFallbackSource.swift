import Foundation

/// Layer 3 (last resort) of the resolver chain — "the device-shape heuristic that never
/// fails." Pure computation, zero I/O. This is what guarantees
/// ``ResolveAntennaLocationUseCase`` never returns without a profile.
public struct GenericFallbackSource: AntennaLocationSource {
    public init() {}

    public func resolve(signals: DeviceIdentitySignals) async -> DeviceAntennaProfile? {
        let zone = Self.zone(for: signals.formFactor, foldState: signals.foldState)
        return DeviceAntennaProfile(
            manufacturer: signals.fingerprint.manufacturer,
            model: signals.fingerprint.model,
            formFactor: signals.formFactor,
            silhouetteTemplateID: signals.formFactor.silhouetteTemplateID(foldState: signals.foldState),
            antennaZone: zone,
            confidence: .generic,
            source: .heuristic,
            catalogVersion: 0,
            lastVerifiedAt: nil
        )
    }

    /// The zone-assignment algorithm: a small, fixed lookup keyed by form factor and fold
    /// state, not a computed geometry model.
    static func zone(for formFactor: FormFactor, foldState: FoldState) -> NormalizedRect {
        let (centerX, centerY, side): (Float, Float, Float)
        switch (formFactor, foldState) {
        case (.bar, _):
            // Upper-center rear, near the main camera bump.
            (centerX, centerY, side) = (0.5, 0.22, 0.30)
        case (.tablet, _):
            // Center mid-back regardless of orientation.
            (centerX, centerY, side) = (0.5, 0.45, 0.34)
        case (.foldBook, .folded):
            // Thick bar phone, upper-center rear (cover screen side).
            (centerX, centerY, side) = (0.5, 0.24, 0.34)
        case (.foldBook, .unfolded), (.foldBook, .notApplicable):
            // One inner half, away from the hinge.
            (centerX, centerY, side) = (0.25, 0.5, 0.30)
        case (.foldFlip, .folded):
            // Center rear, near the cover screen/hinge.
            (centerX, centerY, side) = (0.5, 0.45, 0.34)
        case (.foldFlip, .unfolded), (.foldFlip, .notApplicable):
            // Center-upper rear.
            (centerX, centerY, side) = (0.5, 0.28, 0.32)
        }
        return NormalizedRect.centeredSquare(centerX: centerX, centerY: centerY, side: side)
    }
}
