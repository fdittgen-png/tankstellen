import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/country/country_provider.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/cross_border_suggestion_provider.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

void main() {
  group('crossBorderSuggestionProvider', () {
    test('returns null when user position is unknown', () async {
      final container = _container(
        position: null,
        country: Countries.germany,
        fuel: FuelType.e10,
        localStations: const [],
        neighborStations: const {},
      );
      addTearDown(container.dispose);

      final result =
          await container.read(crossBorderSuggestionProvider.future);
      expect(result, isNull);
    });

    test('returns null when user is far from any border (Berlin)',
        () async {
      // Berlin: ~150 km from any DE land border.
      final container = _container(
        position: const _Pos(52.52, 13.405),
        country: Countries.germany,
        fuel: FuelType.e10,
        localStations: _stations(prices: const [1.85, 1.86]),
        neighborStations: const {},
      );
      addTearDown(container.dispose);

      final result =
          await container.read(crossBorderSuggestionProvider.future);
      expect(result, isNull);
    });

    test(
        'synthetic Saarbrücken position triggers DE→FR signal '
        'when neighbor is cheaper', () async {
      // Saarbrücken (49.23, 7.0) is essentially on the FR border.
      final container = _container(
        position: const _Pos(49.23, 7.0),
        country: Countries.germany,
        fuel: FuelType.e10,
        localStations: _stations(prices: const [1.90, 1.92, 1.91]),
        neighborStations: {
          'FR': _stations(prices: const [1.78, 1.80]),
        },
      );
      addTearDown(container.dispose);

      final result =
          await container.read(crossBorderSuggestionProvider.future);

      expect(result, isNotNull);
      expect(result!.neighborCountryCode, 'FR');
      expect(result.neighborName, 'France');
      expect(result.priceDeltaPerLiter, greaterThan(0));
      // Local avg ≈ 1.910, neighbor avg = 1.790 → delta ≈ 0.120
      expect(result.priceDeltaPerLiter, closeTo(0.12, 0.005));
      expect(result.sampleCount, 2);
      expect(result.distanceKm, lessThanOrEqualTo(crossBorderThresholdKm));
    });

    test('returns null when neighbor returns no stations', () async {
      final container = _container(
        position: const _Pos(49.23, 7.0),
        country: Countries.germany,
        fuel: FuelType.e10,
        localStations: _stations(prices: const [1.90, 1.92]),
        neighborStations: const {'FR': []},
      );
      addTearDown(container.dispose);

      final result =
          await container.read(crossBorderSuggestionProvider.future);
      expect(result, isNull);
    });

    test('returns null when neighbor is not cheaper (delta <= 0)',
        () async {
      final container = _container(
        position: const _Pos(49.23, 7.0),
        country: Countries.germany,
        fuel: FuelType.e10,
        localStations: _stations(prices: const [1.70, 1.72]),
        neighborStations: {
          'FR': _stations(prices: const [1.85, 1.90]),
        },
      );
      addTearDown(container.dispose);

      final result =
          await container.read(crossBorderSuggestionProvider.future);
      expect(result, isNull);
    });

    test('returns null when current-country search has no prices',
        () async {
      final container = _container(
        position: const _Pos(49.23, 7.0),
        country: Countries.germany,
        fuel: FuelType.e10,
        localStations: const [], // empty
        neighborStations: {
          'FR': _stations(prices: const [1.78, 1.80]),
        },
      );
      addTearDown(container.dispose);

      final result =
          await container.read(crossBorderSuggestionProvider.future);
      expect(result, isNull);
    });

    test('skips electric fuel — kWh vs L are not comparable', () async {
      final container = _container(
        position: const _Pos(49.23, 7.0),
        country: Countries.germany,
        fuel: FuelType.electric,
        localStations: _stations(prices: const [1.90, 1.92]),
        neighborStations: {
          'FR': _stations(prices: const [1.78]),
        },
      );
      addTearDown(container.dispose);

      final result =
          await container.read(crossBorderSuggestionProvider.future);
      expect(result, isNull);
    });

    test('does not propose neighbors that do not support the fuel',
        () async {
      // CNG is unsupported by France; force the user onto CNG and confirm
      // the FR neighbor is skipped even though it would be otherwise eligible.
      final container = _container(
        position: const _Pos(49.23, 7.0),
        country: Countries.germany,
        fuel: FuelType.cng,
        localStations: _stations(prices: const [1.90]),
        neighborStations: {
          'FR': _stations(prices: const [1.50]),
        },
      );
      addTearDown(container.dispose);

      final result =
          await container.read(crossBorderSuggestionProvider.future);
      expect(result, isNull);
    });
  });
}

// ─── Helpers ──────────────────────────────────────────────────────────────

class _Pos {
  final double lat;
  final double lng;
  const _Pos(this.lat, this.lng);
}

ProviderContainer _container({
  required _Pos? position,
  required CountryConfig country,
  required FuelType fuel,
  required List<Station> localStations,
  required Map<String, List<Station>> neighborStations,
}) {
  return ProviderContainer(
    overrides: [
      activeCountryProvider.overrideWith(() => _FixedCountry(country)),
      userPositionProvider.overrideWith(
        () => position == null
            ? _NullUserPosition()
            : _FixedUserPosition(position.lat, position.lng),
      ),
      selectedFuelTypeProvider.overrideWith(() => _FixedFuelType(fuel)),
      searchStateProvider.overrideWith(() => _FakeSearchState(localStations)),
      crossBorderStationServiceFactoryProvider.overrideWith(
        (ref) => (code) => _FakeStationService(neighborStations[code] ?? []),
      ),
    ],
  );
}

List<Station> _stations({required List<double> prices}) {
  return [
    for (var i = 0; i < prices.length; i++)
      Station(
        id: 'test-${prices[i].toStringAsFixed(3)}-$i',
        name: 'Station $i',
        brand: 'TEST',
        street: 'Teststr.',
        postCode: '00000',
        place: 'Test',
        lat: 49.23,
        lng: 7.0,
        dist: 1.0,
        e5: prices[i],
        e10: prices[i],
        diesel: prices[i],
        e98: prices[i],
        dieselPremium: prices[i],
        e85: prices[i],
        lpg: prices[i],
        cng: prices[i],
        isOpen: true,
      ),
  ];
}

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
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() {
    return AsyncValue.data(ServiceResult(
      data: _stations
          .map((s) => FuelStationResult(s) as SearchResultItem)
          .toList(),
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
    ));
  }
}

class _FakeStationService implements StationService {
  final List<Station> _stationsToReturn;
  _FakeStationService(this._stationsToReturn);

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    return ServiceResult(
      data: _stationsToReturn,
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
    );
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String id) {
    throw UnimplementedError();
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
      List<String> ids) {
    throw UnimplementedError();
  }
}
