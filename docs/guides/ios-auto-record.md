# iOS hands-free trip auto-record (port from #1004)

Status: phase 2 — Dart-side scaffolding shipped. Native iOS layer
NOT YET applied or verified — see "How to verify on a Mac" below.

This document explains the iOS port of the hands-free trip
auto-record flow tracked in #1295 (sibling of the Android flow in
#1004), and the platform-side changes a Mac-equipped developer must
apply before the iOS path can be exercised end-to-end.

## Why this scaffolding ships before iOS verification

The autonomous worker that produced this PR has no Mac. The Dart
layer is **platform-safe** — every public method on
`IosStateRestorationService` is a no-op on Android (and on the
Linux / Windows headless runners that drive CI). Wiring Phase 2's
classes does not break the Android build, does not change Android
behaviour, and lands no untestable iOS code into the tree.

The actual iOS verification — the Phase 1 spike per #1295 that
proves `centralManager:willRestoreState:` fires after a real
background relaunch — requires a Mac, an iPhone, and an ELM327 BLE
adapter. That work is a human-driven phase, not autonomous-worker
territory.

## Info.plist changes the developer must apply on a Mac

The values below are quoted **verbatim** from the issue body of
#1295:

> **Info.plist.** Declare `UIBackgroundModes = ["bluetooth-central",
> "location"]`. Add `NSBluetoothAlwaysUsageDescription`,
> `NSLocationAlwaysAndWhenInUseUsageDescription`,
> `NSLocationWhenInUseUsageDescription`. The two BG modes are the
> App-Store-reviewable claims that gate everything.

Open `ios/Runner/Info.plist` in Xcode (or any plist editor; do NOT
edit it from Windows since the worker tooling does not preserve
plist whitespace) and add the following keys. They are reproduced
in copy-pasteable XML form below — the exact values matter for
App Store review.

### `UIBackgroundModes`

Two background-mode entitlements: `bluetooth-central` lets iOS
relaunch us into the background when a BLE peripheral we registered
for state restoration becomes available; `location` lets the GPS
fallback for the speed source keep firing while the app is in the
background.

```xml
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
    <string>location</string>
</array>
```

Without `bluetooth-central` the entire state-restoration flow is
dead — iOS will not relaunch the app on a Bluetooth event. Without
`location` the GPS fallback (used when PID 0x0D stalls) cannot
update in the background; the user sees a frozen speed reading
between BLE drop and the 60 s save debounce.

### `NSBluetoothAlwaysUsageDescription`

Mandatory iOS 13+ usage string for any app that touches
Core Bluetooth. Presented to the user in the system permission
sheet. Must be a sentence the user understands — Apple rejects
boilerplate like "for Bluetooth".

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Tankstellen connects to your paired OBD2 adapter so it can record your trips automatically when you start driving, even when the app is closed.</string>
```

### `NSLocationAlwaysAndWhenInUseUsageDescription`

Required when requesting "Always Allow" location authorization.
iOS shows this string in the second-stage prompt (the one with the
map of recent locations). The user must explicitly upgrade from
"While Using" to "Always" — many decline; the PID-0x0D speed
source mostly avoids this prompt, but the GPS fallback needs it.

```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Tankstellen uses your location in the background only as a fallback for measuring trip speed when the OBD2 adapter cannot provide it. Trips are saved on your device.</string>
```

### `NSLocationWhenInUseUsageDescription`

Required for the first-stage "While Using" location prompt. iOS
will not show the Always prompt unless the app is already authorized
for While Using.

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Tankstellen uses your location to measure trip distance when the OBD2 adapter cannot provide it.</string>
```

## How to verify on a Mac

This is the Phase 1 spike per #1295 — confirm `flutter_blue_plus`
state restoration actually fires `willRestoreState` on a real
ELM327 BLE adapter. Acceptance criteria: the app, started cold via
a BLE event from the OS, runs Dart code without the user ever
opening it.

1. **Apply the Info.plist keys above.** Open `ios/Runner/Info.plist`
   in Xcode and paste each `<key>` / value pair into the top-level
   `<dict>`. Build settings: confirm "Background Modes" capability
   is ticked in the Signing & Capabilities tab, with both
   "Uses Bluetooth LE accessories" and "Location updates" checked.
2. **Refresh CocoaPods.** From the repo root on a Mac:
   ```bash
   flutter pub get
   cd ios && pod install
   cd ..
   ```
   `pod install` regenerates `Podfile.lock` for the
   `flutter_blue_plus_darwin` 7.x pod. Commit the updated
   `Podfile.lock`.
3. **Build for a real iPhone.** State restoration does NOT work on
   the simulator (Apple TN3115). Connect an iPhone via USB:
   ```bash
   flutter build ios --release --no-codesign
   open ios/Runner.xcworkspace
   ```
   Select the connected device, sign with your provisioning
   profile, and Run.
4. **Pair the ELM327 once in foreground.** Walk through the
   existing OBD2 adapter scan + pick flow with the engine running.
   The `IosStateRestorationService.registerPersistedAdapter(uuid)`
   call (Phase 3) will issue the long-lived connect that the OS
   retains across termination.
5. **Background the app.** Press the home button — do NOT swipe
   it out of the app switcher. Force-quit permanently disables
   state restoration until next manual launch (Apple-documented).
