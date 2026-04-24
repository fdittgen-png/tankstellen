import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/effective_fuel_type_provider.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

/// Coverage for the search-filters providers (#727):
/// - [SearchLocation] — plain string holder.
/// - [SelectedFuelType] — profile-aware chip selection with
///   `FuelType.all` wildcard before onboarding.
/// - [SearchRadius] — clamped to 1.0 … 25.0.
/// - [fuelStations] — extracts [Station] objects from a unified search
///   result stream, dropping EV entries.

class _FixedProfile extends ActiveProfile {
  _FixedProfile(this._profile);
  final UserProfile? _profile;
  @override
  UserProfile? build() => _profile;
}

class _FakeSearchState extends SearchState {
  _FakeSearchState(this._value);
  final AsyncValue<ServiceResult<List<SearchResultItem>>> _value;

  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() => _value;
}

AsyncValue<ServiceResult<List<SearchResultItem>>> _dataState(
  List<SearchResultItem> items,
) {
  return AsyncValue.data(
    ServiceResult(
      data: items,
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
    ),
  );
}

Station _station(String id) => Station(
      id: id,
      name: 'Station $id',
      brand: 'TEST',
      street: 'Teststr.',
      postCode: '10115',
      place: 'Testtown',
      lat: 52.5,
      lng: 13.4,
      isOpen: true,
    );

ChargingStation _charger(String id) => ChargingStation(
      id: id,
      name: 'Charger $id',
      latitude: 52.5,
      longitude: 13.4,
    );

void main() {
  group('SearchLocation notifier', () {
    test('initial state is empty string', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(searchLocationProvider), '');
    });

    test('set() updates the state', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(searchLocationProvider.notifier).set('12345 Berlin');
      expect(c.read(searchLocationProvider), '12345 Berlin');
    });
  });

  group('SelectedFuelType notifier', () {
    test('no active profile → FuelType.all wildcard', () {
      final c = ProviderContainer(
        overrides: [
          activeProfileProvider.overrideWith(() => _FixedProfile(null)),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(selectedFuelTypeProvider), FuelType.all);
    });

    test(
      'profile present → reads effectiveFuelTypeProvider '
      '(here overridden to diesel)',
      () {
        final c = ProviderContainer(
          overrides: [
            activeProfileProvider.overrideWith(
              () => _FixedProfile(
                const UserProfile(
                  id: 'p1',
                  name: 'p',
                  preferredFuelType: FuelType.e10,
                ),
              ),
            ),
            effectiveFuelTypeProvider.overrideWithValue(FuelType.diesel),
          ],
        );
        addTearDown(c.dispose);
        expect(c.read(selectedFuelTypeProvider), FuelType.diesel);
      },
    );

    test('select() updates the state', () {
      final c = ProviderContainer(
        overrides: [
          activeProfileProvider.overrideWith(() => _FixedProfile(null)),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(selectedFuelTypeProvider), FuelType.all);
      c.read(selectedFuelTypeProvider.notifier).select(FuelType.diesel);
      expect(c.read(selectedFuelTypeProvider), FuelType.diesel);
    });
  });

  group('SearchRadius notifier', () {
    test('no profile → default 10.0 km', () {
      final c = ProviderContainer(
        overrides: [
          activeProfileProvider.overrideWith(() => _FixedProfile(null)),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(searchRadiusProvider), 10.0);
    });

    test('profile with defaultSearchRadius: 5.0 → 5.0', () {
      final c = ProviderContainer(
        overrides: [
          activeProfileProvider.overrideWith(
            () => _FixedProfile(
              const UserProfile(
                id: 'p1',
                name: 'p',
                defaultSearchRadius: 5.0,
              ),
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(searchRadiusProvider), 5.0);
    });

    test('set(0.5) clamps up to 1.0', () {
      final c = ProviderContainer(
        overrides: [
          activeProfileProvider.overrideWith(() => _FixedProfile(null)),
        ],
      );
      addTearDown(c.dispose);
      c.read(searchRadiusProvider.notifier).set(0.5);
      expect(c.read(searchRadiusProvider), 1.0);
    });

    test('set(99) clamps down to 25.0', () {
      final c = ProviderContainer(
        overrides: [
          activeProfileProvider.overrideWith(() => _FixedProfile(null)),
        ],
      );
      addTearDown(c.dispose);
      c.read(searchRadiusProvider.notifier).set(99);
      expect(c.read(searchRadiusProvider), 25.0);
    });

    test('set(15) → 15.0 (inside bounds, no clamp)', () {
      final c = ProviderContainer(
        overrides: [
          activeProfileProvider.overrideWith(() => _FixedProfile(null)),
        ],
      );
      addTearDown(c.dispose);
      c.read(searchRadiusProvider.notifier).set(15);
      expect(c.read(searchRadiusProvider), 15.0);
    });
  });

  group('fuelStations derived provider', () {
    test('searchState without a value → empty list', () {
      final c = ProviderContainer(
        overrides: [
          searchStateProvider.overrideWith(
            () => _FakeSearchState(const AsyncValue.loading()),
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(fuelStationsProvider), isEmpty);
    });

    test(
      'mixed EV + fuel results → only fuel stations are extracted in order',
      () {
        final s1 = _station('f1');
        final s2 = _station('f2');
        final ev1 = _charger('ev1');
        final c = ProviderContainer(
          overrides: [
            searchStateProvider.overrideWith(
              () => _FakeSearchState(
                _dataState([
                  FuelStationResult(s1),
                  EVStationResult(ev1),
                  FuelStationResult(s2),
                ]),
              ),
            ),
          ],
        );
        addTearDown(c.dispose);

        final stations = c.read(fuelStationsProvider);
        expect(stations.map((s) => s.id).toList(), ['f1', 'f2']);
      },
    );

    test('all-EV result set → empty list', () {
      final c = ProviderContainer(
        overrides: [
          searchStateProvider.overrideWith(
            () => _FakeSearchState(
              _dataState([
                EVStationResult(_charger('ev1')),
                EVStationResult(_charger('ev2')),
              ]),
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(fuelStationsProvider), isEmpty);
    });
  });
}
