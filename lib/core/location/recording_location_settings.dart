// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../l10n/app_localizations.dart';
import '../language/language_provider.dart';

/// #2787/#1498 — whether the GPS-recording foreground service may be requested.
///
/// #2766 promotes the recording GPS stream to an Android foreground service to
/// beat the OS's ~5 s background batching. But the `FOREGROUND_SERVICE`
/// permission is `tools:node="remove"`'d from AndroidManifest.xml for the Open
/// Testing release (#1498 — ship without triggering Google Play's "Foreground
/// Service Use" form). With the permission gone, geolocator's `startForeground`
/// throws `Permission Denial: startForeground … requires FOREGROUND_SERVICE`
/// and the GPS stream never starts — the trip captures zero fixes and is
/// discarded as "no movement" (error log #17).
///
/// While this is `false` the recorder streams **foreground-only**, which is
/// reliable because the recording screen pins itself (screen-on by default,
/// #2785).
///
/// ## The un-throttle trigger (#3173)
///
/// The restore is a single build flag, so it ships dark and flips the day
/// the Play form clears — no code change, no forgotten manifest sibling:
///
/// ```
/// flutter build appbundle --flavor play --dart-define=FGS_FORM_APPROVED=true
/// ```
///
/// The SAME define drives BOTH halves of the restore in lockstep:
///   1. **Dart** — this flag turns `true`, so [recordingLocationSettings]
///      passes geolocator the [ForegroundNotificationConfig] (the actual
///      un-throttle lever) and the Android Auto / auto-record Dart side
///      finds its native service.
///   2. **Manifest** — `android/app/build.gradle.kts` decodes the
///      `dart-defines` Gradle property Flutter forwards and, when the flag
///      is set, swaps the flavor manifest overlay for the `*FgsApproved`
///      variant that re-declares the `FOREGROUND_SERVICE*` permissions and
///      the `AutoRecordForegroundService` (restore points formerly
///      commented in `AndroidManifest.xml`).
///
/// Keeping the two halves on one define removes the historical failure
/// mode (#2787 / error log #17): flag on + permission absent =
/// `startForeground` Permission Denial = zero GPS fixes. Without the
/// define every build stays byte-identical to today's Play-compliant
/// shape (no `FOREGROUND_SERVICE*` permission in the merged manifest, so
/// the Open-Testing upload never 403s on the #1498 form).
///
/// `bool.fromEnvironment` is opaque to the analyzer, so the gated
/// `ForegroundNotificationConfig` branch stays compiled + visible (the old
/// `final`-not-`const` trick is no longer needed).
const bool kGpsRecordingForegroundServiceEnabled =
    bool.fromEnvironment('FGS_FORM_APPROVED');

/// #2766 — the platform-specific [LocationSettings] used while a trip is
/// **actively recording**, so the GPS trace stays fine-grained (~1 s) instead
/// of the ~5 s the OS batches a backgrounded `getPositionStream` down to.
///
/// ## Why a bare `LocationSettings` throttles
///
/// `LocationSettings(accuracy: high)` carries no interval, no distance filter,
/// and — on Android — does **not** promote geolocator to a foreground service.
/// Once the recording screen is backgrounded (driving, screen off) Android
/// batches fixes to a ~5000 ms median, coarsening the polyline + every
/// distance / fuel analytic derived from it.
///
/// ## The un-throttle levers (per platform, via the plugin pattern)
///
///   * **Android** — an [AndroidSettings] with `intervalDuration: 1 s`,
///     `distanceFilter: 0`, and a [ForegroundNotificationConfig]. The
///     foreground service is the actual lever: it raises geolocator_android's
///     priority so the OS stops the ~5 s batching while the persistent
///     notification is showing. `enableWakeLock` keeps the CPU awake for the
///     fixes. Title/text come from the already-localized ARB keys.
///   * **iOS** — an [AppleSettings] with `activityType:
///     automotiveNavigation` (CLLocationManager tunes accuracy/cadence for a
///     car), `allowBackgroundLocationUpdates: true`, and
///     `pauseLocationUpdatesAutomatically: false` so iOS does not auto-pause
///     updates when it thinks the user stopped moving.
///
/// ## Platform selection (no inline `Platform.isX` in business logic)
///
/// Selection is on [defaultTargetPlatform] — the same idiom
/// `auto_record_orchestrator_factories.dart` and `pip_controller.dart` use —
/// so tests drive it with `debugDefaultTargetPlatform`. An explicit
/// [platform] override is also accepted for direct unit testing.
///
/// ## Battery bound
///
/// This is the fine, foreground-service-promoted profile. It is requested
/// ONLY by the recording pipeline, and the shared position source is
/// refcounted to the trip lifecycle (opens on the first trip listener,
/// cancels on the last), so the wakelock + 1 s cadence apply only while a
/// trip is actively recording. The interval is a self-bounded 1000 ms with
/// `distanceFilter: 0` — never geolocator's unbounded "fastest".
///
/// #3112 — [approachLocationSettings] is the radar/approach-detector sibling:
/// not foreground-service-promoted and no l10n, but it MUST still pass iOS the
/// `pauseLocationUpdatesAutomatically: false` flag — a bare `LocationSettings`
/// lets iOS CoreLocation auto-pause the stream when it thinks the user stopped
/// (red light / fuel stop), freezing the radar after its first scan ("radar
/// stuck on iPhone"). Android's bare high-accuracy stream does not auto-pause,
/// so it is left unchanged. `automotiveNavigation` + `allowBackgroundLocationUpdates`
/// mirror the recorder so the #2065 PiP approach keeps receiving fixes.
LocationSettings approachLocationSettings({TargetPlatform? platform}) {
  switch (platform ?? defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        allowBackgroundLocationUpdates: true,
        pauseLocationUpdatesAutomatically: false,
      );
    default:
      return const LocationSettings(accuracy: LocationAccuracy.high);
  }
}

