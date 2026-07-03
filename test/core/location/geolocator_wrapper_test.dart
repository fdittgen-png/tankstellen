// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';

void main() {
  group('GeolocatorWrapper.forceLocationManager (#2574)', () {
    test('defaults to false without the FORCE_LOCATION_MANAGER dart-define', () {
      // The plain `flutter test` build carries no --dart-define, so the
      // compile-time const resolves to false. The fdroid CI/release build
      // passes --dart-define=FORCE_LOCATION_MANAGER=true to flip it; that
      // wrapping is exercised by the on-device/instrumented path and the
      // dependency-graph audit (scripts/audit_no_gms.sh), not here, because
      // bool.fromEnvironment is fixed at compile time.
      expect(GeolocatorWrapper.forceLocationManager, isFalse);
    });

    test('source centralises the LocationManager forcing in the wrapper', () {
      // Regression guard: the GPS call sites (location_service.dart,
      // approach_state_provider.dart, trip_gps_stream_controller.dart —
      // movement_detection_provider was removed as dead code, #3253)
      // must stay free of flavor branching;
      // the AndroidSettings(forceLocationManager:) wrapping lives ONLY here so
      // they keep passing a plain LocationSettings.
      final source = File(
        'lib/core/location/geolocator_wrapper.dart',
      ).readAsStringSync();
      expect(
        source.contains('bool.fromEnvironment'),
        isTrue,
        reason: 'forceLocationManager must read the compile-time define',
      );
      expect(
        source.contains('forceLocationManager: true'),
        isTrue,
        reason: 'wrapper must build an AndroidSettings(forceLocationManager:)',
      );
      expect(
        source.contains('_withForcedLocationManager'),
        isTrue,
        reason: 'both getCurrentPosition and getPositionStream route through it',
      );

      // The call sites stay unchanged: none of them constructs AndroidSettings
      // or reads the FORCE_LOCATION_MANAGER define directly.
      for (final path in const [
        'lib/core/location/location_service.dart',
        'lib/features/approach/providers/approach_state_provider.dart',
        'lib/features/consumption/providers/trip_gps_stream_controller.dart',
      ]) {
        final callSite = File(path).readAsStringSync();
        expect(
          callSite.contains('AndroidSettings'),
          isFalse,
          reason: '$path must not construct AndroidSettings — that is the '
              'wrapper\'s job (#2574)',
        );
        expect(
          callSite.contains('FORCE_LOCATION_MANAGER'),
          isFalse,
          reason: '$path must not read the FORCE_LOCATION_MANAGER define',
        );
      }
    });
  });
}
