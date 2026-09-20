// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';

/// #4353 fault injection for the never-throws contract documented on
/// `_SharedPositionSource._replaceUpstream`. That method is fired with
/// `unawaited(...)`, so an escaping error would become an unhandled async
/// error in the recording isolate — the contract has to be tested, not
/// asserted in a docstring.
///
/// Each `getPositionStream` hands back a fresh single-subscription stream
/// (the wrapper only ever attaches one listener), whose cancel fails with
/// [cancelError] when one is set and whose open throws [failNextOpen].
class _FaultyGeolocator extends GeolocatorWrapper {
  final List<LocationSettings?> openedSettings = [];

  /// Error the NEXT subscription cancel completes with.
  Object? cancelError;

  /// Error the NEXT open throws.
  Object? failNextOpen;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    final fail = failNextOpen;
    if (fail != null) {
      failNextOpen = null;
      Error.throwWithStackTrace(fail, StackTrace.current);
    }
    openedSettings.add(locationSettings);
    // Closed by the wrapper's own cancel path when the last consumer leaves.
    // ignore: close_sinks
    late final StreamController<Position> ctl;
    ctl = StreamController<Position>(
      onCancel: () {
        final err = cancelError;
        if (err == null) return null;
        cancelError = null;
        return Future<void>.error(err, StackTrace.empty);
      },
    );
    return ctl.stream;
  }
}

Future<void> _pump() => Future<void>.delayed(Duration.zero);

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
        'lib/features/trips/providers/trip_gps_stream_controller.dart',
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

  // #4353 — `_replaceUpstream` is documented as never throwing because it is
  // fired with `unawaited`. These are its fault paths.
  group('shared upstream replacement never throws (#4353)', () {
    final fine = AndroidSettings(
      accuracy: LocationAccuracy.high,
      intervalDuration: const Duration(seconds: 1),
      distanceFilter: 0,
    );
    const coarse = LocationSettings(accuracy: LocationAccuracy.high);

    test('a cancel that FAILS neither escapes nor strands the recording',
        () async {
      final geo = _FaultyGeolocator();
      final errors = <Object>[];
      final subDetector = geo
          .sharedPositionStream(locationSettings: coarse)
          .listen((_) {}, onError: errors.add);
      await _pump();

      geo.cancelError = StateError('platform refused to release the channel');

      // The promotion runs unawaited inside this synchronous call: if the
      // contract were broken the failure would surface as an unhandled async
      // error and fail the test outright.
      late final StreamSubscription<Position> subRecorder;
      expect(
        () {
          subRecorder = geo
              .sharedPositionStream(locationSettings: fine, recording: true)
              .listen((_) {}, onError: errors.add);
        },
        returnsNormally,
      );
      await _pump();

      expect(errors.whereType<StateError>(), hasLength(2),
          reason: 'the failure is reported to both consumers, not swallowed');
      expect(geo.openedSettings.last, same(fine),
          reason: 'a failed cancel must not strand the trip on the old '
              'profile — the replacement still opens');
      expect(geo.sharedPositionDiagnostics.effective, same(fine));

      await subDetector.cancel();
      await subRecorder.cancel();
    });

    test(
        "the benign EventChannel 'No active stream to cancel' stays "
        'swallowed', () async {
      final geo = _FaultyGeolocator();
      final errors = <Object>[];
      final subDetector = geo
          .sharedPositionStream(locationSettings: coarse)
          .listen((_) {}, onError: errors.add);
      await _pump();

      geo.cancelError = PlatformException(
        code: 'channelError',
        message: 'No active stream to cancel',
      );
      final subRecorder = geo
          .sharedPositionStream(locationSettings: fine, recording: true)
          .listen((_) {}, onError: errors.add);
      await _pump();

      expect(errors, isEmpty, reason: '#1323: the platform is already down');
      expect(geo.sharedPositionDiagnostics.effective, same(fine));

      await subDetector.cancel();
      await subRecorder.cancel();
    });

    test('an open that THROWS is reported, not raised', () async {
      final geo = _FaultyGeolocator();
      final errors = <Object>[];
      final subDetector = geo
          .sharedPositionStream(locationSettings: coarse)
          .listen((_) {}, onError: errors.add);
      await _pump();

      geo.failNextOpen = PlatformException(code: 'PERMISSION_DENIED');
      final subRecorder = geo
          .sharedPositionStream(locationSettings: fine, recording: true)
          .listen((_) {}, onError: errors.add);
      await _pump();

      expect(errors, hasLength(2));
      expect(errors.first, isA<PlatformException>());
      final d = geo.sharedPositionDiagnostics;
      expect(d.requested, same(fine));
      expect(d.effective, isNull, reason: 'requested, but NOT applied');

      await subDetector.cancel();
      await subRecorder.cancel();
    });
  });
}
