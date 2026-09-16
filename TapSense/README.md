# TapSense (iOS)

A complete reference integration built on [`NFCLocatorCore`](../NFCLocatorCore), demonstrating
every screen, confidence tier, and integration seam the library exposes.

## Requirements

- Xcode 15.3+ (built and verified against Xcode 26.5)
- iOS 17+ (Simulator or device)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate `TapSense.xcodeproj` from
  [`project.yml`](project.yml) — `brew install xcodegen`
- A physical device + **paid** Apple Developer Program membership to exercise the live Tap Test
  screen's Core NFC reader session — a free/personal Apple ID cannot get the NFC entitlement
  approved at all, and Core NFC does not work in the Simulator regardless of account type (see
  [`DECISIONS.md`](DECISIONS.md))

## Building & running

```bash
xcodegen generate
xcodebuild -project TapSense.xcodeproj -scheme TapSense -destination 'generic/platform=iOS Simulator' build
xcodebuild -project TapSense.xcodeproj -scheme TapSense -destination 'id=<simulator-udid>' test
```

Or open `TapSense.xcodeproj` in Xcode after running `xcodegen generate` and run/test normally.
Re-run `xcodegen generate` after adding, removing, or renaming any source file — `project.yml`
declares `Sources`/`Resources`/`Tests` as folder references XcodeGen expands at generation time,
not the generated `.xcodeproj` itself (which is not checked in — see `.gitignore`).

### Running Tap Test on a real device

Every other screen works fine in the Simulator. Tap Test's live Core NFC reader session needs a
physical device *and* a correctly signed build, or it won't work at all:

```bash
export DEVELOPMENT_TEAM=<your Apple Developer Team ID>   # Signing & Capabilities → Team, or
                                                            # find it at developer.apple.com/account
xcodegen generate
xcodebuild -project TapSense.xcodeproj -scheme TapSense -destination 'generic/platform=iOS' build
```

Set `DEVELOPMENT_TEAM` before running `xcodegen generate` rather than picking a team through
Xcode's own Signing & Capabilities UI — `xcodegen generate` rewrites the whole `.xcodeproj` from
`project.yml` on every run, which silently discards a team selected only in the UI. Without a
team at all, building for a device fails immediately with "Signing for 'TapSense' requires a
development team," before the build even reaches Core NFC.

If Tap Test reaches **"Couldn't start the NFC reader"** immediately, with no system "Hold Near
the Top of iPhone" sheet ever appearing, check the device's own console log first — connect the
device, then **Xcode → Window → Devices and Simulators → select the device → Open Console**, and
filter for `TapReaderModeController`. Every path that can lead to "Couldn't start the NFC reader"
logs at error level there, including the underlying `NFCReaderError` domain/code.

If that line reads **`domain: NFCError, code: 2, "Missing required entitlement"`**, the fix is on
the developer-portal/Xcode-UI side, not in this project's code or config:

1. Open `TapSense.xcodeproj` in Xcode.app, select the TapSense target → **Signing & Capabilities**.
2. If **Near Field Communication Tag Reading** is not listed there as its own capability card,
   click **+ Capability** and add it explicitly, even though `project.yml` already declares the
   entitlement key — adding it through this picker is what actually registers the capability
   against the App ID on the developer portal and regenerates the profile. Declaring the raw
   entitlement key via `project.yml`/XcodeGen alone does not reliably trigger that registration.
3. Let Xcode finish resolving signing, then delete the app from the device and reinstall (a
   profile cached from before the capability existed won't self-refresh).
4. Still failing? Confirm **NFC Tag Reading** is checked for `com.tapsense.app` directly at
   developer.apple.com/account → Certificates, Identifiers & Profiles → Identifiers, and if
   Xcode still won't pick it up, delete the cached profile at `~/Library/Developer/Xcode/UserData/Provisioning Profiles/`
   to force a fresh download.

See [`DECISIONS.md`](DECISIONS.md) for the full investigation, what each logged branch means, and
why an earlier "provisioning is fine" conclusion in that log turned out to be wrong (it verified
entitlements for a different Apple Developer account than the one actually signing the installed
build).

## What's here

Every screen needed for a complete NFC-locator experience, covering all four confidence tiers
end to end:

| Screen | Notes |
|---|---|
| Splash | Fixed 1100ms minimum visible time, then Onboarding or Home |
| Onboarding | 3-page walkthrough (`TabView` + `.page` style), real resolver preview on page 3 |
| Home | Dashboard: dark mockup card, confidence chip, tip banner |
| My Phone | Back/Front toggle; Front is a decorative "not applicable" placeholder |
| Phone Selection / Confirmed | Search + merged seed/remote catalog, manual override flow |
| Tap Guide | 5-step walkthrough, auto-redirects to Tap Test if NFC is unsupported |
| Tap Test | Real Core NFC reader session — the one screen needing a physical device |
| Troubleshoot | Issue picker with contextual actions |
| Education | Expandable FAQ rows |
| Settings | Phone override, haptics/reduce-motion toggles, appearance picker |
| Privacy & data | Static, code-path-accurate privacy copy |

Navigation is a single flat `NavigationStack` with a bottom tab bar shown/hidden per-route (see
`Router.swift`, `TapSenseRootView.swift`), including a four-item bar (Home / My Phone / a raised
Tap Guide FAB / Settings).

## Testing

31 unit tests cover `Router`'s navigation-stack logic, `TapTestViewModel`'s Core-NFC-adjacent
state machine — including session-end handling, the activated-vs-never-activated distinction
that separates a genuine `.timedOut` from `.readerUnavailable`, and retry (via a fake
`TapReaderModeStarting`, since real Core NFC session behavior can only be exercised on a
device) — and the `DisplayNames` friendly-name mapping, including the real-device regression
covered in `DECISIONS.md` (a raw `hw.machine` string and its already-normalized form must both
resolve to the same marketing name).

## License

MIT — see [`../LICENSE`](../LICENSE).
