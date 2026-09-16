import Observation
import NFCLocatorCore

/// Drives the Tap Test screen's state machine. `startListening`/`stopListening` are the only
/// methods that touch the real Core NFC boundary (via `TapReaderModeController`); everything
/// else is plain state-machine logic with no framework dependency, kept deliberately separate
/// so it stays unit-testable without a live Core NFC session.
///
/// Platform note: a Core NFC `NFCTagReaderSession` is ephemeral — it ends on its own when the
/// user dismisses the system sheet, when the OS's own ~60s session timeout elapses, or
/// immediately if the app's NFC entitlement isn't correctly provisioned. This class reacts to
/// that (`onSessionEnded`) rather than assuming the session outlives the on-screen timer.
@MainActor
@Observable
final class TapTestViewModel {
    private(set) var uiState: TapTestUIState = .ready
    /// The resolved device's marker, shown behind the Ready/Detecting content.
    private(set) var antennaState: AntennaLocatorUIState?

    private let readerModeController: TapReaderModeStarting
    private let isNfcSupported: Bool
    private let timeoutDuration: Duration
    private var timeoutTask: Task<Void, Never>?

    init(readerModeController: TapReaderModeStarting, isNfcSupported: Bool, timeoutDuration: Duration = .seconds(25)) {
        self.readerModeController = readerModeController
        self.isNfcSupported = isNfcSupported
        self.timeoutDuration = timeoutDuration
    }

    func loadAntennaState(env: AppEnvironment) async {
        let settings = env.settingsStore.settings
        let signals = env.activeDeviceSignalsProvider.signals(for: settings)
        let profile = await env.resolveAntennaLocation(signals)
        antennaState = profile.toUIState()
    }

    /// Starts a real Core NFC reader session — call when the screen appears.
    func startListening() {
        let started = readerModeController.start(
            onTagDetected: { [weak self] in self?.onTagDetected() },
            onSessionEnded: { [weak self] error, becameActive in self?.onSessionEnded(error, becameActive: becameActive) }
        )
        onReaderModeStarted(started: started)
    }

    /// Stops the reader session — call when the screen disappears.
    func stopListening() {
        readerModeController.stop()
    }

    private func onReaderModeStarted(started: Bool) {
        guard isNfcSupported else {
            uiState = .nfcUnsupported
            return
        }
        // The session object itself was never created (or the OS refused `begin()` outright) —
        // it never had a chance to become active, so this is the same "reader unavailable"
        // outcome as `onSessionEnded` reports for a session invalidated before activation, not a
        // "nothing detected" timeout.
        guard started else {
            uiState = .readerUnavailable
            return
        }
        beginDetecting()
    }

    private func onTagDetected() {
        timeoutTask?.cancel()
        uiState = .detected
    }

    /// The real session ended on its own. A session ending after a successful detection is
    /// expected, not an error, so only react while still waiting on one. `becameActive` tells
    /// apart a session that genuinely ran — the system sheet appeared, the user had a real
    /// chance to present a tag before it ended — from one rejected before it ever started, which
    /// is almost always a signing/entitlement problem rather than "no tag was presented."
    /// Surfacing the wrong one of these as `.timedOut` ("No NFC signal detected yet") is actively
    /// misleading when the real problem is that the reader session never even started.
    private func onSessionEnded(_ error: Error, becameActive: Bool) {
        guard uiState == .detecting else { return }
        timeoutTask?.cancel()
        uiState = becameActive ? .timedOut : .readerUnavailable
    }

    /// User tapped "Try again". A fresh Core NFC session must be started here, not just the UI
    /// timer reset against the old one — unlike Android's `enableReaderMode`, the previous
    /// session is almost certainly already dead (it either hit the timeout that put us here, or
    /// the user dismissed the system sheet), so re-registering is required every time or every
    /// retry after the first would silently listen to nothing and time out again regardless of
    /// whether a tag is actually presented.
    func retry() {
        readerModeController.stop()
        startListening()
    }

    private func beginDetecting() {
        timeoutTask?.cancel()
        uiState = .detecting
        timeoutTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: self.timeoutDuration)
            guard !Task.isCancelled else { return }
            if self.uiState == .detecting {
                self.uiState = .timedOut
            }
        }
    }
}
