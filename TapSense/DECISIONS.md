# Design decisions (TapSense)

Trade-offs made building the TapSense sample app in SwiftUI. Entries here are either a
platform-forced departure from what the layout naturally suggests, or something a real Simulator
or device run surfaced that reading the source alone wouldn't have shown. See
[`NFCLocatorCore/DECISIONS.md`](../NFCLocatorCore/DECISIONS.md) for the library-level decisions
this app builds on.

## Navigation: one flat `NavigationStack`, not per-tab stacks
A single route table drives navigation — one flat table of routes with a bottom bar shown/hidden
per-current-route rather than a nested per-tab graph (see `TapSenseDestinations.BOTTOM_BAR_ROUTES`).
`Router` (`root` + `path`) implements "clear the path and swap root" for top-level tab switches —
this means switching tabs doesn't preserve each tab's own scroll/navigation state, a minor UX
simplification with no functional effect the design specifies elsewhere.

## Back button: default chevron with an empty title, not a hidden bar
The first attempt hid the navigation bar entirely (`.toolbar(.hidden, for: .navigationBar)`) to
match the design's intended absence of back-button chrome. **Confirmed by driving the built app
in the Simulator**: this also disabled the interactive swipe-back gesture — a real regression, not
a hypothetical one, since every pushed screen except Tap Guide (which has its own explicit close
button) would otherwise have had no way back at all. `navigationBarBackButtonHidden(true)` was
tried next and has the same documented coupling. The fix: leave the default back button in place,
but give every screen (including tab roots, whose title is what a *pushed child's* back button
reads) `.navigationTitle("")` — iOS then renders a bare chevron with no "Back" text, visually
matching the intended design, with both tap and swipe-to-go-back intact. Tap Guide alone keeps
`navigationBarBackButtonHidden(true)`, since its own close (X) button makes the default one
redundant and swipe-back isn't needed there.

## Root containers need an explicit `.frame(maxWidth: .infinity, maxHeight: .infinity)`
**Found by running the app**: a screen's outer `VStack` only reports its *content's* natural size
to its parent unless a child inside it is flexible (a `ScrollView` filling most of the screen
masks this in practice; `PhoneConfirmedScreen`, whose content is short and centered, showed it
immediately as a background color that stopped short of the screen edges). Every screen's root
container now explicitly requests the full available size before `.background()` is applied,
rather than relying on a `ScrollView` child to imply it.

## `TapTestViewModel` depends on a protocol, not `TapReaderModeController` directly
Swift classes aren't substitutable in tests the way a protocol-typed dependency is, so
`TapReaderModeStarting` (`start(onTagDetected:onSessionEnded:)`/`stop`) is the minimal seam
`TapTestViewModel` depends on instead of the concrete controller — `TapReaderModeController`
conforms to it for real use, `TapTestViewModelTests` uses a fake. This keeps the state machine
(Ready → Detecting → Detected/TimedOut, retry) fully testable without Core NFC or a physical
device.

## Tap Test didn't work at all on a real device — two compounding bugs, found only by reasoning through the untestable path
Every earlier verification pass could only exercise the `!isNfcSupported` branch of
`TapReaderModeController` — `NFCTagReaderSession.readingAvailable` is unconditionally `false` in
the Simulator, so the actual session-handling code had **never executed once**, in any build,
before a real device revealed it didn't work. Two real, compounding bugs, not one:

1. **`didInvalidateWithError` only logged.** A Core NFC session is ephemeral: `NFCTagReaderSession`
   ends on its own when the user dismisses the system "Hold Near the Top of iPhone" sheet, when
   the OS's own ~60s session timeout elapses, or immediately after `begin()` if the app's NFC
   entitlement isn't correctly provisioned. None of that was ever reported back to
   `TapTestViewModel` — the screen just sat on "Detecting…" until the *app's own* 25s timer
   fired, regardless of what the real session was doing. Fixed: `start` now takes a second
   `onSessionEnded` callback, invoked from `didInvalidateWithError`, which the view model uses to
   move out of `.detecting` immediately instead of waiting on an unrelated timer.
