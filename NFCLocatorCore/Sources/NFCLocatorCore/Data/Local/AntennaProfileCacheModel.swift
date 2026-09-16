import Foundation
import SwiftData

/// The SwiftData-persisted row shape for a cached catalog entry. `lookupKey` uses the same
/// normalization as `DeviceFingerprint.lookupKeys()` / `CatalogEntryDTO.lookupKey()`:
/// `"<manufacturer>:<model>"`, both pre-normalized.
@Model
final class AntennaProfileCacheModel {
    @Attribute(.unique) var lookupKey: String
    var manufacturer: String
    var model: String
    var formFactor: String
    var silhouetteTemplateID: String
    var zoneX: Float
    var zoneY: Float
    var zoneWidth: Float
    var zoneHeight: Float
    var confidence: String
    var source: String
    var catalogVersion: Int
    var lastVerifiedAtEpochMillis: Int64?
    var aspectRatio: Float?

    init(
        lookupKey: String,
        manufacturer: String,
        model: String,
        formFactor: String,
        silhouetteTemplateID: String,
        zoneX: Float,
        zoneY: Float,
        zoneWidth: Float,
        zoneHeight: Float,
        confidence: String,
        source: String,
        catalogVersion: Int,
        lastVerifiedAtEpochMillis: Int64?,
        aspectRatio: Float?
    ) {
        self.lookupKey = lookupKey
        self.manufacturer = manufacturer
        self.model = model
        self.formFactor = formFactor
        self.silhouetteTemplateID = silhouetteTemplateID
        self.zoneX = zoneX
        self.zoneY = zoneY
        self.zoneWidth = zoneWidth
        self.zoneHeight = zoneHeight
        self.confidence = confidence
        self.source = source
        self.catalogVersion = catalogVersion
        self.lastVerifiedAtEpochMillis = lastVerifiedAtEpochMillis
        self.aspectRatio = aspectRatio
    }

    convenience init(lookupKey: String, profile: DeviceAntennaProfile) {
        self.init(
            lookupKey: lookupKey,
            manufacturer: profile.manufacturer,
            model: profile.model,
            formFactor: profile.formFactor.rawValue,
            silhouetteTemplateID: profile.silhouetteTemplateID,
            zoneX: profile.antennaZone.x,
            zoneY: profile.antennaZone.y,
            zoneWidth: profile.antennaZone.width,
            zoneHeight: profile.antennaZone.height,
            confidence: profile.confidence.rawValue,
            source: profile.source.rawValue,
            catalogVersion: profile.catalogVersion,
            lastVerifiedAtEpochMillis: profile.lastVerifiedAt.map { Int64($0.timeIntervalSince1970 * 1000) },
            aspectRatio: profile.aspectRatio
        )
    }

    /// Defensive against a corrupted row (unknown enum string, out-of-range zone): returns
    /// `nil` rather than crashing — a malformed cache row should degrade gracefully, not take
    /// down the resolver chain.
    func toDomainOrNull() -> DeviceAntennaProfile? {
        guard let formFactorValue = FormFactor(rawValue: formFactor),
              let confidenceValue = Confidence(rawValue: confidence),
              let sourceValue = DataSource(rawValue: source),
              let rect = try? NormalizedRect(x: zoneX, y: zoneY, width: zoneWidth, height: zoneHeight)
        else { return nil }

        return DeviceAntennaProfile(
            manufacturer: manufacturer,
            model: model,
            formFactor: formFactorValue,
            silhouetteTemplateID: silhouetteTemplateID,
            antennaZone: rect,
            confidence: confidenceValue,
            source: sourceValue,
            catalogVersion: catalogVersion,
            lastVerifiedAt: lastVerifiedAtEpochMillis.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) },
            aspectRatio: aspectRatio
        )
    }
}
