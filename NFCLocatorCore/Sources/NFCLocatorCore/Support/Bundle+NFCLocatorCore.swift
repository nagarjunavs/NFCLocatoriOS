import Foundation

extension Bundle {
    /// The bundle containing this package's resources — localized strings and the bundled seed
    /// catalog JSON.
    ///
    /// Swift Package Manager consumers get `Bundle.module`, synthesized automatically at build
    /// time. CocoaPods has no equivalent synthesis, so this resolves the resource bundle
    /// CocoaPods produces instead, under the same `NFCLocatorCore` name declared in
    /// `NFCLocatorCore.podspec`'s `resource_bundles`. Every resource lookup in this package goes
    /// through this property rather than `Bundle.module` directly, so the same source works
    /// unmodified under either distribution mechanism.
    static var nfcLocatorCoreResources: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        let bundleName = "NFCLocatorCore"
        let candidates: [URL?] = [
            Bundle(for: ResourceBundleFinder.self).resourceURL,
            Bundle.main.resourceURL,
            Bundle(for: ResourceBundleFinder.self).bundleURL
        ]
        for case let candidate? in candidates {
            let bundleURL = candidate.appendingPathComponent(bundleName + ".bundle")
            if let bundle = Bundle(url: bundleURL) {
                return bundle
            }
        }
        // No standalone resource bundle found (e.g. a non-CocoaPods manual integration) — fall
        // back to the bundle housing this compiled code, which still works for a consumer that
        // ships the Resources folder alongside the source files directly.
        return Bundle(for: ResourceBundleFinder.self)
        #endif
    }
}

/// Anchor type solely so `Bundle(for:)` can locate the bundle this code compiled into — never
/// otherwise instantiated or exposed.
private final class ResourceBundleFinder {}
