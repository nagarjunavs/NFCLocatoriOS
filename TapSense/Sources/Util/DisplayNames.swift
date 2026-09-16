import Foundation
import NFCLocatorCore

/// Raw `manufacturer`/`model` catalog strings are lowercase, underscore-or-hyphen-separated
/// codes (e.g. "sm-a546b"). This capitalizes after every space/underscore/hyphen, leaving
/// digit-led segments alone — there's no canonical casing for a bare SKU like "24031pn0dc"
/// without a device-name dictionary. Kept as the fallback for `friendlyModelName()`.
extension String {
    func toDisplayDeviceName() -> String {
        let spaced = replacingOccurrences(of: "_", with: " ")
        var result = ""
        var capitalizeNext = true
        for char in spaced {
            if capitalizeNext, char.isLetter {
                result.append(Character(char.uppercased()))
                capitalizeNext = false
            } else {
                result.append(char)
                if char == " " || char == "-" { capitalizeNext = true }
            }
        }
        return result
    }
}

/// Marketing names for the SKUs/model codes in `seed_catalog.json`, keyed by
/// ``DeviceFingerprint/normalize(_:)``'s normalized form of the catalog's `manufacturer`/`model`
/// strings — lowercase, with every run of non-alphanumeric characters collapsed to a single
/// `_` (so `"iPhone15,2"` and `"iphone15,2"` both key as `"iphone15_2"`, `"SM-S918B"` and
/// `"sm-s918b"` both key as `"sm_s918b"`).
///
/// This matters beyond cosmetics: a *catalog-matched* profile's `model` is the raw JSON string
/// as authored (e.g. `"iphone15,2"`, comma intact), but `TapSenseDeviceFingerprintProvider`
/// (the real, on-device path — used whenever a device isn't in the bundled seed catalog)
/// already normalizes the raw `hw.machine` sysctl string before it ever reaches here, so it
/// arrives as `"iphone13_2"`, not `"iphone13,2"`. Keying this table on the catalog's raw comma
/// format — as an earlier version of this file did — meant it could *only* ever match a catalog
/// hit, never a real device on the generic-fallback path, silently mangling every non-catalog
/// iPhone's name through `toDisplayDeviceName()`'s generic capitalization instead (confirmed: a
/// real iPhone 12 displayed as "Iphone13 2" — `"iPhone13,2"` is Apple's *actual* `hw.machine`
/// identifier for the iPhone 12, not the 13). `friendlyModelName()` below normalizes its input
/// the same way before looking it up here, so this table now matches regardless of which path
/// (catalog or real-device fingerprint) produced the string.
///
/// A model not in this table falls back to `toDisplayDeviceName()`'s generic capitalization.
/// Apple entries cover iPhone 8 through the iPhone 16 line plus the SE line — Apple's own
/// `hw.machine` identifiers, not marketing generation numbers, and the two are deliberately
/// *not* the same sequence (e.g. `iPhone13,2` is the iPhone 12, not the iPhone 13) — extend this
/// table for newer hardware rather than guessing a pattern.
private let friendlyModelNames: [String: String] = [
    "sm_s921b": "Galaxy S24",
    "sm_s926b": "Galaxy S24+",
    "sm_s928b": "Galaxy S24 Ultra",
    "sm_s918b": "Galaxy S23 Ultra",
    "sm_s911b": "Galaxy S23",
    "sm_s711b": "Galaxy S23 FE",
    "sm_a546b": "Galaxy A54 5G",
    "sm_a556b": "Galaxy A55 5G",
    "sm_f956b": "Galaxy Z Fold6",
    "sm_f946b": "Galaxy Z Fold5",
    "sm_f741b": "Galaxy Z Flip6",
    "sm_f731b": "Galaxy Z Flip5",
    "sm_x610": "Galaxy Tab S6 Lite",
    "sm_x710": "Galaxy Tab S9",
    "pixel_9_pro": "Pixel 9 Pro",
    "pixel_9a": "Pixel 9a",
    "pixel_9": "Pixel 9",
    "pixel_8a": "Pixel 8a",
    "pixel_8": "Pixel 8",
    "pixel_8_pro": "Pixel 8 Pro",
    "pixel_7": "Pixel 7",
    "pixel_6a": "Pixel 6a",
    "pixel_fold": "Pixel Fold",
    "pixel_tablet": "Pixel Tablet",
    "cph2581": "OnePlus 12",
    "cph2655": "OnePlus 13",
    "2312dra50g": "Redmi Note 13 Pro+",
    "23127pn0cg": "Xiaomi 14",
    "24031pn0dc": "Xiaomi 14 Ultra",
    "moto_g_power": "Moto G Power",
    "razr_2024": "Razr (2024)",
    "xq_ct72": "Xperia 5 IV",
    "xq_ec72": "Xperia 1 VI",

    // Apple — keyed by normalized `hw.machine` (see doc comment above).
    "iphone10_1": "iPhone 8",
    "iphone10_4": "iPhone 8",
    "iphone10_2": "iPhone 8 Plus",
    "iphone10_5": "iPhone 8 Plus",
    "iphone10_3": "iPhone X",
    "iphone10_6": "iPhone X",
    "iphone11_2": "iPhone XS",
    "iphone11_4": "iPhone XS Max",
    "iphone11_6": "iPhone XS Max",
    "iphone11_8": "iPhone XR",
    "iphone12_1": "iPhone 11",
    "iphone12_3": "iPhone 11 Pro",
    "iphone12_5": "iPhone 11 Pro Max",
    "iphone12_8": "iPhone SE (2nd generation)",
    "iphone13_1": "iPhone 12 mini",
    "iphone13_2": "iPhone 12",
    "iphone13_3": "iPhone 12 Pro",
    "iphone13_4": "iPhone 12 Pro Max",
    "iphone14_4": "iPhone 13 mini",
    "iphone14_5": "iPhone 13",
    "iphone14_2": "iPhone 13 Pro",
    "iphone14_3": "iPhone 13 Pro Max",
    "iphone14_6": "iPhone SE (3rd generation)",
    "iphone14_7": "iPhone 14",
    "iphone14_8": "iPhone 14 Plus",
    "iphone15_2": "iPhone 14 Pro",
    "iphone15_3": "iPhone 14 Pro Max",
    "iphone15_4": "iPhone 15",
    "iphone15_5": "iPhone 15 Plus",
    "iphone16_1": "iPhone 15 Pro",
    "iphone16_2": "iPhone 15 Pro Max",
    "iphone17_3": "iPhone 16",
    "iphone17_4": "iPhone 16 Plus",
    "iphone17_1": "iPhone 16 Pro",
    "iphone17_2": "iPhone 16 Pro Max",
    "iphone17_5": "iPhone 16e",
]

