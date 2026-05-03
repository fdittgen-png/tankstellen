import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/data/vin_auto_populator.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vin_data.dart';

/// Tests for [VinAutoPopulator] (#1399) — pure-merge function.
///
/// Covers:
///   1. Empty user fields get filled from decoded.
///   2. Populated user fields are NEVER silently overwritten.
///   3. Conflicting populated fields produce a non-null conflictSummary.
///   4. PID 0x51 wins over decoded fuel type.
///   5. detectedX fields are always written when decoded value is non-null.
///   6. lastReadVin / lastVinReadAt are always stamped.
void main() {
  const populator = VinAutoPopulator();

  VehicleProfile baseProfile({
    String? make,
    String? model,
    int? year,
    int? engineDisplacementCc,
    String? preferredFuelType,
    String? vin,
  }) {
    return VehicleProfile(
      id: 'v1',
      name: 'Test Car',
      make: make,
      model: model,
      year: year,
      engineDisplacementCc: engineDisplacementCc,
      preferredFuelType: preferredFuelType,
      vin: vin,
    );
  }

  group('empty user fields are auto-populated', () {
    test('fills make/model/year/displacement/fuelType from vPIC decoded',
        () {
      final result = populator.populate(
        profile: baseProfile(),
        vin: 'VF36B8HZL8R123456',
        decoded: const VinData(
          vin: 'VF36B8HZL8R123456',
          make: 'PEUGEOT',
          model: '107',
          modelYear: 2008,
          displacementL: 1.0,
          fuelTypePrimary: 'Gasoline',
          source: VinDataSource.vpic,
        ),
        pidFuelType: null,
      );

      expect(result.profile.make, 'PEUGEOT');
      expect(result.profile.model, '107');
      expect(result.profile.year, 2008);
      expect(result.profile.engineDisplacementCc, 1000);
      expect(result.profile.preferredFuelType, 'petrol');
      expect(result.profile.vin, 'VF36B8HZL8R123456');
      expect(result.appliedAny, isTrue);
      expect(result.conflictSummary, isNull);
      expect(result.didDecodeOnline, isTrue);
    });

    test('fills offline make/year only when decoded source is wmiOffline', () {
      final result = populator.populate(
        profile: baseProfile(),
        vin: 'VF31234567L1234567',
        decoded: const VinData(
          vin: 'VF31234567L1234567',
          make: 'Peugeot',
          country: 'France',
          modelYear: 2020,
          source: VinDataSource.wmiOffline,
        ),
        pidFuelType: null,
      );

      expect(result.profile.make, 'Peugeot');
      expect(result.profile.year, 2020);
      expect(result.profile.model, isNull);
      expect(result.profile.engineDisplacementCc, isNull);
      expect(result.didDecodeOnline, isFalse);
      expect(result.appliedAny, isTrue);
    });
  });

  group('populated user fields are never silently overwritten', () {
    test('conflicting make is reported via conflictSummary, not overwritten',
        () {
      final result = populator.populate(
        profile: baseProfile(make: 'Renault'),
        vin: 'VF36B8HZL8R123456',
        decoded: const VinData(
          vin: 'VF36B8HZL8R123456',
          make: 'PEUGEOT',
          source: VinDataSource.vpic,
        ),
        pidFuelType: null,
      );

      // User-entered make stays.
      expect(result.profile.make, 'Renault');
      // Detected mirror still tracks the decoded value.
      expect(result.profile.detectedMake, 'PEUGEOT');
      expect(result.conflictSummary, isNotNull);
      expect(result.conflictSummary, contains('PEUGEOT'));
    });

    test('matching user value produces no conflict', () {
      final result = populator.populate(
        profile: baseProfile(make: 'PEUGEOT'),
        vin: 'VF36B8HZL8R123456',
        decoded: const VinData(
          vin: 'VF36B8HZL8R123456',
          make: 'PEUGEOT',
          source: VinDataSource.vpic,
        ),
        pidFuelType: null,
      );

      expect(result.conflictSummary, isNull);
      expect(result.profile.make, 'PEUGEOT');
      expect(result.profile.detectedMake, 'PEUGEOT');
    });
  });

  group('PID 0x51 wins over decoded fuel type', () {
    test('pidFuelType=diesel overrides vPIC Gasoline', () {
      final result = populator.populate(
        profile: baseProfile(),
        vin: 'VF36B8HZL8R123456',
        decoded: const VinData(
          vin: 'VF36B8HZL8R123456',
          make: 'PEUGEOT',
          fuelTypePrimary: 'Gasoline',
          source: VinDataSource.vpic,
        ),
        pidFuelType: 'diesel',
      );

      expect(result.profile.detectedFuelType, 'diesel');
      expect(result.profile.preferredFuelType, 'diesel');
    });

    test('null pidFuelType falls back to decoded', () {
      final result = populator.populate(
        profile: baseProfile(),
        vin: 'VF36B8HZL8R123456',
        decoded: const VinData(
          vin: 'VF36B8HZL8R123456',
          fuelTypePrimary: 'Diesel',
          source: VinDataSource.vpic,
        ),
        pidFuelType: null,
      );

      expect(result.profile.detectedFuelType, 'diesel');
    });

    test('pidFuelType=petrol with no decoded fuel still populates', () {
      final result = populator.populate(
        profile: baseProfile(),
        vin: 'VF36B8HZL8R123456',
        decoded: const VinData(
          vin: 'VF36B8HZL8R123456',
          source: VinDataSource.wmiOffline,
        ),
        pidFuelType: 'petrol',
      );

      expect(result.profile.detectedFuelType, 'petrol');
      expect(result.profile.preferredFuelType, 'petrol');
    });
  });

  group('detected fields and timestamp', () {
    test('lastReadVin / lastVinReadAt are always stamped', () {
      final fixedNow = DateTime.utc(2026, 5, 1, 12, 30);
      final result = populator.populate(
        profile: baseProfile(),
        vin: 'VF36B8HZL8R123456',
        decoded: null,
        pidFuelType: null,
        now: fixedNow,
      );
      expect(result.profile.lastReadVin, 'VF36B8HZL8R123456');
      expect(result.profile.lastVinReadAt, fixedNow);
    });

    test('detectedX from a previous read is preserved when re-decode is null',
        () {
      // Simulate an earlier vPIC read having stored detectedMake.
      final earlier = baseProfile().copyWith(
        detectedMake: 'PEUGEOT',
        detectedModel: '107',
      );
      // Subsequent offline-only re-read with no make/model from the
      // decoder must not blank out the previously-detected values.
      final result = populator.populate(
        profile: earlier,
        vin: 'VF36B8HZL8R123456',
        decoded: const VinData(
          vin: 'VF36B8HZL8R123456',
          source: VinDataSource.wmiOffline,
        ),
        pidFuelType: null,
      );
      expect(result.profile.detectedMake, 'PEUGEOT');
      expect(result.profile.detectedModel, '107');
    });
  });

  group('vin field handling', () {
    test('empty VIN field is filled when read succeeds', () {
      final result = populator.populate(
        profile: baseProfile(),
        vin: 'VF36B8HZL8R123456',
        decoded: null,
        pidFuelType: null,
      );
      expect(result.profile.vin, 'VF36B8HZL8R123456');
    });

    test('existing VIN field is NOT overwritten by a different read', () {
      final result = populator.populate(
        profile: baseProfile(vin: 'OLDVIN12345678901'),
        vin: 'VF36B8HZL8R123456',
        decoded: null,
        pidFuelType: null,
      );
      // User-entered VIN wins; lastReadVin reflects the freshest read
      // for diagnostics.
      expect(result.profile.vin, 'OLDVIN12345678901');
      expect(result.profile.lastReadVin, 'VF36B8HZL8R123456');
    });
  });
}
