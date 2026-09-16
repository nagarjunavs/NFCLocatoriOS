import Foundation

/// Reads the raw hardware identifier (e.g. `"iPhone15,2"`) via the `hw.machine` sysctl. This is
/// the exact string format the bundled seed catalog's Apple entries are keyed by (see
/// `NFCLocatorCore`'s `DECISIONS.md`).
enum DeviceModelIdentifier {
    static func current() -> String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        guard size > 0 else { return "unknown" }
        var raw = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &raw, &size, nil, 0)
        return String(cString: raw)
    }
}
