import Foundation

/// The wire format for one catalog entry — shared by the bundled seed catalog JSON and any
/// remote `CatalogRemoteAPI` response. `formFactor` is a raw enum-name string, validated on
/// mapping (see `CatalogEntryMapper`), not decoded directly as ``FormFactor`` — an unknown
/// value from an old/new catalog version should be skipped, not fail the whole decode.
public struct CatalogEntryDTO: Codable, Sendable, Equatable {
    public let manufacturer: String
    public let model: String
    public let formFactor: String
    public let silhouetteTemplateID: String
    public let zoneX: Float
    public let zoneY: Float
    public let zoneWidth: Float
    public let zoneHeight: Float
    public let catalogVersion: Int
    public let lastVerifiedAtEpochMillis: Int64?
    public let aspectRatio: Float?
    /// Vendor/community-confirmed as measured for this exact model. `true` maps to
    /// ``Confidence/exact``; `false` (the default) maps to ``Confidence/approximate``.
    public let verified: Bool

    enum CodingKeys: String, CodingKey {
        case manufacturer, model, formFactor
        case silhouetteTemplateID = "silhouetteTemplateId"
        case zoneX, zoneY, zoneWidth, zoneHeight, catalogVersion
        case lastVerifiedAtEpochMillis = "lastVerifiedAtEpochMs"
        case aspectRatio, verified
    }

    public init(
        manufacturer: String,
        model: String,
        formFactor: String,
        silhouetteTemplateID: String,
        zoneX: Float,
        zoneY: Float,
        zoneWidth: Float,
        zoneHeight: Float,
        catalogVersion: Int,
        lastVerifiedAtEpochMillis: Int64? = nil,
        aspectRatio: Float? = nil,
        verified: Bool = false
    ) {
        self.manufacturer = manufacturer
        self.model = model
        self.formFactor = formFactor
        self.silhouetteTemplateID = silhouetteTemplateID
        self.zoneX = zoneX
        self.zoneY = zoneY
        self.zoneWidth = zoneWidth
        self.zoneHeight = zoneHeight
        self.catalogVersion = catalogVersion
        self.lastVerifiedAtEpochMillis = lastVerifiedAtEpochMillis
        self.aspectRatio = aspectRatio
        self.verified = verified
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        manufacturer = try c.decode(String.self, forKey: .manufacturer)
        model = try c.decode(String.self, forKey: .model)
        formFactor = try c.decode(String.self, forKey: .formFactor)
        silhouetteTemplateID = try c.decode(String.self, forKey: .silhouetteTemplateID)
        zoneX = try c.decode(Float.self, forKey: .zoneX)
        zoneY = try c.decode(Float.self, forKey: .zoneY)
        zoneWidth = try c.decode(Float.self, forKey: .zoneWidth)
        zoneHeight = try c.decode(Float.self, forKey: .zoneHeight)
        catalogVersion = try c.decode(Int.self, forKey: .catalogVersion)
        lastVerifiedAtEpochMillis = try c.decodeIfPresent(Int64.self, forKey: .lastVerifiedAtEpochMillis)
        aspectRatio = try c.decodeIfPresent(Float.self, forKey: .aspectRatio)
        verified = try c.decodeIfPresent(Bool.self, forKey: .verified) ?? false
    }

    public func lookupKey() -> String {
        "\(DeviceFingerprint.normalize(manufacturer)):\(DeviceFingerprint.normalize(model))"
    }
}

/// A remote catalog fetch response — the return type of `CatalogRemoteAPI.fetchCatalog`.
public struct CatalogResponseDTO: Codable, Sendable, Equatable {
    public let catalogVersion: Int
    public let entries: [CatalogEntryDTO]

    public init(catalogVersion: Int, entries: [CatalogEntryDTO]) {
        self.catalogVersion = catalogVersion
        self.entries = entries
    }
}

/// The envelope shape of the bundled `seed_catalog.json` asset.
public struct SeedCatalogDTO: Codable, Sendable, Equatable {
    public let catalogVersion: Int
    public let entries: [CatalogEntryDTO]

    public init(catalogVersion: Int, entries: [CatalogEntryDTO]) {
        self.catalogVersion = catalogVersion
        self.entries = entries
    }
}
