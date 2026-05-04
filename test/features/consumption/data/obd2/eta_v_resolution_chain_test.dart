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

/// Tests for the η_v resolution chain extension landed in #1422 phase 1.
///
/// Builds on top of the #1397 chain (`fuel_rate_resolution_chain_test.dart`)
/// — those tests pin manual-override / stored-vehicle / catalog-literal
/// precedence. This file pins the new behaviour: when the user's profile
/// sits on the cold-start 0.85 default with zero VeLearner samples AND a
/// reference catalog row is available, the chain should call
/// [defaultVolumetricEfficiency] instead of using the catalog literal —
/// so a Dacia dCi VNT diesel resolves 0.95 from day one rather than 0.85.
///
/// Order of precedence (post-#1422):
///   1. `vehicle.manualVolumetricEfficiencyOverride`
///   2. `vehicle.volumetricEfficiency` when learned (samples > 0) OR
///      explicitly non-default (≠ 0.85)
///   3. `defaultVolumetricEfficiency(referenceVehicle)`
///   4. `kDefaultVolumetricEfficiency` (0.85) — only when no reference
///      row resolves at all.
void main() {
  // VNT diesel reference. Engine-tech helper resolves to 0.95;
  // the legacy `referenceVehicle.volumetricEfficiency` literal is 0.85
  // so we can prove the helper is consulted (not the literal).
  const dustnerDci = ReferenceVehicle(
    make: 'Dacia',
    model: 'Duster',
    generation: 'II dCi 115 (2017-2024)',
    yearStart: 2017,
    yearEnd: 2024,
    displacementCc: 1461,
    fuelType: 'diesel',
    transmission: 'manual',
    volumetricEfficiency: 0.85,
    odometerPidStrategy: 'stdA6',
    inductionType: InductionType.vnt,
    directInjection: true,
  );

  // Turbo + DI petrol reference (e.g. 1.2 PureTech). Helper → 0.93.
  const peugeot208 = ReferenceVehicle(
    make: 'Peugeot',
    model: '208',
    generation: 'II (2019-)',
    yearStart: 2019,
    displacementCc: 1199,
    fuelType: 'petrol',
    transmission: 'manual',
    volumetricEfficiency: 0.85,
    odometerPidStrategy: 'psaUds',
    inductionType: InductionType.turbocharged,
    directInjection: true,
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

  group('Obd2Service η_v engine-tech defaults (#1422 phase 1)', () {
    test('manual override wins over the engine-tech helper', () async {
      // User typed 0.78 into the calibration card. Even with a VNT
      // diesel reference whose helper would say 0.95, the override wins.
      final service = await connect();
      const profile = VehicleProfile(
        id: 'v',
        name: 'Duster (manual override)',
        engineDisplacementCc: 1461,
        preferredFuelType: 'diesel',
        manualVolumetricEfficiencyOverride: 0.78,
      );

      final rate = await service.readFuelRateLPerHour(
        vehicle: profile,
        referenceVehicle: dustnerDci,
      );
      final expected = estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: 1461,
        volumetricEfficiency: 0.78,
        afr: kDieselAfr,
        fuelDensityGPerL: kDieselDensityGPerL,
      );
      expect(rate, isNotNull);
      expect(rate, closeTo(expected!, 1e-3));
    });

    test(
        'stored non-default profile value (e.g. 0.91) wins over the helper',
        () async {
      // Profile carries a non-default 0.91 — could be from VeLearner or
      // a previous app version that wrote a derived value. The helper
      // would say 0.93 for the turbo+DI 208 reference, but the stored
      // user value is the source of truth once it diverges from 0.85.
      final service = await connect();
      const profile = VehicleProfile(
        id: 'v',
        name: '208 (stored non-default)',
        engineDisplacementCc: 1199,
        volumetricEfficiency: 0.91,
        preferredFuelType: 'petrol',
      );

      final rate = await service.readFuelRateLPerHour(
        vehicle: profile,
        referenceVehicle: peugeot208,
      );
      final expected = estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: 1199,
        volumetricEfficiency: 0.91,
        afr: kPetrolAfr,
        fuelDensityGPerL: kPetrolDensityGPerL,
      );
      expect(rate, closeTo(expected!, 1e-3));
    });

    test(
        'stored learned value (samples > 0) wins even when equal to 0.85',
        () async {
      // VeLearner converged on 0.85 (rare but possible); samples > 0
      // signals "this 0.85 is intentional". Don't override with helper.
      final service = await connect();
      const profile = VehicleProfile(
        id: 'v',
        name: 'Duster (VeLearner converged)',
        engineDisplacementCc: 1461,
        preferredFuelType: 'diesel',
        // ignore: avoid_redundant_argument_values
        volumetricEfficiency: 0.85,
        volumetricEfficiencySamples: 3,
      );

      final rate = await service.readFuelRateLPerHour(
        vehicle: profile,
        referenceVehicle: dustnerDci,
      );
      final expected = estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: 1461,
        volumetricEfficiency: 0.85,
        afr: kDieselAfr,
        fuelDensityGPerL: kDieselDensityGPerL,
      );
      expect(rate, closeTo(expected!, 1e-3));
    });

    test(
        'cold-start profile (0.85, samples == 0) + VNT reference '
        'falls through to helper 0.95 (the headline behaviour change)',
        () async {
      // The motivating case: a fresh user picks Dacia Duster dCi from
      // the catalog, the wizard writes the VehicleProfile with the
      // default 0.85 + 0 samples. Pre-#1422 the chain returned 0.85
      // (the catalog literal). Post-#1422 the helper kicks in and
      // returns 0.95.
      final service = await connect();
      const profile = VehicleProfile(
        id: 'v',
        name: 'Duster (cold-start)',
        engineDisplacementCc: 1461,
        preferredFuelType: 'diesel',
        // VehicleProfile defaults: volumetricEfficiency = 0.85, samples = 0.
      );

      final rate = await service.readFuelRateLPerHour(
        vehicle: profile,
        referenceVehicle: dustnerDci,
      );
      final expected = estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: 1461,
        volumetricEfficiency: 0.95, // helper, NOT catalog literal 0.85
        afr: kDieselAfr,
        fuelDensityGPerL: kDieselDensityGPerL,
      );
      expect(rate, isNotNull);
      expect(expected, isNotNull);
      expect(rate, closeTo(expected!, 1e-3));

      // Sanity: the pre-#1422 path (0.85) would have produced an
      // observably smaller rate. Pin the headline behaviour change.
      final pre1422Rate = estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: 1461,
        volumetricEfficiency: 0.85,
        afr: kDieselAfr,
        fuelDensityGPerL: kDieselDensityGPerL,
      )!;
      expect(rate! - pre1422Rate, greaterThan(0.0),
          reason: '0.95 helper should produce a higher L/h than 0.85 '
              'literal for the same MAP/IAT/RPM');
    });

    test(
        'turbo + DI petrol reference cold-start resolves 0.93 not '
        'catalog 0.85', () async {
      // 1.2 PureTech pattern: catalog literal stays at 0.85 (intentional
      // — VeLearner-converged users keep their values), but a fresh
      // profile gets 0.93 from the helper.
      final service = await connect();
      const profile = VehicleProfile(
        id: 'v',
        name: '208 (cold-start)',
        engineDisplacementCc: 1199,
        preferredFuelType: 'petrol',
      );
      final rate = await service.readFuelRateLPerHour(
        vehicle: profile,
        referenceVehicle: peugeot208,
      );
      final expected = estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: 1199,
        volumetricEfficiency: 0.93,
        afr: kPetrolAfr,
        fuelDensityGPerL: kPetrolDensityGPerL,
      );
      expect(rate, closeTo(expected!, 1e-3));
    });

    test(
        'no reference vehicle resolved → kDefaultVolumetricEfficiency '
        '0.85 hard fallback', () async {
      // No catalog match (e.g. niche import). The helper has nothing
      // to derive from, so the chain lands on the legacy 0.85 constant.
      final service = await connect();
      const profile = VehicleProfile(
        id: 'v',
        name: 'Niche import (no catalog match)',
        engineDisplacementCc: 1500,
        preferredFuelType: 'petrol',
      );

      final rate = await service.readFuelRateLPerHour(
        vehicle: profile,
        // No referenceVehicle.
      );
      final expected = estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: 1500,
        volumetricEfficiency: kDefaultVolumetricEfficiency,
        afr: kPetrolAfr,
        fuelDensityGPerL: kPetrolDensityGPerL,
      );
      expect(rate, closeTo(expected!, 1e-3));
    });

    test(
        'cold-start profile + atkinson reference resolves 0.70 '
        '(Toyota Hybrid)', () async {
      // Atkinson takes precedence over induction; a fresh Yaris HSD
      // profile gets 0.70 not 0.85.
      const yarisHybrid = ReferenceVehicle(
        make: 'Toyota',
        model: 'Yaris',
        generation: 'IV (2020-)',
        yearStart: 2020,
        displacementCc: 1490,
        fuelType: 'hybrid',
        transmission: 'automatic',
        volumetricEfficiency: 0.88,
        atkinsonCycle: true,
      );
      final service = await connect();
      const profile = VehicleProfile(
        id: 'v',
        name: 'Yaris HSD (cold-start)',
        engineDisplacementCc: 1490,
        preferredFuelType: 'petrol',
      );

      final rate = await service.readFuelRateLPerHour(
        vehicle: profile,
        referenceVehicle: yarisHybrid,
      );
      final expected = estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: 1490,
        volumetricEfficiency: 0.70,
        afr: kPetrolAfr,
        fuelDensityGPerL: kPetrolDensityGPerL,
      );
      expect(rate, closeTo(expected!, 1e-3));
    });
  });
}
