import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/effective_fuel_type_provider.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// Exhaustive coverage for `effectiveFuelTypeProvider` (#694/#700/#706).
///
/// Every branch of the priority chain is pinned so a future refactor of
/// the vehicle-vs-profile resolution has a single test file to consult.

class _FixedProfile extends ActiveProfile {
  _FixedProfile(this._profile);
  final UserProfile? _profile;
  @override
  UserProfile? build() => _profile;
}

class _FixedVehicles extends VehicleProfileList {
  _FixedVehicles(this._list);
  final List<VehicleProfile> _list;
  @override
  List<VehicleProfile> build() => _list;
}

ProviderContainer _container({
  UserProfile? profile,
  List<VehicleProfile> vehicles = const [],
}) {
  final c = ProviderContainer(
    overrides: [
      activeProfileProvider.overrideWith(() => _FixedProfile(profile)),
      vehicleProfileListProvider.overrideWith(() => _FixedVehicles(vehicles)),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

UserProfile _profile({
  FuelType? preferredFuelType,
  String? defaultVehicleId,
  FuelType? hybridFuelChoice,
}) {
  // `preferredFuelType` has a freezed @Default of FuelType.e10, so a
  // call site that passes `null` ends up with e10 unless we explicitly
  // route around the default. All callers below pass an explicit value
  // when they care; otherwise the test pinpoints the default branch.
  return UserProfile(
    id: 'p1',
    name: 'p',
    preferredFuelType: preferredFuelType ?? FuelType.e10,
    defaultVehicleId: defaultVehicleId,
    hybridFuelChoice: hybridFuelChoice,
  );
}

void main() {
  group('effectiveFuelTypeProvider — no-profile / profile-only branches', () {
    test('no profile at all → FuelType.e10 (built-in fallback)', () {
      final c = _container();
      expect(c.read(effectiveFuelTypeProvider), FuelType.e10);
    });

    test(
      'profile, no defaultVehicleId → profile.preferredFuelType wins',
      () {
        final c = _container(
          profile: _profile(preferredFuelType: FuelType.diesel),
        );
        expect(c.read(effectiveFuelTypeProvider), FuelType.diesel);
      },
    );

    test(
      'defaultVehicleId set but no matching vehicle → profile.preferredFuelType',
      () {
        final c = _container(
          profile: _profile(
            preferredFuelType: FuelType.e5,
            defaultVehicleId: 'ghost',
          ),
          vehicles: const [],
        );
        expect(c.read(effectiveFuelTypeProvider), FuelType.e5);
      },
    );
  });

  group('effectiveFuelTypeProvider — EV branch', () {
    test('default vehicle is EV → FuelType.electric', () {
      const ev = VehicleProfile(
        id: 'v-ev',
        name: 'Model 3',
        type: VehicleType.ev,
      );
      final c = _container(
        profile: _profile(
          preferredFuelType: FuelType.e10,
          defaultVehicleId: 'v-ev',
        ),
        vehicles: const [ev],
      );
      expect(c.read(effectiveFuelTypeProvider), FuelType.electric);
    });
  });

  group('effectiveFuelTypeProvider — combustion branch', () {
    test('combustion vehicle with fuel "diesel" → FuelType.diesel', () {
      const v = VehicleProfile(
        id: 'v-ice',
        name: '208',
        type: VehicleType.combustion,
        preferredFuelType: 'diesel',
      );
      final c = _container(
        profile: _profile(
          preferredFuelType: FuelType.e10,
          defaultVehicleId: 'v-ice',
        ),
        vehicles: const [v],
      );
      expect(c.read(effectiveFuelTypeProvider), FuelType.diesel);
    });

    test(
      'combustion vehicle with fuel "E10" (uppercase) → FuelType.e10 '
      '(fromString is case-insensitive)',
      () {
        const v = VehicleProfile(
          id: 'v-ice',
          name: 'Golf',
          type: VehicleType.combustion,
          preferredFuelType: 'E10',
        );
        final c = _container(
          profile: _profile(
            preferredFuelType: FuelType.diesel,
            defaultVehicleId: 'v-ice',
          ),
          vehicles: const [v],
        );
        expect(c.read(effectiveFuelTypeProvider), FuelType.e10);
      },
    );

    test('combustion vehicle with fuel "e5" → FuelType.e5', () {
      const v = VehicleProfile(
        id: 'v-ice',
        name: 'Yaris',
        type: VehicleType.combustion,
        preferredFuelType: 'e5',
      );
      final c = _container(
        profile: _profile(
          preferredFuelType: FuelType.diesel,
          defaultVehicleId: 'v-ice',
        ),
        vehicles: const [v],
      );
      expect(c.read(effectiveFuelTypeProvider), FuelType.e5);
    });

    test(
      'combustion vehicle with null fuel → falls back to profile fuel',
      () {
        const v = VehicleProfile(
          id: 'v-ice',
          name: 'Unspecified',
          type: VehicleType.combustion,
          // preferredFuelType omitted (null by default).
        );
        final c = _container(
          profile: _profile(
            preferredFuelType: FuelType.e85,
            defaultVehicleId: 'v-ice',
          ),
          vehicles: const [v],
        );
        expect(c.read(effectiveFuelTypeProvider), FuelType.e85);
      },
    );

    test(
      'combustion vehicle with empty-string fuel → falls back to profile fuel',
      () {
        const v = VehicleProfile(
          id: 'v-ice',
          name: 'Blank',
          type: VehicleType.combustion,
          preferredFuelType: '',
        );
        final c = _container(
          profile: _profile(
            preferredFuelType: FuelType.dieselPremium,
            defaultVehicleId: 'v-ice',
          ),
          vehicles: const [v],
        );
        expect(c.read(effectiveFuelTypeProvider), FuelType.dieselPremium);
      },
    );

    test(
      'combustion vehicle with whitespace-only fuel → falls back to profile',
      () {
        const v = VehicleProfile(
          id: 'v-ice',
          name: 'Whitespace',
          type: VehicleType.combustion,
          preferredFuelType: '   ',
        );
        final c = _container(
          profile: _profile(
            preferredFuelType: FuelType.lpg,
            defaultVehicleId: 'v-ice',
          ),
          vehicles: const [v],
        );
        expect(c.read(effectiveFuelTypeProvider), FuelType.lpg);
      },
    );
  });

  group('effectiveFuelTypeProvider — hybrid branch', () {
    test(
      'hybrid vehicle + profile.hybridFuelChoice = diesel → FuelType.diesel '
      '(overrides the vehicle\'s own e10 label)',
      () {
        const v = VehicleProfile(
          id: 'v-hybrid',
          name: 'Prius',
          type: VehicleType.hybrid,
          preferredFuelType: 'e10',
        );
        final c = _container(
          profile: _profile(
            preferredFuelType: FuelType.e5,
            defaultVehicleId: 'v-hybrid',
            hybridFuelChoice: FuelType.diesel,
          ),
          vehicles: const [v],
        );
        expect(c.read(effectiveFuelTypeProvider), FuelType.diesel);
      },
    );

    test(
      'hybrid vehicle, null hybridFuelChoice, vehicle fuel "diesel" → diesel',
      () {
        const v = VehicleProfile(
          id: 'v-hybrid',
          name: 'Plug-in',
          type: VehicleType.hybrid,
          preferredFuelType: 'diesel',
        );
        final c = _container(
          profile: _profile(
            preferredFuelType: FuelType.e5,
            defaultVehicleId: 'v-hybrid',
          ),
          vehicles: const [v],
        );
        expect(c.read(effectiveFuelTypeProvider), FuelType.diesel);
      },
    );

    test(
      'hybrid vehicle, null hybridFuelChoice, null vehicle fuel '
      '→ falls back to profile.preferredFuelType',
      () {
        const v = VehicleProfile(
          id: 'v-hybrid',
          name: 'Unspecified',
          type: VehicleType.hybrid,
          // preferredFuelType omitted.
        );
        final c = _container(
          profile: _profile(
            preferredFuelType: FuelType.e98,
            defaultVehicleId: 'v-hybrid',
          ),
          vehicles: const [v],
        );
        expect(c.read(effectiveFuelTypeProvider), FuelType.e98);
      },
    );

    test(
      'hybrid vehicle, null hybridFuelChoice, empty vehicle fuel '
      '→ falls back to profile.preferredFuelType',
      () {
        const v = VehicleProfile(
          id: 'v-hybrid',
          name: 'Blank',
          type: VehicleType.hybrid,
          preferredFuelType: '',
        );
        final c = _container(
          profile: _profile(
            preferredFuelType: FuelType.e85,
            defaultVehicleId: 'v-hybrid',
          ),
          vehicles: const [v],
        );
        expect(c.read(effectiveFuelTypeProvider), FuelType.e85);
      },
    );
  });
}
