import Foundation

/// One of the library's three host seams. The library never bundles a logging framework —
/// the host supplies a sink (e.g. `os.Logger`, a bridge to its own pipeline, or a no-op stub).
public protocol NFCLocatorLogger: Sendable {
    func d(tag: String, message: String)
    func w(tag: String, message: String, error: Error?)
    func e(tag: String, message: String, error: Error?)
}

extension NFCLocatorLogger {
    public func w(tag: String, message: String) { w(tag: tag, message: message, error: nil) }
    public func e(tag: String, message: String) { e(tag: tag, message: message, error: nil) }
}
