import os
import NFCLocatorCore

/// The host-supplied `NFCLocatorAnalytics` implementation for this sample app — every event
/// just logs via `os.Logger`, standing in for a real analytics backend.
struct OSLogNfcLocatorAnalytics: NFCLocatorAnalytics {
    private let logger = Logger(subsystem: "com.tapsense.app", category: "NfcLocatorAnalytics")

    func guidanceShown(confidence: Confidence, source: DataSource, formFactor: FormFactor) {
        logger.info("guidanceShown confidence=\(confidence.rawValue, privacy: .public) source=\(source.rawValue, privacy: .public) formFactor=\(formFactor.rawValue, privacy: .public)")
    }

    func guidanceDismissed(confidence: Confidence, timeVisibleMillis: Int64) {
        logger.info("guidanceDismissed confidence=\(confidence.rawValue, privacy: .public) timeVisibleMs=\(timeVisibleMillis)")
    }

    func unknownDeviceDetected(manufacturer: String, formFactorGuess: FormFactor) {
        logger.info("unknownDeviceDetected manufacturer=\(manufacturer, privacy: .public) formFactorGuess=\(formFactorGuess.rawValue, privacy: .public)")
    }

    func catalogMatchFound(confidence: Confidence, source: DataSource, catalogVersion: Int) {
        logger.info("catalogMatchFound confidence=\(confidence.rawValue, privacy: .public) source=\(source.rawValue, privacy: .public) catalogVersion=\(catalogVersion)")
    }

    func android14AntennaDetected(antennaCount: Int) {
        logger.info("android14AntennaDetected antennaCount=\(antennaCount)")
    }

    func retryGuidanceShown(attemptNumber: Int, confidence: Confidence) {
        logger.info("retryGuidanceShown attemptNumber=\(attemptNumber) confidence=\(confidence.rawValue, privacy: .public)")
    }
}
