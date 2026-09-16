import Foundation
import NFCLocatorCore

/// Resolves signals for "the phone the app should show guidance for right now" — the real
/// running device by default, or a synthetic override when the user picked a different phone
/// to preview (`TapSenseSettings.hasManualPhoneOverride`).
struct ActiveDeviceSignalsProvider {
    private let autoDetectProvider: DeviceIdentitySignalsProvider

    init(autoDetectProvider: DeviceIdentitySignalsProvider) {
        self.autoDetectProvider = autoDetectProvider
    }

    func signals(for settings: TapSenseSettings) -> DeviceIdentitySignals {
        guard let manufacturer = settings.manufacturer,
              let model = settings.model,
              let formFactor = settings.formFactor
        else {
            return autoDetectProvider.current()
        }

        let normalizedManufacturer = DeviceFingerprint.normalize(manufacturer)
        let normalizedModel = DeviceFingerprint.normalize(model)
        let fingerprint = DeviceFingerprint(
            manufacturer: normalizedManufacturer,
            brand: normalizedManufacturer,
            model: normalizedModel,
            device: normalizedModel,
            product: normalizedModel,
            sku: nil
        )
        return DeviceIdentitySignals(
            fingerprint: fingerprint,
            formFactor: formFactor,
            foldState: .notApplicable,
            screenSizeClass: .compact
        )
    }
}
