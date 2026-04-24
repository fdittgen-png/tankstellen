import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/fuel_rate_estimator.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

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

  group('isDieselProfile — #800', () {
    test('null profile → false (safe default is petrol)', () {
      expect(isDieselProfile(null), isFalse);
    });

    test('empty preferredFuelType → false', () {
      const vehicle = VehicleProfile(id: 'x', name: 'Test');
      expect(isDieselProfile(vehicle), isFalse);
    });

    test('preferredFuelType "diesel" → true', () {
      const vehicle = VehicleProfile(
        id: 'x',
        name: 'Test',
        preferredFuelType: 'diesel',
      );
      expect(isDieselProfile(vehicle), isTrue);
    });

    test('preferredFuelType with diesel variant (dieselPremium) → true', () {
      const vehicle = VehicleProfile(
        id: 'x',
        name: 'Test',
        preferredFuelType: 'dieselPremium',
      );
      expect(isDieselProfile(vehicle), isTrue);
    });

    test('petrol-class fuel types → false', () {
      for (final fuel in ['e5', 'e10', 'super', 'petrol', 'Gasoline']) {
        final vehicle = VehicleProfile(
          id: 'x',
          name: 'Test',
          preferredFuelType: fuel,
        );
        expect(isDieselProfile(vehicle), isFalse, reason: 'for $fuel');
      }
    });

    test('whitespace + mixed case normalisation', () {
      const vehicle = VehicleProfile(
        id: 'x',
        name: 'Test',
        preferredFuelType: '  DIESEL  ',
      );
      expect(isDieselProfile(vehicle), isTrue);
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

    test('default displacement 1000 cc (Peugeot 107 class)', () {
      expect(kDefaultEngineDisplacementCc, 1000);
    });

    test('default volumetric efficiency 0.85', () {
      expect(kDefaultVolumetricEfficiency, closeTo(0.85, 0.0001));
    });
  });
}
