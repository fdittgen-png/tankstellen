// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tankstellen/core/location/recording_location_settings.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #2766 — the recording GPS settings builder.
///
/// Pins the platform-specific un-throttle levers:
///   - Android → an [AndroidSettings] with a 1 s interval, distanceFilter 0,
///     and a [ForegroundNotificationConfig] carrying the ARB title/text +
///     wakelock (the foreground service is what stops the ~5 s background
///     batching);
///   - iOS → an [AppleSettings] with automotiveNavigation +
///     allowBackgroundLocationUpdates + no auto-pause;
///   - selection is on the target platform (here via the explicit override),
///     mirroring the `debugDefaultTargetPlatform` seam tests would otherwise
///     use — no inline `Platform.isX`.
void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  group('recordingLocationSettings (#2766)', () {
    test('Android → AndroidSettings: 1 s interval, foreground-only (#2787)',
        () {
      final settings = recordingLocationSettings(
        l10n: l10n,
        platform: TargetPlatform.android,
      );

      expect(settings, isA<AndroidSettings>());
      final android = settings as AndroidSettings;
      expect(android.accuracy, LocationAccuracy.high);
      expect(android.intervalDuration, const Duration(seconds: 1),
          reason: 'fine ~1 s cadence, not the ~5 s background default');
      expect(android.distanceFilter, 0,
          reason: 'every fix through — dense trace even at a standstill');

      // #2787 — the foreground service is gated OFF while the manifest
      // FOREGROUND_SERVICE permission is removed (#1498); requesting it threw
      // a startForeground Permission Denial that killed the GPS stream (error
      // log #17). #3173 made the restore a single build define
      // (FGS_FORM_APPROVED) that flips the Dart flag AND the manifest overlay
      // together — this test runs WITHOUT the define, so it pins the
      // ships-dark default: throttled, foreground-only, Play-compliant.
      expect(kGpsRecordingForegroundServiceEnabled, isFalse,
          reason: 'default builds (no --dart-define=FGS_FORM_APPROVED=true) '
              'must stay foreground-only until the #1498 Play form clears');
      expect(android.foregroundNotificationConfig, isNull,
          reason: 'no startForeground while FOREGROUND_SERVICE is removed');
    });

    group('#3173 — FGS_FORM_APPROVED gating (throttled vs restored)', () {
      test(
          'throttled (form pending, foregroundServiceEnabled: false) → '
          'NO foreground service requested', () {
        final settings = recordingLocationSettings(
          l10n: l10n,
          platform: TargetPlatform.android,
          foregroundServiceEnabled: false,
        ) as AndroidSettings;

        expect(settings.foregroundNotificationConfig, isNull,
            reason: 'while the #1498 form is pending the merged manifest has '
                'no FOREGROUND_SERVICE permission — requesting the service '
                'would crash startForeground (error log #17)');
        // The fine cadence stays requested either way; only the
        // background-batching counter-lever (the FGS) is withheld.
        expect(settings.intervalDuration, const Duration(seconds: 1));
        expect(settings.distanceFilter, 0);
      });

      test(
          'restored (form approved, foregroundServiceEnabled: true) → '
          'ForegroundNotificationConfig with ARB copy + wakelock + ongoing',
          () {
        final settings = recordingLocationSettings(
          l10n: l10n,
          platform: TargetPlatform.android,
          foregroundServiceEnabled: true,
        ) as AndroidSettings;

        final config = settings.foregroundNotificationConfig;
        expect(config, isNotNull,
            reason: 'with FGS_FORM_APPROVED the foreground service is the '
                'un-throttle lever against the ~5 s background batching');
        expect(config!.notificationTitle,
            l10n.tripRecordingGpsNotificationTitle,
            reason: 'notification copy must come from ARB, never inline');
        expect(
            config.notificationText, l10n.tripRecordingGpsNotificationText);
        expect(config.enableWakeLock, isTrue,
            reason: 'CPU must stay awake for the 1 s fixes with screen off');
        expect(config.setOngoing, isTrue,
            reason: 'the recording notification must not be swipe-dismissable');
        // The restored profile keeps the same fine cadence.
        expect(settings.intervalDuration, const Duration(seconds: 1));
        expect(settings.distanceFilter, 0);
      });

      test('iOS ignores the Android FGS flag entirely (no platform fork)', () {
        final settings = recordingLocationSettings(
          l10n: l10n,
          platform: TargetPlatform.iOS,
          foregroundServiceEnabled: true,
        );
        expect(settings, isA<AppleSettings>(),
            reason: 'the flag is an Android-only lever behind the existing '
                'platform seam — iOS keeps its full background profile');
      });
    });

    group('#3319 — coarse (stationary) profile', () {
      test('Android coarse → backed-off cadence (5 s / 25 m / medium) but '
          'the FGS config is kept alive', () {
        final coarse = recordingLocationSettings(
          l10n: l10n,
          platform: TargetPlatform.android,
          foregroundServiceEnabled: true,
          coarse: true,
        ) as AndroidSettings;

        expect(coarse.intervalDuration, const Duration(seconds: 5),
            reason: 'back the receiver off while parked');
        expect(coarse.distanceFilter, 25);
        expect(coarse.accuracy, LocationAccuracy.medium);
        expect(coarse.foregroundNotificationConfig, isNotNull,
            reason: 'the FGS (and its wake lock) must stay alive across the '
                'stationary stretch so it can re-fine on resumed motion');
      });

      test('Android fine (coarse:false) keeps the 1 s / 0 / high cadence', () {
        final fine = recordingLocationSettings(
          l10n: l10n,
          platform: TargetPlatform.android,
        ) as AndroidSettings;
        expect(fine.intervalDuration, const Duration(seconds: 1));
        expect(fine.distanceFilter, 0);
        expect(fine.accuracy, LocationAccuracy.high);
      });
    });

    test('iOS → AppleSettings: automotiveNavigation + background updates', () {
      final settings = recordingLocationSettings(
        l10n: l10n,
        platform: TargetPlatform.iOS,
      );

      expect(settings, isA<AppleSettings>());
      final apple = settings as AppleSettings;
      expect(apple.accuracy, LocationAccuracy.high);
      expect(apple.activityType, ActivityType.automotiveNavigation);
      expect(apple.allowBackgroundLocationUpdates, isTrue);
      expect(apple.pauseLocationUpdatesAutomatically, isFalse,
          reason: 'a red light / fuel stop must not auto-end the trace');
    });

    test('selection follows debugDefaultTargetPlatformOverride when no override',
        () {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(recordingLocationSettings(l10n: l10n), isA<AndroidSettings>());

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(recordingLocationSettings(l10n: l10n), isA<AppleSettings>());
    });

    test('desktop/web → plain high-accuracy LocationSettings (no fg lever)',
        () {
      final settings = recordingLocationSettings(
        l10n: l10n,
        platform: TargetPlatform.macOS,
      );
      expect(settings, isA<LocationSettings>());
      expect(settings, isNot(isA<AndroidSettings>()));
      expect(settings, isNot(isA<AppleSettings>()));
      expect(settings.accuracy, LocationAccuracy.high);
    });
  });

  group('approachLocationSettings (#3112) — radar / approach detector', () {
    test('iOS → AppleSettings with pauseLocationUpdatesAutomatically:false '
        '(or CoreLocation auto-pauses and the radar freezes)', () {
      final settings = approachLocationSettings(platform: TargetPlatform.iOS);
      expect(settings, isA<AppleSettings>());
      final apple = settings as AppleSettings;
      expect(apple.accuracy, LocationAccuracy.high);
      expect(apple.activityType, ActivityType.automotiveNavigation);
      expect(apple.pauseLocationUpdatesAutomatically, isFalse,
          reason: 'the load-bearing flag: a fuel stop / red light must not '
              'auto-pause the radar GPS stream on iPhone');
      expect(apple.allowBackgroundLocationUpdates, isTrue);
    });

    test('Android → plain high-accuracy LocationSettings, UNCHANGED (no '
        'AppleSettings, no prod-Android behaviour change)', () {
      final settings =
          approachLocationSettings(platform: TargetPlatform.android);
      expect(settings, isA<LocationSettings>());
      expect(settings, isNot(isA<AppleSettings>()));
      expect(settings, isNot(isA<AndroidSettings>()));
      expect(settings.accuracy, LocationAccuracy.high);
    });

    test('selection follows debugDefaultTargetPlatformOverride', () {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(approachLocationSettings(), isA<AppleSettings>());
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(approachLocationSettings(), isNot(isA<AppleSettings>()));
    });
  });
}
