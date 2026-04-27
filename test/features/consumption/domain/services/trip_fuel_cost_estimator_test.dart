import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/services/trip_fuel_cost_estimator.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Pure-helper coverage for #1209's trip fuel-cost estimator.
///
/// Each test builds the smallest [TripHistoryEntry] / [FillUp] pair
/// the case requires. No real fixtures, no Riverpod, no Hive — the
/// helper is intentionally pure so the gates can be verified with
/// synthetic data.
void main() {
  group('estimateTripFuelCost', () {
    test('multiplies fuelLitersConsumed by the most recent eligible '
        'fill-up\'s pricePerLiter', () {
      final trip = _trip(
        fuelLitersConsumed: 0.27,
        startedAt: DateTime(2026, 4, 25, 14),
      );
      final fillUp = _fillUp(
        date: DateTime(2026, 4, 24, 9),
        liters: 40,
        // pricePerLiter = totalCost / liters = 66 / 40 = 1.65
        totalCost: 66,
      );

      final cost = estimateTripFuelCost(
        trip: trip,
        fillUpsForVehicle: [fillUp],
      );

      // 0.27 × 1.65 = 0.4455 — let the test float-compare on a tight
      // tolerance so a floating-point round-trip doesn't mislead a
      // future reader chasing a real regression.
      expect(cost, isNotNull);
      expect(cost!, closeTo(0.4455, 1e-9));
    });

    test('returns null when fuelLitersConsumed is null', () {
      final trip = _trip(
        fuelLitersConsumed: null,
        startedAt: DateTime(2026, 4, 25, 14),
      );
      final fillUp = _fillUp(
        date: DateTime(2026, 4, 24, 9),
        liters: 40,
        totalCost: 66,
      );

      expect(
        estimateTripFuelCost(trip: trip, fillUpsForVehicle: [fillUp]),
        isNull,
      );
    });

    test('returns null when startedAt is null', () {
      final trip = _trip(fuelLitersConsumed: 0.27, startedAt: null);
      final fillUp = _fillUp(
        date: DateTime(2026, 4, 24, 9),
        liters: 40,
        totalCost: 66,
      );

      expect(
        estimateTripFuelCost(trip: trip, fillUpsForVehicle: [fillUp]),
        isNull,
      );
    });

    test('returns null when there are no fill-ups for the vehicle', () {
      final trip = _trip(
        fuelLitersConsumed: 0.27,
        startedAt: DateTime(2026, 4, 25, 14),
      );

      expect(
        estimateTripFuelCost(trip: trip, fillUpsForVehicle: const []),
        isNull,
      );
    });

    test('returns null when every fill-up is dated AFTER the trip start',
        () {
      final trip = _trip(
        fuelLitersConsumed: 0.27,
        startedAt: DateTime(2026, 4, 25, 14),
      );
      // Both fill-ups are strictly after the trip start, so neither
      // can supply a "what did I pay before this drive?" baseline.
      final fillUps = [
        _fillUp(
          date: DateTime(2026, 4, 25, 18),
          liters: 40,
          totalCost: 66,
        ),
        _fillUp(
          date: DateTime(2026, 4, 26, 9),
          liters: 30,
          totalCost: 50,
        ),
      ];

      expect(
        estimateTripFuelCost(trip: trip, fillUpsForVehicle: fillUps),
        isNull,
      );
    });

    test(
        'walks back to the next fill-up when the most recent has no usable '
        'pricePerLiter (zero litres)', () {
      final trip = _trip(
        fuelLitersConsumed: 0.27,
        startedAt: DateTime(2026, 4, 25, 14),
      );
      // Newest first: the recent fill-up has liters == 0, so its
      // [FillUpX.pricePerLiter] falls back to 0 — the helper must
      // skip it and use the older one with a real price.
      final fillUps = [
        _fillUp(
          date: DateTime(2026, 4, 25, 8),
          liters: 0,
          totalCost: 0,
        ),
        _fillUp(
          date: DateTime(2026, 4, 20, 9),
          liters: 40,
          totalCost: 66, // 1.65 €/L
        ),
      ];

      final cost = estimateTripFuelCost(
        trip: trip,
        fillUpsForVehicle: fillUps,
      );
      expect(cost, isNotNull);
      expect(cost!, closeTo(0.27 * 1.65, 1e-9));
    });

    test('uses the NEWEST eligible fill-up when several pre-date the trip',
        () {
      final trip = _trip(
        fuelLitersConsumed: 1.0,
        startedAt: DateTime(2026, 4, 25, 14),
      );
      // List is documented "newest first" so the helper must trust
      // that order — pick the first match it walks to.
      final fillUps = [
        _fillUp(
          date: DateTime(2026, 4, 24, 9),
          liters: 40,
          totalCost: 80, // 2.00 €/L — the one we WANT
        ),
        _fillUp(
          date: DateTime(2026, 4, 1, 9),
          liters: 40,
          totalCost: 60, // 1.50 €/L — older, must NOT be picked
        ),
      ];

      final cost = estimateTripFuelCost(
        trip: trip,
        fillUpsForVehicle: fillUps,
      );
      expect(cost, isNotNull);
      expect(cost!, closeTo(2.0, 1e-9));
    });

    test('treats an exact tie (fill-up date == trip start) as eligible', () {
      // The helper skips fill-ups that are strictly AFTER the trip
      // start — equal timestamps still count, so a fill-up logged at
      // the trip's exact start (e.g. user filled up then immediately
      // drove away) supplies the price.
      final start = DateTime(2026, 4, 25, 14);
      final trip = _trip(fuelLitersConsumed: 0.5, startedAt: start);
      final fillUp = _fillUp(date: start, liters: 50, totalCost: 75);

      final cost = estimateTripFuelCost(
        trip: trip,
        fillUpsForVehicle: [fillUp],
      );
      expect(cost, isNotNull);
      expect(cost!, closeTo(0.5 * 1.50, 1e-9));
    });
  });
}

TripHistoryEntry _trip({
  required double? fuelLitersConsumed,
  required DateTime? startedAt,
  String id = 'trip-1',
  String? vehicleId = 'v1',
}) {
  return TripHistoryEntry(
    id: id,
    vehicleId: vehicleId,
    summary: TripSummary(
      distanceKm: 10,
      maxRpm: 0,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      fuelLitersConsumed: fuelLitersConsumed,
      startedAt: startedAt,
      distanceSource: 'virtual',
    ),
  );
}

FillUp _fillUp({
  required DateTime date,
  required double liters,
  required double totalCost,
  String id = 'f-1',
  String vehicleId = 'v1',
}) {
  return FillUp(
    id: id,
    date: date,
    liters: liters,
    totalCost: totalCost,
    odometerKm: 0,
    fuelType: FuelType.e10,
    vehicleId: vehicleId,
  );
}
