# Design decisions

Trade-offs made building `NFCLocatorCore`. Kept to one page; see doc comments on the referenced
types for more detail.

## No on-device antenna-hardware layer
Some Android devices running Android 14+ can report `NfcAntennaInfo` — an OS API that gives the
*measured* physical location of the antenna on that specific unit. Core NFC has no equivalent:
`NFCTagReaderSession` reads tags, never antenna geometry, and Apple has never needed to expose
one since the system already draws a "hold near the top" sheet during a scan. The resolver chain
here is therefore three layers (remote catalog → seed catalog → heuristic), not four. `DataSource`
has no case for an OS-measured reading, and `DeviceIdentitySignals` carries no field for it —
both would be permanently dead on this platform. `Confidence.exact` remains fully reachable via a
`verified: true` catalog entry (OEM/vendor-curated data, not an OS reading).

`NFCLocatorAnalytics.android14AntennaDetected(antennaCount:)` is kept in the protocol (and never
called on iOS) purely so a host reporting to one shared analytics backend across multiple client
platforms can implement a single handler without special-casing per platform.

## Confidence model
`EXACT` means "non-heuristic, model-specific data" — a verified catalog entry — and
`APPROXIMATE` covers unverified catalog matches. `APPROXIMATE` entries older than 180 days, or
with no `lastVerifiedAt` at all, are flagged stale and paired with the sweep animation instead of
standing alone as a solid marker; `EXACT` never degrades this way. See
`DeviceAntennaProfile.isStale(now:)`.

## SwiftData for the local cache
A suspend-function-style DAO pattern maps directly onto a SwiftData `@ModelActor` — one writer,
off the main thread by construction, no hand-rolled serial-queue plumbing. No migration story is
implemented: this is a disposable cache, not a source of truth, so a schema change just starts
over empty. This decision fixes iOS 17+ as the deployment floor (SwiftData's minimum).

## `AntennaLocatorUIState`'s invariant: `precondition`, not a thrown error
A `ResolvedMarker` constructed with `.generic`/`.unknown` confidence must trap immediately,
deliberately, because that combination is a programmer error, not a recoverable runtime
condition — a UI that silently swallowed it via a `throws`/`Result` path a caller could
accidentally catch would be far worse than a crash during development. `precondition(...)` in
`ResolvedMarker`/`FallbackGuidance`'s initializers enforces this. `NormalizedRect`'s validation,
by contrast, uses a `throws` initializer, because a malformed catalog row is a "skip this one bad
entry" recoverable path, not a hard invariant.

## `DeviceFingerprint` fields are pre-normalized by the producer
`lookupKeys()` does not itself call `normalize()` — it assumes the `DeviceFingerprintProvider`
implementation already normalized every field (lowercase, `_`-separated) before constructing the
value. The real iOS provider (in the TapSense sample app, Phase 2) derives its fingerprint from
the `hw.machine` sysctl identifier and normalizes it before use, matching
`CatalogEntryDTO.lookupKey()`'s normalization on the catalog side — this is what lets a raw
identifier like `"iPhone15,2"` (sysctl form) and a catalog entry authored as `"iphone15,2"` (JSON
form) land on the same key, `"iphone15_2"`.

## Bundled seed catalog uses a shared wire format
`Resources/seed_catalog.json` ships 37 entries using the same field names
(`CatalogEntryDTO`'s `CodingKeys` intentionally match the wire format's `@Serializable` field
names, e.g. `silhouetteTemplateId`, `zoneX`, not Swift-conventional names) so a single backend
serving `CatalogRemoteAPI` responses can be shared verbatim across client platforms without a
translation layer. Apple entries are directly load-bearing on iOS, not just informational —
`TapSenseDeviceFingerprintProvider`'s real-device path matches against them for any iPhone the
generic heuristic would otherwise have to fall back on (see `DisplayNames.swift`'s doc comment in
the `TapSense` sample app for the normalization this depends on).

### What "37 entries" actually means — and doesn't
No manufacturer publishes a database of exact per-model NFC antenna coordinates; `zoneX`/`zoneY`/
`zoneWidth`/`zoneHeight` here are *not* measured, certified values the way `verified: true` on a
handful of the original entries implies for those specific rows. Every entry added in this
expansion (10 more Apple models, 7 more Samsung, 3 more Pixel) deliberately leaves `verified`
unset — the same signal the original catalog already used for its own unconfirmed rows — so they
surface as `Confidence.approximate`, never `.exact`, through the resolver chain. What *is*
verified, from each manufacturer's own published specs (Apple's support pages, GSMArena/Samsung's
own spec sheets): the model identifiers themselves (Apple `hw.machine` strings, Samsung `SM-`
codes, Pixel `Build.MODEL` names) and the `aspectRatio` field, computed from each device's real
published body dimensions (width/height in mm). The antenna zone for each new entry reuses its
own manufacturer's already-established zone for the equivalent prior-generation device in this
same file (e.g. every new iPhone reuses `iphone15,2`'s zone; new Galaxy S24 entries reuse the
S23/S23 Ultra zone) — a defensible, consistent placement given each manufacturer's NFC coil
position is well-documented to stay stable generation-to-generation (multiple manufacturer/NFC
accessory support sites consistently describe "upper-to-middle back, near the camera module" as
the pattern), not an independently fabricated per-model measurement.

## `FormFactor`/`FoldState` kept at full width, not trimmed to `bar`/`tablet`
No shipping iPhone is a foldable, but the catalog is universal — a user can preview *any* phone's
antenna zone via the phone-picker screen, including foldables already in the seed catalog.
Trimming the enum would break catalog/wire-format compatibility for no benefit; the real iOS
`DeviceIdentitySignalsProvider` (Phase 2) will simply never *produce* `.foldBook`/`.foldFlip` for
the running device today.

## `ScreenSizeClass` — modeled but not yet load-bearing
`GenericFallbackSource`'s heuristic currently branches only on `formFactor`/`foldState`, never
`screenSizeClass`. Kept in the model for future heuristic refinement and because it's part of the
shared catalog wire format, not because it currently affects the resolved zone.

## Colors and fonts: system defaults, not a bundled design system
`AntennaSilhouette`/`ConfidenceBadge` default to plain SwiftUI system colors (`Color.accentColor`,
`Color.orange`, `Color.gray.opacity(...)`), all overridable via initializer parameters — this
package has no design system of its own and shouldn't own one (see "the library never hardcodes
brand hues" above). The TapSense sample app (Phase 2) supplies its own palette on top.

## String Catalog keys
`Localizable.xcstrings` uses dotted keys (`nfc_locator.marker.stale_hint`) — idiomatic for a
String Catalog, and namespaced to match the wire format in spirit. One string was written
iOS-specific rather than reused verbatim: the sweep-fallback copy avoids naming a specific OS in
its "most phones have their NFC antenna near the top or back" hint text, since the same package
is meant to be readable independent of which platform it's compiled for.

## Deferred / explicitly out of scope (Phase 1)
- The TapSense sample app (onboarding, home dashboard, antenna detail, guided tap flow, live tap
  test via Core NFC, phone selection/preview, troubleshooting, settings) is Phase 2, tracked
  separately — this package is the library only.
- No real backend; `CatalogRemoteAPI` + `CatalogEntryDTO`/`CatalogResponseDTO` are the wire
  contract a backend workstream would implement against.
- Core NFC's live tag-reading APIs (`NFCTagReaderSession`) only work on a physical device, never
  the Simulator — Phase 2's live tap-test screen can be built correctly against the API but
  needs a real iPhone to verify end-to-end.
