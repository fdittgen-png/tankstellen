import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

void main() {
  group('fuelCompatibilityFamily', () {
    test('petrol fuels map to the petrol family', () {
      expect(
        fuelCompatibilityFamily(FuelType.e5),
        FuelCompatibilityFamily.petrol,
      );
      expect(
        fuelCompatibilityFamily(FuelType.e10),
        FuelCompatibilityFamily.petrol,
      );
      expect(
        fuelCompatibilityFamily(FuelType.e98),
        FuelCompatibilityFamily.petrol,
      );
      expect(
        fuelCompatibilityFamily(FuelType.e85),
        FuelCompatibilityFamily.petrol,
      );
    });

    test('diesel + dieselPremium map to diesel family', () {
      expect(
        fuelCompatibilityFamily(FuelType.diesel),
        FuelCompatibilityFamily.diesel,
      );
      expect(
        fuelCompatibilityFamily(FuelType.dieselPremium),
        FuelCompatibilityFamily.diesel,
      );
    });

    test('LPG / CNG / electric / hydrogen are their own families', () {
      expect(
        fuelCompatibilityFamily(FuelType.lpg),
        FuelCompatibilityFamily.lpg,
      );
      expect(
        fuelCompatibilityFamily(FuelType.cng),
        FuelCompatibilityFamily.cng,
      );
      expect(
        fuelCompatibilityFamily(FuelType.electric),
        FuelCompatibilityFamily.electric,
      );
      expect(
        fuelCompatibilityFamily(FuelType.hydrogen),
        FuelCompatibilityFamily.hydrogen,
      );
    });
  });

  group('compatibleFuelsFor', () {
    test(
        'petrol primary yields e10/e5/e98/e85 with the primary pinned first',
        () {
      expect(
        compatibleFuelsFor(FuelType.e85),
        [FuelType.e85, FuelType.e10, FuelType.e5, FuelType.e98],
      );
      expect(
        compatibleFuelsFor(FuelType.e10),
        [FuelType.e10, FuelType.e5, FuelType.e98, FuelType.e85],
      );
    });

    test(
        'diesel primary yields diesel + dieselPremium with primary first',
        () {
      expect(
        compatibleFuelsFor(FuelType.diesel),
        [FuelType.diesel, FuelType.dieselPremium],
      );
      expect(
        compatibleFuelsFor(FuelType.dieselPremium),
        [FuelType.dieselPremium, FuelType.diesel],
      );
    });

    test('single-fuel families return a one-entry list', () {
      expect(compatibleFuelsFor(FuelType.lpg), [FuelType.lpg]);
      expect(compatibleFuelsFor(FuelType.cng), [FuelType.cng]);
      expect(compatibleFuelsFor(FuelType.electric), [FuelType.electric]);
      expect(compatibleFuelsFor(FuelType.hydrogen), [FuelType.hydrogen]);
    });
  });
}