2. **`retry()` didn't restart anything.** By the time a user sees a reason to retry, the real
   `NFCTagReaderSession` has almost always already ended (that's `.timedOut`'s call, and now bug
   #1's fix makes it fire correctly). Resetting only the UI countdown left every retry after the
   first listening to nothing, timing out again no matter what was presented to the phone — this
   alone could fully explain "doesn't work at all." Fixed: `retry()` now calls `stop()` then
   `startListening()`, genuinely re-arming Core NFC each time.

Reconciling "did this session end on purpose or is this a stale callback from a session we've
already moved past" is done by comparing the session instance's identity
(`session === self.session`) inside the delegate callbacks, not a boolean flag — a flag set by
`stop()` and cleared by the next `start()` (as in an earlier draft of this fix) races exactly the
sequence `retry()` triggers: `stop()` sets it, `start()` immediately clears it again, and the
*first* session's now-asynchronous invalidation callback arrives after that, misreading the
fresh session's state. Identity comparison has no such window: a callback naming any session
other than the one `self.session` currently holds is definitionally stale and ignored.

## Tap Test on a real device went straight to "No NFC signal detected yet" — a second, distinct bug the first fix's own device testing exposed
After the fix above, the screen stopped hanging on "Detecting…" forever — but on the actual
device it was tested on, it went to `.timedOut` ("No NFC signal detected yet") *immediately*,
with no system "Hold Near the Top of iPhone" sheet ever appearing. That copy is wrong for what
actually happened: it reads as "you held your phone up and nothing was read," but a session that
never even reached the system sheet was rejected before the user had any chance to present a tag
at all — Core NFC only calls `tagReaderSessionDidBecomeActive` once a session has genuinely
started polling, and this callback was never firing. That combination (immediate invalidation,
no activation) is the textbook signature of `NFCTagReaderSession.begin()` being rejected outright
— almost always because the *installed build* isn't actually signed with the NFC entitlement
provisioned, even though `readingAvailable` (a hardware/OS check only, not an entitlement check —
see below) reported `true` and the app never took the `.nfcUnsupported` branch at all.

Fixed at the root: `TapReaderModeController` now tracks `sessionBecameActive`, set only from
`tagReaderSessionDidBecomeActive` (reset per session generation, same identity-comparison
discipline as above), and threads it through `onSessionEnded`'s new `becameActive` parameter.
`TapTestViewModel` uses it to route to two genuinely different states: `.timedOut` when the
session *did* activate and the user had a real chance to present a tag, and the new
`.readerUnavailable` when it didn't — copy: "Couldn't start the NFC reader," not "No NFC signal
detected yet." The same `.readerUnavailable` state also now covers `start()` returning `false`
outright (previously mislabeled `.timedOut` too). This doesn't fix the underlying provisioning
problem — that's outside the app's code, see below — but it stops the UI from lying about what
happened, which is what made "the feature doesn't work at all" so hard to diagnose from the
outside in the first place.

If you hit `.readerUnavailable` on a device: this is not something `retry()` can fix by itself.
Confirm in Xcode → target → Signing & Capabilities that "Near Field Communication Tag Reading" is
listed under the target's capabilities and that the provisioning profile shown there actually
includes it (Automatic signing usually needs the project opened in Xcode.app itself, connected to
your Apple ID, at least once for a *newly added* capability like this one to be registered with
the App ID on the developer portal and folded into the profile — a bare `xcodebuild` command-line
build, even with `DEVELOPMENT_TEAM` set, does not reliably trigger that first-time registration).

## Still failing instantly with no system sheet, even with a locally-verified entitlement — the reader session was starting mid-navigation-transition
**Correction — see the section below this one.** At the time this was written, a full
`xcodebuild -destination generic/platform=iOS build` was run signed (not
`CODE_SIGNING_ALLOWED=NO`) using whatever Apple Development identity happened to be in the build
machine's keychain, and both the built app's embedded entitlements (`codesign -d
--entitlements`) and the provisioning profile it was signed with (`security cms -D -i
embedded.mobileprovision`) were inspected directly. Both correctly listed
`com.apple.developer.nfc.readersession.formats = [NDEF, TAG]`, which was (wrongly) taken as proof
that provisioning wasn't the problem. It proved something narrower: the entitlement *key* round-
trips correctly through `project.yml` → XcodeGen → `codesign` for *that* signing identity. It said
nothing about whether the account actually used to install onto the test device had the NFC Tag
Reading capability approved for its own App ID — a different Apple ID than the one that build was
signed with. The real answer, confirmed directly from the device's own console log, is in "Found:
`NFCError` code 2" below.

With that ruled out, the same symptom (immediate failure, system sheet never appears, 100%
reproducible) has another, purely code-side explanation: `TapTestScreen`'s `.task` — which calls
`readerModeController.start()` — fires the instant the screen is inserted into the navigation
stack, which is the *start* of the push transition (`Run a tap test` on Tap Guide → pushes Tap
Test), not after it settles. Calling `NFCTagReaderSession.begin()` while the screen is still
mid-transition is a known way to get Core NFC to reject the session outright: it invalidates
before ever becoming active, so the system sheet never appears at all — from the user's
perspective, indistinguishable from a real entitlement problem, and exactly what "transitions to
error immediately, without any delay, no dialog ever shown" describes. Fixed: `.task` now awaits
a short `Constants.readerStartDelay` (500ms — comfortably past a standard push transition) before
calling `startListening()`, checking `Task.isCancelled` first so backing out of the screen before
the delay elapses doesn't start a session on a screen that's already gone.

Also hardened for the next time this needs debugging on a device: `didInvalidateWithError`'s log
line moved from `.d` (debug) to `.e` (error) and now includes the underlying `NSError`'s
`domain`/`code`, not just `localizedDescription` — the one diagnostic signal available for a
failure mode that can't be reproduced in the Simulator at all.

## The transition-timing fix didn't fix it either — on a fresh install, on an iPhone 7+, with confirmed-correct provisioning
Retested after the fix above with the entitlement/provisioning question and the "stale install"
question both directly ruled out (fresh delete-then-reinstall, a real iPhone 7-or-later, not an
iPad or a Mac running the iOS app — no iPad model supports `NFCTagReaderSession`'s tag reading at
all, which would otherwise have been a clean, fully-explanatory answer on its own). Still
immediate, still no system sheet.

`.readerUnavailable` is reached two ways, and they weren't equally diagnosable: `onSessionEnded`
firing with `becameActive: false` (an async round trip through Core NFC, however fast) was
already logged at error level with the `NSError` domain/code. `start()` returning `false`
directly — either `Self.isSupported` (`NFCTagReaderSession.readingAvailable`) reading `false`, or
`NFCTagReaderSession(pollingOption:delegate:)` itself returning `nil` — was a bare, silent,
*synchronous* return with no logging at all. That path matches "zero perceptible delay, no
dialog whatsoever" far better than any async invalidation ever could — there's no system round
trip on that path at all, nothing to be slow. It was also the one branch with no diagnostic
trail. Fixed: both early-return branches of `start()` now log at error level before returning
`false`, so the *next* Console.app capture will show, unambiguously, whether this is
`readingAvailable` itself reporting `false` on this specific device at this specific moment (a
genuine runtime/OS-state condition — e.g. another app or a background NFC feature such as Wallet
Express Transit holding the controller — not a config or provisioning gap, both of which are now
independently confirmed correct) or the session object failing to construct at all.

This is the point in the investigation where every angle checkable through static analysis, code
review, and a real signed build's inspected output — entitlement, provisioning profile, Info.plist
keys, deployment target vs. hardware minimum, fresh-install state, screen-transition timing — has
been individually verified and ruled out. What's left needs the actual `NFCReaderError`
domain/code from the device itself, which no amount of further code reading can substitute for;
see `README.md`'s "Running Tap Test on a real device" section for exactly where to find it.

## Found: `NFCError` code 2, "Missing required entitlement" — and why the earlier "provisioning is fine" conclusion was wrong
The device console log came back unambiguous: `domain: NFCError, code: 2, "Missing required
entitlement"`. This *is* a provisioning problem after all — but the entitlement inspection earlier
in this document didn't catch it, and the reason why matters: that inspection signed a build with
whatever Apple Development identity happened to be in *this* machine's keychain
(`security find-identity -v -p codesigning` → a different Apple Development identity than the
one on file for this project's owner). It proved the entitlements *key* round-trips correctly
through `project.yml` → XcodeGen → `codesign` — a real and useful thing to confirm — but it never
touched the account, App ID, or profile that actually signs the build installed on the test
iPhone. Two separate questions got conflated: "does the tooling embed the entitlement correctly"
(yes, confirmed) and "does *your* Apple Developer account have the NFC Tag Reading capability
approved for `com.tapsense.app`, with a profile that reflects it" (the actual open question, and
per this error, currently no).

The concrete, most common cause of exactly this error — entitlement key present in the project,
but the OS rejects the session at runtime with "missing required entitlement" — is that the App ID
on the developer portal has never actually had the **NFC Tag Reading** capability turned on, or
Xcode's automatically-managed profile predates it being turned on and hasn't refreshed. Declaring
`com.apple.developer.nfc.readersession.formats` in `project.yml`'s `entitlements:` block (which is
what this project does) puts the *key* in the `.entitlements` file XcodeGen generates, but it does
not, by itself, register the capability against the App ID on Apple's servers the way adding it
through Xcode's own Signing & Capabilities "+ Capability" picker does. This is a real, sharp edge
in the Automatic-signing + generated-project workflow, not a mistake in this repo's config.

