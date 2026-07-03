// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/obd2/data/fuel_mixture_model.dart';
import 'package:tankstellen/features/obd2/data/fuel_rate_estimator.dart';

/// Epic #3416 — the mixture policy: ethanol blend (#3429), diesel-aware
/// effective AFR (#3430), mass-rate conversions (#3428), and the parity
/// lock against the legacy `resolveAfrDensity` mapping.
void main() {
  group('fuelKindForKey / afrDensityForKind parity with resolveAfrDensity',
      () {
    // Every representative key spelling the legacy mapper handles. The
    // two implementations live in different files; this lock keeps them
    // from drifting (the schema-parity lesson).
    const keys = [
      null, '', 'petrol', 'e10', 'e5', 'super', 'gasoline', 'diesel',
      'dieselPremium', 'e85', 'ethanol', 'lpg', 'autogas', 'cng',
      'electric', 'unknown-fuel',
    ];

    test('kind→constants matches the legacy key→constants for every key',
        () {
      for (final key in keys) {
        final legacy = resolveAfrDensity(null, fallbackFuelType: key);
        final viaKind = afrDensityForKind(fuelKindForKey(key));
        expect(viaKind.afr, legacy.afr, reason: 'afr for key=$key');
        expect(viaKind.densityGPerL, legacy.densityGPerL,
            reason: 'density for key=$key');
      }
    });

    test('resolveMixtureConstants with no 0x51/0x52 signal == '
        'resolveAfrDensity (regression parity)', () {
      const diesel = VehicleProfile(
        id: 'd',
        name: 'diesel',
        preferredFuelType: 'diesel',
      );
      final legacy = resolveAfrDensity(diesel);
      final mixture = resolveMixtureConstants(diesel);
      expect(mixture.afr, legacy.afr);
      expect(mixture.densityGPerL, legacy.densityGPerL);
      expect(mixture.kind, ResolvedFuelKind.diesel);
    });
  });

  group('ethanol blend (#3429)', () {
    test('0 % → exactly the petrol constants', () {
      final b = blendedAfrDensityForEthanol(0);
      expect(b.afr, closeTo(kPetrolAfr, 1e-9));
      expect(b.densityGPerL, closeTo(kPetrolDensityGPerL, 1e-9));
    });

    test('85 % → exactly the E85 constants', () {
      final b = blendedAfrDensityForEthanol(85);
      expect(b.afr, closeTo(kE85Afr, 1e-9));
      expect(b.densityGPerL, closeTo(kE85DensityGPerL, 1e-9));
    });

    test('50 % → the linear midpoint at t = 50/85', () {
      final b = blendedAfrDensityForEthanol(50);
      const t = 50.0 / 85.0;
      expect(b.afr, closeTo(kPetrolAfr + (kE85Afr - kPetrolAfr) * t, 1e-9));
      expect(
        b.densityGPerL,
        closeTo(
          kPetrolDensityGPerL +
              (kE85DensityGPerL - kPetrolDensityGPerL) * t,
          1e-9,
        ),
      );
      // Sanity: AFR falls monotonically with ethanol content.
      expect(b.afr, lessThan(kPetrolAfr));
      expect(b.afr, greaterThan(kE85Afr));
    });

    test('100 % extrapolates to ~pure-ethanol figures (stoich ≈ 9.0)', () {
      final b = blendedAfrDensityForEthanol(100);
      expect(b.afr, closeTo(9.0, 0.15));
      expect(b.densityGPerL, closeTo(789, 8));
    });

    test('measured 0x52 replaces the fixed petrol constants in '
        'resolveMixtureConstants', () {
      const petrol = VehicleProfile(
        id: 'p',
        name: 'flexfuel on petrol key',
        preferredFuelType: 'petrol',
      );
      final mixture =
          resolveMixtureConstants(petrol, measuredEthanolPercent: 85);
      expect(mixture.afr, closeTo(kE85Afr, 1e-9));
      expect(mixture.densityGPerL, closeTo(kE85DensityGPerL, 1e-9));
    });

    test('measured 0x52 never overrides a manual AFR/density override',
        () {
      const pinned = VehicleProfile(
        id: 'p2',
        name: 'pinned',
        preferredFuelType: 'e85',
        manualAfrOverride: 10.5,
        manualFuelDensityGPerLOverride: 800.0,
      );
      final mixture =
          resolveMixtureConstants(pinned, measuredEthanolPercent: 40);
      expect(mixture.afr, 10.5);
      expect(mixture.densityGPerL, 800.0);
    });

    test('ethanol is ignored on a diesel (garbage flexfuel PID)', () {
      const diesel = VehicleProfile(
        id: 'd2',
        name: 'diesel',
        preferredFuelType: 'diesel',
      );
      final mixture =
          resolveMixtureConstants(diesel, measuredEthanolPercent: 50);
      expect(mixture.afr, kDieselAfr);
      expect(mixture.densityGPerL, kDieselDensityGPerL);
    });

    test('session 0x51 key beats the profile free-text key '
        '(ECU runtime truth, #3429)', () {
      const wrongProfile = VehicleProfile(
        id: 'w',
        name: 'profile says petrol, ECU says diesel',
        preferredFuelType: 'petrol',
      );
      final mixture = resolveMixtureConstants(wrongProfile,
          sessionFuelTypeKey: 'diesel');
      expect(mixture.kind, ResolvedFuelKind.diesel);
      expect(mixture.afr, kDieselAfr);
    });
  });

  group('effectiveAfrForMixture (#3427 / #3430)', () {
    test('petrol: measured φ beats commanded φ', () {
      final eff = effectiveAfrForMixture(
        kPetrolAfr,
        measuredPhi: 0.9,
        commandedPhi: 1.2,
        isDiesel: false,
      );
      expect(eff, closeTo(kPetrolAfr / 0.9, 1e-9));
    });

    test('petrol: commanded φ is the fallback when nothing measured', () {
      final eff = effectiveAfrForMixture(
        kPetrolAfr,
        measuredPhi: null,
        commandedPhi: 1.2,
        isDiesel: false,
      );
      expect(eff, closeTo(kPetrolAfr / 1.2, 1e-9));
    });

    test('diesel: commanded φ is NEVER applied', () {
      final eff = effectiveAfrForMixture(
        kDieselAfr,
        measuredPhi: null,
        commandedPhi: 1.2,
        isDiesel: true,
      );
      expect(eff, kDieselAfr);
    });

    test('diesel: measured wideband φ IS applied, with the wide diesel '
        'clamp band (φ = 0.25 → AFR ≈ 58)', () {
      final eff = effectiveAfrForMixture(
        kDieselAfr,
        measuredPhi: 0.25, // deep-lean cruise — legit on a diesel
        commandedPhi: null,
        isDiesel: true,
      );
      expect(eff, closeTo(kDieselAfr / 0.25, 1e-9));
      // The petrol clamp (min 0.5) would have destroyed this signal.
      expect(eff, greaterThan(kDieselAfr / kMinCommandedPhi));
    });

    test('diesel measured φ garbage is clamped to the diesel band', () {
      expect(
        effectiveAfrForMixture(kDieselAfr,
            measuredPhi: 0.001, isDiesel: true),
        closeTo(kDieselAfr / kMinDieselMeasuredPhi, 1e-9),
      );
      expect(
        effectiveAfrForMixture(kDieselAfr,
            measuredPhi: 3.0, isDiesel: true),
        closeTo(kDieselAfr / kMaxDieselMeasuredPhi, 1e-9),
      );
    });
  });

  group('mass-rate conversions (#3428)', () {
    test('g/s → L/h via density only: 10 g/s petrol ≈ 48.6 L/h', () {
      final lph =
          fuelRateLPerHourFromGramsPerSecond(10.0, kPetrolDensityGPerL);
      expect(lph, closeTo(10.0 * 3600.0 / 740.0, 1e-9));
    });

    test('non-positive density / negative flow → null', () {
      expect(fuelRateLPerHourFromGramsPerSecond(10.0, 0), isNull);
      expect(fuelRateLPerHourFromGramsPerSecond(-1.0, 740), isNull);
    });

    test('0xA2 mg/stroke → g/s: 20 mg × 3000 RPM × 4 cyl = 2.0 g/s', () {
      // 20 mg × (3000/60 = 50 rev/s) / 2 strokes-per-rev-pair × 4 cyl
      // = 20 × 25 × 4 = 2000 mg/s = 2.0 g/s.
      final gps = cylinderFuelRateToGramsPerSecond(
        mgPerStroke: 20.0,
        rpm: 3000,
        cylinders: 4,
      );
      expect(gps, closeTo(2.0, 1e-9));
    });

    test('0xA2 conversion is undefined without RPM / cylinders', () {
      expect(
        cylinderFuelRateToGramsPerSecond(
            mgPerStroke: 20, rpm: 0, cylinders: 4),
        isNull,
      );
      expect(
        cylinderFuelRateToGramsPerSecond(
            mgPerStroke: 20, rpm: 3000, cylinders: 0),
        isNull,
      );
    });
  });
}
