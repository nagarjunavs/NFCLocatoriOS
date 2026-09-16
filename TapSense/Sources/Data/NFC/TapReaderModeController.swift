import CoreNFC
import NFCLocatorCore

/// The seam `TapTestViewModel` depends on instead of `TapReaderModeController` directly, so its
/// state-machine logic can be unit tested with a fake instead of a live Core NFC session.
@MainActor
protocol TapReaderModeStarting {
    /// `onSessionEnded`'s `becameActive` flag distinguishes a session that genuinely ran (the
    /// system sheet appeared, the user had a real chance to present a tag) from one that was
    /// rejected before it ever started — almost always a signing/entitlement problem, not "no
    /// tag was presented." See `TapReaderModeController`'s doc comment.
    @discardableResult
    func start(onTagDetected: @escaping () -> Void, onSessionEnded: @escaping (_ error: Error, _ becameActive: Bool) -> Void) -> Bool
    func stop()
}

/// Wraps `NFCTagReaderSession`, Core NFC's "detect any tag, any tech, don't decode it" reader
/// mode.
///
/// Two behaviors worth calling out up front (both documented in `DECISIONS.md`, not bugs):
/// (1) a Core NFC session shows a system-drawn "Hold Near the Top of iPhone" sheet the whole
/// time it's active — there is no headless reader-mode option — and (2) `NFCTagReaderSession`
/// has an OS-enforced ~60s timeout with no API to extend it, and does not stay active
/// indefinitely the way a long-lived reader-mode registration might. This second point is *not*
/// cosmetic — see `onSessionEnded` below, and `TapTestViewModel.retry()`.
///
/// Only works on a physical device — `NFCTagReaderSession.readingAvailable` is always `false` in
/// the Simulator, so `start(onTagDetected:onSessionEnded:)` always returns `false` there, and
/// this class's actual session-handling code (everything past that check) has no coverage from
/// Simulator testing at all — it can only be verified on a real device.
@MainActor
final class TapReaderModeController: NSObject, TapReaderModeStarting {
    private var session: NFCTagReaderSession?
    private var onTagDetected: (() -> Void)?
    private var onSessionEnded: ((Error, Bool) -> Void)?
    /// Set only from `tagReaderSessionDidBecomeActive`, i.e. only once the system has actually
    /// presented the "Hold Near the Top of iPhone" sheet for the *current* session. Reset at the
    /// top of every `start()` so each session generation tracks its own activation, independent
    /// of whatever the previous session (if any) managed to reach.
    private var sessionBecameActive = false
    private let logger: NFCLocatorLogger

    init(logger: NFCLocatorLogger) {
        self.logger = logger
    }

    static var isSupported: Bool {
        NFCTagReaderSession.readingAvailable
    }

    /// Starts a reader session. Returns `false` if Core NFC reading isn't available on this
    /// device (no hardware, or running in Simulator), or if the OS refused to create a session
    /// object at all despite `isSupported` reporting `true` — the caller should treat either as
    /// "reader unavailable," matching `NfcAdapter#enableReaderMode()` returning without throwing
    /// when the adapter can't be used. Note `isSupported`/`readingAvailable` is a hardware+OS
    /// capability check only — it does *not* confirm the app's NFC entitlement is actually
    /// provisioned on the installed build, so `start` can still return `true` for a session that
    /// is rejected moments later (see `onSessionEnded` below).
    ///
    /// `onSessionEnded` fires whenever the session ends *on its own* — the user dismissed the
    /// system sheet, the OS's own ~60s session timeout elapsed, or (if the app's NFC entitlement
    /// isn't correctly provisioned in Xcode/the Developer portal) the session was rejected
    /// immediately after `begin()`, before the system sheet ever appeared. Every one of those
    /// previously went completely unnoticed: `didInvalidateWithError` only logged, so the screen
    /// stayed on "Detecting…" indefinitely with no real session behind it. Reported here instead
    /// of just logged, tagged with whether the session ever became active so the caller can tell
    /// "rejected before it started" (almost always a provisioning problem) apart from "ran, but
    /// nothing was detected" (a genuine timeout).
    @discardableResult
    func start(onTagDetected: @escaping () -> Void, onSessionEnded: @escaping (Error, Bool) -> Void) -> Bool {
        // These two early-return branches previously logged nothing at all, unlike the
        // `didInvalidateWithError` path below — meaning a `.readerUnavailable` reached from
        // *here* (a synchronous, no-system-round-trip rejection, indistinguishable from here at
        // the call site from one reached via a fast async invalidation) left zero trace of which
        // of the two actually happened. Logged now so Console.app can tell them apart.
        guard Self.isSupported else {
            logger.e(tag: "TapReaderModeController", message: "start() aborted: NFCTagReaderSession.readingAvailable is false")
            return false
        }
        self.onTagDetected = onTagDetected
        self.onSessionEnded = onSessionEnded
        sessionBecameActive = false
        guard let newSession = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693, .iso18092], delegate: self) else {
            logger.e(tag: "TapReaderModeController", message: "start() aborted: NFCTagReaderSession init returned nil")
            return false
        }
        newSession.alertMessage = String(localized: "taptest.reader_alert", bundle: .main, comment: "System NFC sheet prompt")
        newSession.begin()
        session = newSession
        return true
    }

    func stop() {
        session?.invalidate()
        session = nil
        onTagDetected = nil
        onSessionEnded = nil
    }
}

extension TapReaderModeController: NFCTagReaderSessionDelegate {
    nonisolated func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        Task { @MainActor in
            guard session === self.session else { return }
            self.sessionBecameActive = true
        }
    }

    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
            let becameActive = self.sessionBecameActive
            let nsError = error as NSError
            // Logged at error level (not debug) specifically so it survives a release-build
            // Console.app filter — this is the one signal available to diagnose a real-device
            // failure that can't be reproduced in the Simulator. domain/code pinpoint *why* Core
            // NFC rejected or ended the session (e.g. a missing-entitlement rejection reads very
            // differently from a user-dismissed-the-sheet or OS-timeout invalidation).
            self.logger.e(
                tag: "TapReaderModeController",
                message: "Session invalidated (becameActive: \(becameActive), domain: \(nsError.domain), code: \(nsError.code)): \(nsError.localizedDescription)"
            )
            // Identity-compare against the currently held session rather than tracking an
            // "intentional stop" flag: `stop()` (leaving the screen) already niled `self.session`
            // by the time this fires, and `retry()` may have already installed a *new* session
            // before this late callback for the *old* one arrives — a flag shared across session
            // generations would race exactly that sequence. Comparing identity is race-free: a
            // callback for anything other than the live session is simply stale, ignore it.
            guard session === self.session else { return }
            self.session = nil
            self.onSessionEnded?(error, becameActive)
        }
    }

    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        Task { @MainActor in
            guard session === self.session else { return }
            self.onTagDetected?()
            session.restartPolling()
        }
    }
}
