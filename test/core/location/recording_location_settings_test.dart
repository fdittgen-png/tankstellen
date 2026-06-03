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
      // log #17). Foreground-only until the flag + manifest permission return.
      expect(kGpsRecordingForegroundServiceEnabled, isFalse,
          reason: 'guards against re-enabling the FGS without the manifest '
              'permission — flip both together when #1498 lands');
      expect(android.foregroundNotificationConfig, isNull,
          reason: 'no startForeground while FOREGROUND_SERVICE is removed');
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
}
