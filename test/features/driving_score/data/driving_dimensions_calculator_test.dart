// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4205 — behaviour dimensions with value + confidence + evidence, judged in
// context: missing signals are unknown (never zero behaviour), a climb or a
// curve or a stop is not a penalty by itself, and a replay is deterministic.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/driving_score/data/driving_dimensions_calculator.dart';
import 'package:tankstellen/features/driving_score/domain/driving_dimensions.dart';
import 'package:tankstellen/features/trips/domain/trip_sample.dart';

final _t0 = DateTime.utc(2026, 9, 15, 8);

TripSample _s(int sec, double kmh,
        {double? rpm,
        double? pedal,
        double? alt,
        double? bearing,
        double? fuel,
        double acc = 5}) =>
    TripSample(
      timestamp: _t0.add(Duration(seconds: sec)),
      speedKmh: kmh,
      rpm: rpm,
      pedalPercent: pedal,
      altitudeM: alt,
      bearingDeg: bearing,
      fuelRateLPerHour: fuel,
      hAccuracyM: acc,
    );

void main() {
  test('a GPS-only trip leaves engine dimensions unknown, not perfect', () {
    final d = computeDrivingDimensions(
        [for (var i = 0; i < 400; i++) _s(i, 60)]);
    for (final kind in [
      DrivingDimensionKind.avoidableIdle,
      DrivingDimensionKind.powertrainOperation,
      DrivingDimensionKind.coasting,
    ]) {
      expect(d[kind].value, isNull, reason: kind.name);
      expect(d[kind].confidence, DimensionConfidence.none);
    }
  });

  group('hills', () {
    List<TripSample> trip({required double climbPedal}) => [
          // 3 min flat at gentle demand, then 3 min on a 5 % climb.
          for (var i = 0; i < 180; i++) _s(i, 72, rpm: 2000, pedal: 30, alt: 100),
          for (var i = 0; i < 180; i++)
            _s(180 + i, 72, rpm: 2400, pedal: climbPedal, alt: 100.0 + i),
        ];

    test('climbing at moderate demand is not a penalty', () {
      final hill = computeDrivingDimensions(trip(climbPedal: 55))[
          DrivingDimensionKind.hillBehaviour];
      expect(hill.value, 1.0);
      expect(hill.confidence.index,
          greaterThanOrEqualTo(DimensionConfidence.medium.index));
    });

    test('flooring it on the climb beyond the flat habit is an opportunity',
        () {
      final hill = computeDrivingDimensions(trip(climbPedal: 95))[
          DrivingDimensionKind.hillBehaviour];
      expect(hill.value, lessThan(0.5));
    });
  });

  group('braking in context', () {
    test('hard braking that ends in a stop is traffic, not late braking', () {
      final samples = <TripSample>[];
      var t = 0;
      for (var n = 0; n < 3; n++) {
        for (var i = 0; i < 20; i++, t++) {
          samples.add(_s(t, 50, rpm: 1800));
        }
        for (var i = 1; i <= 3; i++, t++) {
          samples.add(_s(t, 50.0 - 16 * i, rpm: 1500)); // ≈ −4.4 m/s²
        }
        for (var i = 0; i < 10; i++, t++) {
          samples.add(_s(t, 0, rpm: 800));
        }
      }
      final braking = computeDrivingDimensions(samples)[
          DrivingDimensionKind.brakingAnticipation];
      expect(braking.evidenceCount, greaterThan(0));
      expect(braking.value, 1.0, reason: braking.context);
    });
  });

  test('long idling is an opportunity; red-light stops are not', () {
    List<TripSample> withStops(int stopSeconds) {
      final out = <TripSample>[];
      var t = 0;
      for (var n = 0; n < 3; n++) {
        for (var i = 0; i < 120; i++, t++) {
          out.add(_s(t, 50, rpm: 1800));
        }
        for (var i = 0; i < stopSeconds; i++, t++) {
          out.add(_s(t, 0, rpm: 800));
        }
      }
      return out;
    }

    final lights = computeDrivingDimensions(withStops(40))[
        DrivingDimensionKind.avoidableIdle];
    final parked = computeDrivingDimensions(withStops(300))[
        DrivingDimensionKind.avoidableIdle];
    expect(lights.value, 1.0);
    expect(parked.value, lessThan(lights.value!));
  });

  test('top opportunities: at most three, known, confident, worst first', () {
    final samples = [
      for (var i = 0; i < 180; i++) _s(i, 72, rpm: 2000, pedal: 30, alt: 100),
      for (var i = 0; i < 180; i++)
        _s(180 + i, 72, rpm: 3600, pedal: 95, alt: 100.0 + i),
    ];
    final top = computeDrivingDimensions(samples).topOpportunities();
    expect(top.length, lessThanOrEqualTo(3));
    for (final d in top) {
      expect(d.value, isNotNull);
      expect(d.confidence.index,
          greaterThanOrEqualTo(DimensionConfidence.medium.index));
    }
    for (var i = 1; i < top.length; i++) {
      expect(top[i - 1].value!, lessThanOrEqualTo(top[i].value!));
    }
  });

  test('a replay of the same samples yields the same dimensions', () {
    final samples = [for (var i = 0; i < 300; i++) _s(i, 40.0 + i % 20, rpm: 2100)];
    expect(computeDrivingDimensions(samples).toJson(),
        computeDrivingDimensions(samples).toJson());
  });
}