**Fix (needs your own Apple Developer account — not something further code changes can resolve):**
1. Open `TapSense.xcodeproj` in Xcode.app, select the TapSense target → **Signing & Capabilities**.
2. If **Near Field Communication Tag Reading** is *not* listed as its own capability card there
   (separate from just having the entitlement key present), click **+ Capability** and add it
   explicitly. This is the action that actually tells Xcode to register the capability against
   the App ID on the developer portal and regenerate the profile — the missing step.
3. Let Xcode finish resolving signing (it does this automatically once the capability is added;
   watch for it to stop showing a signing error).
4. Delete the app from the device, then rebuild and reinstall (a stale cached profile from before
   the capability existed won't self-refresh otherwise).
5. If it's still rejected: check developer.apple.com/account → Certificates, Identifiers &
   Profiles → Identifiers → `com.tapsense.app` directly, and confirm **NFC Tag Reading** is
   checked there. If Xcode's automatic signing still won't pick up the change, delete the cached
   profile at `~/Library/Developer/Xcode/UserData/Provisioning Profiles/` (and, on older Xcode
   versions, `~/Library/MobileDevice/Provisioning Profiles/`) to force a fresh download.

Once this is done, re-check the `TapReaderModeController` log line on the next run — it should
either disappear entirely (the session now activates, the real "Hold Near the Top of iPhone"
sheet appears) or, if something is still wrong, report a different domain/code that will point
at whatever's next.

## Building for a real device needs a Development Team — and `DEVELOPMENT_TEAM` in `project.yml`, not just Xcode's UI
Core NFC's reader-session entitlement can only be provisioned under a paid Apple Developer
Program membership; a free/personal Apple ID cannot get it approved at all, and building for a
device with no team selected fails outright (confirmed: `xcodebuild ... -destination
'generic/platform=iOS' build` errors with "Signing for 'TapSense' requires a development team"
before it even reaches the compiler — the underlying Swift/Core NFC code itself was separately
confirmed to compile cleanly for the device architecture with `CODE_SIGNING_ALLOWED=NO`). Picking
a team purely through Xcode's Signing & Capabilities UI doesn't survive this project's workflow,
because `xcodegen generate` rewrites the whole `.xcodeproj` from `project.yml` on every run —
`project.yml` now reads `DEVELOPMENT_TEAM` from the `${DEVELOPMENT_TEAM}` shell environment
variable at generate time instead, so `export DEVELOPMENT_TEAM=<your team ID>` before generating
is durable across regenerations. See `README.md` for the full device-testing setup.

## Icons: SF Symbols for navigation, hand-drawn only for the brand mark
The bottom bar's Home/My Phone/Settings glyphs use SF Symbols (`house.fill`, `iphone`,
`gearshape.fill`) — standard platform icons are the idiomatic iOS choice for generic navigation
affordances, and avoid maintaining custom vector paths for controls a system font already covers
well. `TapSenseLogo` (the concentric-ring mark used on Splash, Onboarding, and the Tap Guide FAB)
is a hand-drawn brand asset instead, including its `singleRing` variant and pulse animation math
— it's the one piece of chrome specific to this product's identity, not a generic control, so it's
drawn pixel-for-pixel rather than approximated with a system symbol.

