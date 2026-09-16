import Foundation

extension CatalogEntryDTO {
    /// Validates and maps this DTO to a domain profile, or returns `nil` on any failure —
    /// never throws. An invalid entry (bad enum name, out-of-range zone, blank required field,
    /// negative version) is silently skipped so one bad catalog row never breaks the whole
    /// catalog.
    public func toDomainOrNull(source: DataSource) -> DeviceAntennaProfile? {
        guard let formFactor = FormFactor(rawValue: formFactor) else { return nil }
        guard let rect = try? NormalizedRect(x: zoneX, y: zoneY, width: zoneWidth, height: zoneHeight) else {
            return nil
        }
        guard !manufacturer.trimmingCharacters(in: .whitespaces).isEmpty,
              !model.trimmingCharacters(in: .whitespaces).isEmpty,
              !silhouetteTemplateID.trimmingCharacters(in: .whitespaces).isEmpty
        else { return nil }
        guard catalogVersion >= 0 else { return nil }

        let lastVerifiedAt = lastVerifiedAtEpochMillis.map {
            Date(timeIntervalSince1970: TimeInterval($0) / 1000)
        }

        return DeviceAntennaProfile(
            manufacturer: manufacturer,
            model: model,
            formFactor: formFactor,
            silhouetteTemplateID: silhouetteTemplateID,
            antennaZone: rect,
            confidence: verified ? .exact : .approximate,
            source: source,
            catalogVersion: catalogVersion,
            lastVerifiedAt: lastVerifiedAt,
            aspectRatio: aspectRatio
        )
    }
}
