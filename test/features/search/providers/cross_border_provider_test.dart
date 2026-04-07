import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/country/country_provider.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/cross_border_provider.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

void main() {
  group('crossBorderComparisonsProvider', () {
    test('returns empty when user position is null', () {
      final container = ProviderContainer(
        overrides: [
          activeCountryProvider.overrideWith(() => _FixedCountry(Countries.germany)),
          userPositionProvider.overrideWith(() => _NullUserPosition()),
          selectedFuelTypeProvider.overrideWith(() => _FixedFuelType(FuelType.e10)),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(crossBorderComparisonsProvider);
      expect(result, isEmpty);
    });

    test('returns empty when search has no results', () {
      final container = ProviderContainer(
        overrides: [
          activeCountryProvider.overrideWith(() => _FixedCountry(Countries.germany)),
          userPositionProvider.overrideWith(() => _FixedUserPosition(52.52, 13.405)),
          selectedFuelTypeProvider.overrideWith(() => _FixedFuelType(FuelType.e10)),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(crossBorderComparisonsProvider);
      expect(result, isEmpty);
    });

    test('returns empty when user is far from borders', () {
      final container = ProviderContainer(
        overrides: [
          activeCountryProvider.overrideWith(() => _FixedCountry(Countries.germany)),
          userPositionProvider.overrideWith(() => _FixedUserPosition(52.52, 13.405)),
          selectedFuelTypeProvider.overrideWith(() => _FixedFuelType(FuelType.e10)),
          searchStateProvider.overrideWith(() => _FakeSearchState(_berlinStations())),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(crossBorderComparisonsProvider);
      expect(result, isEmpty);
    });

    test('returns comparison when user is near French border', () {
      final container = ProviderContainer(
        overrides: [
          activeCountryProvider.overrideWith(() => _FixedCountry(Countries.germany)),
          userPositionProvider.overrideWith(() => _FixedUserPosition(48.57, 7.82)),
          selectedFuelTypeProvider.overrideWith(() => _FixedFuelType(FuelType.e10)),
          searchStateProvider.overrideWith(() => _FakeSearchState(_borderStations())),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(crossBorderComparisonsProvider);
      expect(result, isNotEmpty);
      expect(result.first.neighborCode, 'FR');
      expect(result.first.neighborName, 'France');
      expect(result.first.currentAvgPrice, greaterThan(0));
      expect(result.first.stationCount, 2);
    });

    test('computes correct average price', () {
      final stations = [
        _makeStation(id: 's1', e10: 1.800),
        _makeStation(id: 's2', e10: 1.900),
      ];

      final container = ProviderContainer(
        overrides: [
          activeCountryProvider.overrideWith(() => _FixedCountry(Countries.germany)),
          userPositionProvider.overrideWith(() => _FixedUserPosition(48.57, 7.82)),
          selectedFuelTypeProvider.overrideWith(() => _FixedFuelType(FuelType.e10)),
          searchStateProvider.overrideWith(() => _FakeSearchState(stations)),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(crossBorderComparisonsProvider);
      expect(result, isNotEmpty);
      expect(result.first.currentAvgPrice, closeTo(1.850, 0.001));
    });

    test('returns empty when all prices are null for selected fuel', () {
      final stations = [
        _makeStation(id: 's1', e10: null),
        _makeStation(id: 's2', e10: null),
      ];

      final container = ProviderContainer(
        overrides: [
          activeCountryProvider.overrideWith(() => _FixedCountry(Countries.germany)),
          userPositionProvider.overrideWith(() => _FixedUserPosition(48.57, 7.82)),
          selectedFuelTypeProvider.overrideWith(() => _FixedFuelType(FuelType.e10)),
          searchStateProvider.overrideWith(() => _FakeSearchState(stations)),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(crossBorderComparisonsProvider);
      expect(result, isEmpty);
    });

    test('works with Austrian border', () {
      final container = ProviderContainer(
        overrides: [
          activeCountryProvider.overrideWith(() => _FixedCountry(Countries.germany)),
          userPositionProvider.overrideWith(() => _FixedUserPosition(47.60, 13.05)),
          selectedFuelTypeProvider.overrideWith(() => _FixedFuelType(FuelType.diesel)),
          searchStateProvider.overrideWith(() => _FakeSearchState(_borderStations())),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(crossBorderComparisonsProvider);
      expect(result, isNotEmpty);
      expect(result.first.neighborCode, 'AT');
    });
  });
}

// --- Test helpers ---

Station _makeStation({
  required String id,
  double? e5 = 1.859,
  double? e10 = 1.799,
  double? diesel = 1.659,
}) {
  return Station(
    id: id,
    name: 'Test Station $id',
    brand: 'TEST',
    street: 'Teststr.',
    postCode: '10115',
    place: 'Test',
    lat: 48.57,
    lng: 7.82,
    dist: 1.0,
    e5: e5,
    e10: e10,
    diesel: diesel,
    isOpen: true,
  );
}

List<Station> _berlinStations() => [
  _makeStation(id: 'b1'),
  _makeStation(id: 'b2'),
];

List<Station> _borderStations() => [
  _makeStation(id: 'border-1', e10: 1.800),
  _makeStation(id: 'border-2', e10: 1.900),
];

class _FixedCountry extends ActiveCountry {
  final CountryConfig _country;
  _FixedCountry(this._country);

  @override
  CountryConfig build() => _country;
}

class _NullUserPosition extends UserPosition {
  @override
  UserPositionData? build() => null;
}

class _FixedUserPosition extends UserPosition {
  final double _lat;
  final double _lng;
  _FixedUserPosition(this._lat, this._lng);

  @override
  UserPositionData? build() => UserPositionData(
    lat: _lat,
    lng: _lng,
    updatedAt: DateTime.now(),
    source: 'test',
  );
}

class _FixedFuelType extends SelectedFuelType {
  final FuelType _type;
  _FixedFuelType(this._type);

  @override
  FuelType build() => _type;
}

class _FakeSearchState extends SearchState {
  final List<Station> _stations;

  _FakeSearchState(this._stations);

  @override
  AsyncValue<ServiceResult<List<Station>>> build() {
    return AsyncValue.data(ServiceResult(
      data: _stations,
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
    ));
  }
}
