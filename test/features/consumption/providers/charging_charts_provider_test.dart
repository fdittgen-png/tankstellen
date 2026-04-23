import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/providers/charging_charts_provider.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';

/// #582 phase 3 — unit tests for the derived monthly-cost and
/// monthly-efficiency rollups. Exercising the pure functions keeps
/// the tests fast (no Hive, no Riverpod container) while mirroring
/// exactly the math the providers run.
void main() {
  ChargingLog log({
    required String id,
    required DateTime date,
    required int odometerKm,
    double kWh = 30,
    double costEur = 12,
    String vehicleId = 'v1',
  }) =>
      ChargingLog(
        id: id,
        vehicleId: vehicleId,
        date: date,
        kWh: kWh,
        costEur: costEur,
        chargeTimeMin: 20,
        odometerKm: odometerKm,
      );

  group('rollupMonthlyCost', () {
    test('three logs in the current month sum to the expected total', () {
      final now = DateTime.utc(2026, 4, 15);
      final result = rollupMonthlyCost(
        [
          log(
            id: 'a',
            date: DateTime.utc(2026, 4, 3),
            odometerKm: 10000,
            costEur: 10,
          ),
          log(
            id: 'b',
            date: DateTime.utc(2026, 4, 10),
            odometerKm: 10300,
            costEur: 18,
          ),
          log(
            id: 'c',
            date: DateTime.utc(2026, 4, 14),
            odometerKm: 10700,
            costEur: 22,
          ),
        ],
        now: now,
      );
      final april = DateTime.utc(2026, 4, 1);
      expect(result[april], 50);
    });

    test('no logs → every month maps to 0 (never absent, never null)', () {
      final now = DateTime.utc(2026, 4, 15);
      final result = rollupMonthlyCost(const [], now: now);
      expect(result, hasLength(6));
      for (final v in result.values) {
        expect(v, 0.0);
      }
    });

    test('logs older than six months are dropped', () {
      final now = DateTime.utc(2026, 4, 15);
      final result = rollupMonthlyCost(
        [
          log(
            id: 'ancient',
            date: DateTime.utc(2025, 1, 10),
            odometerKm: 5000,
            costEur: 99,
          ),
          log(
            id: 'recent',
            date: DateTime.utc(2026, 4, 5),
            odometerKm: 11000,
            costEur: 10,
          ),
        ],
        now: now,
      );
      final april = DateTime.utc(2026, 4, 1);
      expect(result[april], 10);
      // The 2025-01 log silently drops — never shows up as a key
      // because the chart is strictly last-6-months.
      expect(result.keys.any((k) => k.year == 2025 && k.month == 1), isFalse);
    });
  });

  group('rollupMonthlyEfficiency', () {
    test(
      'two logs in the same month with 50 kWh over 400 km → 12.5 kWh/100km',
      () {
        final now = DateTime.utc(2026, 4, 20);
        final result = rollupMonthlyEfficiency(
          [
            log(
              id: 'prev',
              date: DateTime.utc(2026, 4, 1),
              odometerKm: 10000,
              kWh: 0, // anchor only — distance source
            ),
            log(
              id: 'cur',
              date: DateTime.utc(2026, 4, 15),
              odometerKm: 10400,
              kWh: 50,
            ),
          ],
          now: now,
        );
        final april = DateTime.utc(2026, 4, 1);
        expect(result[april], 12.5);
      },
    );

    test('zero distance between anchors → null (no divide by zero)', () {
      final now = DateTime.utc(2026, 4, 20);
      final result = rollupMonthlyEfficiency(
        [
          log(
            id: 'prev',
            date: DateTime.utc(2026, 4, 1),
            odometerKm: 10000,
            kWh: 10,
          ),
          log(
            id: 'same_odo',
            date: DateTime.utc(2026, 4, 15),
            odometerKm: 10000,
            kWh: 5,
          ),
        ],
        now: now,
      );
      final april = DateTime.utc(2026, 4, 1);
      // Both logs in April, but no kilometres driven between them →
      // no data.
      expect(result[april], isNull);
    });

    test('single log in the window → null (needs a prior anchor)', () {
      final now = DateTime.utc(2026, 4, 20);
      final result = rollupMonthlyEfficiency(
        [
          log(
            id: 'alone',
            date: DateTime.utc(2026, 4, 10),
            odometerKm: 10000,
            kWh: 25,
          ),
        ],
        now: now,
      );
      final april = DateTime.utc(2026, 4, 1);
      expect(result[april], isNull);
    });

    test('logs from other vehicles are NOT filtered here — caller does that',
        () {
      // This is the rollup helper, which is vehicle-agnostic. The
      // actual provider filters upstream.
      final now = DateTime.utc(2026, 4, 20);
      final result = rollupMonthlyEfficiency(
        [
          log(
            id: 'a',
            date: DateTime.utc(2026, 4, 1),
            odometerKm: 10000,
            kWh: 0,
            vehicleId: 'v1',
          ),
          log(
            id: 'b',
            date: DateTime.utc(2026, 4, 10),
            odometerKm: 10400,
            kWh: 50,
            vehicleId: 'v2',
          ),
        ],
        now: now,
      );
      final april = DateTime.utc(2026, 4, 1);
      // The helper blindly takes the deltas regardless of vehicle —
      // that's why [chargingMonthlyEfficiencyProvider] filters by
      // active vehicle BEFORE calling this helper.
      expect(result[april], isNotNull);
    });
  });

  group('provider-level behaviour (mixed vehicle filter)', () {
    test('different vehicle logs are excluded before rollup', () {
      // Caller-side filter — matches what the provider does before
      // delegating to the rollup helper.
      final now = DateTime.utc(2026, 4, 20);
      final all = [
        log(
          id: 'mine-prev',
          date: DateTime.utc(2026, 4, 1),
          odometerKm: 10000,
          costEur: 5,
          vehicleId: 'mine',
        ),
        log(
          id: 'theirs-prev',
          date: DateTime.utc(2026, 4, 2),
          odometerKm: 70000,
          costEur: 50,
          vehicleId: 'theirs',
        ),
        log(
          id: 'mine-cur',
          date: DateTime.utc(2026, 4, 15),
          odometerKm: 10500,
          costEur: 7,
          vehicleId: 'mine',
        ),
      ];
      final mine = all.where((l) => l.vehicleId == 'mine').toList();
      final costResult = rollupMonthlyCost(mine, now: now);
      final april = DateTime.utc(2026, 4, 1);
      // Sum: 5 + 7 = 12 — the 50 EUR bill from the other vehicle
      // is absent because the caller filtered it out.
      expect(costResult[april], 12);
    });
  });
}
