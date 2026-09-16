import Foundation

/// Supplies the current device's ``DeviceFingerprint``. The library ships no real-device
/// implementation of this (that lives in the host app, e.g. reading the `hw.machine` sysctl on
/// iOS) — this seam exists so a host can override device identification entirely, e.g. for a
/// phone-picker/preview screen that reports a synthetic fingerprint instead of the real one.
public protocol DeviceFingerprintProvider: Sendable {
    func current() -> DeviceFingerprint
}