private let friendlyManufacturerNames: [String: String] = [
    "samsung": "Samsung",
    "google": "Google",
    "apple": "Apple",
    "oneplus": "OnePlus",
    "xiaomi": "Xiaomi",
    "motorola": "Motorola",
    "sony": "Sony",
]

extension String {
    /// The device's marketing name (e.g. "Galaxy S23 Ultra"), not the raw SKU/model code. Looks
    /// up the *normalized* form (see `friendlyModelNames`'s doc comment) so this matches
    /// regardless of whether `self` is a catalog-authored string (raw, e.g. `"iphone15,2"`) or
    /// an on-device fingerprint (already normalized, e.g. `"iphone13_2"`) — falling back to
    /// `toDisplayDeviceName()` applied to the *original*, un-normalized string, which reads
    /// better for an unrecognized model than the all-lowercase normalized form would.
    func friendlyModelName() -> String {
        friendlyModelNames[DeviceFingerprint.normalize(self)] ?? toDisplayDeviceName()
    }

    /// The manufacturer's proper display name (e.g. "Samsung"), not the raw lowercase code.
    func friendlyManufacturerName() -> String {
        friendlyManufacturerNames[trimmingCharacters(in: .whitespaces).lowercased()] ?? toDisplayDeviceName()
    }
}

/// "Samsung Galaxy S23 Ultra" — the manufacturer + marketing name combined, for single-line display.
func friendlyDeviceName(manufacturer: String, model: String) -> String {
    "\(manufacturer.friendlyManufacturerName()) \(model.friendlyModelName())"
}
