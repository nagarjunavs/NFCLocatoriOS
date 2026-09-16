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
xcodebuild -project TapSense.xcodeproj -scheme TapSense -destination 'generic/platform=iOS' build \
  -allowProvisioningUpdates -allowProvisioningDeviceRegistration
```

Set `DEVELOPMENT_TEAM` before running `xcodegen generate` rather than picking a team through
Xcode's own Signing & Capabilities UI — `xcodegen generate` rewrites the whole `.xcodeproj` from
`project.yml` on every run, which silently discards a team selected only in the UI. Without a
team at all, building for a device fails immediately with "Signing for 'TapSense' requires a
development team," before the build even reaches Core NFC.

**`-allowProvisioningUpdates` is not optional** for this command, and its absence is a
previously-confirmed cause of Tap Test failing with the exact same "Missing required entitlement"
error even *after* correctly adding the NFC capability in Xcode's Signing & Capabilities UI: that
UI talks to the developer portal and refreshes the provisioning profile on its own, but a plain
`xcodebuild build` invoked from Terminal does not — it silently reuses whatever profile is already
cached on disk, which may predate the capability. See `DECISIONS.md`'s "Same 'Missing required
entitlement' error recurred after the capability was added" for the full account. After any build,
you can confirm what's actually embedded without touching a device at all:

```bash
codesign -d --entitlements :- \
  ~/Library/Developer/Xcode/DerivedData/TapSense-*/Build/Products/Debug-iphoneos/TapSense.app
```

Look for `com.apple.developer.nfc.readersession.formats` in the output. If it's missing, the
build itself — not the device, not the developer portal — is the problem: delete the cached
profile at `~/Library/Developer/Xcode/UserData/Provisioning Profiles/` and rebuild with
`-allowProvisioningUpdates` again.

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
3. Confirm at developer.apple.com/account → Certificates, Identifiers & Profiles → Identifiers
   that `com.tapsense.app` is registered as its own **explicit** App ID (not matched by a wildcard
   like `com.tapsense.*`) with **NFC Tag Reading** checked — Apple does not allow the NFC
   entitlement on a wildcard App ID at all, and Xcode's "+ Capability" step can silently no-op
   against one instead of erroring.
4. Confirm Xcode → Settings → Accounts is signed in with the **same Apple ID** that actually owns
   this App ID's registration — signing/building with a different Apple ID's automatic-signing
   session creates or reuses an entirely different profile that never sees the capability you just
   added (this exact mismatch is what caused an earlier false "provisioning is fine" conclusion in
   `DECISIONS.md`).
5. Let Xcode finish resolving signing (watch for the signing-error banner to clear), then either
   run from Xcode.app directly (`Cmd+R`) or rebuild from Terminal with
   `-allowProvisioningUpdates` — **a plain `xcodebuild build` without that flag reuses whatever
   profile is already cached and will not pick up the change**, reproducing the identical error
   even after steps 1–4 are all done correctly. See the `-allowProvisioningUpdates` note above.
6. Before touching the device again, verify directly: `codesign -d --entitlements :-` on the
   freshly built `.app` (command above) must show
   `com.apple.developer.nfc.readersession.formats`. If it doesn't, the build/profile is still the
   problem — delete `~/Library/Developer/Xcode/UserData/Provisioning Profiles/` and rebuild.
7. Fully delete the app from the device (long-press → Remove App, not just reinstalling over it)
   before the next install — a stale installed binary's own embedded profile doesn't get replaced
   by installing on top of it in every case.

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

44 unit tests cover `Router`'s navigation-stack logic, `TapTestViewModel`'s Core-NFC-adjacent
state machine — including session-end handling, the activated-vs-never-activated distinction
that separates a genuine `.timedOut` from `.readerUnavailable`, and retry (via a fake
`TapReaderModeStarting`, since real Core NFC session behavior can only be exercised on a
device) — `TapSenseSettingsStore`'s JSON persistence and backup-exclusion (against a temp
directory, not the real `Application Support`), `PhoneSelectionViewModel`'s platform-filter/search
combination logic (against in-memory catalog fixtures), and the `DisplayNames` friendly-name
mapping, including the real-device regression covered in `DECISIONS.md` (a raw `hw.machine`
string and its already-normalized form must both
resolve to the same marketing name).

## License

MIT — see [`../LICENSE`](../LICENSE).
