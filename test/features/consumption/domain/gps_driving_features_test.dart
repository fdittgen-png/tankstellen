// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/gps_driving_features.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

TripSample _s(
  DateTime t,
  double speedKmh, {
  double? lat,
  double? lng,
  double? altM,
}) =>
    TripSample(
      timestamp: t,
      speedKmh: speedKmh,
      rpm: 0,
      latitude: lat,
      longitude: lng,
      altitudeM: altM,
    );

Iterable<TripSample> _constantSpeed({
  required double speedKmh,
  required int seconds,
  required DateTime start,
}) sync* {
  for (var i = 0; i <= seconds; i++) {
    yield _s(start.add(Duration(seconds: i)), speedKmh);
  }
}

void main() {
  group('GpsDrivingFeatures.from', () {
    final t0 = DateTime.utc(2026, 5, 25, 10);

    test('null on empty stream', () {
      expect(GpsDrivingFeatures.from(const <TripSample>[]), isNull);
    });

    test('null on single-sample stream', () {
      expect(GpsDrivingFeatures.from([_s(t0, 50)]), isNull);
    });

    group('speed-band integration', () {
      test('all idle (speed < 5) → idleSeconds = totalSeconds', () {
        final f = GpsDrivingFeatures.from(
          _constantSpeed(speedKmh: 0, seconds: 60, start: t0),
        )!;
        expect(f.totalSeconds, closeTo(60.0, 0.01));
        expect(f.idleSeconds, closeTo(60.0, 0.01));
        expect(f.lowSpeedSeconds, 0);
        expect(f.cruiseSeconds, 0);
        expect(f.highSpeedSeconds, 0);
        expect(f.idleShare, closeTo(1.0, 0.001));
      });

      test('all cruise (50 ≤ speed < 110) → cruiseSeconds = totalSeconds',
          () {
        final f = GpsDrivingFeatures.from(
          _constantSpeed(speedKmh: 80, seconds: 120, start: t0),
        )!;
        expect(f.cruiseSeconds, closeTo(120.0, 0.01));
        expect(f.idleSeconds, 0);
        expect(f.lowSpeedSeconds, 0);
        expect(f.highSpeedSeconds, 0);
      });

      test('all high-speed (≥ 110) → highSpeedSeconds + highSpeedShare = 1',
          () {
        final f = GpsDrivingFeatures.from(
          _constantSpeed(speedKmh: 130, seconds: 30, start: t0),
        )!;
        expect(f.highSpeedSeconds, closeTo(30.0, 0.01));
        expect(f.highSpeedShare, closeTo(1.0, 0.001));
      });

      test('threshold edges: 5, 50, 110 each go to the upper band', () {
        // speed = 5 → low; speed = 50 → cruise; speed = 110 → high
        final f = GpsDrivingFeatures.from([
          _s(t0, 5),
          _s(t0.add(const Duration(seconds: 10)), 50),
          _s(t0.add(const Duration(seconds: 20)), 110),
          _s(t0.add(const Duration(seconds: 30)), 110),
        ])!;
        // Each leading sample is integrated over the next dt (10s):
        //   leading 5 → low: 10s
        //   leading 50 → cruise: 10s
        //   leading 110 → high: 10s
        expect(f.lowSpeedSeconds, closeTo(10.0, 0.01));
        expect(f.cruiseSeconds, closeTo(10.0, 0.01));
        expect(f.highSpeedSeconds, closeTo(10.0, 0.01));
      });
    });

    group('accel / brake events', () {
      test('a sustained > 2 m/s² ramp for ≥ 1s counts once', () {
        // Speed goes 0 → 36 km/h over 5s → 2 m/s². Sustained, single
        // event.
        final samples = <TripSample>[];
        for (var i = 0; i <= 5; i++) {
          // 36 km/h = 10 m/s. Linear ramp.
          samples.add(_s(t0.add(Duration(seconds: i)), i * 36.0 / 5));
        }
        // Then 10s of cruise so the integrator has time after the ramp.
        for (var i = 1; i <= 10; i++) {
          samples.add(_s(t0.add(Duration(seconds: 5 + i)), 36.0));
        }
        final f = GpsDrivingFeatures.from(samples)!;
        expect(f.accelEvents, 1);
        expect(f.brakeEvents, 0);
        expect(f.maxAccelG, greaterThan(0.1));
      });

      test('a hard brake (< -2 m/s² for ≥ 1s) counts as brakeEvent', () {
        // Speed drops 72 → 0 km/h over 5s → -4 m/s².
        final samples = <TripSample>[];
        for (var i = 0; i <= 5; i++) {
          samples.add(_s(t0.add(Duration(seconds: i)), 72.0 - i * 14.4));
        }
        for (var i = 1; i <= 5; i++) {
          samples.add(_s(t0.add(Duration(seconds: 5 + i)), 0.0));
        }
        final f = GpsDrivingFeatures.from(samples)!;
        expect(f.brakeEvents, 1);
        expect(f.accelEvents, 0);
      });

      test('a sub-1s blip is NOT an event (debounce)', () {
        // 500 ms isolated bump — speed jumps 50 → 70 over 0.5s then
        // drops back over 0.5s. Both deltas are sustained for less
        // than the 1s threshold individually.
        final samples = [
          _s(t0, 50),
          _s(t0.add(const Duration(milliseconds: 500)), 70),
          _s(t0.add(const Duration(milliseconds: 1000)), 50),
          _s(t0.add(const Duration(milliseconds: 2000)), 50),
          _s(t0.add(const Duration(milliseconds: 3000)), 50),
        ];
        final f = GpsDrivingFeatures.from(samples)!;
        expect(f.accelEvents, 0);
        expect(f.brakeEvents, 0);
      });
    });

    test('distance via haversine when both samples have GPS fixes', () {
      // Two points ~1 km apart on the same latitude line at the
      // equator (latitude 0). 1° of longitude at the equator ≈
      // 111 km, so 0.009° ≈ 1 km.
      final samples = [
        _s(t0, 50, lat: 0, lng: 0),
        _s(t0.add(const Duration(seconds: 60)), 50, lat: 0, lng: 0.009),
      ];
      final f = GpsDrivingFeatures.from(samples)!;
      // ~1 km expected, give a generous tolerance.
      expect(f.distanceKm, closeTo(1.0, 0.05));
    });

    test('distance falls back to speed × dt when GPS is missing', () {
      // No lat/lng provided — falls back to speedKmh × dt math.
      // 50 km/h × 60 s = 50 km/h × 60/3600 h = 50/60 km ≈ 0.833 km.
      final samples = [
        _s(t0, 50),
        _s(t0.add(const Duration(seconds: 60)), 50),
      ];
      final f = GpsDrivingFeatures.from(samples)!;
      expect(f.distanceKm, closeTo(50 / 60, 0.01));
    });

    test('mean speed = distance / total_hours', () {
      final f = GpsDrivingFeatures.from(
        _constantSpeed(speedKmh: 60, seconds: 600, start: t0),
      )!;
      expect(f.meanSpeedKmh, closeTo(60.0, 0.5));
    });

    group('altitude (grade) tracking', () {
      test('climb sums positive deltas, descent sums absolute negatives',
          () {
        final samples = [
          _s(t0, 50, lat: 45, lng: 5, altM: 100),
          _s(t0.add(const Duration(seconds: 10)), 50, lat: 45, lng: 5.001, altM: 110), // +10
          _s(t0.add(const Duration(seconds: 20)), 50, lat: 45, lng: 5.002, altM: 105), // -5
          _s(t0.add(const Duration(seconds: 30)), 50, lat: 45, lng: 5.003, altM: 120), // +15
        ];
        final f = GpsDrivingFeatures.from(samples)!;
        expect(f.gradeClimbMeters, closeTo(25.0, 0.01));
        expect(f.gradeDescentMeters, closeTo(5.0, 0.01));
      });

      test('null altitudes leave grade fields at 0', () {
        final f = GpsDrivingFeatures.from(
          _constantSpeed(speedKmh: 60, seconds: 60, start: t0),
        )!;
        expect(f.gradeClimbMeters, 0);
        expect(f.gradeDescentMeters, 0);
      });
    });

    test('idleShare + highSpeedShare for the matrix coefficients', () {
      // 30s idle, then 30s cruise — share split should be 0.5/0.0.
      final samples = [
        ..._constantSpeed(speedKmh: 0, seconds: 30, start: t0).toList()
          ..removeLast(),
        ..._constantSpeed(
          speedKmh: 80,
          seconds: 30,
          start: t0.add(const Duration(seconds: 30)),
        ),
      ];
      final f = GpsDrivingFeatures.from(samples)!;
      expect(f.idleShare, closeTo(0.5, 0.05));
      expect(f.highSpeedShare, 0);
    });

    test('accelEventsPerKm guards against zero-distance', () {
      // Two stationary samples — distance is 0.
      final samples = [_s(t0, 0), _s(t0.add(const Duration(seconds: 30)), 0)];
      final f = GpsDrivingFeatures.from(samples)!;
      expect(f.distanceKm, 0);
      expect(f.accelEventsPerKm, 0);
    });
  });
}
