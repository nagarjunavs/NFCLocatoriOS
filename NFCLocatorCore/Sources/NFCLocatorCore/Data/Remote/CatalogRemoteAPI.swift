import Foundation

/// One of the library's three host seams. The library performs zero networking itself — the
/// host implements this against its own networking stack (`URLSession`, Alamofire, etc.).
///
/// `sinceVersion` requests a delta (`0` = full sync). Implementations should `throw` on
/// transport/parse failure; ``RemoteCatalogSource`` catches any error and treats it as "remote
/// unavailable, fall through to the next source" — never surfaced as an error to the UI.
///
/// If you have no real backend yet, or want to ship fully offline, implement this to throw
/// unconditionally.
public protocol CatalogRemoteAPI: Sendable {
    func fetchCatalog(sinceVersion: Int) async throws -> CatalogResponseDTO
}
