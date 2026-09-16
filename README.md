# NFC Locator (iOS)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

<!-- TODO(owner): once this repo has pushed commits and a CI run has completed, add
     `https://github.com/nagarjunavs/NFCLocatoriOS/actions/workflows/ci.yml/badge.svg` — omitted
     for now since a badge pointing at a repo with no history yet would just show "no status". -->

An on-device library that tells a user **exactly where to hold their phone** against an NFC
reader, tag, or smart lock. Most phones' NFC antennas sit in an unlabeled spot on the back panel,
and a scan that misses it by a centimeter just doesn't read — this shows the user where to move
their phone before they give up.

This repository contains two deliverables:

| Deliverable                        | Status             | What it is                                                                                                             |
| ---------------------------------- | ------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| [`NFCLocatorCore`](NFCLocatorCore) | **Done (Phase 1)** | The publishable Swift package. No UI opinions about your app's screens — you place its components where you want them. |
| [`TapSense`](TapSense) (iOS app)   | **Done (Phase 2)** | A complete sample app built on the package, demonstrating every screen, confidence tier, and integration seam.         |

See [`NFCLocatorCore/DECISIONS.md`](NFCLocatorCore/DECISIONS.md) and
[`TapSense/DECISIONS.md`](TapSense/DECISIONS.md) for the trade-offs made building the library and
the sample app.

## Platform gap, up front

There is no public iOS API that reports where an NFC antenna physically sits on the running
device — Core NFC's `NFCTagReaderSession` reads tags, never antenna geometry, and Apple has never
needed to expose one because the system already draws its own "hold near the top of iPhone" sheet
during a scan. The resolver chain here is therefore three layers (remote catalog → bundled seed
catalog → form-factor heuristic), and `Confidence.exact` is reachable only via a vendor-verified
catalog entry, never a live on-device measurement. Full detail in `NFCLocatorCore/DECISIONS.md`.

## Status

- **Phase 1 — `NFCLocatorCore` package: complete.** Builds and passes its full unit test suite
  (`swift test`, 52/52 passing) both on the local macOS host and for iOS Simulator
  (`xcodebuild -scheme NFCLocatorCore -destination 'generic/platform=iOS Simulator'`).
- **Phase 2 — `TapSense` sample app: complete.** Every screen (onboarding, home dashboard, "My
  Phone" antenna detail, guided tap flow, live tap test via Core NFC, phone selection/preview,
  troubleshooting, settings, privacy) is driven end-to-end in the iOS Simulator against all four
  confidence tiers, light and dark appearance, and a manual phone override. 31/31 app-level unit
  tests passing. See [`TapSense/README.md`](TapSense/README.md) to build and run it.

## Release readiness

- **TapSense's live Tap Test (Core NFC) currently fails on at least one tested physical device**
  with a "Missing required entitlement" error whose root cause is unresolved — see
  [`TapSense/DECISIONS.md`](TapSense/DECISIONS.md). **Do not submit TapSense to App Review until
  this is resolved.**
- This repository has **no commits or tags yet** — SwiftPM remote installs, CocoaPods
  publication, and CI all need at least one commit and a pushed remote first.
- See [`docs/app-store/README.md`](docs/app-store/README.md) for the full App Store Connect
  submission checklist, and `NFCLocatorCore/README.md`'s "Versioning & releasing" section for
  the SwiftPM/CocoaPods publish process.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md). Security issues: see [`SECURITY.md`](SECURITY.md), not
a public issue. This project follows the [Code of Conduct](CODE_OF_CONDUCT.md). Changes are
tracked in [`CHANGELOG.md`](CHANGELOG.md).

## License

MIT — see [`LICENSE`](LICENSE). Copyright (c) 2026 Nagarjuna Vutkuri Swamy.
