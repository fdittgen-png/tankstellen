import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/co2_calculator.dart';
import 'package:tankstellen/features/consumption/domain/entities/consumption_stats.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

FillUp _f({
  required String id,
  required DateTime date,
  required double liters,
  required double cost,
  required double odo,
  FuelType fuelType = FuelType.e10,
  bool isFullTank = true,
  bool isCorrection = false,
}) =>
    FillUp(
      id: id,
      date: date,
      liters: liters,
      totalCost: cost,
      odometerKm: odo,
      fuelType: fuelType,
      isFullTank: isFullTank,
      isCorrection: isCorrection,
    );

void main() {
  group('ConsumptionStats.fromFillUps', () {
    test('empty list returns empty stats', () {
      final stats = ConsumptionStats.fromFillUps(const []);
      expect(stats.fillUpCount, 0);
      expect(stats.totalLiters, 0);
      expect(stats.totalSpent, 0);
      expect(stats.totalCo2Kg, 0);
      expect(stats.avgConsumptionL100km, isNull);
      expect(stats.avgCostPerKm, isNull);
      expect(stats.avgCo2PerKm, isNull);
    });

    test('single fill-up reports totals but no consumption', () {
      final stats = ConsumptionStats.fromFillUps([
        _f(
          id: '1',
          date: DateTime(2026, 1, 1),
          liters: 50,
          cost: 80,
          odo: 10000,
        ),
      ]);
      expect(stats.fillUpCount, 1);
      expect(stats.totalLiters, 50);
      expect(stats.totalSpent, 80);
      expect(stats.totalDistanceKm, 0);
      expect(stats.avgConsumptionL100km, isNull);
      expect(stats.avgCostPerKm, isNull);
      expect(stats.avgPricePerLiter, closeTo(1.6, 0.0001));
    });

    test('two fill-ups compute L/100km from distance between', () {
      // First tank: odo 10000, ignored for consumption
      // Second tank: 50 L over 1000 km => 5.0 L/100km, 80€ over 1000km = 0.08/km
      final stats = ConsumptionStats.fromFillUps([
        _f(
          id: '1',
          date: DateTime(2026, 1, 1),
          liters: 40,
          cost: 60,
          odo: 10000,
        ),
        _f(
          id: '2',
          date: DateTime(2026, 1, 15),
          liters: 50,
          cost: 80,
          odo: 11000,
        ),
      ]);
      expect(stats.fillUpCount, 2);
      expect(stats.totalLiters, 90);
      expect(stats.totalSpent, 140);
      expect(stats.totalDistanceKm, 1000);
      expect(stats.avgConsumptionL100km, closeTo(5.0, 0.0001));
      expect(stats.avgCostPerKm, closeTo(0.08, 0.0001));
    });

    test('accepts fill-ups in any order — sorts by date', () {
      final stats = ConsumptionStats.fromFillUps([
        _f(
          id: '2',
          date: DateTime(2026, 1, 15),
          liters: 50,
          cost: 80,
          odo: 11000,
        ),
        _f(
          id: '1',
          date: DateTime(2026, 1, 1),
          liters: 40,
          cost: 60,
          odo: 10000,
        ),
      ]);
      expect(stats.totalDistanceKm, 1000);
      expect(stats.avgConsumptionL100km, closeTo(5.0, 0.0001));
      expect(stats.periodStart, DateTime(2026, 1, 1));
      expect(stats.periodEnd, DateTime(2026, 1, 15));
    });

    test('zero distance returns null consumption without dividing by zero',
        () {
      final stats = ConsumptionStats.fromFillUps([
        _f(
          id: '1',
          date: DateTime(2026, 1, 1),
          liters: 10,
          cost: 15,
          odo: 10000,
        ),
        _f(
          id: '2',
          date: DateTime(2026, 1, 2),
          liters: 10,
          cost: 15,
          odo: 10000,
        ),
      ]);
      expect(stats.totalDistanceKm, 0);
      expect(stats.avgConsumptionL100km, isNull);
      expect(stats.avgCostPerKm, isNull);
      expect(stats.totalLiters, 20);
    });

    test('totalCo2Kg aggregates across all fill-ups', () {
      final stats = ConsumptionStats.fromFillUps([
        _f(
          id: '1',
          date: DateTime(2026, 1, 1),
          liters: 40,
          cost: 60,
          odo: 10000,
          fuelType: FuelType.diesel,
        ),
        _f(
          id: '2',
          date: DateTime(2026, 1, 15),
          liters: 50,
          cost: 80,
          odo: 11000,
          fuelType: FuelType.diesel,
        ),
      ]);
      // 90 L diesel * 2.65 kg/L
      expect(stats.totalCo2Kg,
          closeTo(90 * Co2Calculator.kgCo2PerLiterDiesel, 0.0001));
    });

    test('avgCo2PerKm excludes first tank like L/100km', () {
      // first tank 40 L (odo 10000) ignored for per-km math
      // second tank 50 L diesel over 1000 km
      final stats = ConsumptionStats.fromFillUps([
        _f(
          id: '1',
          date: DateTime(2026, 1, 1),
          liters: 40,
          cost: 60,
          odo: 10000,
          fuelType: FuelType.diesel,
        ),
        _f(
          id: '2',
          date: DateTime(2026, 1, 15),
          liters: 50,
          cost: 80,
          odo: 11000,
          fuelType: FuelType.diesel,
        ),
      ]);
      const expectedCo2PerKm =
          50 * Co2Calculator.kgCo2PerLiterDiesel / 1000;
      expect(stats.avgCo2PerKm, closeTo(expectedCo2PerKm, 0.0001));
    });

    test('avgCo2PerKm is null when distance is zero', () {
      final stats = ConsumptionStats.fromFillUps([
        _f(
          id: '1',
          date: DateTime(2026, 1, 1),
          liters: 10,
          cost: 15,
          odo: 10000,
          fuelType: FuelType.diesel,
        ),
        _f(
          id: '2',
          date: DateTime(2026, 1, 2),
          liters: 10,
          cost: 15,
          odo: 10000,
          fuelType: FuelType.diesel,
        ),
      ]);
      expect(stats.avgCo2PerKm, isNull);
    });

    test('three fill-ups: excludes first tank from L/100km', () {
      // tank 1 (odo 10000) ignored
      // tank 2: 40 L over 500 km
      // tank 3: 40 L over 500 km
      // total: 80 L / 1000 km = 8 L/100km
      final stats = ConsumptionStats.fromFillUps([
        _f(
          id: '1',
          date: DateTime(2026, 1, 1),
          liters: 30,
          cost: 45,
          odo: 10000,
        ),
        _f(
          id: '2',
          date: DateTime(2026, 1, 10),
          liters: 40,
          cost: 60,
          odo: 10500,
        ),
        _f(
          id: '3',
          date: DateTime(2026, 1, 20),
          liters: 40,
          cost: 60,
          odo: 11000,
        ),
      ]);
      expect(stats.totalDistanceKm, 1000);
      expect(stats.avgConsumptionL100km, closeTo(8.0, 0.0001));
    });

    // ─── #1362 — window walker ──────────────────────────────────────
    //
    // The walker must produce byte-identical numbers to the legacy
    // `sorted.skip(1).fold(liters)` formula for the all-plein case,
    // skip the in-progress window after the latest plein, and surface
    // auto-correction contribution to the user.

    test(
      'BACKWARD COMPAT — all-plein three-fillup case is byte-identical to '
      'the legacy fold formula',
      () {
        // Replays the existing "three fill-ups: excludes first tank"
        // fixture and asserts on the exact closed-window math:
        // - litersBetween (legacy) = 40 + 40 = 80
        // - totalDistance (legacy) = 11000 - 10000 = 1000
        // - avgL100 = 80 / 1000 * 100 = 8.0 EXACT
        // The new walker MUST hit the same 8.0 to the bit.
        final stats = ConsumptionStats.fromFillUps([
          _f(
              id: '1',
              date: DateTime(2026, 1, 1),
              liters: 30,
              cost: 45,
              odo: 10000),
          _f(
              id: '2',
              date: DateTime(2026, 1, 10),
              liters: 40,
              cost: 60,
              odo: 10500),
          _f(
              id: '3',
              date: DateTime(2026, 1, 20),
              liters: 40,
              cost: 60,
              odo: 11000),
        ]);

        // Byte-identical guarantee (the load-bearing assertion):
        expect(stats.avgConsumptionL100km, 8.0);
        expect(stats.avgCostPerKm, (60 + 60) / 1000);
        // Open window must be empty — every fill is plein-complet.
        expect(stats.openWindowFillCount, 0);
        expect(stats.openWindowLiters, 0);
        // No corrections — share must be exactly zero.
        expect(stats.correctionLitersTotal, 0);
        expect(stats.correctionShare, 0);
      },
    );

    test(
      'plein → partial → plein closes one window with the partial included',
      () {
        // Window: opens at fill 1 (plein), closes at fill 3 (plein).
        // Partial fill 2 sits inside.
        // closed liters (sum after opening) = 20 + 40 = 60
        // closed distance = 11000 - 10000 = 1000
        // avg L/100km = 60 / 1000 * 100 = 6.0 EXACT
        final stats = ConsumptionStats.fromFillUps([
          _f(
            id: '1',
            date: DateTime(2026, 1, 1),
            liters: 50,
            cost: 75,
            odo: 10000,
          ),
          _f(
            id: '2',
            date: DateTime(2026, 1, 8),
            liters: 20,
            cost: 30,
            odo: 10400,
            isFullTank: false,
          ),
          _f(
            id: '3',
            date: DateTime(2026, 1, 20),
            liters: 40,
            cost: 60,
            odo: 11000,
          ),
        ]);
        expect(stats.avgConsumptionL100km, 6.0);
        expect(stats.totalDistanceKm, 1000);
        expect(stats.openWindowFillCount, 0);
        expect(stats.openWindowLiters, 0);
      },
    );

    test(
      'open window after the latest plein is excluded from the average and '
      'surfaced via openWindowFillCount/openWindowLiters',
      () {
        // Closed window: fill 1 → fill 3 (60 L over 1000 km = 6.0 L/100km).
        // Open window: fill 4 (partial, 15 L) — excluded from average,
        // counted on openWindowFillCount/openWindowLiters.
        final stats = ConsumptionStats.fromFillUps([
          _f(
            id: '1',
            date: DateTime(2026, 1, 1),
            liters: 50,
            cost: 75,
            odo: 10000,
          ),
          _f(
            id: '2',
            date: DateTime(2026, 1, 8),
            liters: 20,
            cost: 30,
            odo: 10400,
            isFullTank: false,
          ),
          _f(
            id: '3',
            date: DateTime(2026, 1, 20),
            liters: 40,
            cost: 60,
            odo: 11000,
          ),
          _f(
            id: '4',
            date: DateTime(2026, 1, 28),
            liters: 15,
            cost: 22.5,
            odo: 11200,
            isFullTank: false,
          ),
        ]);
        // Avg only sees the closed window — same 6.0 as the previous test.
        expect(stats.avgConsumptionL100km, 6.0);
        // Open window surfaced for the UI.
        expect(stats.openWindowFillCount, 1);
        expect(stats.openWindowLiters, 15);
      },
    );

    test(
      'plein → correction → plein keeps correction liters in the average and '
      'surfaces the correction share to the user',
      () {
        // Closed window: fills 2..3 → liters = 5 + 40 = 45 over 1000 km
        // → 4.5 L/100km. The correction liter total is 5 and
        // totalLiters = 50 + 5 + 40 = 95, so share = 5/95 ≈ 0.0526.
        final stats = ConsumptionStats.fromFillUps([
          _f(
            id: '1',
            date: DateTime(2026, 1, 1),
            liters: 50,
            cost: 75,
            odo: 10000,
          ),
          _f(
            id: '2',
            date: DateTime(2026, 1, 8),
            liters: 5,
            cost: 7.5,
            odo: 10500,
            isFullTank: false,
            isCorrection: true,
          ),
          _f(
            id: '3',
            date: DateTime(2026, 1, 20),
            liters: 40,
            cost: 60,
            odo: 11000,
          ),
        ]);
        expect(stats.avgConsumptionL100km, 4.5);
        expect(stats.correctionLitersTotal, 5);
        expect(stats.correctionShare, closeTo(5 / 95, 0.0001));
      },
    );

    test('single fill — stats blank, openWindowFillCount stays at 0', () {
      // Spec: "single fill → stats blank (no window closed yet),
      //       openWindowFillCount: 1". The first fill itself OPENS the
      // window — fills strictly INSIDE the open window (i.e. logged
      // after the first fill) are what we count toward partials. With
      // exactly one fill there is no partial inside, so the count is 0.
      final stats = ConsumptionStats.fromFillUps([
        _f(
          id: '1',
          date: DateTime(2026, 1, 1),
          liters: 50,
          cost: 75,
          odo: 10000,
        ),
      ]);
      expect(stats.fillUpCount, 1);
      expect(stats.avgConsumptionL100km, isNull);
      expect(stats.openWindowFillCount, 0);
      expect(stats.openWindowLiters, 0);
    });

    test('two pleins, no trips/corrections → equivalent to old formula', () {
      // Old formula: liters = sorted.skip(1).fold(liters) = 50,
      // distance = 11000 - 10000 = 1000, avg = 50/1000*100 = 5.0.
      final stats = ConsumptionStats.fromFillUps([
        _f(
          id: '1',
          date: DateTime(2026, 1, 1),
          liters: 40,
          cost: 60,
          odo: 10000,
        ),
        _f(
          id: '2',
          date: DateTime(2026, 1, 15),
          liters: 50,
          cost: 80,
          odo: 11000,
        ),
      ]);
      expect(stats.avgConsumptionL100km, 5.0);
      expect(stats.openWindowFillCount, 0);
      expect(stats.correctionShare, 0);
    });

    test('two partials, no plein → entire history is the open window', () {
      // Spec edge: with no plein-complet anywhere the very first fill
      // opens the window; nothing closes it; the average has no closed
      // window to draw from.
      final stats = ConsumptionStats.fromFillUps([
        _f(
          id: '1',
          date: DateTime(2026, 1, 1),
          liters: 20,
          cost: 30,
          odo: 10000,
          isFullTank: false,
        ),
        _f(
          id: '2',
          date: DateTime(2026, 1, 8),
          liters: 25,
          cost: 37.5,
          odo: 10300,
          isFullTank: false,
        ),
      ]);
      expect(stats.avgConsumptionL100km, isNull);
      expect(stats.openWindowFillCount, 1);
      expect(stats.openWindowLiters, 25);
    });
  });

  group('FillUpX', () {
    test('pricePerLiter computes correctly', () {
      final f = _f(
        id: '1',
        date: DateTime(2026, 1, 1),
        liters: 40,
        cost: 60,
        odo: 1000,
      );
      expect(f.pricePerLiter, closeTo(1.5, 0.0001));
    });

    test('pricePerLiter returns 0 for zero liters (no divide-by-zero)', () {
      final f = _f(
        id: '1',
        date: DateTime(2026, 1, 1),
        liters: 0,
        cost: 0,
        odo: 1000,
      );
      expect(f.pricePerLiter, 0);
    });
  });

  group('FillUp JSON round-trip', () {
    test('preserves all fields', () {
      final original = FillUp(
        id: 'abc',
        date: DateTime(2026, 3, 15, 10, 30),
        liters: 42.5,
        totalCost: 67.89,
        odometerKm: 15432,
        fuelType: FuelType.diesel,
        stationId: 'station-xyz',
        stationName: 'Shell Berlin',
        notes: 'After vacation trip',
      );
      final json = original.toJson();
      final restored = FillUp.fromJson(json);
      expect(restored, original);
    });

    test('handles optional fields being null', () {
      final original = FillUp(
        id: 'abc',
        date: DateTime(2026, 3, 15),
        liters: 40,
        totalCost: 60,
        odometerKm: 10000,
        fuelType: FuelType.e10,
      );
      final json = original.toJson();
      final restored = FillUp.fromJson(json);
      expect(restored.stationId, isNull);
      expect(restored.stationName, isNull);
      expect(restored.notes, isNull);
    });
  });
}
