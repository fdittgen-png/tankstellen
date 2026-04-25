import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/reference_vehicle.dart';

/// Unit tests for the [ReferenceVehicle] entity (#950 phase 1).
void main() {
  group('ReferenceVehicle', () {
    test('JSON roundtrip preserves every field on a fully-populated entry',
        () {
      const original = ReferenceVehicle(
        make: 'Peugeot',
        model: '208',
        generation: 'II (2019-)',
        yearStart: 2019,
        yearEnd: 2024,
        displacementCc: 1199,
        fuelType: 'petrol',
        transmission: 'manual',
        volumetricEfficiency: 0.85,
        odometerPidStrategy: 'psaUds',
        notes: 'PureTech 1.2 three-cylinder',
      );

      final restored = ReferenceVehicle.fromJson(original.toJson());

      expect(restored, equals(original));
    });

    test('JSON roundtrip preserves null yearEnd (still in production)', () {
      const original = ReferenceVehicle(
        make: 'Renault',
        model: 'Clio',
        generation: 'V (2019-)',
        yearStart: 2019,
        yearEnd: null,
        displacementCc: 999,
        fuelType: 'petrol',
        transmission: 'manual',
      );

      final json = original.toJson();
      expect(json['yearEnd'], isNull);

      final restored = ReferenceVehicle.fromJson(json);
      expect(restored, equals(original));
      expect(restored.yearEnd, isNull);
      // Defaults round-trip cleanly.
      expect(restored.volumetricEfficiency, 0.85);
      expect(restored.odometerPidStrategy, 'stdA6');
      expect(restored.notes, isNull);
    });

    group('coversYear', () {
      test('returns true for the start year', () {
        const v = ReferenceVehicle(
          make: 'X',
          model: 'Y',
          generation: 'I',
          yearStart: 2019,
          yearEnd: 2023,
          displacementCc: 1000,
          fuelType: 'petrol',
          transmission: 'manual',
        );
        expect(v.coversYear(2019), isTrue);
      });

      test('returns true for the end year (inclusive)', () {
        const v = ReferenceVehicle(
          make: 'X',
          model: 'Y',
          generation: 'I',
          yearStart: 2019,
          yearEnd: 2023,
          displacementCc: 1000,
          fuelType: 'petrol',
          transmission: 'manual',
        );
        expect(v.coversYear(2023), isTrue);
      });

      test('returns false before the start year', () {
        const v = ReferenceVehicle(
          make: 'X',
          model: 'Y',
          generation: 'I',
          yearStart: 2019,
          yearEnd: 2023,
          displacementCc: 1000,
          fuelType: 'petrol',
          transmission: 'manual',
        );
        expect(v.coversYear(2018), isFalse);
      });

      test('returns false after the end year', () {
        const v = ReferenceVehicle(
          make: 'X',
          model: 'Y',
          generation: 'I',
          yearStart: 2019,
          yearEnd: 2023,
          displacementCc: 1000,
          fuelType: 'petrol',
          transmission: 'manual',
        );
        expect(v.coversYear(2024), isFalse);
      });

      test('open-ended generation (yearEnd null) covers the far future', () {
        const v = ReferenceVehicle(
          make: 'X',
          model: 'Y',
          generation: 'I',
          yearStart: 2019,
          yearEnd: null,
          displacementCc: 1000,
          fuelType: 'petrol',
          transmission: 'manual',
        );
        expect(v.coversYear(2050), isTrue);
      });
    });
  });
}
