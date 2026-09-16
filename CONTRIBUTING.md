# Contributing

Thanks for considering a contribution to NFC Locator (iOS).

## Repository layout

- [`NFCLocatorCore`](NFCLocatorCore) — the publishable Swift package. This is the library;
  changes here are the ones that affect every consumer.
- [`TapSense`](TapSense) — the sample app, built on the package via XcodeGen (`project.yml` →
  `TapSense.xcodeproj`, which is generated and gitignored — never edit the `.xcodeproj` directly).

Each has its own `DECISIONS.md` recording the trade-offs made building it — read the relevant
one before changing behavior that looks odd at first glance, so a deliberate design choice isn't
mistaken for a bug.

## Local setup

```bash
# Package
cd NFCLocatorCore
swift build
swift test

# Sample app
cd ../TapSense
brew install xcodegen   # if not already installed
xcodegen generate
xcodebuild -project TapSense.xcodeproj -scheme TapSense -destination 'generic/platform=iOS Simulator' build
xcodebuild -project TapSense.xcodeproj -scheme TapSense -destination 'id=<simulator-udid>' test
```

See [`TapSense/README.md`](TapSense/README.md) for real-device setup (Tap Test's live Core NFC
session needs a physical device and a paid Apple Developer Program membership).

## Making a change

1. Open an issue first for anything beyond a small fix, so the approach can be discussed before
   you invest time in it.
2. Keep changes focused — one logical change per pull request.
3. Match existing conventions: doc comments on public API (`///`, DocC cross-references via
   `` `Type` ``/``Type``), no new abstractions beyond what the change requires, no unrelated
   formatting churn.
4. Add or update tests for any behavior change. `swift test` (package) and the relevant
   `xcodebuild test` invocation (sample app) must pass.
5. If the change affects public API in `NFCLocatorCore`, note it in `CHANGELOG.md` under
   `[Unreleased]`, and call out any breaking change explicitly.
6. If the change touches a documented trade-off, update the relevant `DECISIONS.md` rather than
   leaving the reasoning only in the PR description.

## Reporting bugs

Open an issue with: what you expected, what happened, repro steps, and whether it reproduces in
the iOS Simulator or requires a physical device (Core NFC only works on-device — see
`TapSense/README.md`). For security issues, see [`SECURITY.md`](SECURITY.md) instead of a public
issue.

## Code of conduct

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md). Participation implies agreement
to it.
