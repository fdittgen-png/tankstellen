import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/refuel/charging_station_as_refuel_option.dart';
import 'package:tankstellen/core/refuel/refuel_option.dart';
import 'package:tankstellen/core/refuel/station_as_refuel_option.dart';
import 'package:tankstellen/core/refuel/unified_search_results_enabled.dart';
import 'package:tankstellen/core/refuel/unified_search_results_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/ev_search_provider.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

/// Coverage for the #1116 phase 3a unified search results provider.
///
/// Each test pre-overrides `searchStateProvider` (fuel side) and
/// `eVSearchStateProvider` (EV side) with fakes that return a
/// canned [AsyncValue]. The flag is flipped via the real notifier
/// against an in-memory [SettingsStorage] so the on/off path is
/// exercised end-to-end.

class _FakeSearchState extends SearchState {
  _FakeSearchState(this._value);
  final AsyncValue<ServiceResult<List<SearchResultItem>>> _value;

  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() => _value;
}

class _FakeEvSearchState extends EVSearchState {
  _FakeEvSearchState(this._value);
  final AsyncValue<ServiceResult<List<ChargingStation>>> _value;

  @override
  AsyncValue<ServiceResult<List<ChargingStation>>> build() => _value;
}

class _FakeSettings implements SettingsStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  bool get isSetupComplete => false;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}

AsyncValue<ServiceResult<List<SearchResultItem>>> _fuelData(
  List<SearchResultItem> items,
) =>
    AsyncValue.data(ServiceResult(
      data: items,
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
    ));

AsyncValue<ServiceResult<List<ChargingStation>>> _evData(
  List<ChargingStation> items,
) =>
    AsyncValue.data(ServiceResult(
      data: items,
      source: ServiceSource.openChargeMapApi,
      fetchedAt: DateTime.now(),
    ));

Station _fuelStation({
  String id = 'f1',
  double? e10 = 1.749,
  double? diesel,
  String brand = 'Total',
}) =>
    Station(
      id: id,
      name: 'Station $id',
      brand: brand,
      street: 'Teststr.',
      postCode: '10115',
      place: 'Testtown',
      lat: 52.5,
      lng: 13.4,
      e10: e10,
      diesel: diesel,
      isOpen: true,
    );

ChargingStation _charger({String id = 'ev1', String? operator = 'Ionity'}) =>
    ChargingStation(
      id: id,
      name: 'Charger $id',
      operator: operator,
      latitude: 52.5,
      longitude: 13.4,
    );

/// Build a container with the canned fuel + EV upstreams plus an
/// in-memory settings store. Profile is null by default so
/// `selectedFuelTypeProvider` falls back to [FuelType.all]; tests that
/// need a specific fuel type call `select()` on the notifier.
///
/// As of #1373 phase 3f the `unifiedSearchResultsEnabled` flag is
/// backed by [featureFlagsProvider]. Tests flip the flag by overriding
/// the shim provider directly with `overrideWithValue(true)` rather
/// than writing to the legacy settings key.
ProviderContainer _container({
  required AsyncValue<ServiceResult<List<SearchResultItem>>> fuel,
  required AsyncValue<ServiceResult<List<ChargingStation>>> ev,
  bool flagOn = false,
}) {
  final storage = _FakeSettings();
  final container = ProviderContainer(
    overrides: [
      settingsStorageProvider.overrideWithValue(storage),
      activeProfileProvider.overrideWith(_NullProfile.new),
      searchStateProvider.overrideWith(() => _FakeSearchState(fuel)),
      eVSearchStateProvider.overrideWith(() => _FakeEvSearchState(ev)),
      if (flagOn) unifiedSearchResultsEnabledProvider.overrideWithValue(true),
    ],
  );
  return container;
}

class _NullProfile extends ActiveProfile {
  @override
  UserProfile? build() => null;
}

