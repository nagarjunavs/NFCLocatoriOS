import SwiftUI
import SwiftData
import NFCLocatorCore

/// The composition root. Built once in `TapSenseApp.init()` and threaded through the
/// environment; every ViewModel takes what it needs from this via plain Swift initializer
/// injection rather than a property-wrapper-based DI framework.
@MainActor
final class AppEnvironment {
    let logger: NFCLocatorLogger
    let analytics: NFCLocatorAnalytics
    let remoteAPI: CatalogRemoteAPI
    let seedCatalogLoader: BundledSeedCatalogLoader
    let catalogCache: SwiftDataCatalogCache
    let resolveAntennaLocation: ResolveAntennaLocationUseCase
    let fingerprintProvider: DeviceFingerprintProvider
    let deviceIdentitySignalsProvider: DeviceIdentitySignalsProvider
    let activeDeviceSignalsProvider: ActiveDeviceSignalsProvider
    let settingsStore: TapSenseSettingsStore
    let nfcStateObserver: NfcStateObserver
    let phoneCatalogRepository: PhoneCatalogRepository

    init() {
        let logger = OSLogNfcLocatorLogger()
        let analytics = OSLogNfcLocatorAnalytics()
        let remoteAPI = FakeCatalogRemoteAPI()
        let seedCatalogLoader = BundledSeedCatalogLoader(logger: logger)
        let fingerprintProvider = TapSenseDeviceFingerprintProvider()

        let container: ModelContainer
        do {
            container = try SwiftDataCatalogCache.makeModelContainer()
        } catch {
            fatalError("Failed to create SwiftData ModelContainer for antenna profile cache: \(error)")
        }
        let catalogCache = SwiftDataCatalogCache(modelContainer: container)

        self.logger = logger
        self.analytics = analytics
        self.remoteAPI = remoteAPI
        self.seedCatalogLoader = seedCatalogLoader
        self.catalogCache = catalogCache
        self.resolveAntennaLocation = ResolveAntennaLocationUseCase(
            remoteAPI: remoteAPI,
            cache: catalogCache,
            seedCatalogLoader: seedCatalogLoader,
            analytics: analytics,
            logger: logger
        )
        self.fingerprintProvider = fingerprintProvider
        self.deviceIdentitySignalsProvider = DeviceIdentitySignalsProvider(fingerprintProvider: fingerprintProvider)
        self.activeDeviceSignalsProvider = ActiveDeviceSignalsProvider(autoDetectProvider: deviceIdentitySignalsProvider)
        self.settingsStore = TapSenseSettingsStore(logger: logger)
        self.nfcStateObserver = NfcStateObserver()
        self.phoneCatalogRepository = PhoneCatalogRepository(seedLoader: seedCatalogLoader, remoteAPI: remoteAPI)
    }

    func makeReaderModeController() -> TapReaderModeController {
        TapReaderModeController(logger: logger)
    }
}

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppEnvironment? = nil
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment? {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
