import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/impl/demo_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';

void main() {
  late DemoStationService service;

  setUp(() {
    service = DemoStationService(countryCode: 'DE');
  });

  final defaultParams = SearchParams(
    lat: 52.52,
    lng: 13.405,
    radiusKm: 10.0,
  );

  group('searchStations', () {
    test('returns a non-empty list of stations', () async {
      final result = await service.searchStations(defaultParams);
      expect(result.data, isNotEmpty);
      expect(result.data.length, greaterThanOrEqualTo(5));
      expect(result.data.length, lessThanOrEqualTo(12));
    });

    test('returns ServiceResult with cache source', () async {
      final result = await service.searchStations(defaultParams);
      expect(result.source, ServiceSource.cache);
      expect(result.fetchedAt, isNotNull);
    });

    test('generated stations have valid data', () async {
      final result = await service.searchStations(defaultParams);
      for (final station in result.data) {
        expect(station.id, startsWith('demo-'));
        expect(station.brand, isNotEmpty);
        expect(station.street, isNotEmpty);
        expect(station.e5, isNotNull);
        expect(station.e10, isNotNull);
        expect(station.diesel, isNotNull);
      }
    });

    test('stations are near search coordinates', () async {
      final result = await service.searchStations(defaultParams);
      for (final station in result.data) {
        expect((station.lat - 52.52).abs(), lessThan(1.0));
        expect((station.lng - 13.405).abs(), lessThan(1.0));
      }
    });

    test('sorts by price when requested', () async {
      final params = SearchParams(
        lat: 52.52,
        lng: 13.405,
        radiusKm: 10.0,
        sortBy: SortBy.price,
      );
      final result = await service.searchStations(params);
      for (int i = 0; i < result.data.length - 1; i++) {
        expect(result.data[i].e10 ?? 99, lessThanOrEqualTo(result.data[i + 1].e10 ?? 99));
      }
    });

    test('sorts by distance when requested', () async {
      final params = SearchParams(lat: 52.52, lng: 13.405, radiusKm: 10.0, sortBy: SortBy.distance);
      final result = await service.searchStations(params);
      for (int i = 0; i < result.data.length - 1; i++) {
        expect(result.data[i].dist, lessThanOrEqualTo(result.data[i + 1].dist));
      }
    });

    test('uses German brands for DE country', () async {
      final result = await service.searchStations(defaultParams);
      final germanBrands = ['ARAL', 'Shell', 'TOTAL', 'JET', 'ESSO', 'Star', 'HEM'];
      for (final station in result.data) {
        expect(germanBrands, contains(station.brand));
      }
    });

    test('uses French brands for FR country', () async {
      final frService = DemoStationService(countryCode: 'FR');
      final result = await frService.searchStations(defaultParams);
      final frBrands = ['TotalEnergies', 'Leclerc', 'Carrefour', 'Intermarché', 'Auchan', 'BP', 'Shell'];
      for (final station in result.data) {
        expect(frBrands, contains(station.brand));
      }
    });

    test('uses postal code from params', () async {
      final params = SearchParams(
        lat: 52.52,
        lng: 13.405,
        radiusKm: 10.0,
        postalCode: '10115',
      );
      final result = await service.searchStations(params);
      for (final station in result.data) {
        expect(station.postCode, '10115');
      }
    });

    test('uses location name from params', () async {
      final params = SearchParams(
        lat: 52.52,
        lng: 13.405,
        radiusKm: 10.0,
        locationName: 'Berlin',
      );
      final result = await service.searchStations(params);
      for (final station in result.data) {
        expect(station.place, 'Berlin');
      }
    });
  });

  group('getStationDetail', () {
    test('returns detail for previously searched station', () async {
      final searchResult = await service.searchStations(defaultParams);
      final firstStation = searchResult.data.first;

      final detail = await service.getStationDetail(firstStation.id);
      expect(detail.data.station.id, firstStation.id);
      expect(detail.data.station.brand, firstStation.brand);
    });

    test('returns opening times', () async {
      final searchResult = await service.searchStations(defaultParams);
      final detail = await service.getStationDetail(searchResult.data.first.id);
      expect(detail.data.openingTimes, isNotNull);
      expect(detail.data.openingTimes, isNotEmpty);
    });

    test('returns fallback for unknown station ID', () async {
      final detail = await service.getStationDetail('unknown-id');
      expect(detail.data.station.id, 'unknown-id');
      expect(detail.data.station.brand, isNotEmpty);
      expect(detail.source, ServiceSource.cache);
    });
  });

  group('getPrices', () {
    test('returns prices for previously searched stations', () async {
      final searchResult = await service.searchStations(defaultParams);
      final ids = searchResult.data.map((s) => s.id).toList();

      final prices = await service.getPrices(ids);
      expect(prices.data.length, ids.length);
      for (final id in ids) {
        expect(prices.data[id], isNotNull);
        expect(prices.data[id]!.e10, isNotNull);
      }
    });

    test('returns default prices for unknown station IDs', () async {
      final prices = await service.getPrices(['unknown-1', 'unknown-2']);
      expect(prices.data.length, 2);
      expect(prices.data['unknown-1']!.e5, 1.459);
      expect(prices.data['unknown-1']!.diesel, 1.359);
    });

    test('returns status based on cached isOpen', () async {
      final searchResult = await service.searchStations(defaultParams);
      final openStation = searchResult.data.firstWhere((s) => s.isOpen);
      final prices = await service.getPrices([openStation.id]);
      expect(prices.data[openStation.id]!.status, 'open');
    });
  });

  group('country support', () {
    test('falls back to DE brands for unknown country', () async {
      final unknownService = DemoStationService(countryCode: 'XX');
      final result = await unknownService.searchStations(defaultParams);
      final germanBrands = ['ARAL', 'Shell', 'TOTAL', 'JET', 'ESSO', 'Star', 'HEM'];
      expect(germanBrands, contains(result.data.first.brand));
    });

    test('supports AT country', () async {
      final atService = DemoStationService(countryCode: 'AT');
      final result = await atService.searchStations(defaultParams);
      expect(result.data, isNotEmpty);
    });

    test('supports ES country', () async {
      final esService = DemoStationService(countryCode: 'ES');
      final result = await esService.searchStations(defaultParams);
      expect(result.data, isNotEmpty);
    });

    test('supports IT country', () async {
      final itService = DemoStationService(countryCode: 'IT');
      final result = await itService.searchStations(defaultParams);
      expect(result.data, isNotEmpty);
    });
  });
}
