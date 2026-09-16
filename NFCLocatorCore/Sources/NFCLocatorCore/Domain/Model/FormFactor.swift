import Foundation

/// The physical shape of a device. Kept as a 4-case enum (not just bar/tablet) to match the
/// shared catalog wire format — the bundled/remote catalog can describe any phone, including
/// foldables, so a user previewing a different phone needs the full vocabulary even though no
/// shipping iPhone is a foldable today.
public enum FormFactor: String, Codable, Sendable, CaseIterable {
    case bar = "BAR"
    case foldBook = "FOLD_BOOK"
    case foldFlip = "FOLD_FLIP"
    case tablet = "TABLET"
}

/// Whether a foldable device is currently folded, unfolded, or the concept doesn't apply
/// (a non-foldable bar phone or tablet).
public enum FoldState: String, Codable, Sendable, CaseIterable {
    case notApplicable = "NOT_APPLICABLE"
    case folded = "FOLDED"
    case unfolded = "UNFOLDED"
}
