import Foundation
import NFCLocatorCore

/// App-level convenience layer behind the phone-picker/preview screen — not part of
/// `NFCLocatorCore`. Reuses the package's public `BundledSeedCatalogLoader` and
/// `CatalogEntryMapper` rather than duplicating catalog-parsing logic at the app layer.
struct PhoneCatalogRepository {
    private let seedLoader: BundledSeedCatalogLoader
    private let remoteAPI: CatalogRemoteAPI

    init(seedLoader: BundledSeedCatalogLoader, remoteAPI: CatalogRemoteAPI) {
        self.seedLoader = seedLoader
        self.remoteAPI = remoteAPI
    }

    /// Remote entries win over seed entries on key collision; remote failure silently falls
    /// back to seed-only (never surfaced as an error). Sorted by (manufacturer, model).
    func listAll() async -> [DeviceAntennaProfile] {
        let seed = await seedLoader.load()
        var byKey: [String: (dto: CatalogEntryDTO, source: DataSource)] = [:]
        for dto in seed.entries {
            byKey[dto.lookupKey()] = (dto, .seedCatalog)
        }

        if let remote = try? await remoteAPI.fetchCatalog(sinceVersion: 0) {
            for dto in remote.entries {
                byKey[dto.lookupKey()] = (dto, .remoteCatalog)
            }
        }

        let profiles = byKey.values.compactMap { $0.dto.toDomainOrNull(source: $0.source) }
        return profiles.sorted {
            $0.manufacturer == $1.manufacturer ? $0.model < $1.model : $0.manufacturer < $1.manufacturer
        }
    }

    func search(_ query: String) async -> [DeviceAntennaProfile] {
        let all = await listAll()
        let trimmed = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return all }
        return all.filter {
            $0.manufacturer.lowercased().contains(trimmed) || $0.model.lowercased().contains(trimmed)
        }
    }
}
