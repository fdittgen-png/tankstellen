import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// #1361 phase 2a — [FillUp.isCorrection] must round-trip through JSON
/// and default to `false` when missing from a legacy payload (so
/// fill-ups persisted before this field landed deserialise as
/// non-correction entries).
void main() {
  group('FillUp.isCorrection', () {
    test('defaults to false when not provided', () {
      final f = FillUp(
        id: '1',
        date: DateTime(2026, 4, 1),
        liters: 30,
        totalCost: 50,
        odometerKm: 12345,
        fuelType: FuelType.e10,
      );
      expect(f.isCorrection, isFalse);
    });

    test('preserves the supplied value', () {
      final f = FillUp(
        id: '1',
        date: DateTime(2026, 4, 1),
        liters: 30,
        totalCost: 0,
        odometerKm: 12345,
        fuelType: FuelType.e10,
        isCorrection: true,
      );
      expect(f.isCorrection, isTrue);
    });

    test('round-trips through fromJson/toJson', () {
      final original = FillUp(
        id: 'correction_p1',
        date: DateTime.utc(2026, 4, 8, 12),
        liters: 7.5,
        totalCost: 0,
        odometerKm: 12500,
        fuelType: FuelType.diesel,
        vehicleId: 'veh-a',
        isFullTank: false,
        isCorrection: true,
      );
      final decoded = FillUp.fromJson(original.toJson());
      expect(decoded, equals(original));
      expect(decoded.isCorrection, isTrue);
      expect(decoded.isFullTank, isFalse);
    });

    test('legacy JSON without isCorrection decodes with default false',
        () {
      // A fill-up persisted before #1361 won't carry the key.
      final legacyJson = {
        'id': '1',
        'date': DateTime.utc(2026, 4, 1).toIso8601String(),
        'liters': 42.5,
        'totalCost': 70,
        'odometerKm': 100000.0,
        'fuelType': 'e10',
      };
      final decoded = FillUp.fromJson(legacyJson);
      expect(decoded.isCorrection, isFalse);
    });

    test(
        'a non-correction fill round-trip preserves isCorrection=false',
        () {
      final original = FillUp(
        id: '1',
        date: DateTime.utc(2026, 4, 1),
        liters: 42.5,
        totalCost: 70,
        odometerKm: 100000,
        fuelType: FuelType.e10,
      );
      final decoded = FillUp.fromJson(original.toJson());
      expect(decoded.isCorrection, isFalse);
    });
  });
}