## Settings persistence: Codable JSON file, not SwiftData
`NFCLocatorCore` uses SwiftData for its catalog *cache* (a genuine collection with query needs).
App settings are a single small struct with no query surface, so `TapSenseSettingsStore` is a
plain `Codable` struct written to Application Support with the file's `isExcludedFromBackup`
resource value set. Writing settings somewhere backups skip entirely — rather than relying on
export-rule exclusions layered on a backed-up location — matters concretely here: without it, a
restored backup can silently reintroduce a completed-onboarding flag after a genuine reinstall,
making onboarding permanently unreachable.

## Dark "mockup card" colors: explicit parameters, not a theme override
`NFCLocatorCore`'s SwiftUI `AntennaSilhouette` takes its colors as explicit parameters rather than
reading them from an ambient theme, so drawing the phone-mockup card's dark-appropriate
primary/tertiary/outline tones needs no environment-override wrapper at all —
`DarkMockupColors.swift` is a set of plain functions returning the right fixed color for a given
screen context, passed directly into `AntennaMarker`.

## No OS-level NFC on/off toggle — removed the UI, not faked it
**iOS has no user-facing on/off toggle for NFC hardware** and no settings screen to deep-link to
for one — Core NFC scanning is simply available or unavailable based on hardware + entitlement.
An earlier version of this app faked an `isEnabled` flag that always mirrored `isNfcSupported`,
and showed Home's/Settings' "NFC status: on/off" rows and Troubleshoot's "Open NFC settings"
action against it — all three implied a toggle a user could go find and flip, which doesn't exist
on this platform and would only confuse. All three are gone: `NfcStateObserver` now carries only
`isNfcSupported` (real hardware/entitlement capability, not a toggle), and `TapTestUIState` has no
`.nfcOff` case — a session that fails to start folds into `.timedOut` (see the Tap Test bugfix
above), same as one that started but detected nothing. The "no NFC hardware" notices on Home/My
Phone/Tap Test stay exactly as they were: `isNfcSupported` is a real, meaningful capability check,
just not a toggle.

