import os
import NFCLocatorCore

/// The host-supplied `NFCLocatorLogger` implementation for this sample app — forwards straight
/// to `os.Logger`.
struct OSLogNfcLocatorLogger: NFCLocatorLogger {
    private func logger(for tag: String) -> Logger {
        Logger(subsystem: "com.tapsense.app", category: tag)
    }

    func d(tag: String, message: String) {
        logger(for: tag).debug("\(message, privacy: .public)")
    }

    func w(tag: String, message: String, error: Error?) {
        if let error {
            logger(for: tag).warning("\(message, privacy: .public) — \(String(describing: error), privacy: .public)")
        } else {
            logger(for: tag).warning("\(message, privacy: .public)")
        }
    }

    func e(tag: String, message: String, error: Error?) {
        if let error {
            logger(for: tag).error("\(message, privacy: .public) — \(String(describing: error), privacy: .public)")
        } else {
            logger(for: tag).error("\(message, privacy: .public)")
        }
    }
}
