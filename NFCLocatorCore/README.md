# NFCLocatorCore

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](../LICENSE)

An on-device iOS Swift package that tells a user **exactly where to tap their phone** against
an NFC reader, tag, or smart lock.

It resolves the antenna's physical location through a layered, confidence-aware chain — your
own remote catalog, a bundled offline seed catalog, and a device-shape heuristic that never
fails — and ships SwiftUI components to draw the result as a marker or a guided sweep
animation.

## Platform gap: no on-device antenna-hardware API

There is no public Core NFC API that reports where an NFC antenna physically sits on the
running device. `NFCReaderSession`/`NFCTagReaderSession` expose tag reading, never antenna
geometry, and Apple has never needed to expose one — Core NFC already draws a system "hold near
the top of iPhone" sheet during a scan.

Because of this, the resolver chain has **three layers**:

1. Remote catalog (host-supplied, cache-first)
2. Bundled offline seed catalog
3. Form-factor heuristic — always succeeds

`Confidence.exact` is still reachable — via a vendor/community-verified catalog entry — just
never via a live on-device measurement. See [`DECISIONS.md`](DECISIONS.md) for the full list of
design decisions and the reasoning behind each one.

## Features

- **Layered resolver chain, most-confident-first**: remote catalog → bundled offline catalog →
  a form-factor heuristic that always succeeds, so the library never returns "no answer."
- **Confidence is explicit, never hidden**: every result carries `Confidence.exact` /
  `.approximate` / `.generic` / `.unknown`, and the bundled UI draws a solid marker only for
  trustworthy results — a dashed, sweeping highlight otherwise.
- **Bring your own backend, analytics, and logging**: the package defines the protocols
  (`CatalogRemoteAPI`, `NFCLocatorAnalytics`, `NFCLocatorLogger`); you implement them against
  your existing stack. The package itself makes no network calls and ships no analytics SDK.
- **Works fully offline** out of the box via the bundled seed catalog and heuristic fallback.
- **Foldable/tablet aware** at the *model* level (`FormFactor`/`FoldState` cover foldables for
  catalog compatibility with the shared wire format), even though no shipping iPhone is a
  foldable today.
- **Accessible by default**: `reducedMotion` support throughout, accessibility labels on every
  interactive/informational element, and system-color-aware defaults — you supply the colors,
  the package never hardcodes brand hues.
- Written in Swift, built on SwiftUI, SwiftData, and Swift Concurrency (`async`/`await`).

## Requirements

- **iOS 17+**
- Swift 5.10+ / Xcode 15.3+

## Installation

### Swift Package Manager

Local path (while developing alongside a checkout of this repo):

```swift
dependencies: [
    .package(path: "../NFCLocatoriOS")
]
```

Or add it as a remote dependency — in Xcode: **File → Add Package Dependencies…**, or in
`Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/nagarjunavs/NFCLocatoriOS.git", from: "0.1.0")
]
```

### CocoaPods

```ruby
pod 'NFCLocatorCore', '~> 0.1'
```

Published to CocoaPods Trunk from [`NFCLocatorCore.podspec`](../NFCLocatorCore.podspec) at the
repository root — see "Versioning & releasing" below for how new versions are cut.

## Setup

The package deliberately does **not** own networking, analytics, or logging — it defines the
protocols and leaves the implementation to you:

```swift
struct MyCatalogRemoteAPI: CatalogRemoteAPI {
    func fetchCatalog(sinceVersion: Int) async throws -> CatalogResponseDTO {
        // your networking stack here
    }
}
```

If you have no real backend yet, or want to ship fully offline, implement `CatalogRemoteAPI` to
throw unconditionally — any error is treated as "unavailable, fall through to the next source,"
never surfaced to the user. See the TapSense sample app's `FakeCatalogRemoteAPI` for exactly
this pattern.

## Quick start

```swift
let useCase = ResolveAntennaLocationUseCase(
    remoteAPI: MyCatalogRemoteAPI(),
    cache: SwiftDataCatalogCache(modelContainer: myContainer),
    seedCatalogLoader: BundledSeedCatalogLoader(logger: myLogger),
    analytics: myAnalytics,
    logger: myLogger
)

let signals = DeviceIdentitySignals(
    fingerprint: myFingerprintProvider.current(),
    formFactor: .bar,
    foldState: .notApplicable,
    screenSizeClass: .compact
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

`AntennaLocatorScreen` is a full, opinionated screen. If you want to lay out the marker
yourself alongside your own copy/branding, drop down to its two building blocks directly —
``AntennaSilhouette`` for `.resolvedMarker`, ``GuidedSweepAnimation`` for `.fallbackGuidance``.

### Key public types

| Type | What it's for |
|---|---|
| `ResolveAntennaLocationUseCase` | The entry point — runs the resolver chain, returns a `DeviceAntennaProfile`. |
| `DeviceAntennaProfile.toUIState()` | Maps the raw resolved profile to the UI-shaped `AntennaLocatorUIState`. |
| `AntennaLocatorScreen` | Complete, batteries-included screen for the state above. |
| `AntennaSilhouette`, `GuidedSweepAnimation` | The individual SwiftUI components `AntennaLocatorScreen` composes. |
| `DeviceAntennaProfile`, `Confidence`, `NormalizedRect` | The resolved data: where, and how sure. |
| `CatalogRemoteAPI`, `NFCLocatorAnalytics`, `NFCLocatorLogger` | The three seams you implement. |
| `DeviceFingerprintProvider` | Override device identification (e.g. a phone-picker/preview screen) instead of the real running device. |

## Building & testing locally

`Package.swift` lives at the repository root (not in this `NFCLocatorCore/` folder), so run these
from there:

```bash
swift build
swift build -c release
swift test
```

## Versioning & releasing

Follows [Semantic Versioning](https://semver.org/): breaking changes to any `public`/`open` API
bump the major version, additive changes bump minor, fixes bump patch. Unreleased changes are
tracked in [`../CHANGELOG.md`](../CHANGELOG.md).

To cut a release (owner action — not automated by this repo):

1. Update `[Unreleased]` in `CHANGELOG.md` to the new version + date.
2. Bump `s.version` in `NFCLocatorCore.podspec` to match.
3. Commit, then tag: `git tag <version> && git push origin <version>` (the tag **must** match the
   podspec's `s.version` exactly — CocoaPods resolves `source_files` from that git tag).
4. `pod trunk push NFCLocatorCore.podspec` to publish to CocoaPods (requires `pod trunk register`
   once, first time — see CocoaPods' own docs). No `--allow-warnings` needed; the podspec lints
   clean.
5. Swift Package Index picks up new tags automatically once the repository is registered there
   (see https://swiftpackageindex.com/add-a-package) — no separate publish step for SPM itself.

## Troubleshooting

- **"No such module 'NFCLocatorCore'" after adding via SPM**: File → Packages → Reset Package
  Caches in Xcode, then rebuild.
- **Localized strings/seed catalog missing under CocoaPods**: confirm the consuming app's
  `Podfile` has run `pod install` (not just `pod update`) since the resource bundle changed —
  CocoaPods resource bundles are wired at `pod install` time.
- **SwiftData model container errors on first run**: `SwiftDataCatalogCache.makeModelContainer()`
  throws if the on-disk schema is incompatible with a previous version; see its doc comment for
  the migration story before working around it with a manual store deletion.

## License

MIT — see [`LICENSE`](../LICENSE).
