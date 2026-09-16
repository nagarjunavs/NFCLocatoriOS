import Foundation
import NFCLocatorCore

/// The real-device implementation of `DeviceFingerprintProvider` — reads `hw.machine` and
/// normalizes it exactly as `CatalogEntryDTO.lookupKey()` normalizes catalog-side keys (see
/// `NFCLocatorCore`'s `DECISIONS.md`: "iPhone15,2" -> "iphone15_2").
struct TapSenseDeviceFingerprintProvider: DeviceFingerprintProvider {
    func current() -> DeviceFingerprint {
        let rawModel = DeviceModelIdentifier.current()
        let normalizedModel = DeviceFingerprint.normalize(rawModel)
        return DeviceFingerprint(
            manufacturer: "apple",
            brand: "apple",
            model: normalizedModel,
            device: normalizedModel,
            product: normalizedModel,
            sku: nil
        )
    }
}
