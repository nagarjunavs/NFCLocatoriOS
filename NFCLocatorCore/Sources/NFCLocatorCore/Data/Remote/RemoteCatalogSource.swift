import Foundation

/// Layer 1 (most-confident-first, since iOS has no on-device antenna-hardware API) of the
/// resolver chain — the host's own remote catalog, cache-first.
struct RemoteCatalogSource: AntennaLocationSource {
    private let remoteAPI: CatalogRemoteAPI
    private let cache: CatalogCache
    private let logger: NFCLocatorLogger

    init(remoteAPI: CatalogRemoteAPI, cache: CatalogCache, logger: NFCLocatorLogger) {
        self.remoteAPI = remoteAPI
        self.cache = cache
        self.logger = logger
    }

    func resolve(signals: DeviceIdentitySignals) async -> DeviceAntennaProfile? {
        let lookupKeys = signals.fingerprint.lookupKeys()

        if let hit = await cache.find(lookupKeys: lookupKeys) {
            return hit
        }

        let refreshed = await refreshCache()
        guard refreshed else { return nil }

        return await cache.find(lookupKeys: lookupKeys)
    }

    /// Fetches a delta from the remote API and upserts valid entries into the cache. Any
    /// network/parse failure is caught here and treated as "remote unavailable" — never
    /// surfaced as an error.
    private func refreshCache() async -> Bool {
        do {
            let sinceVersion = await cache.latestCachedVersion()
            let response = try await remoteAPI.fetchCatalog(sinceVersion: sinceVersion)
            let validEntries: [(key: String, profile: DeviceAntennaProfile)] = response.entries.compactMap { dto in
                guard let profile = dto.toDomainOrNull(source: .remoteCatalog) else {
                    logger.w(tag: "RemoteCatalogSource", message: "Remote entry for \(dto.lookupKey()) failed validation, skipping")
                    return nil
                }
                return (dto.lookupKey(), profile)
            }
            await cache.upsertAll(validEntries)
            return true
        } catch {
            logger.e(tag: "RemoteCatalogSource", message: "Failed to refresh catalog from remote", error: error)
            return false
        }
    }
}
