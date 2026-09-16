import XCTest
@testable import NFCLocatorCore

final class ResolveAntennaLocationUseCaseTests: XCTestCase {
    func testFirstSourceWinsAndLaterSourcesAreNeverCalled() async {
        let winning = TestFixtures.profile(confidence: .exact, source: .remoteCatalog)
        let remote = CallCountingSource(result: winning)
        let seed = CallCountingSource(result: TestFixtures.profile())
        let fallback = CallCountingSource(result: TestFixtures.profile(confidence: .generic, source: .heuristic))
        let analytics = RecordingAnalytics()

        let useCase = ResolveAntennaLocationUseCase(
            remoteCatalogSource: remote,
            seedCatalogSource: seed,
            genericFallbackSource: fallback,
            analytics: analytics,
            logger: NoOpLogger()
        )

        let result = await useCase(TestFixtures.signals)

        XCTAssertEqual(result, winning)
        XCTAssertEqual(remote.callCount, 1)
        XCTAssertEqual(seed.callCount, 0)
        XCTAssertEqual(fallback.callCount, 0)
    }

    func testFallsThroughToSeedWhenRemoteMisses() async {
        let seedWin = TestFixtures.profile(confidence: .approximate, source: .seedCatalog)
        let remote = CallCountingSource(result: nil)
        let seed = CallCountingSource(result: seedWin)
        let fallback = CallCountingSource(result: TestFixtures.profile(confidence: .generic, source: .heuristic))

        let useCase = ResolveAntennaLocationUseCase(
            remoteCatalogSource: remote,
            seedCatalogSource: seed,
            genericFallbackSource: fallback,
            analytics: RecordingAnalytics(),
            logger: NoOpLogger()
        )

        let result = await useCase(TestFixtures.signals)
        XCTAssertEqual(result, seedWin)
        XCTAssertEqual(fallback.callCount, 0)
    }

    func testFallsAllTheWayToHeuristicWhenEverythingMisses() async {
        let heuristicResult = TestFixtures.profile(confidence: .generic, source: .heuristic)
        let useCase = ResolveAntennaLocationUseCase(
            remoteCatalogSource: StubSource(result: nil),
            seedCatalogSource: StubSource(result: nil),
            genericFallbackSource: StubSource(result: heuristicResult),
            analytics: RecordingAnalytics(),
            logger: NoOpLogger()
        )

        let result = await useCase(TestFixtures.signals)
        XCTAssertEqual(result, heuristicResult)
    }

    func testHeuristicWinReportsUnknownDeviceDetected() async {
        let analytics = RecordingAnalytics()
        let useCase = ResolveAntennaLocationUseCase(
            remoteCatalogSource: StubSource(result: nil),
            seedCatalogSource: StubSource(result: nil),
            genericFallbackSource: GenericFallbackSource(),
            analytics: analytics,
            logger: NoOpLogger()
        )

        _ = await useCase(TestFixtures.signals)

        XCTAssertTrue(analytics.events.contains { $0.hasPrefix("guidanceShown") })
        XCTAssertTrue(analytics.events.contains { $0.hasPrefix("unknownDeviceDetected") })
        XCTAssertFalse(analytics.events.contains { $0.hasPrefix("catalogMatchFound") })
    }

    func testCatalogWinReportsCatalogMatchFound() async {
        let analytics = RecordingAnalytics()
        let useCase = ResolveAntennaLocationUseCase(
            remoteCatalogSource: StubSource(result: TestFixtures.profile(source: .remoteCatalog)),
            seedCatalogSource: StubSource(result: nil),
            genericFallbackSource: GenericFallbackSource(),
            analytics: analytics,
            logger: NoOpLogger()
        )

        _ = await useCase(TestFixtures.signals)

        XCTAssertTrue(analytics.events.contains { $0.hasPrefix("catalogMatchFound") })
        XCTAssertFalse(analytics.events.contains { $0.hasPrefix("unknownDeviceDetected") })
    }
}
