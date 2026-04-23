import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/ev/domain/charging_cost_calculator.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';

void main() {
  ChargingLog makeLog({
    String id = 'c1',
    double kWh = 45.0,
    double costEur = 18.0,
    int odometerKm = 32000,
  }) {
    return ChargingLog(
      id: id,
      vehicleId: 'v1',
      date: DateTime.utc(2026, 4, 1),
      kWh: kWh,
      costEur: costEur,
      chargeTimeMin: 32,
      odometerKm: odometerKm,
    );
  }

  group('ChargingCostCalculator.eurPer100km', () {
    test('happy path: €18 over 300 km yields €6.00 / 100 km', () {
      final log = makeLog(costEur: 18.0);
      expect(
        ChargingCostCalculator.eurPer100km(log, kmDriven: 300),
        closeTo(6.0, 1e-9),
      );
    });

    test('throws ArgumentError when kmDriven is zero', () {
      final log = makeLog();
      expect(
        () => ChargingCostCalculator.eurPer100km(log, kmDriven: 0),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when kmDriven is negative', () {
      final log = makeLog();
      expect(
        () => ChargingCostCalculator.eurPer100km(log, kmDriven: -10),
        throwsArgumentError,
      );
    });

    test('very small distance is numerically stable', () {
      // 1 km for €0.15 should map to exactly 15€ / 100 km.
      final log = makeLog(costEur: 0.15);
      expect(
        ChargingCostCalculator.eurPer100km(log, kmDriven: 1),
        closeTo(15.0, 1e-9),
      );
    });
  });

  group('ChargingCostCalculator.kWhPer100km', () {
    test('happy path: 45 kWh over 300 km yields 15 kWh / 100 km', () {
      final log = makeLog(kWh: 45.0);
      expect(
        ChargingCostCalculator.kWhPer100km(log, kmDriven: 300),
        closeTo(15.0, 1e-9),
      );
    });

    test('throws ArgumentError on zero kmDriven', () {
      final log = makeLog();
      expect(
        () => ChargingCostCalculator.kWhPer100km(log, kmDriven: 0),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError on negative kmDriven', () {
      final log = makeLog();
      expect(
        () => ChargingCostCalculator.kWhPer100km(log, kmDriven: -5),
        throwsArgumentError,
      );
    });
  });

  group('ChargingCostCalculator.avgEurPer100km', () {
    test('empty input returns 0.0 (no NaN, no throw)', () {
      expect(ChargingCostCalculator.avgEurPer100km(const [], const []), 0.0);
    });

    test('single-log edge case matches eurPer100km', () {
      final log = makeLog(costEur: 18.0);
      final avg = ChargingCostCalculator.avgEurPer100km(
        [log],
        const [(fromKm: 32000, toKm: 32300)],
      );
      expect(avg, closeTo(6.0, 1e-9));
    });

    test('cost-weighted mean across mixed segments', () {
      // Two sessions:
      //  - €18 over 300 km → would be 6 €/100 km alone
      //  - €30 over 200 km → would be 15 €/100 km alone
      // Weighted mean: (18 + 30) / (300 + 200) * 100 = 9.6 €/100 km.
      // A naive arithmetic mean would give (6 + 15) / 2 = 10.5 €/100 km.
      final logs = [
        makeLog(id: 'a', costEur: 18.0),
        makeLog(id: 'b', costEur: 30.0),
      ];
      final segments = <({int fromKm, int toKm})>[
        (fromKm: 32000, toKm: 32300),
        (fromKm: 32300, toKm: 32500),
      ];
      expect(
        ChargingCostCalculator.avgEurPer100km(logs, segments),
        closeTo(9.6, 1e-9),
      );
    });

    test('throws when a segment has non-positive distance', () {
      final logs = [
        makeLog(id: 'a', costEur: 18.0),
        makeLog(id: 'b', costEur: 10.0),
      ];
      final segments = <({int fromKm, int toKm})>[
        (fromKm: 32000, toKm: 32300),
        (fromKm: 32300, toKm: 32300), // zero distance
      ];
      expect(
        () => ChargingCostCalculator.avgEurPer100km(logs, segments),
        throwsArgumentError,
      );
    });

    test('throws when segment distance is negative (bad odometer edit)', () {
      final logs = [makeLog(id: 'a', costEur: 18.0)];
      final segments = <({int fromKm, int toKm})>[
        (fromKm: 32000, toKm: 31500),
      ];
      expect(
        () => ChargingCostCalculator.avgEurPer100km(logs, segments),
        throwsArgumentError,
      );
    });

    test('throws when logs and segments differ in length', () {
      final logs = [makeLog()];
      final segments = <({int fromKm, int toKm})>[
        (fromKm: 0, toKm: 100),
        (fromKm: 100, toKm: 200),
      ];
      expect(
        () => ChargingCostCalculator.avgEurPer100km(logs, segments),
        throwsArgumentError,
      );
    });

    test('very small total distance remains stable (no runaway ratio)', () {
      // Single 2 km segment at €0.30 → 15 €/100 km
      final logs = [makeLog(costEur: 0.30)];
      final segments = <({int fromKm, int toKm})>[
        (fromKm: 32000, toKm: 32002),
      ];
      expect(
        ChargingCostCalculator.avgEurPer100km(logs, segments),
        closeTo(15.0, 1e-9),
      );
    });
  });
}
