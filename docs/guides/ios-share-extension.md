<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# iOS Share Extension — Mac-developer setup checklist (#2736)

This adds **source-tracked scaffolding** for an iOS **Share Extension** so a
user can share a receipt (photo / PDF / e-receipt text or link) from another
app (Photos, Files, Mail, Safari …) straight into Sparkilo's Add-fill-up flow
— the iOS counterpart of the Android share-intent receiver (#2735).

Everything that can ship blind ships here. The remaining steps need:

- **Xcode** (UI-driven target setup — the `project.pbxproj` schema for an
  embedded `.appex` includes a target dependency, an embed-app-extensions copy
  phase and code-sign settings that break the project file when hand-edited),
- the **Apple Developer Portal** (the App ID for the extension + the App Group
  + re-provisioning),
- a physical iPhone for verification.

Until those steps are done, **the iOS host build still compiles and runs
without the Share Extension** — the Swift source sits on disk but the Xcode
project doesn't compile it (exactly like `ios/TankstellenWidget/`). Android is
unaffected; the cross-platform Dart receiver is already live.

## How it works (architecture)

iOS extensions run in a separate process with no direct line to the Flutter
engine, so the bridge is the **App Group container** both targets can read:

```
   other app  ──share──▶  ShareExtension (ShareViewController.swift)
                              │  copies image/PDF into the App Group container
                              │  writes pending_share.json  { items:[…], country }
                              │  opens  sparkilo-share://receipt
                              ▼
   host app  ◀── URL open ── iOS
       │  AppDelegate.ShareIntentBridge.drainPendingShare()
       │  reads + deletes pending_share.json
       │  replays it down  tankstellen/share_intent/{methods,events}
       ▼
   Dart  ShareReceiptListener → ShareReceiptHandler  (unchanged, #2735)
       → stash + route to /consumption/add → OCR / text-parse → prefill form
```

The manifest shape is **identical** to what the Android `ShareIntentChannel.kt`
emits, so `SharedReceiptIntent.fromPlatform` decodes both with one code path.
There is **no iOS-specific Dart code**. The seam is locked by
`test/features/consumption/presentation/widgets/share_receipt_ios_routing_test.dart`.

## What's already in the tree (ships blind)

```
ios/
├── Runner/
│   ├── AppDelegate.swift          ← inline ShareIntentBridge + URL-open handler (NEW)
│   ├── Info.plist                 ← `sparkilo-share` CFBundleURLTypes (NEW)
│   └── Runner.entitlements        ← App Group (already present, from the widget)
└── ShareExtension/                ← NEW, NOT yet in project.pbxproj
    ├── ShareViewController.swift   ← receives the share, writes the manifest
    ├── Info.plist                  ← NSExtensionActivationRule (image/pdf/text/url)
    └── ShareExtension.entitlements ← App Group
```

The `ShareIntentBridge` lives **inline in `AppDelegate.swift`** on purpose: a
standalone Swift file under `ios/Runner/` is not in the Runner compile sources
until added in Xcode, and referencing an uncompiled class would break the
build. Inline, it compiles today with zero project-file edits, and is a no-op
when no extension is installed (the manifest never exists).

## Required Apple Developer Portal work

The **App Group already exists** if you set up the iOS widget (#widget) —
`group.de.tankstellen.tankstellen`. Reuse it; do not create a second one.

1. **App Group identifier** (skip if the widget already created it) —
   *Certificates, Identifiers & Profiles → Identifiers → App Groups → +*
   - Identifier: `group.de.tankstellen.tankstellen` ← exact value
2. **App ID — main app** — *Identifiers → `de.tankstellen.tankstellen` → Edit
   → ensure "App Groups" is enabled and the group above is selected* (already
   true if the widget is provisioned).
3. **App ID — Share Extension** — *Identifiers → +. Bundle ID:
   `de.tankstellen.tankstellen.ShareExtension`. Enable "App Groups" and select
   the same group.*
4. **Provisioning profiles** — regenerate the **main-app** and the **new
   extension** profiles AFTER the App ID exists / capability is enabled. The
   old profiles do NOT carry the new extension.
   - With **fastlane match**: `bundle exec fastlane match development --force`
     and `match appstore --force`, then copy the new profile UUIDs into Xcode's
     Signing & Capabilities pane. Add the extension bundle ID to the match
     table (see `docs/guides/ios-codesigning.md`).

> This step — registering the extension App ID + re-provisioning under the
> Apple Developer account (`fdittgen@gmx.de`) — is the **only** part that can't
> be defaulted by code, and is why #2736 stays open until a Mac developer runs
> it.

## Required Xcode work

### Step 1 — Add the Share Extension target

1. `open ios/Runner.xcworkspace`
2. *File → New → Target → iOS → Share Extension*
3. **Product Name:** `ShareExtension` (exact case — matches the
   `ios/ShareExtension/` directory the source lives in)
4. **Bundle Identifier:** `de.tankstellen.tankstellen.ShareExtension`
5. **Language:** Swift
6. **Activate scheme when prompted:** No (we run the host app)

### Step 2 — Replace Xcode's template sources with the tracked ones

Xcode generates a default `ShareViewController.swift`, `Info.plist` and a
`MainInterface.storyboard` inside `ios/ShareExtension/`. **We don't use a
storyboard** (the controller is headless — it writes the manifest and opens the
host).

1. **Delete the generated files** from disk (not just the Xcode reference),
   including `MainInterface.storyboard`.
2. Right-click the `ShareExtension` group → *Add Files to "Runner"…* → select
   the tracked `ShareViewController.swift`, `Info.plist` and
   `ShareExtension.entitlements`. **Targets:** check ONLY `ShareExtension`.
3. In the `ShareExtension` target's **Build Settings**, clear
   `INFOPLIST_KEY_NSExtensionMainStoryboard` / any `Main storyboard` reference
   so iOS instantiates `NSExtensionPrincipalClass` (our `ShareViewController`)
   instead of looking for a storyboard. Our `Info.plist` already declares
   `NSExtensionPrincipalClass = $(PRODUCT_MODULE_NAME).ShareViewController`.

### Step 3 — Wire the App Group to both targets

For **each** of `Runner` and `ShareExtension`:
1. Select the target → *Signing & Capabilities*
2. *+ Capability → App Groups* → tick `group.de.tankstellen.tankstellen`
3. Confirm Xcode points each target at the shipped `.entitlements`:
   - `Runner` → `ios/Runner/Runner.entitlements`
   - `ShareExtension` → `ios/ShareExtension/ShareExtension.entitlements`

### Step 4 — Pin the extension version to the host

In the `ShareExtension` target's build settings:
- `MARKETING_VERSION` → `$(inherited)`
- `CURRENT_PROJECT_VERSION` → `$(inherited)`

The `Info.plist` already references these so the extension version tracks the
host (avoids TestFlight version-mismatch warnings).

### Step 5 — Build + upload

The extension is embedded inside the host app's IPA automatically once the
target exists; the TestFlight / App Store upload step (`fastlane`,
`ios-testflight.yml`) needs no change beyond fetching the new provisioning
profile (Step 1.4).

## Localized display name (HARD RULE #1)

The share-sheet entry shows the extension's `CFBundleDisplayName`. The Dart ARB
layer cannot reach a native extension's Info.plist, so per-locale names are
supplied via the **native iOS mechanism**: add an `InfoPlist.strings` file per
locale under the extension target —
`ios/ShareExtension/<lang>.lproj/InfoPlist.strings` — each containing:

```
"CFBundleDisplayName" = "Sparkilo";
```

The base value is the **brand name** (`Sparkilo`), a proper noun that is the
same in every locale, so no translation is required today. If a descriptive
name is ever wanted (e.g. "Add fuel receipt"), localize it through these
`InfoPlist.strings` files — never inline a translatable literal in Swift.

## Manual verification (real iPhone)

1. Build + install the host app on a physical iPhone (the extension is bundled
   in). Enable the feature: *Settings → Features → "Import shared receipts"*
   (`Feature.addFillUpShareIntentReceipt`, opt-in).
2. Open **Photos**, pick a fuel-receipt photo → Share sheet → **Sparkilo**.
3. Sparkilo foregrounds and lands on the Add-fill-up form with the receipt
   OCR'd and the fields prefilled (litres / price-per-L / total / date).
4. Repeat from **Files** with a PDF e-receipt (rasterised on-device → same
   OCR path) and from **Mail / Safari** with a text/link e-receipt (parsed by
   the pure-Dart text parser).
5. Try while the app is already open (warm) and from cold (killed) — both
   funnel through `ShareReceiptListener`.

## Known gaps / future work

- **No share-sheet preview UI** — the extension completes immediately and hands
  off to the host; it does not show a confirm screen. If a preview is wanted
  later, add a SwiftUI view to `ShareViewController` before `openHost()`.
- **Single artifact per share** — `NSExtensionActivationRule` caps each type at
  1; the handler already picks the first image from a batch, matching Android.
