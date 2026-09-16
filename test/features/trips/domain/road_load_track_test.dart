// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4203 — the road-load feature track: grade with confidence (steep climbs,
// GPS noise, tunnels, poor accuracy), curvature that is unknown rather than
// straight when bearing cannot be trusted, curves classified by how they
// were approached (slowing for a bend is not waste), stop/start traffic, and
// accelerate→brake→accelerate as ONE episode.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/road_load_track.dart';
import 'package:tankstellen/features/trips/domain/trip_sample.dart';

final _t0 = DateTime.utc(2026, 9, 15, 8);

TripSample _s(int second, double kmh,
        {double? alt, double? bearing, double? acc = 5}) =>
    TripSample(
      timestamp: _t0.add(Duration(seconds: second)),
      speedKmh: kmh,
      altitudeM: alt,
      bearingDeg: bearing,
      hAccuracyM: acc,
    );

void main() {
  group('grade', () {
    test('a steady 5 % climb is a confident ≈5 % grade', () {
      // 72 km/h = 20 m/s → +1 m of altitude per second on a 5 % grade.
      final track = RoadLoadTrack.from(
          [for (var i = 0; i < 60; i++) _s(i, 72, alt: 100.0 + i)]);
      final g = track.points.last.grade;
      expect(g.confident, isTrue);
      expect(g.gradeFraction, closeTo(0.05, 0.01));
    });

    test('GPS altitude noise on a flat road does not become a steep grade',
        () {
      var seed = 7;
      double noise() {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        return (seed % 1000) / 1000 * 10 - 5; // ±5 m
      }

      final track = RoadLoadTrack.from(
          [for (var i = 0; i < 120; i++) _s(i, 72, alt: 200 + noise())]);
      for (final p in track.points.where((p) => p.grade.confident)) {
        expect(p.grade.gradeFraction.abs(), lessThan(0.05));
      }
    });

    test('a tunnel (no altitude) drops confidence instead of keeping the '
        'grade from before it', () {
      final track = RoadLoadTrack.from([
        for (var i = 0; i < 30; i++) _s(i, 72, alt: 100.0 + i),
        for (var i = 30; i < 50; i++) _s(i, 72), // 400 m without altitude
      ]);
      expect(track.points[29].grade.confident, isTrue);
      expect(track.points.last.grade.confident, isFalse);
    });

    test('an inaccurate fix contributes no altitude', () {
      final track = RoadLoadTrack.from(
          [for (var i = 0; i < 60; i++) _s(i, 72, alt: 100.0 + i, acc: 60)]);
      expect(track.gradeConfidenceShare, 0);
    });
  });

  group('curvature', () {
    test('a real turn from an inaccurate fix is unknown, not a curve', () {
      final track = RoadLoadTrack.from([
        for (var i = 0; i < 20; i++) _s(i, 40, bearing: i * 10.0, acc: 40),
      ]);
      expect(track.curves, isEmpty);
      expect(track.curvatureConfidenceShare, 0);
      expect(track.points.last.yawRateRadPerS, isNull);
    });

    List<TripSample> curveTrip({required bool lateBrake}) {
      final out = <TripSample>[];
      var t = 0;
      // Approach at 72 km/h, straight.
      for (; t < 10; t++) {
        out.add(_s(t, 72, bearing: 0));
      }
      // Slow to 36 km/h: either gradually over 8 s, or in the last 2 s.
      if (lateBrake) {
        for (var i = 0; i < 6; i++, t++) {
          out.add(_s(t, 72, bearing: 0));
        }
        out
          ..add(_s(t++, 54, bearing: 0))
          ..add(_s(t++, 36, bearing: 0));
      } else {
        for (var i = 1; i <= 8; i++, t++) {
          out.add(_s(t, 72 - 36 * i / 8, bearing: 0));
        }
      }
      // A 90° bend over 6 s at 36 km/h (15 °/s ≈ 0.26 rad/s).
      for (var i = 1; i <= 6; i++, t++) {
        out.add(_s(t, 36, bearing: 15.0 * i));
      }
      // Exit: burst back to 72 km/h in 2 s, or gently over 8 s.
      if (lateBrake) {
        out
          ..add(_s(t++, 54, bearing: 90))
          ..add(_s(t++, 72, bearing: 90));
      } else {
        for (var i = 1; i <= 8; i++, t++) {
          out.add(_s(t, 36 + 36 * i / 8, bearing: 90));
        }
      }
      for (var i = 0; i < 6; i++, t++) {
        out.add(_s(t, 72, bearing: 90));
      }
      return out;
    }

    test('slowing early and gently for a bend is smooth — not waste', () {
      final curves = RoadLoadTrack.from(curveTrip(lateBrake: false)).curves;
      expect(curves, hasLength(1));
      expect(curves.single.approach, CurveApproach.smooth);
      expect(curves.single.minSpeedMps, closeTo(10, 0.01));
    });

    test('hard braking at the bend then a burst out is flagged', () {
      final curves = RoadLoadTrack.from(curveTrip(lateBrake: true)).curves;
      expect(curves, hasLength(1));
      expect(curves.single.approach, CurveApproach.lateBrakeHardExit);
      expect(curves.single.entrySpeedMps, closeTo(20, 0.01));
    });
  });

  group('traffic and oscillation', () {
    test('stop/start traffic yields stops, not oscillations', () {
      final samples = <TripSample>[];
      var t = 0;
      for (var n = 0; n < 4; n++) {
        for (var i = 0; i < 5; i++, t++) {
          samples.add(_s(t, 0)); // waiting
        }
        for (var i = 1; i <= 5; i++, t++) {
          samples.add(_s(t, 6.0 * i)); // pull away to 30 km/h
        }
        for (var i = 4; i >= 0; i--, t++) {
          samples.add(_s(t, 6.0 * i)); // roll to a stop
        }
      }
      final track = RoadLoadTrack.from(samples);
      expect(track.stops.length, greaterThanOrEqualTo(3));
      expect(track.oscillations, isEmpty,
          reason: 'a stop between the phases is traffic, not an oscillation');
    });

    test('accelerate → brake → accelerate without stopping is ONE episode',
        () {
      final samples = <TripSample>[];
      var t = 0;
      for (var i = 0; i < 5; i++, t++) {
        samples.add(_s(t, 50));
      }
      for (var i = 1; i <= 4; i++, t++) {
        samples.add(_s(t, 50.0 + 8 * i)); // +2.2 m/s² to 82 km/h
      }
      for (var i = 1; i <= 4; i++, t++) {
        samples.add(_s(t, 82.0 - 9 * i)); // −2.5 m/s² to 46 km/h
      }
      for (var i = 1; i <= 4; i++, t++) {
        samples.add(_s(t, 46.0 + 8 * i)); // +2.2 m/s² again
      }
      for (var i = 0; i < 5; i++, t++) {
        samples.add(_s(t, 78));
      }
      final track = RoadLoadTrack.from(samples);
      expect(track.oscillations, hasLength(1));
      expect(track.stops, isEmpty);
    });
  });

  test('the trace exposes the derived features for validation', () {
    final trace = RoadLoadTrack.from(
        [for (var i = 0; i < 60; i++) _s(i, 72, alt: 100.0 + i)]).toTrace();
    expect(trace['points'], 60);
    expect(trace['gradeConfidenceShare'], greaterThan(0.5));
    expect(trace.keys,
        containsAll(['stops', 'curves', 'oscillations', 'curvatureConfidenceShare']));
  });
}