## Three real-device bugs: wrong device name, unreachable My Phone content, dim link color

All three were reported together after real-device testing (physical iPhone 12) and root-caused
independently — unrelated causes, coincidentally surfacing at the same time.

**Wrong device name ("iPhone 13 2" instead of "iPhone 12").** `DisplayNames.swift`'s
`friendlyModelNames` table was keyed on the catalog's *raw* comma-separated `hw.machine` format
(`"iphone15,2"`), but `TapSenseDeviceFingerprintProvider` — the real-device path, used for every
iPhone not in the bundled seed catalog (a single `apple / iphone15,2` entry at the time this bug
was found — since expanded, see `NFCLocatorCore/DECISIONS.md`) — already runs the raw sysctl string through
`DeviceFingerprint.normalize()` before it ever reaches this table, arriving as `"iphone13_2"`
(underscore, not comma). The table could therefore *only* ever match a catalog hit, never a real
device on the generic-fallback path, silently falling through to `toDisplayDeviceName()`'s
generic capitalization instead — which is what "iPhone 13 2"-style garbling actually was. Not an
iPhone-12-specific bug: every iPhone except the one seeded catalog example was affected the same
way. Fixed by normalizing the lookup key the same way before matching, re-keying every existing
table entry (Samsung/Pixel/OnePlus/etc., not just the Apple ones) to match, and substantially
expanding Apple coverage — `hw.machine` identifiers for iPhone 8 through the iPhone 16 line plus
the SE line, sourced from Apple's own (well-documented, not marketing-generation-numbered)
identifiers, since `iPhone13,2` being the iPhone 12 rather than the 13 is exactly the kind of
mismatch that caused this bug in the first place and is easy to get wrong again by guessing.
Regression tests cover both the raw comma form and the already-normalized form for iPhone 12
specifically, plus a couple of other generations, in `DisplayNamesTests.swift`.

