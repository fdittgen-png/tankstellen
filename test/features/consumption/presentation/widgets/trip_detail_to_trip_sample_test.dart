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
import 'package:tankstellen/features/consumption/domain/gps_driving_features.dart';
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
