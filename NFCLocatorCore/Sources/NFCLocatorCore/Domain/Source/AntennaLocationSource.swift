import Foundation

/// One link in the resolver chain. `nil` means "no answer, try the next source" — a source
/// must never throw *to communicate* a miss, and must never return implausible data.
/// Validation lives inside each source's own implementation.
public protocol AntennaLocationSource: Sendable {
    func resolve(signals: DeviceIdentitySignals) async throws -> DeviceAntennaProfile?
}
