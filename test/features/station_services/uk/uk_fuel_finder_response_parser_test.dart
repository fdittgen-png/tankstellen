import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/station_services/uk/uk_fuel_finder_response_parser.dart';

/// Builds a single Fuel Finder station record matching the documented
/// shape used by [UkFuelFinderResponseParser.parseFuelFinderStations].
/// Defaults centre on Trafalgar Square so tests can reason about
/// distances against the same anchor.
Map<String, dynamic> _ukStation({
  String? siteId = 'AA0001',
  String? id,
  String name = 'Sample Forecourt',
  String brand = 'Shell',
  String address = '1 The Strand',
  String postcode = 'WC2N 5DN',
  String town = 'London',
  double lat = 51.5080,
  double lng = -0.1281,
  Map<String, dynamic>? prices,
}) {
  return <String, dynamic>{
    'site_id': ?siteId,
    'id': ?id,
    'site_name': name,
    'brand': brand,
    'address': address,
    'postcode': postcode,
    'town': town,
    'location': <String, dynamic>{'latitude': lat, 'longitude': lng},
    'prices': prices ??
        <String, dynamic>{
          'E5': 14999, // 149.99p → 1.4999 GBP
          'E10': 14299, // 142.99p → 1.4299 GBP
          'B7': 15499, // 154.99p → 1.5499 GBP
        },
  };
}

