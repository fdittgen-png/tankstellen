// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #2790 — the trip-detail screen recomputes GPS driving features from
// `widget.samples.map(tripDetailToTripSample)`. The reverse converter used to
// drop altitudeM/latitude/longitude, so the recomputed features showed climb
// energy 0 m/km (and speed×dt distance) even when the altitude track clearly
// climbed — while the altitude CHART looked right because it uses the other
// converter (toDetailSample) that keeps altitude. RED before the fix
// (climbEnergyPerKm == 0), GREEN after.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/accel_event_gate.dart';
import 'package:tankstellen/features/consumption/domain/gps_driving_features.dart';
import 'package:tankstellen/features/consumption/domain/trip_sample.dart';
import 'package:tankstellen/features/consumption/presentation/screens/trip_detail_sample_converter.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_detail_charts.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_detail_to_trip_sample.dart';

void main() {
  test('converter preserves altitude/lat/lng (round-trip)', () {
    final s = TripDetailSample(
      timestamp: DateTime(2026, 6, 3, 12),
      speedKmh: 30,
      latitude: 43.46,
      longitude: 3.42,
      altitudeM: 100.0,
    );
    final t = tripDetailToTripSample(s);
    expect(t.latitude, 43.46);
    expect(t.longitude, 3.42);
    expect(t.altitudeM, 100.0);
  });

  test('hAccuracyM survives BOTH converters so the accel-gate fires (#2963)',
      () {
    // A sustained hard-accel ramp where EVERY fix reports a bad accuracy
    // (> the 10 m kAccelEventAccuracyGateM). On master both converters
    // dropped hAccuracyM, so the round-tripped sample carried a null
    // accuracy = "accept" and `countAccelEvents` counted the GPS-derived
    // accel. After the fix the accuracy survives, the bad-fix gate fires,
    // and the count is 0.
    final start = DateTime(2026, 6, 3, 12);
    // ~3.3 m/s² per 1 s step (12 km/h/s), sustained well past the 1 s window.
    final domain = <TripSample>[
      for (var i = 0; i < 8; i++)
        TripSample(
          timestamp: start.add(Duration(seconds: i)),
          speedKmh: 10.0 + i * 12.0,
          hAccuracyM: 40.0, // bad fix — worse than the 10 m gate
        ),
    ];

    // Sanity: the SAME series WITHOUT accuracy counts the accel — proving
    // the ramp is genuinely above-threshold (this is what master scored).
    final noAccuracy = countAccelEvents([
      for (final s in domain)
        AccelSamplePoint(timestamp: s.timestamp, speedKmh: s.speedKmh),
    ]);
    expect(noAccuracy.accelEvents, greaterThan(0));

    // Round-trip through the REAL converters (forward then reverse), exactly
    // as the trip-detail screen does when it recomputes the saved-trip score.
    final roundTripped =
        domain.map(toDetailSample).map(tripDetailToTripSample).toList();
    expect(roundTripped.every((s) => s.hAccuracyM == 40.0), isTrue,
        reason: 'hAccuracyM must survive forward + reverse conversion');

    final gated = countAccelEvents([
      for (final s in roundTripped)
        AccelSamplePoint(
            timestamp: s.timestamp, speedKmh: s.speedKmh, hAccuracyM: s.hAccuracyM),
    ]);
    expect(gated.accelEvents, 0,
        reason: 'a bad-accuracy GPS-derived accel must be dropped end-to-end '
            'through the converters (the revived gate)');
  });

  test('recomputed GPS features keep a non-zero climb energy for a climbing '
      'GPS-only track (#2790)', () {
    final start = DateTime(2026, 6, 3, 12);
    final detail = <TripDetailSample>[
      for (var i = 0; i < 30; i++)
        TripDetailSample(
          timestamp: start.add(Duration(seconds: i)),
          speedKmh: 50, // moving — non-zero distance
          latitude: 43.46 + i * 0.0002, // ~22 m/step, a real ground track
          longitude: 3.42,
          altitudeM: 60.0 + i * 1.5, // climbs ~43 m over the track
        ),
    ];

    final features =
        GpsDrivingFeatures.from(detail.map(tripDetailToTripSample));
    expect(features, isNotNull);
    expect(features!.climbEnergyPerKm, greaterThan(0),
        reason: 'altitude must survive the converter so a real climb is not '
            'reported as 0 m/km on the trip-detail GPS-efficiency card');
  });
}
