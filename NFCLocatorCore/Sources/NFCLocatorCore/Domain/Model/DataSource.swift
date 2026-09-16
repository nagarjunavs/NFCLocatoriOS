import Foundation

/// Which resolver-chain layer produced a ``DeviceAntennaProfile``.
///
/// There is no case here for an OS-measured antenna reading: no public Core NFC API reports a
/// *measured* antenna position — Core NFC exposes tag reading but never antenna geometry. The
/// resolver chain therefore has three layers, not four; see ``ResolveAntennaLocationUseCase``.
public enum DataSource: String, Codable, Sendable, CaseIterable {
    case remoteCatalog = "REMOTE_CATALOG"
    case seedCatalog = "SEED_CATALOG"
    case heuristic = "HEURISTIC"
}
