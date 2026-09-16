import Foundation

/// The library's entry point. Runs the resolver chain, most-confident-first, and returns the
/// first source's non-`nil` answer — never consults further sources once one has answered: a
/// remote-catalog hit means the seed catalog and heuristic are never even called.
///
/// Chain order (three layers, not four — see ``DataSource`` for why there's no OS-measured
/// first layer on this platform):
/// 1. Remote catalog (host-supplied, cache-first)
/// 2. Bundled seed catalog
/// 3. Generic form-factor heuristic — always succeeds
public struct ResolveAntennaLocationUseCase: Sendable {
    private let remoteCatalogSource: AntennaLocationSource
    private let seedCatalogSource: AntennaLocationSource
    private let genericFallbackSource: AntennaLocationSource
    private let analytics: NFCLocatorAnalytics
    private let logger: NFCLocatorLogger

    private var chain: [AntennaLocationSource] {
        [remoteCatalogSource, seedCatalogSource, genericFallbackSource]
    }

    public init(
        remoteAPI: CatalogRemoteAPI,
        cache: CatalogCache,
        seedCatalogLoader: BundledSeedCatalogLoader,
        analytics: NFCLocatorAnalytics,
        logger: NFCLocatorLogger
    ) {
        self.remoteCatalogSource = RemoteCatalogSource(remoteAPI: remoteAPI, cache: cache, logger: logger)
        self.seedCatalogSource = BundledSeedCatalogSource(loader: seedCatalogLoader, logger: logger)
        self.genericFallbackSource = GenericFallbackSource()
        self.analytics = analytics
        self.logger = logger
    }

    /// Test/advanced seam: inject the three sources directly instead of their concrete
    /// implementations.
    public init(
        remoteCatalogSource: AntennaLocationSource,
        seedCatalogSource: AntennaLocationSource,
        genericFallbackSource: AntennaLocationSource,
        analytics: NFCLocatorAnalytics,
        logger: NFCLocatorLogger
    ) {
        self.remoteCatalogSource = remoteCatalogSource
        self.seedCatalogSource = seedCatalogSource
        self.genericFallbackSource = genericFallbackSource
        self.analytics = analytics
        self.logger = logger
    }

    @discardableResult
    public func callAsFunction(_ signals: DeviceIdentitySignals) async -> DeviceAntennaProfile {
        for source in chain {
            let result: DeviceAntennaProfile?
            do {
                result = try await source.resolve(signals: signals)
            } catch {
                logger.e(tag: "ResolveAntennaLocationUseCase", message: "Source failed to resolve", error: error)
                result = nil
            }
            if let result {
                reportResolution(result)
                return result
            }
        }
        // Unreachable in practice: GenericFallbackSource always succeeds. A hard failure here
        // is a defensive last resort only, never expected to actually trigger.
        preconditionFailure("Resolver chain returned no profile — GenericFallbackSource should never fail")
    }

    private func reportResolution(_ profile: DeviceAntennaProfile) {
        analytics.guidanceShown(confidence: profile.confidence, source: profile.source, formFactor: profile.formFactor.rawValue)
        switch profile.source {
        case .remoteCatalog, .seedCatalog:
            analytics.catalogMatchFound(confidence: profile.confidence, source: profile.source, catalogVersion: profile.catalogVersion)
        case .heuristic:
            analytics.unknownDeviceDetected(manufacturer: profile.manufacturer, formFactorGuess: profile.formFactor.rawValue)
        }
    }
}
