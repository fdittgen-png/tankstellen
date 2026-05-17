# Blocker — iOS platform support (#9)

## Status on master

The iOS target has most of the code-side scaffolding in place but is
blocked on external provisioning (Apple Developer enrollment, code
signing certificates, App Store Connect listing). Until those exist no
TestFlight build can be produced and `build-ios` in CI stays commented
out.

### What already works on master
- `ios/Runner.xcodeproj` and `ios/Runner.xcworkspace` exist.
- `ios/Runner/Info.plist` already declares:
  - `NSLocationWhenInUseUsageDescription`
  - `NSLocationAlwaysAndWhenInUseUsageDescription`
  - `NSLocationAlwaysUsageDescription`
  - `UIBackgroundModes = fetch + processing + remote-notification`
  - `BGTaskSchedulerPermittedIdentifiers = de.tankstellen.tankstellen.background`
  - Scene manifest + launch storyboard
- `ios/Runner/AppDelegate.swift` + `SceneDelegate.swift` are in place.
- Supported orientations declared for iPhone and iPad.

### What is missing
1. **Apple Developer Program enrollment** — $99 / year, requires a
   real Apple ID and identity verification. Single-person accounts are
   fine for a solo dev.
2. **Bundle identifier** in App Store Connect — reserve
   `de.tankstellen.tankstellen` to match `PRODUCT_BUNDLE_IDENTIFIER`.
3. **Signing certificates + provisioning profiles** — development and
   distribution pairs. Fastlane Match is recommended; alternatively
   Xcode's automatic signing works for a solo account.
4. **CocoaPods lockfile** — the project has a `Podfile` but no
   `Podfile.lock` has been committed; the first `pod install` on a Mac
   will produce one.
5. **Push notification entitlement** — needed if local notifications
   are promoted to remote (server-side alerts). The current app uses
   `flutter_local_notifications` only, which does not require APNs, so
   this is optional at launch.
6. **CI job re-enabled** — uncomment `build-ios` in
   `.github/workflows/ci.yml`. Needs a `macos-latest` runner, signing
   secrets stored in GitHub Actions, and `fastlane pilot upload` or
   `xcodebuild -exportArchive` for TestFlight delivery.
7. **App Store Connect listing** — separate from the Google Play
   listing tracked in `#594`; iOS has its own metadata dimensions
   (6.5" + 5.5" screenshots, app preview videos, etc.).

## Checklist for the user (order matters)

1. Enroll in Apple Developer Program.
2. Reserve the bundle identifier in App Store Connect.
3. On a Mac: `cd ios && pod install` — commits `Podfile.lock`.
4. Create development + distribution certificates in Xcode or Fastlane
   Match. Export signing secrets for CI if automating.
5. In Xcode: select the Runner target → Signing & Capabilities → tick
   "Automatically manage signing" → pick the team → build a test run
   on a physical device.
6. Verify the Flutter plugins compile (`flutter build ios --no-codesign`
   from the repo root; iOS-only plugins that were never used on Android
   may surface here — `sentry_flutter`, `workmanager`, etc.).
7. Upload the first build to TestFlight (internal track) and
   self-invite to confirm install works.
8. Re-enable `build-ios` in `.github/workflows/ci.yml` once the above
   manual steps produced a green local build.

## What this repo can do autonomously

Nothing — every step above requires the user's Apple ID and physical
Mac access. Opening this issue was the right call; marking it a
long-term blocker rather than a fixable-in-session task is the
honest position. Keep the issue open with `blocked` and `needs-user`
labels and come back after the developer enrollment completes.