void main() {
  group('extractStationList', () {
    test('list at root is returned as-is', () {
      final raw = <dynamic>[
        <String, dynamic>{'site_id': 'A'},
        <String, dynamic>{'site_id': 'B'},
      ];
      final result = UkFuelFinderResponseParser.extractStationList(raw);
      expect(result, hasLength(2));
      expect(result.first, isA<Map>());
    });

    test('map with `stations` key returns the inner list', () {
      final raw = <String, dynamic>{
        'stations': <dynamic>[
          <String, dynamic>{'site_id': 'A'},
        ],
      };
      final result = UkFuelFinderResponseParser.extractStationList(raw);
      expect(result, hasLength(1));
    });

    test('map with `data` key returns the inner list', () {
      final raw = <String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{'site_id': 'A'},
          <String, dynamic>{'site_id': 'B'},
        ],
      };
      final result = UkFuelFinderResponseParser.extractStationList(raw);
      expect(result, hasLength(2));
    });

    test('map with `items` key returns the inner list', () {
      final raw = <String, dynamic>{
        'items': <dynamic>[
          <String, dynamic>{'site_id': 'A'},
        ],
      };
      final result = UkFuelFinderResponseParser.extractStationList(raw);
      expect(result, hasLength(1));
    });

    test('when both `stations` and `data` are present, `stations` wins', () {
      final raw = <String, dynamic>{
        'stations': <dynamic>[
          <String, dynamic>{'site_id': 'STATIONS_KEY'},
        ],
        'data': <dynamic>[
          <String, dynamic>{'site_id': 'DATA_KEY'},
          <String, dynamic>{'site_id': 'DATA_KEY_2'},
        ],
      };
      final result = UkFuelFinderResponseParser.extractStationList(raw);
      expect(result, hasLength(1));
      expect((result.first as Map)['site_id'], 'STATIONS_KEY');
    });

    test('null root degrades to empty list', () {
      expect(UkFuelFinderResponseParser.extractStationList(null), isEmpty);
    });

    test('string root degrades to empty list', () {
      expect(
        UkFuelFinderResponseParser.extractStationList('not a list'),
        isEmpty,
      );
    });

    test('int root degrades to empty list', () {
      expect(UkFuelFinderResponseParser.extractStationList(42), isEmpty);
    });

    test('empty map degrades to empty list', () {
      expect(
        UkFuelFinderResponseParser.extractStationList(<String, dynamic>{}),
        isEmpty,
      );
    });

    test('map with unrecognised keys degrades to empty list', () {
      final raw = <String, dynamic>{
        'results': <dynamic>[
          <String, dynamic>{'site_id': 'A'},
        ],
      };
      expect(UkFuelFinderResponseParser.extractStationList(raw), isEmpty);
    });

    test('returned list is mutable copy (decoupled from input)', () {
      final inner = <dynamic>[
        <String, dynamic>{'site_id': 'A'},
      ];
      final raw = <String, dynamic>{'stations': inner};
      final result = UkFuelFinderResponseParser.extractStationList(raw);
      result.add(<String, dynamic>{'site_id': 'Z'});
      // Original input list is not mutated by callers writing to result.
      expect(inner, hasLength(1));
      expect(result, hasLength(2));
    });
  });

  group('parsePence', () {
    test('null input returns null', () {
      expect(UkFuelFinderResponseParser.parsePence(null), isNull);
    });

    test('non-numeric string returns null', () {
      expect(UkFuelFinderResponseParser.parsePence('not a number'), isNull);
    });

    test('zero stays zero (treated as pounds)', () {
      expect(UkFuelFinderResponseParser.parsePence(0), 0);
    });

    test('values <= 10 are kept as pounds', () {
      expect(UkFuelFinderResponseParser.parsePence(5), 5);
      expect(UkFuelFinderResponseParser.parsePence(1.45), 1.45);
    });

    test('boundary value 10 is kept as pounds (not divided)', () {
      // Source: `price > 10 ? price / 100 : price` — 10 fails the >.
      expect(UkFuelFinderResponseParser.parsePence(10), 10);
    });

    test('values just above 10 are treated as pence', () {
      expect(UkFuelFinderResponseParser.parsePence(11), closeTo(0.11, 1e-9));
    });

    test('typical UK pence prices are converted to pounds', () {
      expect(
        UkFuelFinderResponseParser.parsePence(14999),
        closeTo(149.99, 1e-9),
      );
      expect(
        UkFuelFinderResponseParser.parsePence(15499),
        closeTo(154.99, 1e-9),
      );
    });

    test('double inputs are accepted', () {
      expect(
        UkFuelFinderResponseParser.parsePence(149.9),
        closeTo(1.499, 1e-9),
      );
    });

    test('numeric string inputs are parsed', () {
      expect(
        UkFuelFinderResponseParser.parsePence('14999'),
        closeTo(149.99, 1e-9),
      );
      expect(UkFuelFinderResponseParser.parsePence('5'), 5);
    });
  });

  group('parseFuelFinderStations', () {
    // Anchor: Trafalgar Square (51.5080, -0.1281) — same as fixture default.
    const anchorLat = 51.5080;
    const anchorLng = -0.1281;

    test('empty input → empty output', () {
      final result = UkFuelFinderResponseParser.parseFuelFinderStations(
        const <dynamic>[],
        lat: anchorLat,
        lng: anchorLng,
        radiusKm: 10,
      );
      expect(result, isEmpty);
    });

    test('valid record → parsed Station entity', () {
      final result = UkFuelFinderResponseParser.parseFuelFinderStations(
        <dynamic>[_ukStation()],
        lat: anchorLat,
        lng: anchorLng,
        radiusKm: 10,
      );
      expect(result, hasLength(1));
      final s = result.first;
      expect(s.id, 'uk-AA0001');
      expect(s.name, 'Sample Forecourt');
      expect(s.brand, 'Shell');
      expect(s.street, '1 The Strand');
      expect(s.postCode, 'WC2N 5DN');
      expect(s.place, 'London');
      expect(s.lat, 51.5080);
      expect(s.lng, -0.1281);
      expect(s.e5, closeTo(149.99, 1e-9));
      expect(s.e10, closeTo(142.99, 1e-9));
      expect(s.diesel, closeTo(154.99, 1e-9));
      expect(s.isOpen, isTrue);
    });

    test('non-Map entries are skipped', () {
      final result = UkFuelFinderResponseParser.parseFuelFinderStations(
        <dynamic>['oops', 42, null, _ukStation()],
        lat: anchorLat,
        lng: anchorLng,
        radiusKm: 10,
      );
      expect(result, hasLength(1));
    });

    test('records missing both lat & lng are dropped', () {
      final missingLoc = <String, dynamic>{
        'site_id': 'NOLOC',
        'site_name': 'No Location',
      };
      final result = UkFuelFinderResponseParser.parseFuelFinderStations(
        <dynamic>[missingLoc, _ukStation()],
        lat: anchorLat,
        lng: anchorLng,
        radiusKm: 10,
      );
      expect(result.map((s) => s.id), ['uk-AA0001']);
    });

    test('falls back to top-level latitude/longitude keys', () {
      final station = <String, dynamic>{
        'site_id': 'TOPLEVEL',
        'site_name': 'Top Level Coords',
        'latitude': anchorLat,
        'longitude': anchorLng,
        'prices': <String, dynamic>{'E10': 14000},
      };
      final result = UkFuelFinderResponseParser.parseFuelFinderStations(
        <dynamic>[station],
        lat: anchorLat,
        lng: anchorLng,
        radiusKm: 1,
      );
      expect(result, hasLength(1));
      expect(result.first.id, 'uk-TOPLEVEL');
    });

    test('falls back to lat/lng short keys', () {
      final station = <String, dynamic>{
        'site_id': 'SHORTKEYS',
        'site_name': 'Short Keys',
        'lat': anchorLat,
        'lng': anchorLng,
      };
      final result = UkFuelFinderResponseParser.parseFuelFinderStations(
        <dynamic>[station],
        lat: anchorLat,
        lng: anchorLng,
        radiusKm: 1,
      );
      expect(result, hasLength(1));
      expect(result.first.id, 'uk-SHORTKEYS');
    });

    test('stations beyond the radius are filtered out', () {
      // Edinburgh — ~530 km from London — far outside any urban radius.
      final farStation = _ukStation(
        siteId: 'EDIN',
        name: 'Edinburgh Forecourt',
        lat: 55.9533,
        lng: -3.1883,
      );
      final result = UkFuelFinderResponseParser.parseFuelFinderStations(
        <dynamic>[farStation, _ukStation()],
        lat: anchorLat,
        lng: anchorLng,
        radiusKm: 10,
      );
      expect(result.map((s) => s.id), ['uk-AA0001']);
    });

    test('duplicates by site_id are deduped (first wins)', () {
      final dup1 = _ukStation(siteId: 'DUP', name: 'First');
      final dup2 = _ukStation(siteId: 'DUP', name: 'Second');
      final result = UkFuelFinderResponseParser.parseFuelFinderStations(
        <dynamic>[dup1, dup2],
        lat: anchorLat,
        lng: anchorLng,
        radiusKm: 10,
      );
      expect(result, hasLength(1));
      expect(result.first.name, 'First');
    });

    test('falls back to `id` when site_id is missing', () {
      final station = _ukStation(siteId: null, id: 'ALT123');
      final result = UkFuelFinderResponseParser.parseFuelFinderStations(
        <dynamic>[station],
        lat: anchorLat,
        lng: anchorLng,
        radiusKm: 10,
      );
      expect(result, hasLength(1));
      expect(result.first.id, 'uk-ALT123');
    });

    test('synthesises a coordinate-derived id when both site_id and id are '
        'missing', () {
      final station = _ukStation(siteId: null);
      final result = UkFuelFinderResponseParser.parseFuelFinderStations(
        <dynamic>[station],
        lat: anchorLat,
        lng: anchorLng,
        radiusKm: 10,
      );
      expect(result, hasLength(1));
      expect(result.first.id, startsWith('uk-'));
      expect(result.first.id, contains('_'));
    });

    test('results are sorted by distance ascending', () {
      // Three records at varying distances from the anchor.
      final near = _ukStation(
        siteId: 'NEAR',
        lat: 51.5085,
        lng: -0.1280,
      );
      final mid = _ukStation(
        siteId: 'MID',
        lat: 51.5180,
        lng: -0.1281,
      );
      final far = _ukStation(
        siteId: 'FAR',
        lat: 51.5380,
        lng: -0.1281,
      );
      final result = UkFuelFinderResponseParser.parseFuelFinderStations(
        // Deliberately unsorted input.
        <dynamic>[far, near, mid],
        lat: anchorLat,
        lng: anchorLng,
        radiusKm: 50,
      );
      expect(result.map((s) => s.id), ['uk-NEAR', 'uk-MID', 'uk-FAR']);
      // Distances should be monotonically non-decreasing.
      for (var i = 1; i < result.length; i++) {
        expect(result[i].dist, greaterThanOrEqualTo(result[i - 1].dist));
      }
    });

    test('cap at 50 — 60 nearby stations → only the closest 50 returned', () {
      final stations = <dynamic>[];
      for (var i = 0; i < 60; i++) {
        // Spread along a longitude line; further index → further station.
        stations.add(_ukStation(
          siteId: 'S$i',
          lat: anchorLat + (i * 0.0005),
          lng: anchorLng,
        ));
      }
      final result = UkFuelFinderResponseParser.parseFuelFinderStations(
        stations,
        lat: anchorLat,
        lng: anchorLng,
        radiusKm: 100,
      );
      expect(result, hasLength(50));
      // The closest 50 must all have indices 0..49.
      final ids = result.map((s) => s.id).toSet();
      for (var i = 0; i < 50; i++) {
        expect(ids, contains('uk-S$i'));
      }
      expect(ids, isNot(contains('uk-S50')));
    });

    test('records with non-numeric prices yield null fuel slots without '
        'dropping the station', () {
      final station = _ukStation(
        siteId: 'BADPRICE',
        prices: <String, dynamic>{
          'E5': 'unavailable',
          'E10': null,
          'B7': 14999,
        },
      );
      final result = UkFuelFinderResponseParser.parseFuelFinderStations(
        <dynamic>[station],
        lat: anchorLat,
        lng: anchorLng,
        radiusKm: 10,
      );
      expect(result, hasLength(1));
      final s = result.first;
      expect(s.e5, isNull);
      expect(s.e10, isNull);
      expect(s.diesel, closeTo(149.99, 1e-9));
    });

    test('alternate price keys (unleaded, super_unleaded, diesel, '
        'premium_diesel) are honoured', () {
      final station = _ukStation(
        siteId: 'ALTKEYS',
        prices: <String, dynamic>{
          'unleaded': 14500, // → e5 fallback
          'super_unleaded': 16500, // → e98 fallback
          'diesel': 15800, // → diesel fallback
          'premium_diesel': 17200, // → dieselPremium fallback
        },
      );
      final result = UkFuelFinderResponseParser.parseFuelFinderStations(
        <dynamic>[station],
        lat: anchorLat,
        lng: anchorLng,
        radiusKm: 10,
      );
      expect(result, hasLength(1));
      final s = result.first;
      expect(s.e5, closeTo(145.00, 1e-9));
      expect(s.e98, closeTo(165.00, 1e-9));
      expect(s.diesel, closeTo(158.00, 1e-9));
      expect(s.dieselPremium, closeTo(172.00, 1e-9));
    });

    test('missing prices map yields null fuel slots without dropping the '
        'station', () {
      final station = <String, dynamic>{
        'site_id': 'NOPRICES',
        'site_name': 'No Prices',
        'location': <String, dynamic>{
          'latitude': anchorLat,
          'longitude': anchorLng,
        },
      };
      final result = UkFuelFinderResponseParser.parseFuelFinderStations(
        <dynamic>[station],
        lat: anchorLat,
        lng: anchorLng,
        radiusKm: 10,
      );
      expect(result, hasLength(1));
      final s = result.first;
      expect(s.e5, isNull);
      expect(s.e10, isNull);
      expect(s.diesel, isNull);
      expect(s.dieselPremium, isNull);
    });

    test('falls back to `name` when `site_name` is absent', () {
      final station = <String, dynamic>{
        'site_id': 'FALLBACKNAME',
        'name': 'Generic Forecourt',
        'brand': 'BP',
        'location': <String, dynamic>{
          'latitude': anchorLat,
          'longitude': anchorLng,
        },
      };
      final result = UkFuelFinderResponseParser.parseFuelFinderStations(
        <dynamic>[station],
        lat: anchorLat,
        lng: anchorLng,
        radiusKm: 10,
      );
      expect(result, hasLength(1));
      expect(result.first.name, 'Generic Forecourt');
    });

    test('falls back to `locality` when `town` is missing', () {
      final station = <String, dynamic>{
        'site_id': 'LOCALITY',
        'site_name': 'Locality Forecourt',
        'locality': 'Westminster',
        'location': <String, dynamic>{
          'latitude': anchorLat,
          'longitude': anchorLng,
        },
      };
      final result = UkFuelFinderResponseParser.parseFuelFinderStations(
        <dynamic>[station],
        lat: anchorLat,
        lng: anchorLng,
        radiusKm: 10,
      );
      expect(result, hasLength(1));
      expect(result.first.place, 'Westminster');
    });
  });
}