**My Phone's content unreachable below "Test this location."** Confirmed by driving the screen
directly (multiple gesture techniques, an intentionally oversized 600pt diagnostic block to rule
out a content-height explanation, and isolating `AntennaMarker` as a possible gesture-blocking
suspect by temporarily replacing it with a plain color — none of which was it): the floating
bottom tab bar, added via `.safeAreaInset(edge: .bottom)` on the enclosing `NavigationStack` (see
`TapSenseRootView`), reserves visual space but doesn't reliably give a `ScrollView`'s own content
enough scrollable headroom to clear it once content is tall enough to need scrolling at all — My
Phone's back-content state (ending in the "Test this location" button) is the first screen tall
enough to expose it, since Home and Settings' content happens to fit without scrolling. Fixed by
adding `TapSenseBottomBar.reservedBottomClearance` (110pt — sized off the bar's actual intrinsic
height: the raised FAB item plus its own top/bottom padding, since there's no explicit
`.frame(height:)` to read) as trailing content padding on all three tab-root `ScrollView`s
(Home/My Phone/Settings) — applied to all three defensively, not just the one that already showed
the symptom, since they share the exact same at-risk layout pattern.

**Dim aqua on "Tap not working?" / "Skip" / "Use my phone automatically."** All three route
through the same `.tapSenseText` button style, which read `colors.linkForeground` —
`TapSenseColors.linkForeground` was hardcoded to `TapSensePalette.aquaLink` (`0x0E4B54`, a
near-black teal) regardless of light/dark mode. That color is the *on-primary* contrast color —
meant for dark text/icons drawn on top of an aqua-filled background (see `onPrimary`/`onTertiary`
elsewhere in the same file) — not a color meant to sit directly on the app's own background,
which is what a link's text actually does. `ActionRow` (Troubleshoot's "View my tap zone"/"Learn
NFC basics") already correctly read `colors.primary` directly and looked right, which is what
made the mismatch visible by direct comparison. Fixed by making `linkForeground` theme-aware the
same way `primary`/`tertiary` already are (`isDark ? aquaDark : aqua`), rather than a fixed color
with no light/dark branch.

## "Report inaccurate guidance" removed — a report button that reported nowhere
My Phone's Back and Front tabs both had a "Report inaccurate guidance" / "Thanks — noted for this
session" button. It called `NFCLocatorAnalytics.guidanceDismissed(confidence:timeVisibleMillis:)`
— a real, intentional library integration seam (see `NFCLocatorCore`'s own doc comment on that
protocol method) — but `TapSense`'s own implementation of that protocol,
`OSLogNfcLocatorAnalytics`, only writes to the local OS log; nothing is transmitted anywhere. The
button's copy ("Report…") told the user their feedback went somewhere it didn't, which is both a
misleading affordance and, for a sample app meant to demonstrate a "collects nothing" privacy
posture end to end, a needless thing to have to explain in an App Store privacy review. Removed:
the button in both `backContent` and `frontContent`, `MyPhoneViewModel.reportInaccurateGuidance`/
`uiState.reportSent`/the associated timer `Task`, and the two now-dead localized strings. The
library's `guidanceDismissed` API itself is untouched — it's a legitimate seam for an integrator
with a real backend to wire up, this sample app just no longer pretends to be that integrator.
Removing the button left both tabs' final action button flush against the reserved tab-bar
clearance with no breathing room of its own, so each picked up an explicit `.padding(.bottom,
24)` — the same treatment Home's "Tap not working?" link needed for the same reason (its existing
`.padding(.top, 16).padding(.vertical, 14)` gave it 30pt above but only 14pt below, consolidated
here into an explicit `.padding(.top, 30).padding(.bottom, 24)`).

## Bottom tab bar had a large dead-space band above the home indicator
Reported as "too much spacing at the lower part of the bottom navigation," on both a real device
and the Simulator. Root-caused by sampling rendered pixel rows directly rather than guessing:
`TapSenseBottomBar`'s `HStack(alignment: .top)` sizes itself to its *tallest* child, and that
child is `fabItem` — 52pt circle + spacing + label, ~71pt tall *before* its `-14`/`-10` offsets
shift it upward for the "raised" look. Offsets reposition rendering only; they don't shrink the
layout size SwiftUI computes the row's height from. So the row's true height was driven by the
FAB's *unshifted* footprint, while Home/My Phone/Settings (natural height ~44pt: 18pt icon + 4pt
spacing + `labelSmall`'s 14pt line height + the item's own 4pt padding) sat top-aligned within a
much taller row, leaving a band of plain surface-colored dead space below them — confirmed by
measuring: those three items' content ended roughly 60pt above where the row actually stopped.

