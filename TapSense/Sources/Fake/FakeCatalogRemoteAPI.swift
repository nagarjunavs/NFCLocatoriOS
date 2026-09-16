import Foundation
import NFCLocatorCore

/// Demo `CatalogRemoteAPI` implementation — proves the remote-catalog resolver path works
/// without a real backend. The demo entries are arbitrary; they exist to demonstrate the
/// resolver chain, not to model real iOS devices.
struct FakeCatalogRemoteAPI: CatalogRemoteAPI {
    static let demoCatalogVersion = 2

    func fetchCatalog(sinceVersion: Int) async throws -> CatalogResponseDTO {
        try? await Task.sleep(for: .milliseconds(400))

        guard sinceVersion < Self.demoCatalogVersion else {
            return CatalogResponseDTO(catalogVersion: Self.demoCatalogVersion, entries: [])
        }

        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let entries = [
            CatalogEntryDTO(
                manufacturer: "google", model: "sdk_gphone64_arm64", formFactor: "BAR",
                silhouetteTemplateID: DeviceAntennaProfile.templateBar,
                zoneX: 0.30, zoneY: 0.18, zoneWidth: 0.40, zoneHeight: 0.14,
                catalogVersion: Self.demoCatalogVersion, lastVerifiedAtEpochMillis: now, verified: false
            ),
            CatalogEntryDTO(
                manufacturer: "xiaomi", model: "24031pn0dc", formFactor: "BAR",
                silhouetteTemplateID: DeviceAntennaProfile.templateBar,
                zoneX: 0.30, zoneY: 0.20, zoneWidth: 0.40, zoneHeight: 0.14,
                catalogVersion: Self.demoCatalogVersion, lastVerifiedAtEpochMillis: now, verified: true
            ),
            CatalogEntryDTO(
                manufacturer: "samsung", model: "sm-a556b", formFactor: "BAR",
                silhouetteTemplateID: DeviceAntennaProfile.templateBar,
                zoneX: 0.30, zoneY: 0.34, zoneWidth: 0.40, zoneHeight: 0.18,
                catalogVersion: Self.demoCatalogVersion, lastVerifiedAtEpochMillis: now, verified: false
            ),
        ]
        return CatalogResponseDTO(catalogVersion: Self.demoCatalogVersion, entries: entries)
    }
}
