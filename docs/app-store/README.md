# TapSense — App Store Connect submission checklist

Grounded in an actual audit of `TapSense`'s code and dependencies (not generic boilerplate) — see
the reasoning next to each item. Every `[owner]` item is a manual action only the account holder
can complete; nothing here was submitted, approved, or published on your behalf.

## ⛔ Blocking issue — read this first

**Tap Test (the live Core NFC session, `TapSense`'s headline feature) failed on at least one
tested physical device** with `NFCError` code 2, "Missing required entitlement." The root cause
is now identified: the App ID's **NFC Tag Reading** capability was never registered on the Apple
Developer Portal for the account that actually signed the installed build — declaring
`com.apple.developer.nfc.readersession.formats` in `project.yml` puts the entitlement *key* in
the generated `.entitlements` file, but only adding the capability through Xcode's own Signing &
Capabilities **+ Capability** picker registers it against the App ID and refreshes the
provisioning profile. See [`../../TapSense/DECISIONS.md`](../../TapSense/DECISIONS.md) for the
full investigation and the exact remediation steps. **This is an `[owner]` action** — it needs
the account holder's own Apple Developer Portal access — **and has not yet been re-verified
working end-to-end on a real device. Do not submit to App Review until that re-verification is
done.** Apple's reviewers test on real hardware; a broken core feature is close to a guaranteed
rejection (Guideline 2.1, Performance — App Completeness), and worse, is a bad experience for
real users.

## App record — [owner]

- [ ] App name (30 chars max) — not yet decided in this repo; `TapSense` is the internal/bundle
      name, not necessarily the storefront display name.
- [ ] Subtitle (30 chars max)
- [ ] Bundle ID: `com.tapsense.app` (from `TapSense/project.yml`) — confirm this is the ID you
      want permanently on the App Store; it cannot be changed after first submission.
- [ ] SKU (your own internal identifier, any unique string)
- [ ] Primary category / secondary category (Utilities is the closest fit for the app's actual
      function — a tap-zone locator/reference tool)
- [ ] Promotional text (170 chars, editable without a new build)
- [ ] Description
- [ ] Keywords (100 chars, comma-separated)
- [ ] Support URL — **required**, not present in this repo; needs a real, working page
- [ ] Marketing URL — optional
- [ ] Privacy Policy URL — **required** even for an app that collects nothing (see Privacy
      section below); needs a real, working page

## App Privacy ("nutrition label") — [owner], based on this audit

Audited directly against `TapSense/Sources` and `NFCLocatorCore/Sources`:

| Question | Answer from code audit |
|---|---|
| Does the app collect any data? | **No.** No analytics SDK (`OSLogNfcLocatorAnalytics`/`OSLogNfcLocatorLogger` write to the local OS log only, never transmitted), no network calls in the sample app (`FakeCatalogRemoteAPI` is a local in-memory fake), no accounts, no forms. |
| Does the app track users (per Apple's ATT definition)? | **No.** No cross-app/cross-site tracking of any kind. |
| Third-party SDKs? | **None.** Zero external dependencies in `project.yml`. |
| `PrivacyInfo.xcprivacy` required-reason APIs? | **None used** — confirmed by source scan (no `UserDefaults`, file-timestamp, disk-space, or boot-time API usage). Both targets ship an empty-but-present `PrivacyInfo.xcprivacy` declaring exactly this. |
| Local data stored? | Yes, but **not collected/transmitted**: `TapSenseSettingsStore` (a Codable JSON file, backup-excluded — see `TapSense/DECISIONS.md`), `SwiftDataCatalogCache` (an on-device catalog cache), Core NFC scan results (never leave the device). |

**[owner] action**: in App Store Connect → App Privacy, based on the above you can very likely
answer "No, we do not collect data from this app" — but you must complete this questionnaire
yourself; this document is not a substitute for it, and if you add a real backend
(`CatalogRemoteAPI` implementation) or analytics later, revisit this table first.

## App Tracking Transparency — not applicable
No tracking occurs; no ATT prompt is needed. Confirm this stays true if a real
`CatalogRemoteAPI`/`NFCLocatorAnalytics` implementation is added later.

## Permissions / usage descriptions — audited

| Permission | Usage string (from `TapSense/project.yml`) | Justified? |
|---|---|---|
| NFC (`NFCReaderUsageDescription`) | "TapSense uses NFC to detect when your phone successfully taps an NFC tag or reader, so it can confirm your recommended tap area is working." | Yes — accurately describes Tap Test's actual behavior, nothing broader. |

No other permission usage strings exist in the project — no camera, microphone, location,
contacts, photos, Bluetooth, HealthKit, or calendar access, matching what the code actually
does.

## Entitlements — audited

Only `com.apple.developer.nfc.readersession.formats` (`NDEF`, `TAG`) — see
`TapSense/Generated/TapSense.entitlements`. No App Groups, Keychain Sharing beyond the default
per-app group, Push Notifications, Associated Domains, or background modes. Minimal and
justified by actual functionality — nothing to trim here.

## Accounts, sign-in, IAP, subscriptions — not applicable
No account creation, no third-party login (so no Sign in with Apple requirement is triggered),
no StoreKit/IAP/subscriptions, no external purchase links. Nothing in this category needs a
declaration.

## Age rating & content — [owner]
No user-generated content, no moderation surface, no gambling/crypto/dating/health/financial
functionality. Based on the actual feature set this should qualify for the lowest applicable
age rating tier, but the age-rating questionnaire itself must be completed by the account
holder in App Store Connect — this document doesn't answer it for you.

## Export compliance — [owner]
The app does not implement or link custom cryptography beyond what iOS itself provides
(standard TLS via `URLSession`, if/when a real `CatalogRemoteAPI` backend is added — the sample
app's own `FakeCatalogRemoteAPI` makes no network calls at all). This typically qualifies for
the standard "exempt" export compliance answer, but the account holder must confirm this in App
Store Connect at archive-upload time — it is a legal declaration, not something automatable.

## Screenshots & app previews — [owner]
Required device-size checklist (sizes per Apple's current requirements at submission time —
verify against App Store Connect's own uploader, which enforces current requirements):
- [ ] 6.9" / 6.7" display (iPhone 16 Pro Max / 15 Pro Max class)
- [ ] 6.5" display (iPhone 11 Pro Max / XS Max class) — may be reusable from the 6.7" set
- [ ] iPad Pro 13"/12.9" display, if supporting iPad (`TapSense/project.yml` currently sets
      `TARGETED_DEVICE_FAMILY: "1"` — iPhone only; add iPad support and its own screenshots if
      that changes)
- [ ] App preview video(s) — optional

No screenshots exist in this repo; none are fabricated here.

## App Review notes — [owner]
No login/gated content exists, so no demo account is needed. Given the open Tap Test blocker
above, App Review notes should explain that Tap Test requires a physical NFC-capable device —
Core NFC does not work in Apple's own review simulators either, so reviewers will need a real
device path (standard for any Core NFC app, not specific to this one).

## Release strategy — [owner]
- [ ] TestFlight internal testing first (recommended, especially given the open Tap Test issue —
      do not proceed to external TestFlight or App Review until it's confirmed fixed on a real
      device)
- [ ] Phased release vs. immediate 100% rollout on first version
- [ ] Release notes for this version (template below)

### Release notes template
```
[owner: fill in — e.g. "Initial release: find exactly where to tap your phone against NFC
readers and locks, with a live Tap Test to confirm your tap zone works."]
```

## Final pre-submission checklist
- [ ] Tap Test confirmed working on a real device (see blocking issue above)
- [ ] Support URL and Privacy Policy URL are real, live pages
- [ ] App Privacy questionnaire completed in App Store Connect
- [ ] Age rating questionnaire completed
- [ ] Export compliance answered at archive-upload time
- [ ] Screenshots for all required device sizes uploaded
- [ ] TestFlight internal testing completed with no crashes/regressions
- [ ] Release notes written
- [ ] Bundle ID, version (`CFBundleShortVersionString`), and build number
      (`CFBundleVersion`) reviewed in `TapSense/project.yml` and are what you intend to ship
