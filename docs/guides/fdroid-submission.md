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

The GMS-free `fdroid` flavor (#2574) is what both paths build: it excludes
`com.google.android.gms` and `com.google.mlkit` from the runtime classpath,
maps are OpenStreetMap, and positioning is forced through Android's
`LocationManager` via `--dart-define=FORCE_LOCATION_MANAGER=true`.

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

- **OCR is unavailable in the fdroid flavor.** The pump-display / receipt OCR
  depends on Google ML Kit (`google_mlkit_text_recognition`), which pulls
  `com.google.mlkit` → `com.google.android.gms`. It is excluded from the fdroid
  flavor, so the OCR plugin channel is absent and the in-app scan path degrades
  gracefully (`ReceiptScanService._recogniseRaw` catches the
  `MissingPluginException` and returns null — no crash, the feature is just
  inert). Manual fill-up entry is unaffected. Note this in the MR description so
  reviewers understand the capability gap is intentional.
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
# dependency-graph layer (authoritative)
./gradlew -p android app:dependencies \
  --configuration fdroidReleaseRuntimeClasspath \
  | grep -E 'com\.google\.android\.gms|com\.google\.mlkit'   # must print nothing

# both layers, against a built APK
flutter build apk --release --flavor fdroid --dart-define=FORCE_LOCATION_MANAGER=true
bash scripts/audit_no_gms.sh build/app/outputs/flutter-apk/app-fdroid-release.apk
```

The same audit runs advisory in CI on every PR (`.github/workflows/fdroid.yml`).