6. **Power-cycle the ELM327.** Disconnect the OBD2 dongle from
   the OBD-II port and re-insert it. iOS sees the advertisement,
   completes the pending connect, and relaunches the app in the
   background.
7. **Observe `os_log` in Console.app.** Filter to subsystem
   `com.tankstellen.app` (or "tankstellen" plain text). You must
   see:
   * `IosStateRestorationService: setOptions(restoreState: true) ok`
     — proves Phase 2 wiring ran on cold start.
   * `centralManager:willRestoreState:` fired on the native side —
     proves iOS handed restored peripherals back to the plugin.
   * `IosStateRestorationService: registerPersistedAdapter queued
     connect for <uuid>` — proves Phase 2's connect kept the
     pending peripheral pinned across launches.
8. **Capture findings as a follow-up issue.** Even a successful
   spike usually surfaces compromises (e.g. "PID 0x0D stalls for
   3 s after restore" or "Always Location prompt blocks the
   notification banner"). Open a new issue tagged `area/ios` with
   the observed sequence.

## Compromises vs Android

Reproduced **verbatim** from the issue body of #1295 (attribution:
`fdittgen-png` on the original spec):

> - **First open after install is mandatory.** State restoration
>   cannot register until the user has launched the app at least
>   once.
> - **First open after every reboot or BT toggle is mandatory.**
>   Apple-documented; no workaround.
> - **Force-quit kills the flow until next manual launch.** Train
>   the user via onboarding ("don't swipe Tankstellen out of the
>   app switcher"). No technical fix.
> - **Classic-Bluetooth ELM327 dongles will not work at all.** Only
>   BLE adapters or MFi-certified Classic adapters (vLinker FS,
>   OBDLink MX+). Document this clearly on the iOS install page.
> - **10-second background budget per wake.** All trip-start/save
>   logic must be sync-light; defer heavy computation to next
>   foreground. Driving Insights re-computation needs to be lazy.
> - **Badge requires a notification.** Cannot silently bump on save
>   — the user will see a "Trip recorded" banner. Could be a
>   feature, not a bug; add a setting to mute the banner (but the
>   badge will still increment because the notification still
>   delivers).
> - **Trip may be missed** if iOS terminates the app for memory
>   pressure between BLE drop and the 60 s debounce timer.
> - **Location-Always prompt is rough.** iOS shows it as a separate
>   dialog after a "While Using" grace period, with a map of recent
>   locations — many users decline. The PID-0x0D speed path mostly
>   avoids this, but the GPS fallback will not work for users who
>   said no.

## Known limitations

Reproduced from the issue body, "Compromises vs Android" section
(also above) — these are the architectural limits the iOS port
cannot work around:

* No equivalent of the Android foreground service. iOS owns
  scheduling; the app is woken only via OS-driven events.
* `connectPeripheral` with no timeout works ONLY if registered via
  restored state (TN3115).
* Background launch does NOT survive reboot. Until the user opens
  the app once after reboot or BT toggle, no relaunch happens.
* Force-quit (swipe up from app switcher) permanently disables
  state restoration until next manual launch (Apple-documented).
* Background CPU budget after wake: ~10 s per wake event before
  throttle / kill.
* Launcher badge: only via `UNNotificationContent.badge` on a
  delivered notification, or from foreground via
  `UNUserNotificationCenter.setBadgeCount()` (iOS 17+). No
  silent-bump from background.

## Cross-references

* **Tracking issue:** [#1295](https://github.com/fdittgen-png/tankstellen/issues/1295)
  — iOS hands-free auto-record port (this guide is the Phase 2
  deliverable).
* **iOS platform support epic:** [#9](https://github.com/fdittgen-png/tankstellen/issues/9)
  — overall iOS port. #1295 depends on #9 for general iOS
  Bluetooth scaffolding.
* **Android sibling:** [#1004](https://github.com/fdittgen-png/tankstellen/issues/1004)
  / `docs/guides/auto-record.md` — the Android foreground-service
  implementation this port mirrors as closely as iOS will allow.

## Phase plan (from the issue body)

Phase 2 (this PR) ships the Dart-side scaffolding only. The
remaining phases:

* **Phase 1 — Investigation + plugin spike** (~2 days, **needs
  Mac**): verify `flutter_blue_plus` `restoreState` actually
  triggers `willRestoreState` on a real ELM327 BLE. Confirm Dart
  isolate spins up on background relaunch (build a tiny
  logging-only test app, observe in `Console.app`). Decision gate:
  does FBP suffice, or do we need a native iOS channel?
* **Phase 3 — BLE listener + speed source + trip lifecycle.**
  Port the 3-sample/5-km/h start trigger and 60 s debounce save.
  PID-0x0D primary, GPS fallback gated on Always permission.
* **Phase 4 — Badge via notifications.** Replace Android's
  `flutter_app_badger` path on iOS with a local
  `UNNotificationContent.badge`-driven flow. Add ARB keys for the
  auto-save notification banner. Localize across 23 locales.
* **Phase 5 — Device-test acceptance.** Real iPhone + real ELM327
  BLE. Acceptance script: install, pair once, force-close Xcode,
  drive (or use a 12 V supply + speed simulator), verify wake,
  trip, badge. Write findings as a follow-up issue if any
  compromise needs softening.

None of phases 3-5 are autonomous-worker targets either — each
needs a Mac for at least the verification step.
