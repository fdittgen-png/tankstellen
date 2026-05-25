// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/domain/trip_ve_recompute.dart';

/// Unit coverage for the retroactive η_v recompute (#1858).
void main() {
  TripHistoryEntry entry({
    required String id,
    double? veUsed,
    double? fuel,
    double? avg,
    String vehicleId = 'veh-1',
  }) =>
      TripHistoryEntry(
        id: id,
        vehicleId: vehicleId,
        summary: TripSummary(
          distanceKm: 100,
          maxRpm: 3000,
          highRpmSeconds: 0,
          idleSeconds: 0,
          harshBrakes: 0,
          harshAccelerations: 0,
          fuelLitersConsumed: fuel,
          avgLPer100Km: avg,
          volumetricEfficiencyUsed: veUsed,
        ),
      );

  group('recomputeTripForVe', () {
    test('rescales a recalculable trip and re-stamps the η_v', () {
      // η_v 0.80 → 0.90: speed-density fuel scales ×(0.90/0.80) = 1.125.
      final t = entry(id: 't1', veUsed: 0.80, fuel: 4.0, avg: 8.0);
      final r = recomputeTripForVe(t, 0.90);

      expect(r.summary.fuelLitersConsumed, closeTo(4.5, 1e-9));
      expect(r.summary.avgLPer100Km, closeTo(9.0, 1e-9));
      expect(r.summary.volumetricEfficiencyUsed, 0.90,
          reason: 're-stamped so a later η_v change rescales from the '
              'new basis');
    });

    test('leaves a not-recalculable trip (null volumetricEfficiencyUsed) '
        'untouched — returns the identical instance', () {
      final t = entry(id: 't2', veUsed: null, fuel: 3.0, avg: 6.0);
      final r = recomputeTripForVe(t, 0.90);

      expect(identical(r, t), isTrue,
          reason: 'a legacy / PID-5E / MAF trip carries no η_v provenance '
              'and must not be rescaled');
    });

    test('is a no-op when newVe already matches the stamped η_v', () {
      final t = entry(id: 't3', veUsed: 0.85, fuel: 3.0);
      expect(identical(recomputeTripForVe(t, 0.85), t), isTrue);
    });

    test('preserves id and vehicleId while rescaling the summary', () {
      final t = entry(id: 't4', veUsed: 0.80, fuel: 4.0, vehicleId: 'veh-x');
      final r = recomputeTripForVe(t, 0.88);
      expect(r.id, 't4');
      expect(r.vehicleId, 'veh-x');
      expect(r.summary.fuelLitersConsumed, closeTo(4.0 * 0.88 / 0.80, 1e-9));
    });
  });

  group('recomputeTripsForVe', () {
    test('rescales recalculable trips and passes the rest through', () {
      final trips = [
        entry(id: 'a', veUsed: 0.80, fuel: 4.0, avg: 8.0),
        entry(id: 'b', veUsed: null, fuel: 5.0, avg: 10.0),
      ];
      final out = recomputeTripsForVe(trips, 0.90);

      expect(out[0].summary.fuelLitersConsumed, closeTo(4.5, 1e-9));
      expect(identical(out[1], trips[1]), isTrue,
          reason: 'the not-recalculable trip is untouched');
      expect(out, hasLength(2));
    });
  });
}
