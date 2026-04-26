import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/add_fill_up_fuel_resolver.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

/// Unit tests for the pure helpers extracted from
/// `add_fill_up_screen.dart` (#563 refactor). Covers:
///
///   * fuelForVehicle's three branches (EV → electric, configured
///     fuel → parsed, unconfigured combustion → null).
///   * resolveDefaultFuel's full preference chain (preFill →
///     profilePreferred → vehicle's fuel → e10).
///   * pickInitialVehicleId's three branches (profile default →
///     active vehicle → first in list) plus the empty-list edge case.
void main() {
  const petrolCar = VehicleProfile(
    id: 'petrol-1',
    name: 'Petrol Car',
    type: VehicleType.combustion,
    preferredFuelType: 'e10',
  );

  const flexFuelCar = VehicleProfile(
    id: 'flex-1',
    name: 'Flex-Fuel Car',
    type: VehicleType.combustion,
    preferredFuelType: 'e85',
  );

  const dieselCar = VehicleProfile(
    id: 'diesel-1',
    name: 'Diesel Car',
    type: VehicleType.combustion,
    preferredFuelType: 'diesel',
  );

  const electricCar = VehicleProfile(
    id: 'ev-1',
    name: 'Electric Car',
    type: VehicleType.ev,
  );

  const unconfiguredCar = VehicleProfile(
    id: 'unconf-1',
    name: 'Unconfigured Car',
    type: VehicleType.combustion,
  );

  group('AddFillUpFuelResolver.fuelForVehicle', () {
    test('EV vehicle resolves to electric regardless of stored fuel', () {
      expect(
        AddFillUpFuelResolver.fuelForVehicle(electricCar),
        equals(FuelType.electric),
      );
    });

    test('combustion vehicle resolves to its preferredFuelType', () {
      expect(
        AddFillUpFuelResolver.fuelForVehicle(petrolCar),
        equals(FuelType.e10),
      );
      expect(
        AddFillUpFuelResolver.fuelForVehicle(dieselCar),
        equals(FuelType.diesel),
      );
    });

    test('unconfigured combustion vehicle resolves to null', () {
      expect(
        AddFillUpFuelResolver.fuelForVehicle(unconfiguredCar),
        isNull,
      );
    });

    test('empty-string preferredFuelType resolves to null', () {
      const car = VehicleProfile(
        id: 'x',
        name: 'X',
        type: VehicleType.combustion,
        preferredFuelType: '   ',
      );
      expect(AddFillUpFuelResolver.fuelForVehicle(car), isNull);
    });
  });

  group('AddFillUpFuelResolver.resolveDefaultFuel', () {
    test('preFill wins when compatible with the vehicle', () {
      // Petrol car accepts E10/E5/E98/E85 — pre-fill with E5 must
      // surface as the default even though the vehicle's preferred is
      // E10.
      expect(
        AddFillUpFuelResolver.resolveDefaultFuel(
          vehicle: petrolCar,
          preFill: FuelType.e5,
        ),
        equals(FuelType.e5),
      );
    });

    test('preFill ignored when not compatible (petrol car, diesel preFill)',
        () {
      expect(
        AddFillUpFuelResolver.resolveDefaultFuel(
          vehicle: petrolCar,
          preFill: FuelType.diesel,
        ),
        equals(FuelType.e10),
      );
    });

    test('profilePreferred used when no preFill and compatible', () {
      // Flex-fuel car (E85 family) — profile preferred E10 is in the
      // petrol compatibility set, so it wins over the vehicle's E85.
      expect(
        AddFillUpFuelResolver.resolveDefaultFuel(
          vehicle: flexFuelCar,
          profilePreferred: FuelType.e10,
        ),
        equals(FuelType.e10),
      );
    });

    test(
      'profilePreferred ignored when not compatible — falls back to '
      "vehicle's own fuel",
      () {
        expect(
          AddFillUpFuelResolver.resolveDefaultFuel(
            vehicle: petrolCar,
            profilePreferred: FuelType.diesel,
          ),
          equals(FuelType.e10),
        );
      },
    );

    test("falls back to the vehicle's own fuel when nothing else applies",
        () {
      expect(
        AddFillUpFuelResolver.resolveDefaultFuel(vehicle: dieselCar),
        equals(FuelType.diesel),
      );
    });

    test('falls back to e10 when the vehicle has no configured fuel', () {
      expect(
        AddFillUpFuelResolver.resolveDefaultFuel(vehicle: unconfiguredCar),
        equals(FuelType.e10),
      );
    });
  });

  group('AddFillUpFuelResolver.pickInitialVehicleId', () {
    test('empty list returns null', () {
      expect(
        AddFillUpFuelResolver.pickInitialVehicleId(vehicles: const []),
        isNull,
      );
    });

    test('profile default wins when present in the list', () {
      expect(
        AddFillUpFuelResolver.pickInitialVehicleId(
          vehicles: const [petrolCar, dieselCar],
          profileDefaultId: 'diesel-1',
          activeVehicleId: 'petrol-1',
        ),
        equals('diesel-1'),
      );
    });

    test('falls back to active vehicle when profile default is missing', () {
      expect(
        AddFillUpFuelResolver.pickInitialVehicleId(
          vehicles: const [petrolCar, dieselCar],
          profileDefaultId: 'ghost-vehicle',
          activeVehicleId: 'diesel-1',
        ),
        equals('diesel-1'),
      );
    });

    test('falls back to first vehicle when nothing matches', () {
      expect(
        AddFillUpFuelResolver.pickInitialVehicleId(
          vehicles: const [petrolCar, dieselCar],
          profileDefaultId: 'ghost-1',
          activeVehicleId: 'ghost-2',
        ),
        equals('petrol-1'),
      );
    });

    test('falls back to first vehicle when no hints provided', () {
      expect(
        AddFillUpFuelResolver.pickInitialVehicleId(
          vehicles: const [petrolCar, dieselCar],
        ),
        equals('petrol-1'),
      );
    });
  });
}
