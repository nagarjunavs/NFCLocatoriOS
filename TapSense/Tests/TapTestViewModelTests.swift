import XCTest
@testable import TapSense

@MainActor
private final class FakeReaderModeController: TapReaderModeStarting {
    var startResult = true
    var startCallCount = 0
    var stopCallCount = 0
    private(set) var onTagDetected: (() -> Void)?
    private(set) var onSessionEnded: ((Error, Bool) -> Void)?

    struct SimulatedError: Error {}

    func start(onTagDetected: @escaping () -> Void, onSessionEnded: @escaping (Error, Bool) -> Void) -> Bool {
        startCallCount += 1
        self.onTagDetected = onTagDetected
        self.onSessionEnded = onSessionEnded
        return startResult
    }

    func stop() {
        stopCallCount += 1
    }

    func simulateTagDetected() {
        onTagDetected?()
    }

    /// `becameActive: true` — the session genuinely ran (system sheet appeared) before ending.
    func simulateSessionEnded() {
        onSessionEnded?(SimulatedError(), true)
    }

    /// `becameActive: false` — the session was rejected before it ever started (e.g. a
    /// signing/entitlement problem), the case this fake exists specifically to distinguish.
    func simulateSessionRejectedBeforeActivating() {
        onSessionEnded?(SimulatedError(), false)
    }
}

@MainActor
final class TapTestViewModelTests: XCTestCase {
    func testUnsupportedDeviceGoesStraightToNfcUnsupportedWithoutStartingReader() {
        let reader = FakeReaderModeController()
        let viewModel = TapTestViewModel(readerModeController: reader, isNfcSupported: false)

        viewModel.startListening()

        XCTAssertEqual(viewModel.uiState, .nfcUnsupported)
        // The reader is still asked to start unconditionally — `isNfcSupported` is checked
        // afterward, not used to skip the call.
        XCTAssertEqual(reader.startCallCount, 1)
    }

    /// No dedicated "NFC off" state exists on iOS (there is no OS-level toggle to be in that
    /// state) — a session that fails to even start goes to `.readerUnavailable`, distinct from
    /// `.timedOut` (which implies a session genuinely ran but nothing was detected).
    func testFailedSessionStartGoesToReaderUnavailable() {
        let reader = FakeReaderModeController()
        reader.startResult = false
        let viewModel = TapTestViewModel(readerModeController: reader, isNfcSupported: true)

        viewModel.startListening()

        XCTAssertEqual(viewModel.uiState, .readerUnavailable)
    }

    /// The real bug this covers: a session invalidated before it ever became active (system
    /// sheet never appeared — the classic signature of a signing/entitlement problem on a real
    /// device) was previously indistinguishable from a genuine "nothing detected" timeout, both
    /// surfacing the misleading "No NFC signal detected yet" copy.
    func testSessionRejectedBeforeActivatingGoesToReaderUnavailable() {
        let reader = FakeReaderModeController()
        let viewModel = TapTestViewModel(readerModeController: reader, isNfcSupported: true, timeoutDuration: .seconds(999))
        viewModel.startListening()
        XCTAssertEqual(viewModel.uiState, .detecting)

        reader.simulateSessionRejectedBeforeActivating()

        XCTAssertEqual(viewModel.uiState, .readerUnavailable)
    }

    func testSuccessfulStartBeginsDetecting() {
        let reader = FakeReaderModeController()
        let viewModel = TapTestViewModel(readerModeController: reader, isNfcSupported: true)

        viewModel.startListening()

        XCTAssertEqual(viewModel.uiState, .detecting)
    }

    func testTagDetectedTransitionsToDetected() {
        let reader = FakeReaderModeController()
        let viewModel = TapTestViewModel(readerModeController: reader, isNfcSupported: true)
        viewModel.startListening()

        reader.simulateTagDetected()

        XCTAssertEqual(viewModel.uiState, .detected)
    }

    func testTimeoutTransitionsToTimedOutWhenStillDetecting() async throws {
        let reader = FakeReaderModeController()
        let viewModel = TapTestViewModel(readerModeController: reader, isNfcSupported: true, timeoutDuration: .milliseconds(30))

        viewModel.startListening()
        XCTAssertEqual(viewModel.uiState, .detecting)

        try await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(viewModel.uiState, .timedOut)
    }

    func testTagDetectedBeforeTimeoutCancelsTheTimeout() async throws {
        let reader = FakeReaderModeController()
        let viewModel = TapTestViewModel(readerModeController: reader, isNfcSupported: true, timeoutDuration: .milliseconds(30))

        viewModel.startListening()
        reader.simulateTagDetected()
        XCTAssertEqual(viewModel.uiState, .detected)

        // If the timeout weren't cancelled, this would flip the state back to .timedOut.
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(viewModel.uiState, .detected)
    }

    /// The real bug this covers: a Core NFC session is ephemeral and can end well before the
    /// app's own timeout — the user dismissing the system sheet, or the OS's own ~60s cutoff.
    /// Previously nothing told the view model this happened, so the screen sat on "Detecting…"
    /// indefinitely with no session behind it.
    func testSessionEndingWhileDetectingTransitionsToTimedOut() {
        let reader = FakeReaderModeController()
        let viewModel = TapTestViewModel(readerModeController: reader, isNfcSupported: true, timeoutDuration: .seconds(999))
        viewModel.startListening()
        XCTAssertEqual(viewModel.uiState, .detecting)

        reader.simulateSessionEnded()

        XCTAssertEqual(viewModel.uiState, .timedOut)
    }

    /// A session ending *after* a successful detection is expected (Core NFC sessions restart
    /// polling but eventually wind down), not an error — must not clobber `.detected`.
    func testSessionEndingAfterDetectionDoesNotChangeState() {
        let reader = FakeReaderModeController()
        let viewModel = TapTestViewModel(readerModeController: reader, isNfcSupported: true)
        viewModel.startListening()
        reader.simulateTagDetected()
        XCTAssertEqual(viewModel.uiState, .detected)

        reader.simulateSessionEnded()

        XCTAssertEqual(viewModel.uiState, .detected)
    }

    /// The real bug this covers: `retry()` used to just reset the on-screen timer, assuming
    /// the reader was still listening in the background. In practice the previous session is
    /// almost always already dead by the time the user sees a reason to
    /// retry, so every retry after the first silently listened to nothing and timed out again
    /// no matter what — retry must start a genuinely new session.
    func testRetryStopsAndRestartsTheReaderSession() async throws {
        let reader = FakeReaderModeController()
        let viewModel = TapTestViewModel(readerModeController: reader, isNfcSupported: true, timeoutDuration: .milliseconds(30))
        viewModel.startListening()
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(viewModel.uiState, .timedOut)
        XCTAssertEqual(reader.startCallCount, 1)

        viewModel.retry()

        XCTAssertEqual(reader.stopCallCount, 1)
        XCTAssertEqual(reader.startCallCount, 2)
        XCTAssertEqual(viewModel.uiState, .detecting)

        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(viewModel.uiState, .timedOut)
    }

    func testStopListeningStopsTheReader() {
        let reader = FakeReaderModeController()
        let viewModel = TapTestViewModel(readerModeController: reader, isNfcSupported: true)
        viewModel.startListening()

        viewModel.stopListening()

        XCTAssertEqual(reader.stopCallCount, 1)
    }
}
