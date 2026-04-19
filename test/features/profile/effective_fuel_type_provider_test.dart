import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/effective_fuel_type_provider.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// #705 — Effective fuel type contract.
///
/// Pins the vehicle-driven derivation so every app surface (search
/// chips, consumption, station filter) can read one provider and get
/// the same answer.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('effective_fuel_test_');
    Hive.init(tempDir.path);
    await HiveStorage.initForTest();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ProviderContainer containerWith({
    required UserProfile profile,
    required List<VehicleProfile> vehicles,
  }) {
    final c = ProviderContainer(overrides: [
      activeProfileProvider.overrideWith(() => _FixedProfile(profile)),
      vehicleProfileListProvider
          .overrideWith(() => _FixedVehicleList(vehicles)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('no default vehicle → profile.preferredFuelType wins', () {
    final c = containerWith(
      profile: const UserProfile(
        id: 'p1',
        name: 'p',
        preferredFuelType: FuelType.diesel,
      ),
      vehicles: const [],
    );
    expect(c.read(effectiveFuelTypeProvider), FuelType.diesel);
  });

  test('EV default vehicle → electric regardless of profile fuel', () {
    const ev = VehicleProfile(id: 'v1', name: 'Model 3', type: VehicleType.ev);
    final c = containerWith(
      profile: const UserProfile(
        id: 'p1',
        name: 'p',
        preferredFuelType: FuelType.e10,
        defaultVehicleId: 'v1',
      ),
      vehicles: const [ev],
    );
    expect(c.read(effectiveFuelTypeProvider), FuelType.electric);
  });

  test('combustion default vehicle → vehicle.preferredFuelType wins', () {
    const v = VehicleProfile(
      id: 'v1',
      name: '208',
      type: VehicleType.combustion,
      preferredFuelType: 'diesel',
    );
    final c = containerWith(
      profile: const UserProfile(
        id: 'p1',
        name: 'p',
        preferredFuelType: FuelType.e10,
        defaultVehicleId: 'v1',
      ),
      vehicles: const [v],
    );
    expect(c.read(effectiveFuelTypeProvider), FuelType.diesel);
  });

  test(
    'combustion vehicle WITHOUT preferredFuelType → falls back to profile',
    () {
      const v = VehicleProfile(
        id: 'v1',
        name: 'Unspecified',
        type: VehicleType.combustion,
      );
      final c = containerWith(
        profile: const UserProfile(
          id: 'p1',
          name: 'p',
          preferredFuelType: FuelType.e85,
          defaultVehicleId: 'v1',
        ),
        vehicles: const [v],
      );
      expect(c.read(effectiveFuelTypeProvider), FuelType.e85);
    },
  );

  test(
    'hybrid default vehicle → falls back to profile until #704 ships '
    'hybridFuelChoice',
    () {
      const v = VehicleProfile(
        id: 'v1',
        name: 'Prius',
        type: VehicleType.hybrid,
        preferredFuelType: 'e10',
      );
      final c = containerWith(
        profile: const UserProfile(
          id: 'p1',
          name: 'p',
          preferredFuelType: FuelType.e5,
          defaultVehicleId: 'v1',
        ),
        vehicles: const [v],
      );
      // Hybrid deliberately skipped here — caller falls back.
      expect(c.read(effectiveFuelTypeProvider), FuelType.e5);
    },
  );

  test('defaultVehicleId pointing at a removed vehicle → profile wins', () {
    final c = containerWith(
      profile: const UserProfile(
        id: 'p1',
        name: 'p',
        preferredFuelType: FuelType.diesel,
        defaultVehicleId: 'ghost',
      ),
      vehicles: const [],
    );
    expect(c.read(effectiveFuelTypeProvider), FuelType.diesel);
  });

  test('no profile at all → default FuelType.e10', () {
    final c = containerWith(
      profile: const UserProfile(id: 'p1', name: ''),
      vehicles: const [],
    );
    // Default profile has preferredFuelType = e10 (freezed @Default).
    expect(c.read(effectiveFuelTypeProvider), FuelType.e10);
  });
}

class _FixedProfile extends ActiveProfile {
  final UserProfile _profile;
  _FixedProfile(this._profile);
  @override
  UserProfile? build() => _profile;
}

class _FixedVehicleList extends VehicleProfileList {
  final List<VehicleProfile> _vehicles;
  _FixedVehicleList(this._vehicles);
  @override
  List<VehicleProfile> build() => _vehicles;
}
