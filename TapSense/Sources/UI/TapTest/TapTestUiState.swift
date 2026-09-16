import Foundation

/// Mirrors the design's `testStates`: Ready, Detecting, Detected, Timed out. No `nfcOff` case —
/// iOS has no OS-level NFC on/off toggle to be in that state.
///
/// `.readerUnavailable` is a real, distinct outcome from `.timedOut`, not a duplicate: it means
/// the Core NFC session never actually became active (no system "Hold Near the Top of iPhone"
/// sheet ever appeared) — most commonly a signing/provisioning problem (missing NFC entitlement
/// on the installed build), not "the user tapped and nothing was read." `.timedOut` means the
/// session *did* become active and the user had a real chance to present a tag before the
/// session ended with nothing detected. Conflating the two (an earlier version of this state
/// machine did) shows "No NFC signal detected yet" for a session that never even started, which
/// is actively misleading about what actually happened. See `TapTestViewModel.onSessionEnded`.
enum TapTestUIState: Equatable {
    case nfcUnsupported
    case ready
    case detecting
    case detected
    case timedOut
    case readerUnavailable
}
