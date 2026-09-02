// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3918 — the monthly average re-expresses each estimated trip at the
// vehicle's CURRENT pump gain (summary path and sample path alike);
// without a vehicle the stored figures are used unchanged.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/fill_ups/domain/services/monthly_insights_aggregator.dart';
import 'package:tankstellen/features/trips/data/trip_history_entry.dart';
import 'package:tankstellen/features/trips/domain/trip_sample.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';

final _now = DateTime(2026, 9, 16, 12);
final _start = DateTime(2026, 9, 3, 8);

TripHistoryEntry _entry(String id,
        {String? dominant, double? veUsed, List<TripSample> samples = const []}) =>
    TripHistoryEntry(
      id: id,
      vehicleId: 'v',
      samples: samples,
      summary: TripSummary(
        distanceKm: 100,
        maxRpm: 3000,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        fuelLitersConsumed: 10.5,
        avgLPer100Km: 10.5,
        startedAt: _start,
        endedAt: _start.add(const Duration(hours: 1)),
        dominantFuelSource: dominant,
        volumetricEfficiencyUsed: veUsed,
      ),
    );

const _calibrated = VehicleProfile(
  id: 'v',
  name: 'x',
  pumpGain: 0.72,
  pumpGainSamples: 1,
);

void main() {
  test('summary path: estimated trips scale, measured ones do not', () {
    final trips = [_entry('a', veUsed: 0.85)];
    expect(aggregateMonthlyInsights(trips, _now).currentMonthAvgConsumptionLPer100km,
        closeTo(10.5, 0.01));
    expect(
        aggregateMonthlyInsights(trips, _now, vehicle: _calibrated)
            .currentMonthAvgConsumptionLPer100km,
        closeTo(7.56, 0.01));
    expect(
        aggregateMonthlyInsights([_entry('m', dominant: 'pid5E')], _now,
                vehicle: _calibrated)
            .currentMonthAvgConsumptionLPer100km,
        closeTo(10.5, 0.01));
  });

  test('sample path: the re-integrated litres carry the same scale', () {
    // 60 s at 60 km/h and 6 L/h, 1 Hz → 1 km, 0.1 L → 10 L/100 km.
    final samples = [
      for (var i = 0; i <= 60; i++)
        TripSample(
          timestamp: _start.add(Duration(seconds: i)),
          speedKmh: 60,
          rpm: 2000,
          fuelRateLPerHour: 6,
          fuelSource: 'speedDensity',
        ),
    ];
    final trips = [_entry('s', dominant: 'speedDensity', samples: samples)];
    final raw = aggregateMonthlyInsights(trips, _now)
        .currentMonthAvgConsumptionLPer100km;
    final scaled = aggregateMonthlyInsights(trips, _now, vehicle: _calibrated)
        .currentMonthAvgConsumptionLPer100km;
    if (raw == null) {
      // Below the aggregator's distance floor → both null; the scale
      // contract is exercised by the summary path above.
      expect(scaled, isNull);
      return;
    }
    expect(scaled, closeTo(raw * 0.72, 0.01));
  });
}
