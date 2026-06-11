// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/fuel_rate_estimator.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';

/// Guardrails for the pure-math fuel-rate estimator extracted out of
/// `obd2_service.dart` in the #563 service-split refactor. These
/// assertions duplicate the service-level coverage in
/// `obd2_service_test.dart`, but wiring them directly against the
/// top-level functions means future callers that bypass [Obd2Service]
/// (e.g. the home-widget isolate — which can't instantiate the
/// transport) get covered too.
void main() {
  group('applyFuelTrimCorrection — #813', () {
    test('positive trims enrich (factor > 1)', () {
      expect(
        applyFuelTrimCorrection(10.0, stft: 6.0, ltft: 4.0),
        closeTo(11.0, 0.001),
      );
    });

    test('negative trims lean (factor < 1)', () {
      expect(
        applyFuelTrimCorrection(10.0, stft: -5.0, ltft: -5.0),
        closeTo(9.0, 0.001),
      );
    });

    test('zero trims pass through unchanged', () {
      expect(
        applyFuelTrimCorrection(10.0, stft: 0, ltft: 0),
        closeTo(10.0, 0.001),
      );
    });

    test('asymmetric trims sum (HEM Data canonical formula)', () {
      // STFT +2 % and LTFT +3 % → (1 + 0.05) = 1.05.
      expect(
        applyFuelTrimCorrection(20.0, stft: 2.0, ltft: 3.0),
        closeTo(21.0, 0.001),
      );
    });
  });

  group('applyFuelTrimCorrection bank 2 — #2458', () {
    test('null bank-2 trims → bank-1-only (unchanged from pre-#2458)', () {
      // Both null → exactly the bank-1 result.
      expect(
        applyFuelTrimCorrection(10.0,
            stft: 6.0, ltft: 4.0, stftBank2: null, ltftBank2: null),
        closeTo(applyFuelTrimCorrection(10.0, stft: 6.0, ltft: 4.0), 0.0001),
      );
    });

    test('one bank-2 trim null → falls back to bank-1-only', () {
      // STFT2 present but LTFT2 null → can\'t form a bank-2 total, so
      // the correction stays bank-1-only.
      expect(
        applyFuelTrimCorrection(10.0,
            stft: 6.0, ltft: 4.0, stftBank2: 0.0, ltftBank2: null),
        closeTo(11.0, 0.001),
      );
    });

    test('both banks present → bank-averaged total', () {
      // Bank 1 total +10 % (6+4), bank 2 total -2 % (-1-1) →
      // mean +4 % → factor 1.04.
      expect(
        applyFuelTrimCorrection(10.0,
            stft: 6.0, ltft: 4.0, stftBank2: -1.0, ltftBank2: -1.0),
        closeTo(10.4, 0.001),
      );
    });

    test('symmetric banks → same as a single bank (mean = bank total)', () {
      // Both banks +10 % → mean +10 % → factor 1.10, identical to the
      // bank-1-only +10 % result.
      expect(
        applyFuelTrimCorrection(20.0,
            stft: 6.0, ltft: 4.0, stftBank2: 6.0, ltftBank2: 4.0),
        closeTo(22.0, 0.001),
      );
    });
  });

  group('estimateFuelRateLPerHourFromMap — #800', () {
    test('Peugeot 107 cruise canonical reading: 2500 RPM, 65 kPa, '
        '30 °C → plausible 2.5–6 L/h', () {
      final rate = estimateFuelRateLPerHourFromMap(
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
        engineDisplacementCc: kDefaultEngineDisplacementCc,
        volumetricEfficiency: kDefaultVolumetricEfficiency,
      );
      expect(rate, isNotNull);
      expect(rate, greaterThan(2.5));
      expect(rate, lessThan(6.0));
    });

    test('returns null on non-positive MAP', () {
      expect(
        estimateFuelRateLPerHourFromMap(
          mapKpa: 0,
          iatCelsius: 25,
          rpm: 800,
          engineDisplacementCc: 1000,
          volumetricEfficiency: 0.85,
        ),
        isNull,
      );
    });

    test('returns null at absolute zero (ideal gas law breaks down)', () {
      expect(
        estimateFuelRateLPerHourFromMap(
          mapKpa: 40,
          iatCelsius: -273.15,
          rpm: 800,
          engineDisplacementCc: 1000,
          volumetricEfficiency: 0.85,
        ),
        isNull,
      );
    });

    test('returns null on engine off (rpm == 0)', () {
      expect(
        estimateFuelRateLPerHourFromMap(
          mapKpa: 40,
          iatCelsius: 25,
          rpm: 0,
          engineDisplacementCc: 1000,
          volumetricEfficiency: 0.85,
        ),
        isNull,
      );
    });

    test('doubles with displacement at identical operating point', () {
      final small = estimateFuelRateLPerHourFromMap(
        mapKpa: 50,
        iatCelsius: 20,
        rpm: 2000,
        engineDisplacementCc: 1000,
        volumetricEfficiency: 0.85,
      )!;
      final big = estimateFuelRateLPerHourFromMap(
        mapKpa: 50,
        iatCelsius: 20,
        rpm: 2000,
        engineDisplacementCc: 2000,
        volumetricEfficiency: 0.85,
      )!;
      expect(big / small, closeTo(2.0, 0.01));
    });

    test('diesel branch: denser fuel + leaner AFR produce lower L/h '
        'per air mass than petrol', () {
      // Same inputs, different AFR + density. Diesel denominator
      // (14.5 × 832) = 12_064 is larger than petrol (14.7 × 740) =
      // 10_878, so a given air-mass flow maps to *less* diesel
      // fuel per hour — the expected relationship.
      final petrol = estimateFuelRateLPerHourFromMap(
        mapKpa: 80,
        iatCelsius: 25,
        rpm: 2000,
        engineDisplacementCc: 1600,
        volumetricEfficiency: 0.85,
      )!;
      final diesel = estimateFuelRateLPerHourFromMap(
        mapKpa: 80,
        iatCelsius: 25,
        rpm: 2000,
        engineDisplacementCc: 1600,
        volumetricEfficiency: 0.85,
        afr: kDieselAfr,
        fuelDensityGPerL: kDieselDensityGPerL,
      )!;
      expect(diesel, lessThan(petrol));
      // Ratio equals denominator ratio.
      expect(
        petrol / diesel,
        closeTo(
          (kDieselAfr * kDieselDensityGPerL) / (kPetrolAfr * kPetrolDensityGPerL),
          0.001,
        ),
      );
    });
  });

  group('effectiveAfrForLambda — #2456', () {
    test('null λ returns the stoich AFR unchanged (no-PID fallback)', () {
      expect(effectiveAfrForLambda(kPetrolAfr, null), kPetrolAfr);
      expect(effectiveAfrForLambda(kDieselAfr, null), kDieselAfr);
    });

    test('λ = 1.0 returns the stoich AFR unchanged', () {
      expect(effectiveAfrForLambda(kPetrolAfr, 1.0), closeTo(kPetrolAfr, 1e-9));
    });

    test('λ > 1 (power-enrich) lowers the effective AFR → more fuel', () {
      // afrEff = stoich / λ; richer mixture means a smaller denominator.
      expect(
        effectiveAfrForLambda(kPetrolAfr, 1.2),
        closeTo(kPetrolAfr / 1.2, 1e-9),
      );
      expect(effectiveAfrForLambda(kPetrolAfr, 1.2), lessThan(kPetrolAfr));
    });

    test('λ < 1 (lean cruise) raises the effective AFR → less fuel', () {
      expect(
        effectiveAfrForLambda(kPetrolAfr, 0.9),
        closeTo(kPetrolAfr / 0.9, 1e-9),
      );
      expect(effectiveAfrForLambda(kPetrolAfr, 0.9), greaterThan(kPetrolAfr));
    });

    test('garbage λ is clamped to [kMinLambda, kMaxLambda]', () {
      expect(
        effectiveAfrForLambda(kPetrolAfr, 5.0),
        closeTo(kPetrolAfr / kMaxLambda, 1e-9),
      );
      expect(
        effectiveAfrForLambda(kPetrolAfr, 0.01),
        closeTo(kPetrolAfr / kMinLambda, 1e-9),
      );
    });
  });

  group('estimateFuelRateLPerHourFromMap λ + baro — #2456', () {
    const mapKpa = 65.0;
    const iatCelsius = 30.0;
    const rpm = 2500.0;

    double rateWith({double? lambda, double? baroKpa}) {
      return estimateFuelRateLPerHourFromMap(
        mapKpa: mapKpa,
        iatCelsius: iatCelsius,
        rpm: rpm,
        engineDisplacementCc: kDefaultEngineDisplacementCc,
        volumetricEfficiency: kDefaultVolumetricEfficiency,
        lambda: lambda,
        baroKpa: baroKpa,
      )!;
    }

    test('absent λ + absent baro equals the pre-#2456 stoich result', () {
      final today = estimateFuelRateLPerHourFromMap(
        mapKpa: mapKpa,
        iatCelsius: iatCelsius,
        rpm: rpm,
        engineDisplacementCc: kDefaultEngineDisplacementCc,
        volumetricEfficiency: kDefaultVolumetricEfficiency,
      )!;
      // Same call but explicitly passing nulls must be byte-for-byte equal.
      expect(rateWith(lambda: null, baroKpa: null), today);
    });

    test('λ = 1.0 is identical to absent λ', () {
      expect(rateWith(lambda: 1.0), closeTo(rateWith(lambda: null), 1e-9));
    });

    test('λ = 1.2 derives ~20 % more fuel than λ = 1.0 (richer)', () {
      final stoich = rateWith(lambda: 1.0);
      final rich = rateWith(lambda: 1.2);
      expect(rich / stoich, closeTo(1.2, 0.001));
    });

    test('λ = 0.9 derives less fuel than λ = 1.0 (lean cruise)', () {
      final stoich = rateWith(lambda: 1.0);
      final lean = rateWith(lambda: 0.9);
      expect(lean, lessThan(stoich));
      expect(lean / stoich, closeTo(0.9, 0.001));
    });

    test('lower baro (altitude) reduces fuel vs sea level', () {
      final seaLevel = rateWith(baroKpa: kSeaLevelBaroKpa);
      final altitude = rateWith(baroKpa: 84.0); // ~1500 m
      expect(altitude, lessThan(seaLevel));
      // Air mass scales linearly with the baro factor.
      expect(altitude / seaLevel, closeTo(84.0 / kSeaLevelBaroKpa, 0.001));
    });

    test('baro at sea-level reference equals absent baro', () {
      expect(
        rateWith(baroKpa: kSeaLevelBaroKpa),
        closeTo(rateWith(baroKpa: null), 1e-9),
      );
    });

    test('garbage low baro is clamped (factor floor 0.6)', () {
      final clamped = rateWith(baroKpa: 10.0); // 10/101.325 ≈ 0.099 → 0.6
      final unscaled = rateWith(baroKpa: null);
      expect(clamped / unscaled, closeTo(0.6, 0.001));
    });

    test('λ and baro compose multiplicatively', () {
      final base = rateWith(lambda: 1.0, baroKpa: kSeaLevelBaroKpa);
      final both = rateWith(lambda: 1.2, baroKpa: 84.0);
      expect(
        both / base,
        closeTo(1.2 * (84.0 / kSeaLevelBaroKpa), 0.001),
      );
    });
  });

  group('resolveAfrDensity — #2432', () {
    VehicleProfile profileWith(String? fuel) => VehicleProfile(
          id: 'x',
          name: 'Test',
          preferredFuelType: fuel,
        );

    test('null profile → petrol default (safe default)', () {
      final r = resolveAfrDensity(null);
      expect(r.afr, closeTo(kPetrolAfr, 0.0001));
      expect(r.densityGPerL, closeTo(kPetrolDensityGPerL, 0.0001));
    });

    test('empty preferredFuelType → petrol default', () {
      final r = resolveAfrDensity(profileWith(null));
      expect(r.afr, closeTo(kPetrolAfr, 0.0001));
      expect(r.densityGPerL, closeTo(kPetrolDensityGPerL, 0.0001));
    });

    test('unrecognised fuel key → petrol default', () {
      final r = resolveAfrDensity(profileWith('hydrogen'));
      expect(r.afr, closeTo(kPetrolAfr, 0.0001));
      expect(r.densityGPerL, closeTo(kPetrolDensityGPerL, 0.0001));
    });

    test('petrol-class keys → petrol constants', () {
      for (final fuel in ['petrol', 'e10', 'e5', 'super', 'Gasoline']) {
        final r = resolveAfrDensity(profileWith(fuel));
        expect(r.afr, closeTo(kPetrolAfr, 0.0001), reason: 'AFR for $fuel');
        expect(
          r.densityGPerL,
          closeTo(kPetrolDensityGPerL, 0.0001),
          reason: 'density for $fuel',
        );
      }
    });

    test('diesel + dieselPremium → diesel constants', () {
      for (final fuel in ['diesel', 'dieselPremium', '  DIESEL  ']) {
        final r = resolveAfrDensity(profileWith(fuel));
        expect(r.afr, closeTo(kDieselAfr, 0.0001), reason: 'AFR for $fuel');
        expect(
          r.densityGPerL,
          closeTo(kDieselDensityGPerL, 0.0001),
          reason: 'density for $fuel',
        );
      }
    });

    test('e85 + ethanol keys → E85 constants', () {
      for (final fuel in ['e85', 'E85', 'ethanol']) {
        final r = resolveAfrDensity(profileWith(fuel));
        expect(r.afr, closeTo(kE85Afr, 0.0001), reason: 'AFR for $fuel');
        expect(
          r.densityGPerL,
          closeTo(kE85DensityGPerL, 0.0001),
          reason: 'density for $fuel',
        );
      }
    });

    test('lpg + autogas keys → LPG constants', () {
      for (final fuel in ['lpg', 'LPG', 'autogas']) {
        final r = resolveAfrDensity(profileWith(fuel));
        expect(r.afr, closeTo(kLpgAfr, 0.0001), reason: 'AFR for $fuel');
        expect(
          r.densityGPerL,
          closeTo(kLpgDensityGPerL, 0.0001),
          reason: 'density for $fuel',
        );
      }
    });

    test('cng → petrol default (gaseous: no meaningful liquid g/L)', () {
      // CNG has no liquid L/h, so it follows the documented
      // "unknown → petrol, safer to under-count" rule (kept green by
      // obd2_service_maf_fallback_test). kCngAfr stays exposed for a
      // future native-units follow-up — see #2432.
      final r = resolveAfrDensity(profileWith('cng'));
      expect(r.afr, closeTo(kPetrolAfr, 0.0001));
      expect(r.densityGPerL, closeTo(kPetrolDensityGPerL, 0.0001));
    });

    test('manual AFR override wins over the fuel-type mapping', () {
      const vehicle = VehicleProfile(
        id: 'x',
        name: 'Test',
        preferredFuelType: 'diesel',
        manualAfrOverride: 12.3,
      );
      final r = resolveAfrDensity(vehicle);
      expect(r.afr, closeTo(12.3, 0.0001));
      // density falls through to the diesel mapping (no override set).
      expect(r.densityGPerL, closeTo(kDieselDensityGPerL, 0.0001));
    });

    test('manual density override wins over the fuel-type mapping', () {
      const vehicle = VehicleProfile(
        id: 'x',
        name: 'Test',
        preferredFuelType: 'e85',
        manualFuelDensityGPerLOverride: 799.0,
      );
      final r = resolveAfrDensity(vehicle);
      // AFR falls through to the E85 mapping (no override set).
      expect(r.afr, closeTo(kE85Afr, 0.0001));
      expect(r.densityGPerL, closeTo(799.0, 0.0001));
    });

    test('both overrides win regardless of fuel key', () {
      const vehicle = VehicleProfile(
        id: 'x',
        name: 'Test',
        preferredFuelType: 'petrol',
        manualAfrOverride: 11.0,
        manualFuelDensityGPerLOverride: 700.0,
      );
      final r = resolveAfrDensity(vehicle);
      expect(r.afr, closeTo(11.0, 0.0001));
      expect(r.densityGPerL, closeTo(700.0, 0.0001));
    });

    test('fallbackFuelType maps when there is no profile', () {
      final r = resolveAfrDensity(null, fallbackFuelType: 'diesel');
      expect(r.afr, closeTo(kDieselAfr, 0.0001));
      expect(r.densityGPerL, closeTo(kDieselDensityGPerL, 0.0001));
    });

    test('profile preferredFuelType beats fallbackFuelType', () {
      final r = resolveAfrDensity(
        profileWith('e85'),
        fallbackFuelType: 'diesel',
      );
      expect(r.afr, closeTo(kE85Afr, 0.0001));
      expect(r.densityGPerL, closeTo(kE85DensityGPerL, 0.0001));
    });
  });

  group('E85 under-count fix — #2432', () {
    test('E85 profile yields ~30 %+ higher L/h than the old petrol '
        'default for the same MAF operating point', () {
      const mapKpa = 80.0;
      const iat = 25.0;
      const rpm = 2000.0;
      const displacementCc = 1600;
      const ve = 0.85;

      // New behaviour: an E85 profile resolves to E85 AFR/density.
      final e85 = resolveAfrDensity(
        const VehicleProfile(id: 'x', name: 'E85', preferredFuelType: 'e85'),
      );
      final e85Rate = estimateFuelRateLPerHourFromMap(
        mapKpa: mapKpa,
        iatCelsius: iat,
        rpm: rpm,
        engineDisplacementCc: displacementCc,
        volumetricEfficiency: ve,
        afr: e85.afr,
        fuelDensityGPerL: e85.densityGPerL,
      )!;

      // Old behaviour: the binary branch sent E85 down the petrol path.
      final petrolRate = estimateFuelRateLPerHourFromMap(
        mapKpa: mapKpa,
        iatCelsius: iat,
        rpm: rpm,
        engineDisplacementCc: displacementCc,
        volumetricEfficiency: ve,
        afr: kPetrolAfr,
        fuelDensityGPerL: kPetrolDensityGPerL,
      )!;

      // (14.7×740)/(9.8×785) = 10878/7693 ≈ 1.414 → ~41 % higher.
      expect(e85Rate / petrolRate, greaterThan(1.30));
      expect(
        e85Rate / petrolRate,
        closeTo(
          (kPetrolAfr * kPetrolDensityGPerL) / (kE85Afr * kE85DensityGPerL),
          0.001,
        ),
      );
    });
  });

  group('stoichiometric constants — #800', () {
    test('petrol AFR ~14.7 kg/kg', () {
      expect(kPetrolAfr, closeTo(14.7, 0.0001));
    });

    test('diesel AFR ~14.5 kg/kg', () {
      expect(kDieselAfr, closeTo(14.5, 0.0001));
    });

    test('petrol density 740 g/L (legacy Tankstellen constant)', () {
      expect(kPetrolDensityGPerL, closeTo(740.0, 0.0001));
    });

    test('diesel density 832 g/L (EN 590 reference)', () {
      expect(kDieselDensityGPerL, closeTo(832.0, 0.0001));
    });

    test('E85 AFR ~9.8 + density 785 g/L (#2432)', () {
      expect(kE85Afr, closeTo(9.8, 0.0001));
      expect(kE85DensityGPerL, closeTo(785.0, 0.0001));
    });

    test('LPG AFR ~15.6 + density 535 g/L (#2432)', () {
      expect(kLpgAfr, closeTo(15.6, 0.0001));
      expect(kLpgDensityGPerL, closeTo(535.0, 0.0001));
    });

    test('CNG AFR ~17.2 + petrol-equivalent density (#2432)', () {
      expect(kCngAfr, closeTo(17.2, 0.0001));
      expect(kCngEquivalentDensityGPerL, closeTo(kPetrolDensityGPerL, 0.0001));
    });

    test('default displacement 1000 cc (Peugeot 107 class)', () {
      expect(kDefaultEngineDisplacementCc, 1000);
    });

    test('default volumetric efficiency 0.85', () {
      expect(kDefaultVolumetricEfficiency, closeTo(0.85, 0.0001));
    });
  });
}
