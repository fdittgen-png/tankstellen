import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// #694 — FillUp must carry an optional vehicleId so fill-ups can be
/// attributed to a specific VehicleProfile and grouped in per-vehicle
/// stats. The field is nullable so existing JSON without it parses
/// cleanly.
void main() {
  group('FillUp.vehicleId', () {
    test('is null when not provided (backward-compatible default)', () {
      final fillUp = FillUp(
        id: '1',
        date: DateTime.utc(2026, 4, 1),
        liters: 42.5,
        totalCost: 70,
        odometerKm: 100000,
        fuelType: FuelType.e10,
      );
      expect(fillUp.vehicleId, isNull);
    });

    test('preserves the supplied vehicleId', () {
      final fillUp = FillUp(
        id: '1',
        date: DateTime.utc(2026, 4, 1),
        liters: 42.5,
        totalCost: 70,
        odometerKm: 100000,
        fuelType: FuelType.e10,
        vehicleId: 'vehicle-abc',
      );
      expect(fillUp.vehicleId, 'vehicle-abc');
    });

    test('JSON round-trip preserves vehicleId', () {
      final original = FillUp(
        id: '1',
        date: DateTime.utc(2026, 4, 1),
        liters: 42.5,
        totalCost: 70,
        odometerKm: 100000,
        fuelType: FuelType.diesel,
        vehicleId: 'my-tesla-3',
      );
      final decoded = FillUp.fromJson(original.toJson());
      expect(decoded, equals(original));
      expect(decoded.vehicleId, 'my-tesla-3');
    });

    test('legacy JSON without vehicleId decodes with null', () {
      // An existing fill-up persisted before #694 won't have the key.
      final legacyJson = {
        'id': '1',
        'date': DateTime.utc(2026, 4, 1).toIso8601String(),
        'liters': 42.5,
        'totalCost': 70,
        'odometerKm': 100000.0,
        'fuelType': 'e10',
      };
      final decoded = FillUp.fromJson(legacyJson);
      expect(decoded.vehicleId, isNull);
    });
  });
}
