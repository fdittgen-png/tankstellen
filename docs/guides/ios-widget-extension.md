<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# iOS Widget Extension — Mac-developer setup checklist

This PR adds **source-tracked scaffolding** for an iOS WidgetKit
extension that mirrors the Android home-screen widget. Everything that
can ship blind ships in this PR. The remaining steps require:

- Xcode (UI-driven target setup),
- the Apple Developer Portal (App Group + provisioning),
- a physical iPhone for verification.

Until those steps are completed by a Mac-equipped developer, the iOS
build still compiles and runs without the widget — the Swift sources
sit on disk but the Xcode project doesn't compile them. Android is
unaffected.

## What's already in the tree

```
ios/
├── Runner/
│   └── Runner.entitlements                 ← App Group entitlement (NEW)
└── TankstellenWidget/
    ├── TankstellenWidget.swift             ← @main WidgetBundle
    ├── NearestStationsProvider.swift       ← TimelineProvider
    ├── NearestStationsEntry.swift          ← TimelineEntry
    ├── NearestStationsWidgetView.swift     ← SwiftUI layout
    ├── StationRow.swift                    ← Decodable mirror of Dart row
    ├── Info.plist                          ← Extension Info.plist
    ├── TankstellenWidget.entitlements      ← App Group entitlement (widget)
    └── Assets.xcassets/
        ├── AccentColor.colorset/
        └── WidgetBackground.colorset/
```

Dart side:
- `lib/features/widget/data/home_widget_service.dart` branches the
  App Group ID by platform — Android keeps
  `de.tankstellen.fuelprices.widget`, iOS uses
  `group.de.tankstellen.tankstellen`.

## Required Apple Developer Portal work

1. **App Group identifier** —
   *Certificates, Identifiers & Profiles → Identifiers → App Groups → +*
   - Description: `Tankstellen Widget Shared Storage`
   - Identifier: `group.de.tankstellen.tankstellen` ← exact value, no typos
2. **App ID — main app** —
   *Identifiers → de.tankstellen.tankstellen → Edit → enable "App Groups"
   capability → select the group above*
3. **App ID — widget extension** —
   *Identifiers → +. Bundle ID:
   `de.tankstellen.tankstellen.TankstellenWidget`. Enable "App Groups"
   and select the same group.*
4. **Provisioning profiles** — regenerate both the main-app and the
   widget-extension profiles AFTER enabling App Groups. The old
   profiles do NOT carry the capability.
   - If you use **fastlane match**, run
     `bundle exec fastlane match development --force` and
     `match appstore --force` and copy the new profile UUIDs into
     Xcode's "Signing & Capabilities" pane.

## Required Xcode work — DONE (#3166)

> **Status:** the target wiring below shipped with #3166 —
> `scripts/add_ios_widget_target.rb` (xcodeproj gem, idempotent)
> performs Steps 1–4 reproducibly and has been applied to
> `ios/Runner.xcodeproj`. The TankstellenWidget extension target now
> builds and embeds in every `flutter build ios`. The steps are kept
> below for reference / re-creation from scratch. What remains manual
> is ONLY the Apple Developer Portal work above (App Group + widget
> App ID + `match --force` re-provisioning) — until that is done, the
> nightly TestFlight archive will fail signing, because both targets
> now reference App Group entitlements and the widget's Release config
> expects a `match AppStore de.tankstellen.tankstellen.TankstellenWidget`
> profile. Add the widget bundle ID to `ios/fastlane/Matchfile`'s
> `app_identifier` list and to `build_appstore`'s
> `provisioningProfiles` map in `ios/fastlane/Fastfile` at the same
> time (Step 5).

### Step 1 — Add the Widget Extension target

1. `open ios/Runner.xcworkspace`
2. *File → New → Target → iOS → Widget Extension*
3. **Product Name:** `TankstellenWidget` (exact case — matches the
   `ios/TankstellenWidget/` directory the Swift sources live in)
