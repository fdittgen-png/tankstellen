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
      // #1422 phase 1 — engine-tech defaults round-trip.
      expect(restored.inductionType, InductionType.naturallyAspirated);
      expect(restored.directInjection, isFalse);
      expect(restored.atkinsonCycle, isFalse);
    });

    group('engine-tech schema (#1422 phase 1)', () {
      test('legacy JSON without new fields deserializes with defaults', () {
        // Mirrors a row that pre-dates #1422: no inductionType, no
        // directInjection, no atkinsonCycle keys at all.
        final legacyJson = <String, dynamic>{
          'make': 'Peugeot',
          'model': '107',
          'generation': 'I (2005-2014)',
          'yearStart': 2005,
          'yearEnd': 2014,
          'displacementCc': 998,
          'fuelType': 'petrol',
          'transmission': 'manual',
        };

        final parsed = ReferenceVehicle.fromJson(legacyJson);
        expect(parsed.inductionType, InductionType.naturallyAspirated);
        expect(parsed.directInjection, isFalse);
        expect(parsed.atkinsonCycle, isFalse);
        // Helper falls through to the legacy 0.85 number for an
        // NA + port-injection engine — bit-for-bit compat.
        expect(defaultVolumetricEfficiency(parsed), 0.85);
      });

      test('VNT diesel + DI JSON round-trips correctly', () {
        const original = ReferenceVehicle(
          make: 'Dacia',
          model: 'Duster',
          generation: 'II dCi 115 (2017-2024)',
          yearStart: 2017,
          yearEnd: 2024,
          displacementCc: 1461,
          fuelType: 'diesel',
          transmission: 'manual',
          inductionType: InductionType.vnt,
          directInjection: true,
        );

        final json = original.toJson();
        expect(json['inductionType'], 'vnt');
        expect(json['directInjection'], isTrue);
        expect(json['atkinsonCycle'], isFalse);

        final restored = ReferenceVehicle.fromJson(json);
        expect(restored, equals(original));
        expect(restored.inductionType, InductionType.vnt);
        expect(restored.directInjection, isTrue);
      });

      test('every InductionType serializes to its expected string', () {
        for (final entry in {
          InductionType.naturallyAspirated: 'naturallyAspirated',
          InductionType.turbocharged: 'turbocharged',
          InductionType.supercharged: 'supercharged',
          InductionType.vnt: 'vnt',
        }.entries) {
          final original = ReferenceVehicle(
            make: 'X',
            model: 'Y',
            generation: 'I',
            yearStart: 2020,
            displacementCc: 1500,
            fuelType: 'petrol',
            transmission: 'manual',
            inductionType: entry.key,
          );
          final json = original.toJson();
          expect(json['inductionType'], entry.value,
              reason: '${entry.key} serialization');

          final restored = ReferenceVehicle.fromJson(json);
          expect(restored.inductionType, entry.key);
        }
      });

      test('atkinsonCycle round-trips when true', () {
        const original = ReferenceVehicle(
          make: 'Toyota',
          model: 'Yaris',
          generation: 'IV (2020-)',
          yearStart: 2020,
          displacementCc: 1490,
          fuelType: 'hybrid',
          transmission: 'automatic',
          atkinsonCycle: true,
        );
        final restored = ReferenceVehicle.fromJson(original.toJson());
        expect(restored.atkinsonCycle, isTrue);
      });
    });

    group('defaultVolumetricEfficiency helper (#1422 phase 1)', () {
      const baseRow = ReferenceVehicle(
        make: 'X',
        model: 'Y',
        generation: 'I',
        yearStart: 2020,
        displacementCc: 1500,
        fuelType: 'petrol',
        transmission: 'manual',
      );

      test('atkinsonCycle short-circuits to 0.70 (Toyota HSD)', () {
        // Atkinson takes precedence over induction + DI flags.
        final v = baseRow.copyWith(
          atkinsonCycle: true,
          inductionType: InductionType.turbocharged,
          directInjection: true,
        );
        expect(defaultVolumetricEfficiency(v), 0.70);
      });

      test('VNT induction returns 0.95 (modern common-rail diesel)', () {
        final v = baseRow.copyWith(
          inductionType: InductionType.vnt,
          directInjection: true,
        );
        expect(defaultVolumetricEfficiency(v), 0.95);
      });

      test('turbo + DI returns 0.93', () {
        final v = baseRow.copyWith(
          inductionType: InductionType.turbocharged,
          directInjection: true,
        );
        expect(defaultVolumetricEfficiency(v), 0.93);
      });

      test('supercharged + DI also returns 0.93', () {
        final v = baseRow.copyWith(
          inductionType: InductionType.supercharged,
          directInjection: true,
        );
        expect(defaultVolumetricEfficiency(v), 0.93);
      });

      test('turbo + port injection returns 0.90', () {
        final v = baseRow.copyWith(
          inductionType: InductionType.turbocharged,
        );
        expect(defaultVolumetricEfficiency(v), 0.90);
      });

      test('NA + DI returns 0.88', () {
        final v = baseRow.copyWith(
          directInjection: true,
        );
        expect(defaultVolumetricEfficiency(v), 0.88);
      });

      test('NA + port injection returns 0.85 (legacy fallback)', () {
        // Bit-for-bit compat with the pre-#1422 0.85 default — every
        // catalog row that doesn't carry the new fields lands here.
        expect(defaultVolumetricEfficiency(baseRow), 0.85);
      });
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
