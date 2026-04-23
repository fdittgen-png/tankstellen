import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';

void main() {
  group('ChargingLog (#582 phase 1)', () {
    final date = DateTime.utc(2026, 4, 19, 15, 30);

    ChargingLog make({
      String id = 'c1',
      String vehicleId = 'v1',
      double kWh = 45.0,
      double costEur = 18.0,
      int chargeTimeMin = 32,
      int odometerKm = 32000,
      String? stationName,
      String? chargingStationId,
    }) {
      return ChargingLog(
        id: id,
        vehicleId: vehicleId,
        date: date,
        kWh: kWh,
        costEur: costEur,
        chargeTimeMin: chargeTimeMin,
        odometerKm: odometerKm,
        stationName: stationName,
        chargingStationId: chargingStationId,
      );
    }

    test('JSON round-trip preserves every required field', () {
      final log = make();
      final restored = ChargingLog.fromJson(log.toJson());
      expect(restored, log);
      expect(restored.id, 'c1');
      expect(restored.vehicleId, 'v1');
      expect(restored.kWh, 45.0);
      expect(restored.costEur, 18.0);
      expect(restored.chargeTimeMin, 32);
      expect(restored.odometerKm, 32000);
      expect(restored.date, date);
    });

    test('JSON round-trip preserves optional fields when set', () {
      final log = make(
        stationName: 'Ionity Pomerols',
        chargingStationId: 'ocm-1234',
      );
      final restored = ChargingLog.fromJson(log.toJson());
      expect(restored, log);
      expect(restored.stationName, 'Ionity Pomerols');
      expect(restored.chargingStationId, 'ocm-1234');
    });

    test('JSON round-trip survives null optional fields', () {
      final log = make();
      final restored = ChargingLog.fromJson(log.toJson());
      expect(restored.stationName, isNull);
      expect(restored.chargingStationId, isNull);
    });

    test('copyWith overrides targeted fields and preserves the rest', () {
      final original = make(stationName: 'Ionity');
      final updated = original.copyWith(
        costEur: 22.50,
        chargeTimeMin: 45,
      );

      expect(updated.id, original.id);
      expect(updated.vehicleId, original.vehicleId);
      expect(updated.kWh, original.kWh);
      expect(updated.costEur, 22.50);
      expect(updated.chargeTimeMin, 45);
      expect(updated.odometerKm, original.odometerKm);
      expect(updated.stationName, 'Ionity');
    });

    test('copyWith can clear a previously set optional string', () {
      final original = make(stationName: 'Ionity');
      final cleared = original.copyWith(stationName: null);
      expect(cleared.stationName, isNull);
    });
  });
}
