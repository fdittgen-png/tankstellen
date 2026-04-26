import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/features/station_services/luxembourg/luxembourg_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';

void main() {
  late LuxembourgStationService service;

  setUp(() {
    service = LuxembourgStationService();
  });

  group('LuxembourgStationService', () {
    test('implements StationService interface', () {
      expect(service, isA<StationService>());
    });

    group('searchStations', () {
      test('returns stations tagged with regulated prices', () async {
        const params = SearchParams(
          lat: 49.6116, lng: 6.1319, radiusKm: 50.0,
        );
        final result = await service.searchStations(params);

        expect(result.source, ServiceSource.luxembourgApi);
        expect(result.data, isNotEmpty);

        final first = result.data.first;
        expect(first.e5, isNotNull);
        expect(first.e10, isNotNull);
        expect(first.e98, isNotNull);
        expect(first.diesel, isNotNull);
        expect(first.lpg, isNotNull);
      });

      test('every station carries identical prices (uniform regulation)', () async {
        const params = SearchParams(
          lat: 49.6116, lng: 6.1319, radiusKm: 100.0,
        );
        final result = await service.searchStations(params);

        expect(result.data, hasLength(greaterThan(1)),
            reason: 'Multiple virtual stations should be returned at a large radius');

        final e5Values = result.data.map((s) => s.e5).toSet();
        final e10Values = result.data.map((s) => s.e10).toSet();
        final e98Values = result.data.map((s) => s.e98).toSet();
        final dieselValues = result.data.map((s) => s.diesel).toSet();
        final lpgValues = result.data.map((s) => s.lpg).toSet();

        expect(e5Values, hasLength(1),
            reason: 'Sans Plomb 95 is uniform nationally');
        expect(e10Values, hasLength(1),
            reason: 'E10 matches SP95 in the uniform decree');
        expect(e98Values, hasLength(1),
            reason: 'Sans Plomb 98 is uniform nationally');
        expect(dieselValues, hasLength(1),
            reason: 'Diesel is uniform nationally');
        expect(lpgValues, hasLength(1),
            reason: 'LPG is uniform nationally');
      });

      test('every station id is prefixed with "lu-"', () async {
        const params = SearchParams(
          lat: 49.6116, lng: 6.1319, radiusKm: 100.0,
        );
        final result = await service.searchStations(params);
        for (final s in result.data) {
          expect(s.id, startsWith('lu-'),
              reason: 'Station ids must be prefixed so '
                  'Countries.countryForStationId dispatches to LU');
        }
      });

      test('lu- prefix dispatches to Luxembourg via country_config', () async {
        const params = SearchParams(
          lat: 49.6116, lng: 6.1319, radiusKm: 50.0,
        );
        final result = await service.searchStations(params);
        expect(result.data, isNotEmpty);

        final first = result.data.first;
        final code = Countries.countryCodeForStationId(first.id);
        expect(code, 'LU',
            reason: 'Favourites view must render LU stations with EUR symbol, '
                'so the id prefix has to survive round-tripping through '
                'countryCodeForStationId (#516).');
      });

      test('distance is calculated from the query point', () async {
        // Searching from Luxembourg-Ville — the first entry.
        const params = SearchParams(
          lat: 49.6116, lng: 6.1319, radiusKm: 100.0,
        );
        final result = await service.searchStations(params);

        final luxembourgVille = result.data
            .firstWhere((s) => s.name == 'Luxembourg-Ville');
        expect(luxembourgVille.dist, closeTo(0.0, 1.0),
            reason: 'Search centred on LUX city should yield ~0 km distance');
      });

      test('stations are sorted by distance when SortBy.distance is used', () async {
        // Search from Luxembourg-Ville with explicit distance sort — all
        // stations have identical regulated prices, so a SortBy.price
        // request produces a stable (insertion-order) result, which is
        // why we pin the sort order with SortBy.distance here.
        const params = SearchParams(
          lat: 49.6116, lng: 6.1319, radiusKm: 100.0,
          sortBy: SortBy.distance,
        );
        final result = await service.searchStations(params);

        for (var i = 1; i < result.data.length; i++) {
          expect(result.data[i].dist, greaterThanOrEqualTo(result.data[i - 1].dist),
              reason: 'Stations must be sorted by distance ascending '
                  'when SortBy.distance is requested');
        }
      });

      test('radius filter narrows results near a single city', () async {
        // 5 km around Luxembourg-Ville should hit only the city itself
        // (the next-nearest is Dudelange at ~15 km).
        const params = SearchParams(
          lat: 49.6116, lng: 6.1319, radiusKm: 5.0,
        );
        final result = await service.searchStations(params);
        expect(result.data, hasLength(1));
        expect(result.data.first.name, 'Luxembourg-Ville');
      });

      test('coordinates fall inside the LU bounding box', () async {
        const params = SearchParams(
          lat: 49.6116, lng: 6.1319, radiusKm: 100.0,
        );
        final result = await service.searchStations(params);

        for (final s in result.data) {
          expect(s.lat, inInclusiveRange(49.4, 50.25));
          expect(s.lng, inInclusiveRange(5.7, 6.55));
        }
      });

      test('all stations report isOpen: true', () async {
        const params = SearchParams(
          lat: 49.6116, lng: 6.1319, radiusKm: 100.0,
        );
        final result = await service.searchStations(params);
        for (final s in result.data) {
          expect(s.isOpen, isTrue);
        }
      });
    });

    group('getStationDetail', () {
      test('throws ApiException (detail not supported for uniform prices)', () {
        expect(
          () => service.getStationDetail('lu-luxembourg-ville'),
          throwsA(isA<ApiException>()),
        );
      });

      test('error message mentions Luxembourg', () async {
        try {
          await service.getStationDetail('lu-luxembourg-ville');
          fail('Should have thrown');
        } on ApiException catch (e) {
          expect(e.message, contains('Luxembourg'));
        }
      });
    });

    group('getPrices', () {
      test('returns empty map with Luxembourg source', () async {
        final result = await service.getPrices(['lu-1', 'lu-2']);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.luxembourgApi);
      });

      test('returns empty map for empty id list', () async {
        final result = await service.getPrices([]);
        expect(result.data, isEmpty);
      });

      test('result has correct metadata', () async {
        final result = await service.getPrices(['lu-anything']);
        expect(result.source, ServiceSource.luxembourgApi);
        expect(result.fetchedAt, isA<DateTime>());
        expect(result.isStale, isFalse);
      });
    });

    group('regulated-price sanity checks', () {
      test('E5 and E10 are distinct regulated figures', () async {
        // The Luxembourg arrêté sets separate max prices for "Sans Plomb
        // 95" (E5) and "95 E10" — the two are different blends (sulphur-
        // free 95 vs. up to 10 % ethanol). We carry both so UI pickers
        // that prefer one over the other show the correct decree figure.
        const params = SearchParams(
          lat: 49.6116, lng: 6.1319, radiusKm: 50.0,
        );
        final result = await service.searchStations(params);
        final s = result.data.first;
        expect(s.e5, isNotNull);
        expect(s.e10, isNotNull);
        // Both must fall in a plausible EUR/L range regardless of which
        // decree figure is currently higher (E10 is usually the cheaper
        // one, but we do not assert direction — only presence).
        expect(s.e5, inInclusiveRange(0.3, 3.0));
        expect(s.e10, inInclusiveRange(0.3, 3.0));
      });

      test('prices are plausible EUR/L values (0.3 <= p <= 3.0)', () async {
        const params = SearchParams(
          lat: 49.6116, lng: 6.1319, radiusKm: 50.0,
        );
        final result = await service.searchStations(params);
        final s = result.data.first;

        expect(s.e5, inInclusiveRange(0.3, 3.0));
        expect(s.e10, inInclusiveRange(0.3, 3.0));
        expect(s.e98, inInclusiveRange(0.3, 3.0));
        expect(s.diesel, inInclusiveRange(0.3, 3.0));
        // LPG is typically ~half the petrol price.
        expect(s.lpg, inInclusiveRange(0.3, 2.0));
      });
    });
  });
}
