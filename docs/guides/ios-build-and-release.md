<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# iOS build & release

> This file used to be `BLOCKER-IOS-PROVISIONING.md`, recording iOS as
> blocked on Apple Developer provisioning. That blocker is **resolved**
> — iOS builds, signs and ships. Rewritten for #1827.

## Current state

iOS is a fully supported target:

- `ios/Podfile.lock` is committed; `pod install` resolves cleanly.
- `flutter build ios` produces a signed IPA; TestFlight uploads
  succeed (Apple Developer enrollment, the `de.tankstellen.tankstellen`
  bundle identifier, and signing certificates are all in place).
- `ios/Runner` carries the full Info.plist (location + BLE usage
  descriptions, `UIBackgroundModes`, `BGTaskSchedulerPermittedIdentifiers`),
  `AppDelegate.swift` + `SceneDelegate.swift`, and the scene manifest.

## CI

There is **no per-PR iOS build** — a `macos-latest` job is slow and the
Dart/Flutter analyzer + test suite already gate every PR.

`build-ios` runs in the **Daily GitHub Release** workflow
(`.github/workflows/daily-github-release.yml`) — scheduled nightly and
also `workflow_dispatch`-triggerable. It builds the signed IPA + dSYMs
and attaches them to the nightly pre-release. A red `build-ios` there
is the signal that an iOS-only regression (e.g. a stale `Podfile.lock`)
has landed on `master`.

## Releasing to TestFlight / the App Store

Use `fastlane` from a Mac (the local dev machine runs the full
fastlane stack). See the `flutter-ios-deployment` skill for the
match / App Store Connect API key / track-promotion workflow.
