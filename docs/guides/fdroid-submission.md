<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# F-Droid submission guide

How to publish Sparkilo on F-Droid. There are **two** independent paths; this
guide covers both, but they are not the same thing:

1. **Self-hosted repo** (under `fdroid/`, ships a prebuilt signed APK from
   GitHub Pages) — the fast path the maintainer controls end-to-end. Built by
   `scripts/fdroid_publish.sh` / `.github/workflows/fdroid-publish.yml`. No
   external review; available the moment you deploy.
2. **Official fdroiddata** (the recipe at the repo root
   `metadata/de.tankstellen.fuelprices.yml`) — F-Droid's own buildserver checks
   out the tagged source and **builds it reproducibly**. This reaches the
   default F-Droid catalogue but is gated on **external review that takes days
   to weeks**.

The GMS-free `fdroid` flavor (#2574, #2584) is what both paths build: it ships
**no proprietary `com.google.android.gms` / `com.google.mlkit` code** in the dex,
maps are OpenStreetMap, and positioning is forced through Android's
`LocationManager` via `--dart-define=FORCE_LOCATION_MANAGER=true`.

### How GMS/ML Kit stay out of the fdroid dex (#2584)

The `:app` module's `exclude(group = …)` (android/app/build.gradle.kts) cleans the
**app's** dependency graph, but GMS/ML Kit are pulled in by the Flutter **plugin**
sub-projects (`geolocator_android`, `google_mlkit_commons`,
`google_mlkit_text_recognition`, `mobile_scanner`), which are un-flavored Android
library modules whose single AAR AGP merges into both flavors. Those plugins
`import com.google.android.gms.*` unconditionally, so a blanket exclude breaks
compilation. The fix (android/build.gradle.kts, gated on the fdroid task graph):

1. **Runtime exclude** — drop the real GMS/ML Kit coordinates from each plugin's
   fdroid runtime classpath, so the proprietary classes never reach the dex.
2. **Compile-only stub** — put the GMS/ML Kit *compile* API back on each plugin's
   compile classpath as `compileOnly`, so the plugin Java still compiles against
   the real signatures. `compileOnly` is never packaged, so it adds nothing to the
   dex.

Net: **zero `com.google.android.gms` / `com.google.mlkit` class definitions** in the
fdroid dex. The plugins' own compiled methods still *name* those (now absent) types
in their signatures, leaving inert dangling type *references* in the constant pool —
they reference classes that do not exist and the code that would touch them never
runs (see the OCR caveat below + `forceLocationManager`). The `play` flavor is
untouched: real GMS, full functionality (fused location + ML Kit OCR/barcode).

## Submitting the official fdroiddata recipe

Prerequisites: `fdroidserver` (`brew install fdroidserver`) and a GitLab
account.

1. **Fork** `https://gitlab.com/fdroid/fdroiddata` and clone your fork.
2. **Copy the recipe** in: copy this repo's root
   `metadata/de.tankstellen.fuelprices.yml` to
   `metadata/de.tankstellen.fuelprices.yml` in your fdroiddata fork.
3. **Lint** it:
   ```
   fdroid lint de.tankstellen.fuelprices
   fdroid rewritemeta de.tankstellen.fuelprices   # normalises formatting
   ```
4. **Test the build** in fdroidserver's reproducible build environment:
   ```
   fdroid build -v -l de.tankstellen.fuelprices
   ```
   This checks out the `v5.0.0` tag, runs the `prebuild` (flutter pub get +
   `build_runner build`) and the `build` (`flutter build apk --release --flavor
   fdroid --dart-define=FORCE_LOCATION_MANAGER=true`), and produces
   `app-fdroid-release.apk`.
5. **Set the NDK**: the recipe leaves `ndk:` commented. After the first clean
   `fdroid build` succeeds, read the exact NDK the buildserver used from the log
   and pin it in the `Builds:` block, then re-run the build.
6. **Open a merge request** against fdroiddata. Maintainers review it; expect
   **days to weeks** before it lands and the first reproducible build is
   published.

## Caveats to disclose in the MR

- **OCR (and barcode scanning) is unavailable in the fdroid flavor by design.**
  The pump-display / receipt OCR depends on Google ML Kit
  (`google_mlkit_text_recognition`), and the barcode path on `mobile_scanner` —
  both pull `com.google.mlkit` → `com.google.android.gms`. The fdroid flavor keeps
  ML Kit on the compile classpath only (compile-only stub, #2584) with the real
  classes absent at runtime, so any OCR call throws and the in-app scan path
  degrades gracefully (`ReceiptScanService._recogniseRaw` catches it and returns
  null — no crash, the feature is just inert). Manual fill-up entry is unaffected.
  Note this in the MR description so reviewers understand the capability gap is
  intentional.
- **Sentry.** The app integrates Sentry for *opt-in* crash/diagnostic reporting
  (off by default). F-Droid reviewers may require either the
  `AntiFeatures: [Tracking]` flag on the recipe, **or** compiling Sentry out of
  the fdroid flavor entirely (a build-flavor guard / no-op stub). Decide with
  the reviewer; the cleanest libre outcome is to exclude Sentry from the fdroid
  flavor so no `AntiFeatures` flag is needed.
- **Maps & location.** Already libre: OpenStreetMap tiles + `flutter_map`, and
  `LocationManager` positioning (no `google_maps_flutter`, no Play-Services
  Location). No disclosure needed.

## Verifying GMS-free locally

Before either submission, prove the flavor is clean:

```
# layer A — dependency-graph (authoritative): must print nothing
( cd android && ./gradlew app:dependencies \
  --configuration fdroidReleaseRuntimeClasspath ) \
  | grep -E 'com\.google\.android\.gms|com\.google\.mlkit'

# both layers, against a built APK. Layer B asserts no GMS/ML Kit class
# DEFINITIONS in the dex (no proprietary Google code shipped); inert dangling
# references to absent classes are reported but are not a failure (#2584).
flutter build apk --release --flavor fdroid --dart-define=FORCE_LOCATION_MANAGER=true
bash scripts/audit_no_gms.sh build/app/outputs/flutter-apk/app-fdroid-release.apk

# contrast — the play flavor SHOULD still carry GMS (the exclude is flavor-scoped):
( cd android && ./gradlew app:dependencies \
  --configuration playDebugRuntimeClasspath ) | grep -E 'gms|mlkit'   # non-empty
```

The same audit runs advisory in CI on every PR (`.github/workflows/fdroid.yml`).
It builds a DEBUG fdroid APK (no keystore needed); the debug dex keeps the inert
dangling references (R8 is off), so the audit's pass criterion is "no proprietary
class definition", not "no reference" — see scripts/audit_no_gms.sh layer B.