void main() {
  group('unifiedSearchResultsProvider — flag off', () {
    test('returns empty list with both upstreams empty', () {
      final c = _container(fuel: _fuelData(const []), ev: _evData(const []));
      addTearDown(c.dispose);
      expect(c.read(unifiedSearchResultsProvider), isEmpty);
    });

    test('returns empty list even when upstreams have data', () {
      final c = _container(
        fuel: _fuelData([FuelStationResult(_fuelStation())]),
        ev: _evData([_charger()]),
      );
      addTearDown(c.dispose);
      expect(c.read(unifiedSearchResultsProvider), isEmpty);
    });

    test('returns empty list when upstream fuel is loading', () {
      final c = _container(
        fuel: const AsyncValue.loading(),
        ev: _evData([_charger()]),
      );
      addTearDown(c.dispose);
      expect(c.read(unifiedSearchResultsProvider), isEmpty);
    });
  });

  group('unifiedSearchResultsProvider — flag on, fuel side', () {
    test('returns fuel adapters for the selected fuel type', () {
      final c = _container(
        fuel: _fuelData([
          FuelStationResult(_fuelStation(id: 'f1', e10: 1.749)),
          FuelStationResult(_fuelStation(id: 'f2', e10: 1.689)),
        ]),
        ev: _evData(const []),
        flagOn: true,
      );
      addTearDown(c.dispose);
      // Default profile is null → SelectedFuelType.all wildcard, but
      // StationAsRefuelOption wants a concrete fuel — pick e10.
      c.read(selectedFuelTypeProvider.notifier).select(FuelType.e10);

      final list = c.read(unifiedSearchResultsProvider);
      expect(list, hasLength(2));
      expect(list.every((o) => o is StationAsRefuelOption), isTrue);
      expect(list.map((o) => o.id).toList(), ['fuel:f1', 'fuel:f2']);
    });

    test('skips fuel stations whose price for the selected fuel is null',
        () {
      final c = _container(
        fuel: _fuelData([
          // e10 present → kept.
          FuelStationResult(_fuelStation(id: 'f-e10', e10: 1.749)),
          // e10 missing → dropped.
          FuelStationResult(_fuelStation(id: 'f-no-e10', e10: null)),
          // e10 missing but diesel present → still dropped (selected
          // fuel is e10 in this scenario).
          FuelStationResult(
            _fuelStation(id: 'f-diesel-only', e10: null, diesel: 1.589),
          ),
        ]),
        ev: _evData(const []),
        flagOn: true,
      );
      addTearDown(c.dispose);
      c.read(selectedFuelTypeProvider.notifier).select(FuelType.e10);

      final list = c.read(unifiedSearchResultsProvider);
      expect(list.map((o) => o.id).toList(), ['fuel:f-e10']);
    });

    test('drops EVStationResult entries from the fuel-state stream', () {
      // Mid-flight scenario: the search service returned an EV item
      // mixed in with fuel — should NOT be double-adapted via the fuel
      // path (the EV path handles those).
      final c = _container(
        fuel: _fuelData([
          FuelStationResult(_fuelStation(id: 'f1', e10: 1.749)),
          EVStationResult(_charger(id: 'mixed-ev')),
        ]),
        ev: _evData(const []),
        flagOn: true,
      );
      addTearDown(c.dispose);
      c.read(selectedFuelTypeProvider.notifier).select(FuelType.e10);

      final list = c.read(unifiedSearchResultsProvider);
      expect(list.map((o) => o.id).toList(), ['fuel:f1']);
    });
  });

  group('unifiedSearchResultsProvider — flag on, EV side', () {
    test('returns EV adapters when only EV results are present', () {
      final c = _container(
        fuel: _fuelData(const []),
        ev: _evData([_charger(id: 'ev1'), _charger(id: 'ev2')]),
        flagOn: true,
      );
      addTearDown(c.dispose);

      final list = c.read(unifiedSearchResultsProvider);
      expect(list, hasLength(2));
      expect(list.every((o) => o is ChargingStationAsRefuelOption), isTrue);
      expect(list.map((o) => o.id).toList(), ['ev:ev1', 'ev:ev2']);
    });
  });

  group('unifiedSearchResultsProvider — flag on, both sides', () {
    test('combines fuel + EV adapters with fuel first', () {
      final c = _container(
        fuel: _fuelData([
          FuelStationResult(_fuelStation(id: 'f1', e10: 1.749)),
        ]),
        ev: _evData([_charger(id: 'ev1')]),
        flagOn: true,
      );
      addTearDown(c.dispose);
      c.read(selectedFuelTypeProvider.notifier).select(FuelType.e10);

      final list = c.read(unifiedSearchResultsProvider);
      expect(list.map((o) => o.id).toList(), ['fuel:f1', 'ev:ev1']);
      expect(list.first, isA<StationAsRefuelOption>());
      expect(list.last, isA<ChargingStationAsRefuelOption>());
    });
  });

  group('unifiedSearchResultsProvider — flag on, async edges', () {
    test('fuel AsyncLoading + EV data → only EV adapters surface', () {
      final c = _container(
        fuel: const AsyncValue.loading(),
        ev: _evData([_charger(id: 'ev-only')]),
        flagOn: true,
      );
      addTearDown(c.dispose);

      final list = c.read(unifiedSearchResultsProvider);
      expect(list.map((o) => o.id).toList(), ['ev:ev-only']);
    });

    test('fuel AsyncError + EV data → only EV adapters surface (no rethrow)',
        () {
      final c = _container(
        fuel: AsyncValue.error(StateError('boom'), StackTrace.current),
        ev: _evData([_charger(id: 'ev-still-here')]),
        flagOn: true,
      );
      addTearDown(c.dispose);

      // The provider must not throw when reading; the error is silently
      // dropped on the fuel side per the documented contract.
      expect(
        () => c.read(unifiedSearchResultsProvider),
        returnsNormally,
      );
      final list = c.read(unifiedSearchResultsProvider);
      expect(list.map((o) => o.id).toList(), ['ev:ev-still-here']);
    });

    test('both sides loading → empty list, no throw', () {
      final c = _container(
        fuel: const AsyncValue.loading(),
        ev: const AsyncValue.loading(),
        flagOn: true,
      );
      addTearDown(c.dispose);
      expect(c.read(unifiedSearchResultsProvider), isEmpty);
    });

    test('EV AsyncError + fuel data → only fuel adapters surface', () {
      final c = _container(
        fuel: _fuelData([
          FuelStationResult(_fuelStation(id: 'f-only', e10: 1.749)),
        ]),
        ev: AsyncValue.error(StateError('ev-down'), StackTrace.current),
        flagOn: true,
      );
      addTearDown(c.dispose);
      c.read(selectedFuelTypeProvider.notifier).select(FuelType.e10);

      expect(
        c.read(unifiedSearchResultsProvider).map((o) => o.id).toList(),
        ['fuel:f-only'],
      );
    });
  });

  group('unifiedSearchResultsProvider — reactivity', () {
    test('flipping the flag on/off re-derives the list', () async {
      final c = _container(
        fuel: _fuelData([
          FuelStationResult(_fuelStation(id: 'f1', e10: 1.749)),
        ]),
        ev: _evData(const []),
      );
      addTearDown(c.dispose);
      c.read(selectedFuelTypeProvider.notifier).select(FuelType.e10);

      // Flag starts off → empty.
      expect(c.read(unifiedSearchResultsProvider), isEmpty);

      await c.read(unifiedSearchResultsEnabledProvider.notifier).set(true);
      expect(
        c.read(unifiedSearchResultsProvider).map((o) => o.id).toList(),
        ['fuel:f1'],
      );

      await c.read(unifiedSearchResultsEnabledProvider.notifier).set(false);
      expect(c.read(unifiedSearchResultsProvider), isEmpty);
    });
  });

  group('unifiedSearchResultsProvider — return type', () {
    test('all returned options implement RefuelOption', () {
      final c = _container(
        fuel: _fuelData([
          FuelStationResult(_fuelStation(id: 'f1', e10: 1.749)),
        ]),
        ev: _evData([_charger(id: 'ev1')]),
        flagOn: true,
      );
      addTearDown(c.dispose);
      c.read(selectedFuelTypeProvider.notifier).select(FuelType.e10);

      final list = c.read(unifiedSearchResultsProvider);
      for (final option in list) {
        expect(option, isA<RefuelOption>());
        expect(option.coordinates.lat, isNotNull);
        expect(option.coordinates.lng, isNotNull);
        expect(option.id, isNotEmpty);
      }
    });
  });
}
