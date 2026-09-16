import Foundation

/// A coarse screen-size bucket, supplied by the host alongside ``FormFactor``/``FoldState``.
///
/// Note: this is currently unused by ``GenericFallbackSource``'s heuristic — it only branches
/// on `formFactor`/`foldState`. It's carried through signals for future use (e.g.
/// distinguishing phone vs. tablet silhouette sizing more finely) but has no effect on the
/// resolved zone today.
public enum ScreenSizeClass: String, Codable, Sendable, CaseIterable {
    case compact = "COMPACT"
    case medium = "MEDIUM"
    case expanded = "EXPANDED"
}

/// Everything the resolver chain needs to identify "this device" and its current shape.
///
/// The library deliberately does not compute `formFactor`/`foldState`/`screenSizeClass`
/// itself — detecting these needs host-specific integration (on iOS: `UIDevice.userInterfaceIdiom`,
/// and — if Apple ever ships a foldable — whatever hinge-state API accompanies it). "Inject,
/// don't own": the host supplies these signals, the library only resolves against them.
public struct DeviceIdentitySignals: Sendable, Equatable {
    public var fingerprint: DeviceFingerprint
    public var formFactor: FormFactor
    public var foldState: FoldState
    public var screenSizeClass: ScreenSizeClass

    public init(
        fingerprint: DeviceFingerprint,
        formFactor: FormFactor,
        foldState: FoldState,
        screenSizeClass: ScreenSizeClass
    ) {
        self.fingerprint = fingerprint
        self.formFactor = formFactor
        self.foldState = foldState
        self.screenSizeClass = screenSizeClass
    }
}
