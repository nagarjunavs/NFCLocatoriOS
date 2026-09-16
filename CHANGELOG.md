# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- `NFCLocatorCore`: initial Swift package — resolver chain (remote catalog → bundled seed
  catalog → generic form-factor heuristic), SwiftUI components (`AntennaLocatorScreen`,
  `AntennaSilhouette`, `GuidedSweepAnimation`, `ConfidenceBadge`, `RetryGuidanceBanner`),
  `SwiftDataCatalogCache`, and the `CatalogRemoteAPI`/`NFCLocatorAnalytics`/`NFCLocatorLogger`
  integration seams. 52 unit tests.
- `TapSense`: sample app demonstrating every screen and confidence tier against the package —
  onboarding, home dashboard, My Phone, phone selection/confirmation, tap guide, live Tap Test
  (Core NFC), troubleshooting, education, settings, privacy. 31 unit tests.
- `PrivacyInfo.xcprivacy` for both `NFCLocatorCore` and `TapSense` (neither collects data or
  uses required-reason APIs, per direct source audit).
- `NFCLocatorCore`: bundled seed catalog expanded from 17 to 37 entries — 10 more iPhone models
  (iPhone 11 through 16 Pro Max, plus SE 3rd gen), 7 more Samsung Galaxy models (S24/S24+/S24
  Ultra, S23 FE, A55, Z Fold6, Z Flip6), and 3 more Google Pixel models (9, 9 Pro, 8a). Model
  identifiers and `aspectRatio` (from each device's published body dimensions) are sourced from
  each manufacturer's own specs; antenna zones reuse each manufacturer's already-established zone
  from this file rather than an independently fabricated per-model measurement, and every new
  entry intentionally leaves `verified` unset — see `NFCLocatorCore/DECISIONS.md` for why. Also
  added matching `TapSense` friendly-name entries for the new Samsung/Pixel model codes (the new
  iPhone identifiers were already covered by an earlier fix).
- `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, this changelog.
- `docs/app-store/` — App Store Connect submission checklists and templates.
- `.github/workflows/` — CI covering `swift build`/`swift test` for the package and
  `xcodebuild` build/test for the sample app.
- `NFCLocatorCore.podspec` for optional CocoaPods distribution alongside Swift Package Manager.
- `TapSense`: Android/Apple platform filter on the Phone Selection screen (segmented control
  below the title, above search) — present in the design mockup but not previously implemented.
  Combines with the existing search so switching platforms re-scopes an in-progress search
  instead of clearing it. See `TapSense/DECISIONS.md`.

### Removed
- `TapSense`: My Phone's "Report inaccurate guidance" button — it called through to
  `NFCLocatorAnalytics.guidanceDismissed`, but `TapSense`'s own implementation only writes to
  the local OS log, so the button told users their feedback was sent somewhere it wasn't. See
  `TapSense/DECISIONS.md`.

### Fixed
- `TapSense`: real device (`hw.machine`) model names resolved to a mangled generic-capitalization
  fallback instead of a marketing name for every iPhone except one hardcoded catalog example
  (e.g. a real iPhone 12 displayed as "Iphone13 2") — the friendly-name lookup table was keyed on
  a raw comma-separated format that the real-device path's already-normalized fingerprint could
  never match. Table re-keyed to match the normalized form consistently, and Apple coverage
  expanded through the iPhone 16 line. See `TapSense/DECISIONS.md`.
- `TapSense`: My Phone screen's content below "Test this location" was unreachable — the
  floating bottom tab bar didn't leave a `ScrollView` enough headroom to scroll far enough to
  clear it. Fixed on My Phone, and defensively on Home/Settings, which share the same at-risk
  layout. See `TapSense/DECISIONS.md`.
- `TapSense`: link-style buttons ("Tap not working?", "Skip", "Use my phone automatically")
  rendered in a near-black, barely-visible teal instead of the intended vivid aqua accent —
  `TapSenseColors.linkForeground` was hardcoded to the *on-primary* contrast color instead of
  being theme-aware like every other color role in that file. See `TapSense/DECISIONS.md`.
- `TapSense`: the bottom tab bar left a large band of dead space above the home indicator on
  both a physical device and the Simulator — its row sized itself to the raised Tap Guide FAB's
  *unshifted* layout footprint rather than its actual (offset-shifted) visible content, stretching
  the whole bar well past where Home/My Phone/Settings' own content ended. See
  `TapSense/DECISIONS.md`.
- `TapSense`: the new platform-filter toggle's tap targets, sized visually under Apple's 44pt
  minimum, silently swallowed taps intended for the search field 8pt below it — Apple/iOS expands
  an undersized control's hit-testable area invisibly, and there wasn't enough real gap for that
  expansion to not encroach. Fixed by giving each segment an explicit `.frame(minHeight: 44)` and
  `.contentShape(Rectangle())`, plus a larger real gap. See `TapSense/DECISIONS.md`.

### Known issues
- **TapSense's Tap Test screen (live Core NFC session) fails on at least one tested physical
  device** with `NFCError` code 2, "Missing required entitlement," despite verified-correct
  team/App ID/entitlement/provisioning-profile/device-registration configuration. Root cause is
  not yet resolved and requires Apple Developer Support investigation (server-side entitlement
  grant visibility unavailable from the client side). See
  [`TapSense/DECISIONS.md`](TapSense/DECISIONS.md) for the full investigation trail. **This
  blocks App Store submission until resolved** — do not submit while this is open.

## [0.1.0] - Unreleased
Initial internal milestone. Not yet tagged — see `README.md` for repository/versioning state.