4. **Bundle Identifier:** `de.tankstellen.tankstellen.TankstellenWidget`
5. **Language:** Swift
6. **Include Configuration Intent:** **NO** (the widget is static; we
   do not need an Intent / Configuration UI right now)
7. **Activate scheme when prompted:** No (we run the host app, not
   the widget directly)

### Step 2 — Replace Xcode's template sources with the tracked ones

Xcode generates default template files inside `ios/TankstellenWidget/`
when you add the target. **Delete the generated files** (from the
file system, not just the Xcode reference) and let Xcode pick up the
files this PR shipped:

- `TankstellenWidget.swift` ← keep ours
- `Info.plist` ← keep ours (mirrors the host app version vars)
- `TankstellenWidget.entitlements` ← keep ours
- Provider / Entry / View / StationRow ← keep ours

To re-add the tracked files to the Xcode target:
1. Right-click the `TankstellenWidget` group in the project navigator
2. *Add Files to "Runner"…* → select all four Swift files + the
   `Assets.xcassets` folder + `Info.plist` + the `.entitlements` file
3. **Targets:** check ONLY `TankstellenWidget` (uncheck `Runner`).

### Step 3 — Wire the App Group to both targets

For **each** of `Runner` and `TankstellenWidget`:
1. Select the target → *Signing & Capabilities* tab
2. *+ Capability → App Groups*
3. Tick `group.de.tankstellen.tankstellen` in the list
4. If Xcode complains "no provisioning profile found": pick the
   regenerated profile from Step 1.4 above

Xcode will automatically point each target at the matching
`.entitlements` file we shipped. Verify the path:
- `Runner` → `ios/Runner/Runner.entitlements`
- `TankstellenWidget` → `ios/TankstellenWidget/TankstellenWidget.entitlements`

### Step 4 — Pin the widget version to the host

In the `TankstellenWidget` target's build settings, set:
- `MARKETING_VERSION` → `$(inherited)` (defaults to host)
- `CURRENT_PROJECT_VERSION` → `$(inherited)` (defaults to host)

The `Info.plist` template already references these variables, so the
widget version always tracks the host app.

### Step 5 — Add to fastlane / CI build

If you use `fastlane match` and the GitHub Actions iOS workflow, add
the widget bundle ID to the match table and to the workflow's profile
fetch step. The TestFlight upload step does NOT need changes — the
widget extension is bundled inside the host app's IPA automatically
once the target is added.

## Manual verification (real iPhone)

1. Build + install the host app on a physical iPhone.
2. Open the app, complete onboarding, and let it load a couple of
   nearby stations. This writes `nearest_json` to the App Group.
3. Long-press the iPhone home screen → + → search "Sparkilo" or
   "Tankstellen" → add the medium / large widget to the home screen.
4. The widget should render 3 (medium) or 5 (large) rows of nearby
   stations with prices + distances.
5. Tap a row → the host app cold-starts (or warm-starts) and lands
   directly on `/station/<id>` — same flow as Android, driven by the
   `tankstellenwidget://station?id=<id>` URI.

## Known gaps / future work

- **Cheapest widget variant** — only `NearestStationsWidget` ships
  here. The Android `StationWidgetRenderer` also supports a Favorites
  / Cheapest mode; the SwiftUI equivalent can be added alongside
  `NearestStationsWidget` in `TankstellenWidgetBundle` once a
  matching `FavoritesProvider` lands.
- **Predictive widget content** — the `predictive_*` fields the Dart
  side optionally emits (#1121) are not yet rendered. Add a
  `PredictiveBadge` view in `NearestStationsWidgetView.swift` once
  the iOS widget ships.
- **Configuration UI** — the widget is `StaticConfiguration` today;
  if you want per-widget vehicle / fuel selection like the Android
  `WidgetConfigureActivity`, the Swift side needs an `AppIntent` or
  `IntentConfiguration` (iOS 17+) or `IntentTimelineProvider` (iOS
  14+).
