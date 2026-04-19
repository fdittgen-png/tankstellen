import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/charging_log.dart';

void main() {
  group('ChargingLog (#582)', () {
    final date = DateTime.utc(2026, 4, 19);

    test('pricePerKwh returns totalCost / kWh', () {
      final log = ChargingLog(
        id: 'c1',
        date: date,
        kwh: 45,
        totalCost: 18,
        odometerKm: 32000,
      );
      expect(log.pricePerKwh, closeTo(0.4, 1e-9));
    });

    test('pricePerKwh returns 0 when kWh is 0 (no divide-by-zero)', () {
      final log = ChargingLog(
        id: 'c1',
        date: date,
        kwh: 0,
        totalCost: 0,
        odometerKm: 32000,
      );
      expect(log.pricePerKwh, 0);
    });

    test('JSON round-trip preserves every field (including optional ones)',
        () {
      final log = ChargingLog(
        id: 'c1',
        date: date,
        kwh: 42.5,
        totalCost: 16.75,
        odometerKm: 32000,
        chargeTimeMin: 35,
        stationId: 'ocm-1',
        stationName: 'Ionity Pomerols',
        operator: 'Ionity',
        notes: 'Free on launch weekend',
        vehicleId: 'v-1',
      );
      final restored = ChargingLog.fromJson(log.toJson());
      expect(restored, log);
    });

    test('JSON round-trip survives all-optionals-null', () {
      final log = ChargingLog(
        id: 'c1',
        date: date,
        kwh: 42.5,
        totalCost: 16.75,
        odometerKm: 32000,
      );
      final restored = ChargingLog.fromJson(log.toJson());
      expect(restored, log);
      expect(restored.chargeTimeMin, isNull);
      expect(restored.operator, isNull);
      expect(restored.vehicleId, isNull);
    });

    test(
        'costPer100Km returns EUR-per-100 km when vehicle consumption '
        'kWh/100 km is known', () {
      // 45 kWh for €18 → €0.40 per kWh.
      // Vehicle burns 18 kWh per 100 km → €7.20 per 100 km.
      final log = ChargingLog(
        id: 'c1',
        date: date,
        kwh: 45,
        totalCost: 18,
        odometerKm: 32000,
      );
      expect(
        log.costPer100Km(consumptionKwhPer100Km: 18),
        closeTo(7.2, 1e-9),
      );
    });

    test('costPer100Km returns null when consumption figure is missing', () {
      final log = ChargingLog(
        id: 'c1',
        date: date,
        kwh: 45,
        totalCost: 18,
        odometerKm: 32000,
      );
      expect(log.costPer100Km(consumptionKwhPer100Km: null), isNull);
      expect(log.costPer100Km(consumptionKwhPer100Km: 0), isNull);
    });
  });
}
