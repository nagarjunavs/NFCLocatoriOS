import UIKit
import NFCLocatorCore

/// Builds `DeviceIdentitySignals` for the actual running device. No foldable/hinge API exists
/// on iOS (see `NFCLocatorCore`'s `DECISIONS.md`), so `formFactor` is derived purely from
/// `UIDevice.userInterfaceIdiom` (`.pad` -> `.tablet`, everything else -> `.bar`) and
/// `foldState` is always `.notApplicable` — there is no hinge signal to layer on top of that,
/// since no iPhone reports a `FoldingFeature`.
struct DeviceIdentitySignalsProvider {
    private let fingerprintProvider: DeviceFingerprintProvider

    /// Screen width, in points, at or above which the device is treated as `.expanded` — 600
    /// points matches the shared catalog's tablet-classification threshold (points and the
    /// catalog's density-independent units are numerically equivalent, so the same threshold
    /// carries over).
    private static let tabletSmallestWidth: CGFloat = 600
    private static let mediumSmallestWidth: CGFloat = 480

    init(fingerprintProvider: DeviceFingerprintProvider) {
        self.fingerprintProvider = fingerprintProvider
    }

    func current() -> DeviceIdentitySignals {
        let smallestWidth = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let formFactor: FormFactor = isPad ? .tablet : .bar
        let screenSizeClass: ScreenSizeClass
        if smallestWidth >= Self.tabletSmallestWidth {
            screenSizeClass = .expanded
        } else if smallestWidth >= Self.mediumSmallestWidth {
            screenSizeClass = .medium
        } else {
            screenSizeClass = .compact
        }

        return DeviceIdentitySignals(
            fingerprint: fingerprintProvider.current(),
            formFactor: formFactor,
            foldState: .notApplicable,
            screenSizeClass: screenSizeClass
        )
    }
}
