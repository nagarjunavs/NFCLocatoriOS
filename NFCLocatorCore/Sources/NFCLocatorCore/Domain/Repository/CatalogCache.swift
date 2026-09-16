import Foundation

/// Local persistence for resolved catalog entries, keyed by lookup key (see
/// ``DeviceFingerprint/lookupKeys()``). Backed by SwiftData in this package's shipped
/// implementation (``SwiftDataCatalogCache``); the protocol exists so tests can fake it.
public protocol CatalogCache: Sendable {
    func find(lookupKeys: [String]) async -> DeviceAntennaProfile?
    func upsertAll(_ entries: [(key: String, profile: DeviceAntennaProfile)]) async
    func latestCachedVersion() async -> Int
    func listAll() async -> [DeviceAntennaProfile]
}
