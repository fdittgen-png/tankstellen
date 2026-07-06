// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/accel_event_gate.dart';
import 'package:tankstellen/features/consumption/domain/gps_driving_features.dart';
import 'package:tankstellen/features/consumption/domain/gps_driving_features_shares.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

TripSample _s(
  DateTime t,
  double speedKmh, {
  double? lat,
  double? lng,
  double? altM,
  double? bearingDeg,
  double? hAccuracyM,
}) =>
    TripSample(
      timestamp: t,
      speedKmh: speedKmh,
      rpm: 0,
      latitude: lat,
      longitude: lng,
      altitudeM: altM,
      bearingDeg: bearingDeg,
      hAccuracyM: hAccuracyM,
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
      // #2667 — accel/brake events now route through the ONE shared gate
      // at the CANONICAL kHardAccelThresholdMps2 (3.0), not the old
      // divergent 2.0 m/s² this file used. The ramp below is therefore
      // 3.6 m/s² (0 → 36 km/h over the first 2.78 s — comfortably above
      // 3.0); a 2.0 m/s² ramp would no longer count an event, which is the
      // whole point of the reconciliation.
      test('a sustained ≥ 3 m/s² ramp for ≥ 1s counts once', () {
        // Speed goes 0 → 50 km/h over 2 s → 6.94 m/s². Sustained, single
        // event, then cruise.
        final samples = <TripSample>[
          _s(t0, 0),
          _s(t0.add(const Duration(seconds: 1)), 25),
          _s(t0.add(const Duration(seconds: 2)), 50),
        ];
        for (var i = 1; i <= 10; i++) {
          samples.add(_s(t0.add(Duration(seconds: 2 + i)), 50.0));
        }
        final f = GpsDrivingFeatures.from(samples)!;
        expect(f.accelEvents, 1);
        expect(f.brakeEvents, 0);
        expect(f.maxAccelG, greaterThan(0.1));
      });

      test('a 2.0 m/s² ramp is below the canonical 3.0 threshold (#2667)',
          () {
        // The OLD gps_driving_features fired here at its 2.0 m/s²
        // threshold; reconciled onto the canonical 3.0 it must NOT.
        final samples = <TripSample>[];
        for (var i = 0; i <= 5; i++) {
          samples.add(_s(t0.add(Duration(seconds: i)), i * 36.0 / 5));
        }
        for (var i = 1; i <= 10; i++) {
          samples.add(_s(t0.add(Duration(seconds: 5 + i)), 36.0));
        }
        final f = GpsDrivingFeatures.from(samples)!;
        expect(f.accelEvents, 0);
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

    // #2940 — the REPORTED maxAccelG (not just the event GATE that #2895
    // clamped) must be pinned to the physically-plausible band so a GPS
    // Doppler-speed noise spike can never surface an impossible peak. These
    // drive the REAL `GpsDrivingFeatures.from` path with the exact failure
    // mode the Peugeot-107 export logged (maxAccelG 1.036 — a 68 hp car
    // cannot exceed ~0.4 g). RED before the clamp, green after.
    group('maxAccelG physical-plausibility clamp (#2940)', () {
      // The reported peak ceilings in g, derived from the shared m/s² band.
      const maxAccelGCeiling = kMaxPlausibleAccelMps2 / 9.81; // ≈0.9001 g
      const maxBrakeGCeiling = kMaxPlausibleBrakeMps2 / 9.81; // ≈1.1213 g

      test('a forward speed spike beyond ~0.9 g reports the clamped ceiling, '
          'not the raw value, and is not counted as an event', () {
        // 0 → 40 km/h in ONE second = 11.11 m/s² ≈ 1.13 g — impossible for a
        // real car, past the ≈0.9 g forward ceiling. Then cruise so the rest
        // of the trip is calm.
        final samples = <TripSample>[
          _s(t0, 0),
          _s(t0.add(const Duration(seconds: 1)), 40),
        ];
        for (var i = 1; i <= 10; i++) {
          samples.add(_s(t0.add(Duration(seconds: 1 + i)), 40.0));
        }
        final f = GpsDrivingFeatures.from(samples)!;
        // RED before the fix: maxAccelG ≈ 1.13 (the raw impossible spike).
        expect(f.maxAccelG, lessThanOrEqualTo(maxAccelGCeiling + 1e-9));
        expect(f.maxAccelG, closeTo(maxAccelGCeiling, 1e-6));
        // The same out-of-band spike is also refused by the event gate
        // (#2895) — it breaks the episode rather than counting.
        expect(f.accelEvents, 0);
      });

      test('a braking spike beyond ~1.12 g reports the clamped brake ceiling',
          () {
        // 50 → 0 km/h in ONE second = -13.89 m/s² ≈ 1.42 g — past the ≈1.12 g
        // braking ceiling, so the magnitude is reported clamped.
        final samples = <TripSample>[
          _s(t0, 50),
          _s(t0.add(const Duration(seconds: 1)), 0),
        ];
        for (var i = 1; i <= 10; i++) {
          samples.add(_s(t0.add(Duration(seconds: 1 + i)), 0.0));
        }
        final f = GpsDrivingFeatures.from(samples)!;
        // RED before the fix: maxAccelG ≈ 1.42 (the raw impossible spike).
        expect(f.maxAccelG, lessThanOrEqualTo(maxBrakeGCeiling + 1e-9));
        expect(f.maxAccelG, closeTo(maxBrakeGCeiling, 1e-6));
      });

      test('a genuine in-band hard accel (~0.7 g) is reported verbatim, '
          'not over-clamped', () {
        // 0 → 50 km/h in 2 s = 6.94 m/s² ≈ 0.71 g — a real hard launch, BELOW
        // the ≈0.9 g ceiling. It must pass through unchanged so the clamp
        // introduces no false negatives for genuinely brisk driving.
        final samples = <TripSample>[
          _s(t0, 0),
          _s(t0.add(const Duration(seconds: 1)), 25),
          _s(t0.add(const Duration(seconds: 2)), 50),
        ];
        for (var i = 1; i <= 10; i++) {
          samples.add(_s(t0.add(Duration(seconds: 2 + i)), 50.0));
        }
        final f = GpsDrivingFeatures.from(samples)!;
        expect(f.maxAccelG, closeTo(6.944 / 9.81, 0.01)); // ≈0.708 g
        expect(f.maxAccelG, lessThan(maxAccelGCeiling));
        expect(f.accelEvents, 1); // a real, in-band event still counts
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

      test('#3502 — sub-deadband GPS altitude jitter on a flat road nets to '
          'ZERO climb (no phantom climbEnergy)', () {
        // ±2 m alternating jitter, all inside the 3 m deadband: the old
        // sample-to-sample sum booked ~2 m of climb per oscillation.
        final samples = [
          for (var i = 0; i < 40; i++)
            _s(t0.add(Duration(seconds: 10 * i)), 50,
                lat: 45, lng: 5 + 0.001 * i, altM: 100 + (i.isEven ? 0 : 2)),
        ];
        final f = GpsDrivingFeatures.from(samples)!;
        expect(f.gradeClimbMeters, 0,
            reason: 'oscillation inside the deadband must net out');
        expect(f.gradeDescentMeters, 0);
      });

      test('#3502 — a real sustained grade passes the deadband at full value',
          () {
        // 1 m per 10 s sample, 40 samples → 39 m real climb; the anchor
        // advances every 3 m so the committed total tracks the grade.
        final samples = [
          for (var i = 0; i < 40; i++)
            _s(t0.add(Duration(seconds: 10 * i)), 50,
                lat: 45, lng: 5 + 0.001 * i, altM: 100.0 + i),
        ];
        final f = GpsDrivingFeatures.from(samples)!;
        expect(f.gradeClimbMeters, closeTo(39.0, 3.0),
            reason: 'a real grade must not be eaten by the deadband '
                '(at most one sub-3 m tail is uncommitted)');
      });
    });

    group('cornering load (#2655 — revived from persisted bearing)', () {
      test('a curvy track accumulates cornerLoadIntegral + a sharp-corner '
          'event', () {
        // 80 km/h ≈ 22.2 m/s. Sweep the bearing through a tight turn:
        // 90° → 130° over 1 s = 40°/s ≈ 0.698 rad/s yaw-rate.
        // a_lat ≈ v · ω = 22.2 · 0.698 ≈ 15.5 m/s² — well past the
        // ~3.5 m/s² sharp-corner threshold, so it fires an event.
        final samples = <TripSample>[];
        var bearing = 90.0;
        for (var i = 0; i <= 6; i++) {
          samples.add(_s(
            t0.add(Duration(seconds: i)),
            80,
            lat: 45,
            lng: 5 + i * 0.0002,
            bearingDeg: bearing,
            hAccuracyM: 4,
          ));
          bearing += 40; // 40°/s sweep
        }
        final f = GpsDrivingFeatures.from(samples)!;
        expect(f.cornerLoadIntegral, greaterThan(0));
        expect(f.sharpCornerEvents, greaterThanOrEqualTo(1));
      });

      test('a straight track (constant bearing) has ~0 corner load', () {
        final samples = <TripSample>[];
        for (var i = 0; i <= 30; i++) {
          samples.add(_s(
            t0.add(Duration(seconds: i)),
            80,
            lat: 45,
            lng: 5 + i * 0.0002,
            bearingDeg: 90, // dead straight
            hAccuracyM: 4,
          ));
        }
        final f = GpsDrivingFeatures.from(samples)!;
        expect(f.cornerLoadIntegral, closeTo(0.0, 0.001));
        expect(f.sharpCornerEvents, 0);
      });

      test('bearing wrap-around 350° → 10° is a +20° delta, not −340°', () {
        // Crossing true-north: at low yaw the wrap must NOT manufacture a
        // huge phantom corner. 350 → 10 over 1 s = +20°/s ≈ 0.349 rad/s.
        // At 36 km/h (10 m/s) a_lat ≈ 3.49 m/s² — just under threshold,
        // so it contributes to the integral but stays a gentle bend, and
        // the integral must be small (it would be ~17× larger if the
        // delta were mis-computed as 340°).
        final samples = <TripSample>[
          _s(t0, 36, lat: 45, lng: 5, bearingDeg: 350, hAccuracyM: 4),
          _s(t0.add(const Duration(seconds: 1)), 36,
              lat: 45, lng: 5.0002, bearingDeg: 10, hAccuracyM: 4),
          _s(t0.add(const Duration(seconds: 2)), 36,
              lat: 45, lng: 5.0004, bearingDeg: 10, hAccuracyM: 4),
        ];
        final f = GpsDrivingFeatures.from(samples)!;
        // a_lat·dt for the +20° step = 10 m/s · 0.349 rad/s · 1 s ≈ 3.49.
        // A −340° mis-read would give ≈ 59.3 — assert we are in the small
        // regime, proving the signed-minimal-delta wrap handling.
        expect(f.cornerLoadIntegral, closeTo(3.49, 0.3));
        expect(f.sharpCornerEvents, 0);
      });

      test('legacy samples without bearing stay at 0 (no crash)', () {
        // Pre-#2650 trips carry bearingDeg == null on every sample. The
        // term must gracefully degrade to the historical hard-zero.
        final samples = <TripSample>[];
        for (var i = 0; i <= 30; i++) {
          samples.add(_s(
            t0.add(Duration(seconds: i)),
            80,
            lat: 45,
            lng: 5 + i * 0.0002,
            // bearingDeg omitted → null
          ));
        }
        final f = GpsDrivingFeatures.from(samples)!;
        expect(f.cornerLoadIntegral, 0);
        expect(f.sharpCornerEvents, 0);
      });

      test('a low-accuracy fix is gated out of the corner integral', () {
        // Same tight 40°/s sweep as the curvy test, but every fix is
        // jittery (hAccuracyM = 40 m). The accuracy gate must reject it
        // so a bad fix doesn't manufacture a phantom corner.
        final samples = <TripSample>[];
        var bearing = 90.0;
        for (var i = 0; i <= 6; i++) {
          samples.add(_s(
            t0.add(Duration(seconds: i)),
            80,
            lat: 45,
            lng: 5 + i * 0.0002,
            bearingDeg: bearing,
            hAccuracyM: 40, // jittery — beyond the gate
          ));
          bearing += 40;
        }
        final f = GpsDrivingFeatures.from(samples)!;
        expect(f.cornerLoadIntegral, 0);
        expect(f.sharpCornerEvents, 0);
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

    group('#2695 C9 speed-only energy KPIs', () {
      test('a steady acceleration ramp has positive RPA / PKE / VAPOS', () {
        // 0 → 36 km/h (10 m/s) ramped in 1 m/s² steps, one sample per
        // second, so intermediate leading-sample speeds are non-zero (the
        // rectangle-rule distance + RPA terms are then non-degenerate).
        final samples = <TripSample>[
          for (var i = 0; i <= 10; i++)
            _s(t0.add(Duration(seconds: i)), i * 3.6), // i m/s in km/h
        ];
        final f = GpsDrivingFeatures.from(samples)!;
        // PKE = ∑(v_f² − v_i²)⁺ / distance > 0 for a pure accel ramp.
        expect(f.positiveKineticEnergy, greaterThan(0));
        // RPA / VAPOS accumulate v·a over the accelerating interior.
        expect(f.relativePositiveAcceleration, greaterThan(0));
        expect(f.meanPositiveVa, greaterThan(0));
        // Pure acceleration → no coasting.
        expect(f.coastShare, 0);
      });

      test('a sustained cruise then gentle decel registers a coast share', () {
        // cruise 20 s at 50 km/h, then gently slow 50 → 40 km/h over 5 s
        // (−0.55 m/s², below the harsh-brake threshold → coasting).
        final samples = <TripSample>[
          for (var i = 0; i <= 20; i++)
            _s(t0.add(Duration(seconds: i)), 50),
          _s(t0.add(const Duration(seconds: 25)), 40),
        ];
        final f = GpsDrivingFeatures.from(samples)!;
        expect(f.coastShare, greaterThan(0));
        expect(f.coastShare, lessThanOrEqualTo(1.0));
      });

      test('climb energy per km tracks the altitude gain', () {
        // climb 100 m over a 1 km leg at 36 km/h (10 m/s).
        final samples = <TripSample>[
          for (var i = 0; i <= 100; i++)
            _s(t0.add(Duration(seconds: i)), 36, altM: 100.0 + i),
        ];
        final f = GpsDrivingFeatures.from(samples)!;
        // ~1000 m travelled, ~100 m climbed → ~100 m/km.
        expect(f.climbEnergyPerKm, greaterThan(50));
        expect(f.distanceKm, greaterThan(0.5));
      });

      test('zero-distance stream leaves all energy KPIs at 0', () {
        final samples = [_s(t0, 0), _s(t0.add(const Duration(seconds: 30)), 0)];
        final f = GpsDrivingFeatures.from(samples)!;
        expect(f.relativePositiveAcceleration, 0);
        expect(f.positiveKineticEnergy, 0);
        expect(f.meanPositiveVa, 0);
        expect(f.climbEnergyPerKm, 0);
      });
    });

    group('#2796 C7 movement-phase shares', () {
      test('a pure acceleration ramp is dominated by the accel phase', () {
        // 0 → 36 km/h in 1 m/s² steps — every interior interval accelerates.
        final samples = <TripSample>[
          for (var i = 0; i <= 10; i++) _s(t0.add(Duration(seconds: i)), i * 3.6),
        ];
        final f = GpsDrivingFeatures.from(samples)!;
        expect(f.accelShare, greaterThan(0.5));
        expect(f.coastShare, 0);
      });

      test('accel + steady + coast shares sum to ~1 over moving time', () {
        // Accelerate 0→50, hold 50 for 20 s, then gently coast 50→40.
        final samples = <TripSample>[
          for (var i = 0; i <= 5; i++) _s(t0.add(Duration(seconds: i)), i * 10.0),
          for (var i = 6; i <= 25; i++) _s(t0.add(Duration(seconds: i)), 50),
          _s(t0.add(const Duration(seconds: 30)), 40),
        ];
        final f = GpsDrivingFeatures.from(samples)!;
        expect(f.accelShare, greaterThan(0));
        expect(f.steadyShare, greaterThan(0));
        expect(f.coastShare, greaterThan(0));
        expect(
          f.accelShare + f.steadyShare + f.coastShare,
          closeTo(1.0, 0.001),
        );
      });

      test('low/cruise/high speed-band shares match the integration edges', () {
        // 30 s in town (30 km/h), 30 s cruise (80 km/h), 30 s fast (120 km/h).
        final samples = <TripSample>[
          for (var i = 0; i < 30; i++) _s(t0.add(Duration(seconds: i)), 30),
          for (var i = 30; i < 60; i++) _s(t0.add(Duration(seconds: i)), 80),
          for (var i = 60; i <= 90; i++) _s(t0.add(Duration(seconds: i)), 120),
        ];
        final f = GpsDrivingFeatures.from(samples)!;
        expect(f.lowSpeedShare, closeTo(1 / 3, 0.05));
        expect(f.cruiseShare, closeTo(1 / 3, 0.05));
        expect(f.highSpeedShare, closeTo(1 / 3, 0.05));
        expect(f.idleShare, closeTo(0, 0.05));
      });

      test('all phase/band shares default to 0 on the const constructor', () {
        const f = GpsDrivingFeatures(
          idleSeconds: 0,
          lowSpeedSeconds: 0,
          cruiseSeconds: 0,
          highSpeedSeconds: 0,
          accelEvents: 0,
          brakeEvents: 0,
          maxAccelG: 0,
          meanSpeedKmh: 0,
          distanceKm: 0,
          totalSeconds: 0,
          gradeClimbMeters: 0,
          gradeDescentMeters: 0,
          cornerLoadIntegral: 0,
        );
        expect(f.accelShare, 0);
        expect(f.steadyShare, 0);
      });
    });

    group('stationary GPS jitter must not inflate distance/meanSpeed/climb '
        '(#3412)', () {
      // A parked phone: Doppler speed ≈ 0 (idle) but the fix wanders ~22 m
      // (0.0002°) back and forth every second and the altitude bounces ±15 m.
      // Pre-fix the ungated haversine + altitude integrators piled this jitter
      // into ~km of phantom distance (meanSpeed 276 km/h on a 0.3 km trip) and
      // ~100 m of phantom climb.
      Iterable<TripSample> stationaryJitter({required int seconds}) sync* {
        for (var i = 0; i <= seconds; i++) {
          final wob = i.isEven ? 0.0002 : -0.0002; // ~22 m east/west wobble
          final altWob = i.isEven ? 15.0 : -15.0; // ±15 m altitude noise
          yield _s(
            t0.add(Duration(seconds: i)),
            i.isEven ? 0.0 : 1.5, // Doppler speed stays sub-5 km/h (idle)
            lat: 48.85 + wob,
            lng: 2.35,
            altM: 100.0 + altWob,
            hAccuracyM: 8, // an "accurate" fix — the wander is real GPS noise
          );
        }
      }

      test('a standstill with jittering lat/lon yields ~0 distance and a sane '
          'meanSpeedKmh', () {
        final f = GpsDrivingFeatures.from(stationaryJitter(seconds: 120))!;
        // All time is idle (speed < 5).
        expect(f.idleSeconds, closeTo(120.0, 0.5));
        // The wander must NOT have accumulated into distance.
        expect(f.distanceKm, lessThan(0.05),
            reason: 'standstill jitter must not become real distance');
        // And meanSpeed must stay physically sane (was 276 km/h).
        expect(f.meanSpeedKmh, lessThan(5.0),
            reason: 'a parked car cannot average tens of km/h');
      });

      test('a standstill with altitude noise yields ~0 phantom climb', () {
        final f = GpsDrivingFeatures.from(stationaryJitter(seconds: 120))!;
        expect(f.gradeClimbMeters, lessThan(2.0),
            reason: 'altitude jitter at a standstill must not become climb');
      });

      test('a genuinely moving trip with accurate fixes still measures '
          'distance (no over-gating)', () {
        // ~30 km/h east: each 1 s step advances ~8.3 m. Over 60 s ≈ 500 m.
        Iterable<TripSample> moving() sync* {
          for (var i = 0; i <= 60; i++) {
            yield _s(
              t0.add(Duration(seconds: i)),
              30,
              lat: 48.85,
              lng: 2.35 + i * 0.0001, // ~7.3 m/step east at this latitude
              hAccuracyM: 6,
            );
          }
        }

        final f = GpsDrivingFeatures.from(moving())!;
        expect(f.distanceKm, greaterThan(0.3),
            reason: 'real motion must still accumulate distance');
        expect(f.meanSpeedKmh, greaterThan(15.0));
      });
    });
  });
}
