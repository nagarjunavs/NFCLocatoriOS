import Foundation
import SwiftData

/// SwiftData-backed ``CatalogCache``. A `@ModelActor` gives an "off the main thread, one
/// writer" shape without hand-rolling serial-queue plumbing.
///
/// No migration story is implemented — this is a disposable cache, not a source of truth; a
/// schema change just starts the cache over empty).
@ModelActor
public actor SwiftDataCatalogCache: CatalogCache {
    /// Builds the `ModelContainer` this cache needs. A factory, not a public `@Model` type,
    /// because `AntennaProfileCacheModel` — the row shape — is an implementation detail the
    /// host never needs to reference directly; access goes through ``CatalogCache`` instead.
    /// SwiftData's container-construction API just happens to need the schema handed to
    /// *someone*; this keeps that someone inside the package.
    public static func makeModelContainer(inMemoryOnly: Bool = false) throws -> ModelContainer {
        let schema = Schema([AntennaProfileCacheModel.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemoryOnly)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    public func find(lookupKeys: [String]) -> DeviceAntennaProfile? {
        // Queried one key at a time, in caller-supplied priority order — a `#Predicate` with
        // `keys.contains(lookupKey)` wouldn't preserve that ordering.
        for key in lookupKeys {
            var descriptor = FetchDescriptor<AntennaProfileCacheModel>(
                predicate: #Predicate { $0.lookupKey == key }
            )
            descriptor.fetchLimit = 1
            if let row = try? modelContext.fetch(descriptor).first, let profile = row.toDomainOrNull() {
                return profile
            }
        }
        return nil
    }

    public func upsertAll(_ entries: [(key: String, profile: DeviceAntennaProfile)]) {
        for (key, profile) in entries {
            var descriptor = FetchDescriptor<AntennaProfileCacheModel>(
                predicate: #Predicate { $0.lookupKey == key }
            )
            descriptor.fetchLimit = 1
            if let existing = try? modelContext.fetch(descriptor).first {
                modelContext.delete(existing)
            }
            modelContext.insert(AntennaProfileCacheModel(lookupKey: key, profile: profile))
        }
        try? modelContext.save()
    }

    public func latestCachedVersion() -> Int {
        let descriptor = FetchDescriptor<AntennaProfileCacheModel>(
            sortBy: [SortDescriptor(\.catalogVersion, order: .reverse)]
        )
        var limited = descriptor
        limited.fetchLimit = 1
        return (try? modelContext.fetch(limited).first?.catalogVersion) ?? 0
    }

    public func listAll() -> [DeviceAntennaProfile] {
        let descriptor = FetchDescriptor<AntennaProfileCacheModel>(
            sortBy: [SortDescriptor(\.manufacturer), SortDescriptor(\.model)]
        )
        let rows = (try? modelContext.fetch(descriptor)) ?? []
        return rows.compactMap { $0.toDomainOrNull() }
    }
}
