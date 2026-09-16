import CoreNFC
import Observation

/// Tracks whether this device can run Core NFC's reader-session APIs at all.
///
/// Platform gap (documented, not a bug): **iOS has no user-facing on/off toggle for NFC
/// hardware.** Core NFC scanning is simply available or unavailable based on hardware + the
/// reader-session entitlement; there is nothing for the user to switch off independently, so
/// this type carries no on/off signal at all — every "NFC status" / toggle-shaped UI that would
/// have read
/// one has been removed from this app rather than faked (see `HomeScreen`, `SettingsScreen`).
@MainActor
@Observable
final class NfcStateObserver {
    let isNfcSupported: Bool

    init() {
        isNfcSupported = TapReaderModeController.isSupported
    }
}
