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

The GMS-free `fdroid` flavor (#2574, epic #3473) is what both paths build: it
ships **zero references** to `com.google.android.gms`, `com.google.mlkit`,
`com.google.android.play` or `io.sentry` in the dex, maps are OpenStreetMap,
and positioning is forced through Android's `LocationManager` via
`--dart-define=FORCE_LOCATION_MANAGER=true`.

### How GMS/ML Kit/Play Core/Sentry stay out of the fdroid dex (epic #3473)

> Historical note: the earlier #2584 approach (runtime exclude + compile-only
> stub in android/build.gradle.kts) removed the class *definitions* but left
> inert dangling *references* in the constant pool, which F-Droid's
> `check apk` scanner rejects. Epic #3473 replaced it; the sections below
> describe the current mechanism.

The proprietary code is pulled in by Flutter **plugin** packages, so the libre
build swaps the plugins themselves, at the *Dart package graph* level:

1. **Per-flavor Dart-only stub packages** live under `tool/fdroid_stubs/`
   (`google_mlkit_text_recognition`, `google_mlkit_commons`, `mobile_scanner`,
   `sentry_flutter`, …). Each mirrors the real package's Dart API but contains
   **no Android module at all**, so nothing reaches the Gradle build.
2. **`pubspec_overrides.fdroid.yaml`** maps those package names onto the stubs.
   The F-Droid recipe's `prebuild` copies it to `pubspec_overrides.yaml`
   **before `flutter pub get`** (`tool/apply_fdroid_overrides.dart` does the
   same for local builds), so the resolved graph — and therefore the dex — is
   structurally free of the proprietary code. Play + iOS never apply the
   overrides and keep the real plugins byte-identically.
3. **Behaviour switches** gate the affected features at runtime:
   `QrScannerScreen` uses the FOSS `flutter_zxing` camera path on libre
   (QR scanning still works), `createDefaultOcrTextEngine()` returns a no-op
   engine (receipt/pump OCR unavailable by the maintainer's explicit choice),
   and `SentryFlutter.init` is gated on `!AppFlavor.isLibre`.
4. **R8 keep-rule tuning** (`allowshrinking,allowobfuscation` on the broad
   Flutter keep in `android/app/proguard-rules.pro`) lets the dead
   `PlayStoreDeferredComponentManager` tree-shake out of the release dex.

Net: a release fdroid dex audit shows `gms:0 mlkit:0 play:0 sentry:0`
references (not just definitions). Only the FOSS, Apache-2.0
`com.google.crypto.tink` remains, which F-Droid allows. The `play` flavor is
untouched: real GMS, full functionality (fused location + ML Kit OCR).

## Submitting the official fdroiddata recipe

### Maintainer account binding

An fdroiddata recipe has **no** maintainer, submitter, or GitLab-id field — the
[Build Metadata Reference](https://f-droid.org/docs/Build_Metadata_Reference/)
defines none. The only identity fields a recipe carries are `AuthorName`,
`AuthorEmail` and `AuthorWebSite`. Your status as submitter / maintainer-of-record
is therefore **implicit**: it is whichever GitLab account forks
`fdroid/fdroiddata`, authors the git commits, and opens the merge request.

Bind it by being signed in as the maintainer account through the whole
fork → push → MR flow:

- **GitLab account:** user id `38723484`, display name "Florian FloDitt"
- **Fork URL:** `https://gitlab.com/<your-gitlab-username>/fdroiddata`
  (the numeric id does **not** resolve — the fork path needs your @username;
  fill it in here once confirmed)
- **Contact:** fdittgen@gmail.com (also set in the recipe as `AuthorEmail`)
- **Local git author:** run `git config user.email fdittgen@gmail.com` on the
  fdroiddata-fork clone so the commit author matches the account opening the MR.

The recipe's `AuthorName: Florian DITTGEN` is the **public author credit** (free
text) and is deliberately the real-name form — consistent with the project's
copyright headers, git author, GitHub (`fdittgen-png`) and Apple Developer
identity — not the GitLab display name. The numeric GitLab id never appears in
the `.yml`; encoding it there would fail `fdroid lint`.

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
   This checks out the tag pinned in the recipe's `commit:` (currently
   `v6.0.2`), runs the `prebuild` (**copy the fdroid pubspec overrides**, then
   flutter pub get + `build_runner build`) and the `build` (`flutter build apk
   --release --flavor fdroid --dart-define=FORCE_LOCATION_MANAGER=true
   --dart-define=FGS_FORM_APPROVED=true`), and produces
   `app-fdroid-release.apk`. The pinned tag must contain the epic #3473
   catalog-clean work — earlier tags fail F-Droid's `check apk` scanner on
   dangling GMS references.
