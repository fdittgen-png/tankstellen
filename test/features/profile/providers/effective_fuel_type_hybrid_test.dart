import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/effective_fuel_type_provider.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// Hybrid-fuel-choice wiring (#706). The effective fuel for a hybrid
/// default vehicle should:
/// - honour the profile's `hybridFuelChoice` when set;
/// - fall back to the vehicle's own combustion fuel pre-migration;
/// - still treat EV and combustion vehicles the same as before.

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
  return ProviderContainer(
    overrides: [
      activeProfileProvider.overrideWith(() => _FixedProfile(profile)),
      vehicleProfileListProvider.overrideWith(() => _FixedVehicles(vehicles)),
    ],
  );
}

const _hybrid = VehicleProfile(
  id: 'v-hybrid',
  name: 'Prius',
  type: VehicleType.hybrid,
  preferredFuelType: 'e10',
);

UserProfile _profileWith({
  required String defaultVehicleId,
  FuelType? hybridFuelChoice,
  FuelType preferredFuelType = FuelType.e10,
}) {
  return UserProfile(
    id: 'p1',
    name: 'p1',
    preferredFuelType: preferredFuelType,
    defaultVehicleId: defaultVehicleId,
    hybridFuelChoice: hybridFuelChoice,
  );
}

void main() {
  group('effectiveFuelType hybrid (#706)', () {
    test(
        'hybrid default vehicle + profile.hybridFuelChoice = electric '
        '→ electric', () {
      final c = _container(
        profile: _profileWith(
          defaultVehicleId: 'v-hybrid',
          hybridFuelChoice: FuelType.electric,
        ),
        vehicles: [_hybrid],
      );
      addTearDown(c.dispose);
      expect(c.read(effectiveFuelTypeProvider), FuelType.electric);
    });

    test(
        'hybrid default vehicle + profile.hybridFuelChoice = e85 '
        '→ e85 (overrides the vehicle\'s own e10)', () {
      final c = _container(
        profile: _profileWith(
          defaultVehicleId: 'v-hybrid',
          hybridFuelChoice: FuelType.e85,
        ),
        vehicles: [_hybrid],
      );
      addTearDown(c.dispose);
      expect(c.read(effectiveFuelTypeProvider), FuelType.e85);
    });

    test(
        'hybrid default vehicle with NO hybridFuelChoice falls back to the '
        'vehicle\'s combustion fuel (pre-migration behaviour)', () {
      final c = _container(
        profile: _profileWith(defaultVehicleId: 'v-hybrid'),
        vehicles: [_hybrid],
      );
      addTearDown(c.dispose);
      expect(c.read(effectiveFuelTypeProvider), FuelType.e10);
    });

    test(
        'non-hybrid default vehicle ignores hybridFuelChoice (choice is '
        'meaningless here)', () {
      const combustion = VehicleProfile(
        id: 'v-ice',
        name: 'Golf',
        type: VehicleType.combustion,
        preferredFuelType: 'diesel',
      );
      final c = _container(
        profile: _profileWith(
          defaultVehicleId: 'v-ice',
          hybridFuelChoice: FuelType.electric,
        ),
        vehicles: [combustion],
      );
      addTearDown(c.dispose);
      expect(c.read(effectiveFuelTypeProvider), FuelType.diesel);
    });

    test('EV default vehicle is still electric regardless of hybrid choice',
        () {
      const ev = VehicleProfile(id: 'v-ev', name: 'Model 3', type: VehicleType.ev);
      final c = _container(
        profile: _profileWith(
          defaultVehicleId: 'v-ev',
          hybridFuelChoice: FuelType.e85,
        ),
        vehicles: [ev],
      );
      addTearDown(c.dispose);
      expect(c.read(effectiveFuelTypeProvider), FuelType.electric);
    });
  });
}
