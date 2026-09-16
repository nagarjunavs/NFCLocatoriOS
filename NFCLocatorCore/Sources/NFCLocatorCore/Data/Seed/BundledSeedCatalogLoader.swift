import Foundation

/// Loads and parse-once-caches the bundled offline seed catalog (`Resources/seed_catalog.json`,
/// embedded via ``Bundle/nfcLocatorCoreResources``).
///
/// Public (not an implementation detail) because TapSense's own phone-picker/preview catalog
/// repository reuses this loader directly rather than re-parsing the seed catalog itself.
public actor BundledSeedCatalogLoader {
    private let logger: NFCLocatorLogger
    private let bundle: Bundle
    private var cached: SeedCatalogDTO?

    public init(logger: NFCLocatorLogger, bundle: Bundle? = nil) {
        self.logger = logger
        self.bundle = bundle ?? .nfcLocatorCoreResources
    }

    /// Parses `seed_catalog.json` on first call; every subsequent call returns the cached
    /// result. On any read/decode failure, treated as an empty catalog — never throws, never
    /// crashes.
    public func load() -> SeedCatalogDTO {
        if let cached { return cached }
        let result = parseAsset()
        cached = result
        return result
    }

    private func parseAsset() -> SeedCatalogDTO {
        guard let url = bundle.url(forResource: "seed_catalog", withExtension: "json") else {
            logger.e(tag: "BundledSeedCatalogLoader", message: "seed_catalog.json not found in bundle", error: nil)
            return SeedCatalogDTO(catalogVersion: 0, entries: [])
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(SeedCatalogDTO.self, from: data)
        } catch {
            logger.e(tag: "BundledSeedCatalogLoader", message: "Failed to parse seed_catalog.json", error: error)
            return SeedCatalogDTO(catalogVersion: 0, entries: [])
        }
    }
}