Fixed by constraining the row to `TapSenseBottomBar.itemRowHeight` (44pt, matching the regular
items) via `.frame(height:alignment: .top)`. This does not clip or otherwise affect `fabItem`'s
rendering — SwiftUI doesn't clip a child's rendering to an ancestor's frame by default (the same
principle the ripple-animation fix elsewhere in this app relies on) — so the circle still floats
above the bar exactly as before; only the row's own *reported* height shrinks to match what's
actually visible in the other three items. Verified by re-measuring pixel rows after the fix (the
dead-space band roughly halved, from ~60pt to ~34pt of the remainder being the normal breathing
room most tab bars leave above the home indicator) and by confirming all four tap targets
(Home/My Phone/Settings/the FAB) still navigate correctly — `.frame(height:)` on the parent
`HStack` doesn't shrink or move each item's own `.contentShape(Rectangle())` hit-testing area,
which is sized from that item's own (unconstrained) content.

## Phone Selection: Android/Apple platform filter
Added per the "Phone selection & compatibility search" design mockup, which shows a segmented
Android/Apple control directly below the title, above the search field — present in the design
but never implemented. `PhoneSelectionPlatform` (`.android`/`.apple`) is a plain binary split on
`manufacturer.lowercased() == "apple"`, not a whitelist — every non-Apple catalog entry today
(Samsung/Google/OnePlus/Xiaomi/Motorola/Sony) is a real Android OEM, so "not Apple" is the whole
rule and needs no maintenance as more Android OEMs are added to the catalog. `PlatformFilterToggle`
mirrors My Phone's Back/Front `SideToggle` visual language (same `toggleTrackLight/Dark`/
`toggleTabSelectedDark` tokens) but full-width with two equal-width segments, matching the mockup
rather than `SideToggle`'s compact, content-sized style — this control gates the whole catalog
list, not a secondary per-screen toggle. `PhoneSelectionViewModel.applyFilters()` applies the
platform filter first and the search query on top of that result, so switching platforms
preserves and re-scopes an in-progress search rather than clearing it, and searching never
surfaces a result from the platform the user isn't browsing. Defaults to `.android`, matching the
mockup's default-selected segment.

**A real interaction bug surfaced while verifying this, worth recording**: the toggle segments'
`Button`s used `Text(...).padding(.vertical, 10)` with no explicit height — visually well under
Apple's 44pt minimum tap-target guideline, which iOS enforces by silently expanding a control's
*hit-testable* area beyond its rendered bounds, invisibly. With only 8pt of layout space between
the toggle and the search field below it, that invisible expansion was large enough to swallow
taps clearly inside the search field's own visible bounds — confirmed empirically (not guessed)
by driving the screen directly: identical tap coordinates focused the search field correctly with
the toggle absent and silently failed with it present, and a tap visually centered in the search
box's rendered area registered as a toggle selection instead. Fixed by giving each segment an
explicit `.frame(minHeight: 44)` (meeting the guideline with real, rendered space instead of
invisible overflow) plus `.contentShape(Rectangle())` (pinning the hit area to exactly that
rendered frame, no ambiguity) and increasing the toggle-to-search-field gap to 14pt. The lesson
generalizes: any control sized visually smaller than 44pt tall is a latent hit-testing hazard for
whatever sits close beneath it, regardless of how much space looks sufficient on screen.

## Platform gaps carried over from `NFCLocatorCore`
- Tap Test's live reader session only works on a physical device with a paid-team-signed build —
  `NFCTagReaderSession.readingAvailable` is always `false` in the Simulator, which is exactly
  what drove this app's own NFC-unsupported-state screenshots during development.
- A Core NFC session shows a system-drawn "Hold Near the Top of iPhone" sheet for as long as
  it's active, and times out after roughly 60 seconds with no API to extend it — see
  `TapReaderModeController`'s doc comment for how `retry()` and `restartPolling()` work within
  that constraint.