LocationSettings recordingLocationSettings({
  required AppLocalizations l10n,
  TargetPlatform? platform,
  bool? foregroundServiceEnabled,
}) {
  final target = platform ?? defaultTargetPlatform;
  // #3173 — test seam: production always follows the build-time define
  // (which the Gradle side mirrors into the manifest), while unit tests
  // pin both the throttled and the restored branch explicitly.
  final fgsEnabled =
      foregroundServiceEnabled ?? kGpsRecordingForegroundServiceEnabled;
  switch (target) {
    case TargetPlatform.android:
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        // Self-bounded fine cadence: ask for a fix every second and let
        // every one through (no distance gate) so the trace stays dense
        // even at a standstill / in stop-and-go traffic.
        intervalDuration: const Duration(seconds: 1),
        distanceFilter: 0,
        // The un-throttle lever: promote geolocator to a foreground service so
        // the OS stops the ~5 s background batching for the trip. Gated by
        // [kGpsRecordingForegroundServiceEnabled] (#3173 trigger:
        // --dart-define=FGS_FORM_APPROVED=true) — OFF while the manifest
        // FOREGROUND_SERVICE permission is removed (#1498), so we pass `null`
        // and stream foreground-only rather than crash on startForeground
        // (error log #17 / #2787). Title/text are the already-merged ARB keys.
        foregroundNotificationConfig: fgsEnabled
            ? ForegroundNotificationConfig(
                notificationTitle: l10n.tripRecordingGpsNotificationTitle,
                notificationText: l10n.tripRecordingGpsNotificationText,
                enableWakeLock: true,
                setOngoing: true,
              )
            : null,
      );
    case TargetPlatform.iOS:
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        // Car-tuned Core Location profile — best cadence/accuracy for a
        // vehicle and lets iOS deliver updates with the screen off.
        activityType: ActivityType.automotiveNavigation,
        allowBackgroundLocationUpdates: true,
        // Do not let iOS auto-pause when it heuristically decides the user
        // stopped — a fuel-stop or a red light must not end the trace.
        pauseLocationUpdatesAutomatically: false,
      );
    default:
      // Desktop / web / fuchsia: no platform-specific foreground service
      // lever exists, so the cross-platform high-accuracy settings are all
      // there is to give. Recording is a phone feature in practice.
      return const LocationSettings(accuracy: LocationAccuracy.high);
  }
}

/// #2766 — [recordingLocationSettings] with the active in-app language
/// resolved off [ref] (no `BuildContext`, since the recorder runs from a
/// notifier / service context). `lookupAppLocalizations` is a pure
/// synchronous constructor. Both the language read and the lookup are
/// guarded so a harness (or any context) without the active-profile /
/// storage graph wired degrades to English notification copy rather than
/// crashing the trip start — in production the graph is always wired.
LocationSettings recordingLocationSettingsForRef(
  Ref ref, {
  TargetPlatform? platform,
}) {
  String code;
  try {
    code = ref.read(activeLanguageProvider).code;
  } catch (_) {
    code = 'en';
  }
  AppLocalizations l10n;
  try {
    l10n = lookupAppLocalizations(ui.Locale(code));
  } catch (_) {
    l10n = lookupAppLocalizations(const ui.Locale('en'));
  }
  return recordingLocationSettings(l10n: l10n, platform: platform);
}
