import Foundation

/// A normalized device identity used to look up catalog/cache entries.
///
/// All fields are expected to already be normalized (lowercase, `_`-separated) by whoever
/// constructs this — see ``normalize(_:)``. On iOS, the real-device implementation of the
/// fingerprint provider (in the TapSense sample app) derives `model`/`device`/`product` from
/// the `hw.machine` sysctl identifier (e.g. `"iphone15,2"`), matching the exact string format
/// the bundled seed catalog already uses for its Apple entries.
public struct DeviceFingerprint: Codable, Sendable, Equatable {
    public let manufacturer: String
    public let brand: String
    public let model: String
    public let device: String
    public let product: String
    public let sku: String?

    public init(manufacturer: String, brand: String, model: String, device: String, product: String, sku: String? = nil) {
        self.manufacturer = manufacturer
        self.brand = brand
        self.model = model
        self.device = device
        self.product = product
        self.sku = sku
    }

    /// Lookup keys, most-specific-first, duplicates removed. The resolver chain tries each key
    /// in order against the cache/catalog until one hits.
    public func lookupKeys() -> [String] {
        var keys: [String] = []
        if let sku, !sku.trimmingCharacters(in: .whitespaces).isEmpty {
            keys.append("\(manufacturer):\(model):\(sku)")
        }
        keys.append("\(manufacturer):\(model)")
        keys.append("\(manufacturer):\(device)")
        keys.append("\(manufacturer):\(product)")

        var seen = Set<String>()
        return keys.filter { seen.insert($0).inserted }
    }

    /// `lowercase → trim → replace runs of non-alphanumerics with "_" → trim leading/trailing "_"`.
    /// e.g. `"SM-S918B"` → `"sm_s918b"`, `"--Pixel--Fold--"` → `"pixel_fold"`.
    public static func normalize(_ raw: String) -> String {
        let lowered = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let collapsed = lowered.replacingOccurrences(
            of: "[^a-z0-9]+",
            with: "_",
            options: .regularExpression
        )
        var result = Substring(collapsed)
        while result.first == "_" { result.removeFirst() }
        while result.last == "_" { result.removeLast() }
        return String(result)
    }
}
