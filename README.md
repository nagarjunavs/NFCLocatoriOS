# NFC Locator (iOS)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![CocoaPods](https://img.shields.io/cocoapods/v/NFCLocatorCore.svg)](https://cocoapods.org/pods/NFCLocatorCore)
[![Swift Package Index](https://swiftpackageindex.com/nagarjunavs/NFCLocatoriOS/badge?type=swift-versions)](https://swiftpackageindex.com/nagarjunavs/NFCLocatoriOS)
[![Platform compatibility](https://swiftpackageindex.com/nagarjunavs/NFCLocatoriOS/badge?type=platforms)](https://swiftpackageindex.com/nagarjunavs/NFCLocatoriOS)

<!-- TODO(owner): once a CI run on `master` has completed, add
     `https://github.com/nagarjunavs/NFCLocatoriOS/actions/workflows/ci.yml/badge.svg` above. -->

`NFCLocatorCore` is an on-device Swift package that tells a user **exactly where to hold their
phone** against an NFC reader, tag, or smart lock. Most phones' NFC antennas sit in an unlabeled
spot on the back panel, and a scan that misses it by a centimeter just doesn't read — this
resolves and displays where to move the phone before the user gives up.

The package also ships **TapSense**, a complete sample app that demonstrates every screen and
integration seam the library exposes.

## Platform gap, up front

There is no public iOS API that reports where an NFC antenna physically sits on the running
device — Core NFC's `NFCTagReaderSession` reads tags, never antenna geometry, and Apple has never
needed to expose one because the system already draws its own "hold near the top of iPhone" sheet
during a scan. The resolver chain here is therefore three layers (remote catalog → bundled seed
catalog → form-factor heuristic), and `Confidence.exact` is reachable only via a vendor-verified
catalog entry, never a live on-device measurement. Full detail in
[`NFCLocatorCore/DECISIONS.md`](NFCLocatorCore/DECISIONS.md).

## Getting started

### Requirements

- iOS 17+
- Swift 5.10+ / Xcode 15.3+

### Installation

**Swift Package Manager**

```swift
dependencies: [
    .package(url: "https://github.com/nagarjunavs/NFCLocatoriOS.git", from: "0.1.0")
]
```

Or in Xcode: **File → Add Package Dependencies…** and paste the URL above.

**CocoaPods**

```ruby
pod 'NFCLocatorCore', '~> 0.1'
```

### Usage

```swift
import NFCLocatorCore

let useCase = ResolveAntennaLocationUseCase(
    remoteAPI: MyCatalogRemoteAPI(),
    cache: SwiftDataCatalogCache(modelContainer: myContainer),
    seedCatalogLoader: BundledSeedCatalogLoader(logger: myLogger),
    analytics: myAnalytics,
    logger: myLogger
)

let profile = await useCase(signals)
let uiState = profile.toUIState()
```

```swift
struct MyScreen: View {
    let state: AntennaLocatorUIState

    var body: some View {
        AntennaLocatorScreen(state: state) {
            // re-run the flow above
        }
    }
}
```

See [`NFCLocatorCore/README.md`](NFCLocatorCore/README.md) for the full API guide (setup,
key public types, and every integration seam), and
[`NFCLocatorCore/DECISIONS.md`](NFCLocatorCore/DECISIONS.md) for the design rationale.

## Documentation

Generated API documentation is available at
[Swift Package Index](https://swiftpackageindex.com/nagarjunavs/NFCLocatoriOS/documentation/nfclocatorcore)
once the package is indexed there. To preview it locally:

```bash
swift package add-dependency https://github.com/swiftlang/swift-docc-plugin --from 1.5.0
swift package --disable-sandbox preview-documentation --target NFCLocatorCore
```

## Sample app

**TapSense** is a complete reference integration: onboarding, a home dashboard, a "My Phone"
antenna-detail screen, a guided tap flow, a live tap test via Core NFC, phone selection/preview,
troubleshooting, and settings — driven end-to-end against all four confidence tiers. See
[`TapSense/README.md`](TapSense/README.md) to build and run it.

- Package test suite: `swift test`, **52/52 passing**.
- Sample app test suite: **44/44 passing**.
- **Known issue:** TapSense's live Tap Test (Core NFC) failed on at least one tested physical
  device with a "Missing required entitlement" (`NFCError` code 2) error. The root cause and fix
  are documented in [`TapSense/DECISIONS.md`](TapSense/DECISIONS.md) — it requires the account
  holder's own Apple Developer Portal access and has not yet been re-verified end-to-end on a
  real device. **Do not submit TapSense to App Review until that re-verification is done.** This
  is a `TapSense` (sample app) issue only — it does not affect the published `NFCLocatorCore`
  package.

See [`docs/app-store/README.md`](docs/app-store/README.md) for the full App Store Connect
submission checklist.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the development workflow and what we're looking for.
This project follows the [Code of Conduct](CODE_OF_CONDUCT.md). Changes are tracked in
[`CHANGELOG.md`](CHANGELOG.md).

## Support

- [GitHub Issues](https://github.com/nagarjunavs/NFCLocatoriOS/issues) — bug reports, feature
  requests, and questions.
- Security vulnerabilities: see [`SECURITY.md`](SECURITY.md) instead of a public issue.

## License

MIT — see [`LICENSE`](LICENSE). Copyright (c) 2026 Nagarjuna Vutkuri Swamy.
