# ADR 0009: Cross-platform by default; platform-specific code lives in loosely-coupled plugins

**Status:** Accepted
**Date:** 2026-05-08

## Context

Tankstellen ships on both iOS and Android. The shared business logic lives
in Dart, but a non-trivial set of capabilities — Bluetooth Low Energy
(OBD2), continuous background fetch, home-screen widgets, in-vehicle
infotainment integrations (Android Auto and CarPlay), local notifications,
and platform credential stores — are exposed by very different APIs on the
two operating systems.

Up to now, with the iOS port still bootstrapping, almost every feature
shipped Android-first. As of #1456 (iOS build pipeline) and the four PRs
that close out epic #9 (#1490 / #1491 / #1492 / #1493), iOS is a peer
target with its own signing, fastlane match, and TestFlight workflow.
Owner directive on **2026-05-08**:

> The Mac is now the main development and build server, and all builds
> must happen for both iPhone and Android. Features are by default on both
> platforms. If a feature is intentionally single-platform, the code must
> be written as a plugin that is loosely bound to the app and not be mixed
> with code that runs on both.

We need a written rule so the next contributor doesn't shape platform
divergence ad hoc.

## Decision

**1. Every feature targets iOS and Android by default.** When a new feature
is proposed, the question "which platforms?" is *not* asked — both is the
answer. Issues, PRs, and design docs only need to call out platform scope
when the feature is intentionally restricted to one.

**2. Platform-specific code is structured as a plugin.** When a feature
*does* require a platform-specific API (BLE, BG location, BG tasks, home
widgets, CarPlay/Android Auto), the implementation must follow the
existing two-impl-one-interface pattern already used in
`lib/core/background/`:

- An abstract interface in shared code (e.g.
  `BackgroundPriceFetcher`).
- A concrete `_android_…` implementation that imports Android-only
  packages.
- A concrete `_ios_…` implementation (or a stub like
  `ios_background_price_fetcher_stub.dart` if the iOS API isn't wired
  yet) that *never* imports Android-only packages.
- A Riverpod provider chooses the concrete impl at startup, typically via
  `defaultTargetPlatform` or a feature flag.

Shared business logic — the providers, the screens, the use cases —
imports only the abstract interface. It must compile and run on a target
where the platform-specific impl is a no-op.

**3. No inline `if (Platform.isIOS) { ... } else { ... }` branches in
shared code.** That pattern leaks platform APIs through the shared code's
import graph and makes it impossible to delete a platform without
rewriting half the codebase. The only acceptable use of `Platform.isIOS`
or `defaultTargetPlatform` is in a provider that selects which concrete
plugin impl to inject — never in a screen, controller, or service body.

**4. Both CI workflows must stay green on every PR.** A regression in
`daily-beta.yml` (Android nightly to Play Store) or `ios-testflight.yml`
(iOS nightly to TestFlight) is treated as a release-blocking failure. A
PR that intentionally trades one platform for the other is rejected.

## Consequences

**Positive:**

- The codebase remains buildable on both platforms without surgical
  per-feature carve-outs.
- A reader of `lib/features/<name>/` doesn't need to mentally subtract
  iOS-only or Android-only code paths to understand the feature.
- New contributors can bring up either platform without an existing
  contributor's knowledge of which features "secretly" don't run there.
- Future deprecations (e.g., dropping the `foss` Android flavour) become
  a matter of removing one plugin impl instead of unwinding `if`
  branches throughout the code.

**Negative:**

- More files per platform-divergent feature (one interface + two impls +
  one provider, instead of one inline `if`).
- Forces an early architectural decision when the feature's complexity
  is small. Contributors may grumble that a 30-line iOS-vs-Android split
  feels over-engineered.
- Stub maintenance: when an iOS feature is deferred, a no-op stub still
  has to ship so shared code compiles on iOS.

**Mitigations:**

- The existing `lib/core/background/` split is the canonical worked
  example — point reviewers to it.
- For genuinely platform-only APIs (CarPlay, WidgetKit, Android Auto)
  where there is no shared abstraction, the plugin is allowed to live
  entirely under `ios/` or `android/` native code with a thin Dart
  channel; the rule still applies — no shared Dart code touches the
  platform channel directly.

## Examples already in the codebase

- **`BackgroundPriceFetcher`** — abstract interface, with
  `AndroidBackgroundPriceFetcher` (Workmanager) and
  `IosBackgroundPriceFetcherStub` (placeholder until BGTaskScheduler is
  wired). Shared `BackgroundService` calls only the abstract interface.
- **Notifications** — `flutter_local_notifications` already abstracts
  iOS UNUserNotificationCenter from Android NotificationManager; we
  inherit the plugin pattern via the package itself.
- **Secure storage** — `flutter_secure_storage` does the same for
  Android Keystore and iOS Keychain.

## Alternatives Considered

**Inline `if (Platform.isIOS) { ... }` branches in shared code.** Rejected
— already covered in the Decision section. Short-term cheap, long-term
ruinous: turns the shared code's import graph into a per-platform
dependency soup, and makes deleting a platform an archaeological project
rather than just removing one plugin file.

**Separate Dart packages per platform-specific feature** (e.g. an
`obd2_ble_android` and `obd2_ble_ios` package consumed by the main app).
Rejected for v1: adds packaging overhead (path dependencies, version
pinning, separate test runs) for plugins that today are all single-impl
files. Reconsider if a third party ever wants to ship a platform impl
without forking the whole repo.

**Single platform target.** Rejected: the iOS bootstrap (#1456 + #9
follow-ups) was already a deliberate, completed investment. Walking it
back now would invalidate signing infra (fastlane match repo, ASC API
key, App Store Connect record) and the Mac CI runner job that already
exists.

**Conditional imports** (Dart's `if (dart.library.io)` pattern). Useful
for the web/io split but a poor fit for our iOS/Android divide —
`dart.library.io` is true on both, so it can't carry the platform
branch. The plugin pattern subsumes this anyway.

## Out of scope

This ADR doesn't say anything about *which* APIs we use on each platform
(that's per-feature design), nor about test pyramid or layering. It only
governs **where** platform-specific code is allowed to live.
