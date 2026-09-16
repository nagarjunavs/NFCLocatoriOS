import Foundation
import SwiftData

/// SwiftData-backed ``CatalogCache``. A `@ModelActor` gives an "off the main thread, one
/// writer" shape without hand-rolling serial-queue plumbing.
///
/// No migration story is implemented — this is a disposable cache, not a source of truth; a
/// schema change just starts the cache over empty).
@ModelActor
public actor SwiftDataCatalogCache: CatalogCache {
    private var logger: NFCLocatorLogger?

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

    /// - Parameter logger: optional so existing `init(modelContainer:)` call sites (the
    ///   `@ModelActor` macro's synthesized initializer) keep compiling unmodified; pass one to
    ///   get a diagnostic trail for cache I/O failures (corrupt store, full disk, schema
    ///   mismatch) that would otherwise silently present as "this device always misses the
    ///   cache."
    public init(modelContainer: ModelContainer, logger: NFCLocatorLogger?) {
        let modelContext = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
        self.modelContainer = modelContainer
        self.logger = logger
    }

    public func find(lookupKeys: [String]) -> DeviceAntennaProfile? {
        // Queried one key at a time, in caller-supplied priority order — a `#Predicate` with
        // `keys.contains(lookupKey)` wouldn't preserve that ordering.
        for key in lookupKeys {
            var descriptor = FetchDescriptor<AntennaProfileCacheModel>(
                predicate: #Predicate { $0.lookupKey == key }
            )
            descriptor.fetchLimit = 1
            do {
                if let row = try modelContext.fetch(descriptor).first, let profile = row.toDomainOrNull() {
                    return profile
                }
            } catch {
                logger?.e(tag: "SwiftDataCatalogCache", message: "find(lookupKey: \(key)) failed", error: error)
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
            do {
                if let existing = try modelContext.fetch(descriptor).first {
                    modelContext.delete(existing)
                }
            } catch {
                logger?.e(tag: "SwiftDataCatalogCache", message: "upsertAll fetch-before-replace for \(key) failed", error: error)
            }
            modelContext.insert(AntennaProfileCacheModel(lookupKey: key, profile: profile))
        }
        do {
            try modelContext.save()
        } catch {
            logger?.e(tag: "SwiftDataCatalogCache", message: "upsertAll save() failed", error: error)
        }
    }

    public func latestCachedVersion() -> Int {
        let descriptor = FetchDescriptor<AntennaProfileCacheModel>(
            sortBy: [SortDescriptor(\.catalogVersion, order: .reverse)]
        )
        var limited = descriptor
        limited.fetchLimit = 1
        do {
            return try modelContext.fetch(limited).first?.catalogVersion ?? 0
        } catch {
            logger?.e(tag: "SwiftDataCatalogCache", message: "latestCachedVersion() failed", error: error)
            return 0
        }
    }

    public func listAll() -> [DeviceAntennaProfile] {
        let descriptor = FetchDescriptor<AntennaProfileCacheModel>(
            sortBy: [SortDescriptor(\.manufacturer), SortDescriptor(\.model)]
        )
        do {
            return try modelContext.fetch(descriptor).compactMap { $0.toDomainOrNull() }
        } catch {
            logger?.e(tag: "SwiftDataCatalogCache", message: "listAll() failed", error: error)
            return []
        }
    }
}
