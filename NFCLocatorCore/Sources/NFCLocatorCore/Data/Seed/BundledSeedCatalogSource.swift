import Foundation

/// Layer 2 of the resolver chain — the small bundled offline catalog. Always available, no
/// network required.
struct BundledSeedCatalogSource: AntennaLocationSource {
    private let loader: BundledSeedCatalogLoader
    private let logger: NFCLocatorLogger

    init(loader: BundledSeedCatalogLoader, logger: NFCLocatorLogger) {
        self.loader = loader
        self.logger = logger
    }

    func resolve(signals: DeviceIdentitySignals) async -> DeviceAntennaProfile? {
        let seed = await loader.load()
        guard !seed.entries.isEmpty else { return nil }

        let byKey = Dictionary(seed.entries.map { ($0.lookupKey(), $0) }, uniquingKeysWith: { first, _ in first })

        for key in signals.fingerprint.lookupKeys() {
            guard let dto = byKey[key] else { continue }
            if let profile = dto.toDomainOrNull(source: .seedCatalog) {
                return profile
            }
            logger.w(tag: "BundledSeedCatalogSource", message: "Seed entry for key \(key) failed validation, skipping")
        }
        return nil
    }
}
