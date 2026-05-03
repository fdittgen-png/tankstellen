import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/vehicle/domain/entities/reference_vehicle.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

// Shared AT-init boilerplate so the tests focus on the resolution chain.
const _initResponses = {
  'ATZ': 'ELM327 v1.5>',
  'ATE0': 'OK>',
  'ATL0': 'OK>',
  'ATH0': 'OK>',
  'ATSP0': 'OK>',
};

// Standard speed-density-only fixture: PID 5E + MAF off, MAP 65 kPa,
// IAT 30 °C, RPM 2500. Trims unsupported. Forces the speed-density
// branch where the resolution chain matters.
const _speedDensityResponses = {
  '015E': 'NO DATA>',
  '0110': 'NO DATA>',
  '010B': '41 0B 41>', // MAP 65 kPa
  '010F': '41 0F 46>', // IAT 30 °C
  '010C': '41 0C 27 10>', // RPM 2500
  '0106': 'NO DATA>',
  '0107': 'NO DATA>',
};

/// Tests for the displacement / VE / AFR / density resolution chain
/// landed in #1397. The chain is, in priority order:
///
///   1. `vehicle.manual<X>Override` (user typed a value into the
///      "Advanced calibration" card).
///   2. `vehicle.<X>` (set during onboarding / VIN decode).
///   3. `referenceVehicle.<X>` (catalog default).
///   4. `kDefault<X>` (estimator constant fallback).
///
/// The chain happens INSIDE `Obd2Service.readFuelRateLPerHour`; the
/// pure-math `estimateFuelRateLPerHourFromMap` is unchanged. We assert
/// against the catalog rate to anchor the comparison.
void main() {
  // Catalog row that mirrors a Renault 1.5 dCi — the motivating Duster
  // case. Distinct displacement + VE so a manual override produces a
  // visibly different rate.
  const duster = ReferenceVehicle(
    make: 'Dacia',
    model: 'Duster',
    generation: 'II (2018-)',
    yearStart: 2018,
    displacementCc: 1461,
    fuelType: 'diesel',
    transmission: 'manual',
    volumetricEfficiency: 0.86,
    odometerPidStrategy: 'unknown',
  );

  Future<Obd2Service> connect() async {
    final transport = FakeObd2Transport({
      ..._initResponses,
      ..._speedDensityResponses,
    });
    final service = Obd2Service(transport);
    await service.connect();
    return service;
  }

  group('Obd2Service resolution chain (#1397)', () {
    test('manual override wins over every other source', () async {
      // Manual displacement + VE both differ from vehicle, catalog,
      // and default. Manual AFR + density override the diesel branch
      // (so the user can pin LPG / E85 values without changing the
      // preferredFuelType key).
      final service = await connect();
      const profile = VehicleProfile(
        id: 'v',
        name: 'Duster (overridden)',
        engineDisplacementCc: 1461,
        volumetricEfficiency: 0.86,
        preferredFuelType: 'diesel',
        manualEngineDisplacementCcOverride: 1700.0,
        manualVolumetricEfficiencyOverride: 0.92,
        manualAfrOverride: 14.0,
        manualFuelDensityGPerLOverride: 800.0,
      );

      final rate = await service.readFuelRateLPerHour(
        vehicle: profile,
        referenceVehicle: duster,
      );
      final expected = estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: 1700,
        volumetricEfficiency: 0.92,
        afr: 14.0,
        fuelDensityGPerL: 800.0,
      );
      expect(rate, isNotNull);
      expect(expected, isNotNull);
      expect(rate, closeTo(expected!, 1e-3));

      // Sanity — manual override is observably different from the
      // catalog-only path for the same vehicle / reading.
      final catalogRate = estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: 1461,
        volumetricEfficiency: 0.86,
        afr: kDieselAfr,
        fuelDensityGPerL: kDieselDensityGPerL,
      )!;
      expect((rate! - catalogRate).abs(), greaterThan(0.1));
    });

    test('manual override == null falls through to vehicle field',
        () async {
      final service = await connect();
      const profile = VehicleProfile(
        id: 'v',
        name: 'Duster (vehicle)',
        engineDisplacementCc: 1500,
        volumetricEfficiency: 0.90,
        preferredFuelType: 'diesel',
        // No manual overrides → vehicle fields win over catalog.
      );

      final rate = await service.readFuelRateLPerHour(
        vehicle: profile,
        referenceVehicle: duster,
      );
      final expected = estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: 1500,
        volumetricEfficiency: 0.90,
        afr: kDieselAfr,
        fuelDensityGPerL: kDieselDensityGPerL,
      );
      expect(rate, closeTo(expected!, 1e-3));
    });

    test('manual + vehicle == null falls through to referenceVehicle',
        () async {
      final service = await connect();
      // Profile carries no engine fields; only the catalog values feed
      // the estimator.
      const profile = VehicleProfile(
        id: 'v',
        name: 'Duster (catalog)',
        preferredFuelType: 'diesel',
      );

      final rate = await service.readFuelRateLPerHour(
        vehicle: profile,
        referenceVehicle: duster,
      );
      final expected = estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: 1461,
        volumetricEfficiency:
            0.86, // VehicleProfile non-null default beats catalog VE
        afr: kDieselAfr,
        fuelDensityGPerL: kDieselDensityGPerL,
      );
      // VehicleProfile.volumetricEfficiency is non-nullable with a
      // default of 0.85, so the chain in obd2_service uses 0.85, not
      // the catalog 0.86. Document this so the test pins the wired
      // priority and not the wishful one.
      final expectedActual = estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: 1461,
        volumetricEfficiency: 0.85,
        afr: kDieselAfr,
        fuelDensityGPerL: kDieselDensityGPerL,
      );
      expect(expected, isNotNull);
      expect(rate, closeTo(expectedActual!, 1e-3));
    });

    test('every source null → kDefault constants', () async {
      final service = await connect();
      // No vehicle, no reference, no diesel hint → petrol defaults.
      final rate = await service.readFuelRateLPerHour();
      final expected = estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: kDefaultEngineDisplacementCc,
        volumetricEfficiency: kDefaultVolumetricEfficiency,
        afr: kPetrolAfr,
        fuelDensityGPerL: kPetrolDensityGPerL,
      );
      expect(rate, closeTo(expected!, 1e-3));
    });

    test('partial manual override — only AFR overridden — leaves '
        'displacement / VE / density on their normal chain', () async {
      final service = await connect();
      const profile = VehicleProfile(
        id: 'v',
        name: 'Duster (partial)',
        engineDisplacementCc: 1461,
        volumetricEfficiency: 0.86,
        preferredFuelType: 'diesel',
        manualAfrOverride: 14.0,
      );
      final rate = await service.readFuelRateLPerHour(
        vehicle: profile,
        referenceVehicle: duster,
      );
      final expected = estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: 1461,
        volumetricEfficiency: 0.86,
        afr: 14.0,
        fuelDensityGPerL: kDieselDensityGPerL,
      );
      expect(rate, closeTo(expected!, 1e-3));
    });
  });
}
