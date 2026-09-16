import Foundation

/// The resolved answer: where the antenna is, and how sure we are.
///
/// Rule (enforced downstream by ``AntennaLocatorUIState``'s validating initializers): never
/// present a `DeviceAntennaProfile` to UI without its `confidence`/`source` attached — never
/// silently present a guess as fact.
public struct DeviceAntennaProfile: Codable, Sendable, Equatable {
    public let manufacturer: String
    public let model: String
    public let formFactor: FormFactor
    public let silhouetteTemplateID: String
    public let antennaZone: NormalizedRect
    public let confidence: Confidence
    public let source: DataSource
    public let catalogVersion: Int
    public let lastVerifiedAt: Date?
    public let aspectRatio: Float?

    public init(
        manufacturer: String,
        model: String,
        formFactor: FormFactor,
        silhouetteTemplateID: String,
        antennaZone: NormalizedRect,
        confidence: Confidence,
        source: DataSource,
        catalogVersion: Int,
        lastVerifiedAt: Date?,
        aspectRatio: Float? = nil
    ) {
        self.manufacturer = manufacturer
        self.model = model
        self.formFactor = formFactor
        self.silhouetteTemplateID = silhouetteTemplateID
        self.antennaZone = antennaZone
        self.confidence = confidence
        self.source = source
        self.catalogVersion = catalogVersion
        self.lastVerifiedAt = lastVerifiedAt
        self.aspectRatio = aspectRatio
    }

    // MARK: - Silhouette template ids

    public static let templateBar = "silhouette_bar"
    public static let templateFoldBookOpen = "silhouette_fold_book_open"
    public static let templateFoldBookClosed = "silhouette_fold_book_closed"
    public static let templateFoldFlipOpen = "silhouette_fold_flip_open"
    public static let templateFoldFlipClosed = "silhouette_fold_flip_closed"
    public static let templateTablet = "silhouette_tablet"
}
