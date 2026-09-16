import XCTest
@testable import NFCLocatorCore

final class CatalogEntryMapperTests: XCTestCase {
    private func makeDTO(
        formFactor: String = "BAR",
        manufacturer: String = "google",
        model: String = "pixel 8",
        templateID: String = "silhouette_bar",
        zoneX: Float = 0.3,
        zoneY: Float = 0.16,
        zoneWidth: Float = 0.4,
        zoneHeight: Float = 0.14,
        catalogVersion: Int = 1,
        verified: Bool = false
    ) -> CatalogEntryDTO {
        CatalogEntryDTO(
            manufacturer: manufacturer,
            model: model,
            formFactor: formFactor,
            silhouetteTemplateID: templateID,
            zoneX: zoneX,
            zoneY: zoneY,
            zoneWidth: zoneWidth,
            zoneHeight: zoneHeight,
            catalogVersion: catalogVersion,
            lastVerifiedAtEpochMillis: 1_704_067_200_000,
            verified: verified
        )
    }

    func testVerifiedMapsToExact() {
        let profile = makeDTO(verified: true).toDomainOrNull(source: .seedCatalog)
        XCTAssertEqual(profile?.confidence, .exact)
    }

    func testUnverifiedMapsToApproximate() {
        let profile = makeDTO(verified: false).toDomainOrNull(source: .remoteCatalog)
        XCTAssertEqual(profile?.confidence, .approximate)
    }

    func testInvalidFormFactorReturnsNil() {
        XCTAssertNil(makeDTO(formFactor: "NOT_A_FORM_FACTOR").toDomainOrNull(source: .seedCatalog))
    }

    func testInvalidZoneReturnsNil() {
        XCTAssertNil(makeDTO(zoneX: 1.5).toDomainOrNull(source: .seedCatalog))
    }

    func testBlankManufacturerReturnsNil() {
        XCTAssertNil(makeDTO(manufacturer: "  ").toDomainOrNull(source: .seedCatalog))
    }

    func testNegativeCatalogVersionReturnsNil() {
        XCTAssertNil(makeDTO(catalogVersion: -1).toDomainOrNull(source: .seedCatalog))
    }

    func testLookupKeyNormalizesBothParts() {
        let dto = makeDTO(manufacturer: "Samsung", model: "SM-S918B")
        XCTAssertEqual(dto.lookupKey(), "samsung:sm_s918b")
    }

    func testSeedCatalogJSONDecodesAndRoundTrips() throws {
        let json = """
        {"catalogVersion":1,"entries":[{"manufacturer":"google","model":"pixel 8","formFactor":"BAR","silhouetteTemplateId":"silhouette_bar","zoneX":0.3,"zoneY":0.16,"zoneWidth":0.4,"zoneHeight":0.14,"catalogVersion":1,"lastVerifiedAtEpochMs":1704067200000,"verified":true,"aspectRatio":0.4704}]}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(SeedCatalogDTO.self, from: json)
        XCTAssertEqual(decoded.catalogVersion, 1)
        XCTAssertEqual(decoded.entries.count, 1)
        XCTAssertEqual(decoded.entries[0].toDomainOrNull(source: .seedCatalog)?.confidence, .exact)
    }
}