5. **Set the NDK**: the recipe leaves `ndk:` commented. After the first clean
   `fdroid build` succeeds, read the exact NDK the buildserver used from the log
   and pin it in the `Builds:` block, then re-run the build.
6. **Open a merge request** against fdroiddata. Maintainers review it; expect
   **days to weeks** before it lands and the first reproducible build is
   published.

## Release-notes discipline for split-per-ABI builds

F-Droid keys fastlane changelogs by **versionCode**, and the split builds
carry `base*10 + {1,2,3}` (armeabi-v7a / arm64-v8a / x86_64 — the
fdroid-flavor gradle override, #3518). Every release must therefore ship
FOUR changelog files per locale: `<base>.txt` (Play/self-hosted) plus the
three derived copies — otherwise the catalog listing loses its What's New
(#3516).

## Caveats to disclose in the MR

- **Text OCR is unavailable in the fdroid flavor by design; QR scanning works.**
  The pump-display / receipt OCR depends on Google ML Kit
  (`google_mlkit_text_recognition`), which the libre build replaces with a
  no-op engine (#3490) — the in-app scan path degrades gracefully and manual
  fill-up entry is unaffected. Barcode/QR scanning was migrated to the FOSS
  `flutter_zxing` on libre (#3477), so device pairing and payment QR codes
  still scan. Note the OCR gap in the MR description so reviewers understand
  it is intentional.
- **Sentry is compiled out of the fdroid flavor entirely** (#3492): the libre
  build resolves a Dart-only `sentry_flutter` stub and never calls
  `SentryFlutter.init`, so the dex carries zero `io.sentry` references and no
  `AntiFeatures: [Tracking]` flag is needed.
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

# both layers, against a built APK. With the epic #3473 pubspec-override
# mechanism, the RELEASE fdroid dex must carry ZERO references (not just
# definitions) — the same bar as F-Droid's `check apk` scanner:
dart run tool/apply_fdroid_overrides.dart  # copies the overrides AND pubspec.fdroid.lock (#3507)
flutter build apk --release --flavor fdroid \
  --dart-define=FORCE_LOCATION_MANAGER=true --dart-define=FGS_FORM_APPROVED=true
bash scripts/audit_no_gms.sh build/app/outputs/flutter-apk/app-fdroid-release.apk
unzip -p build/app/outputs/flutter-apk/app-fdroid-release.apk 'classes*.dex' \
  | strings | grep -cE 'com/google/android/gms|com/google/mlkit|com/google/android/play|Lio/sentry/'  # must be 0

# contrast — the play flavor SHOULD still carry GMS (the exclude is flavor-scoped):
( cd android && ./gradlew app:dependencies \
  --configuration playDebugRuntimeClasspath ) | grep -E 'gms|mlkit'   # non-empty
```

The same audit runs advisory in CI on every PR (`.github/workflows/fdroid.yml`).
It builds a DEBUG fdroid APK (no keystore needed); the debug dex keeps the inert
dangling references (R8 is off), so the audit's pass criterion is "no proprietary
class definition", not "no reference" — see scripts/audit_no_gms.sh layer B.
