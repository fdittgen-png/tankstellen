import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/impl/uk_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/utils/geo_utils.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

/// Tests for [UkStationService] and its CMA / checkfuelprices.co.uk
/// JSON parsing logic.
///
/// The production service instantiates Dio internally via `DioFactory.create()`,
/// which means we can't inject a mock HTTP client. We therefore mirror the
/// parsing logic in `_TestableUkParser` and exercise the real service only
/// for its synchronous public surface.
void main() {
  late UkStationService service;

  setUp(() {
    service = UkStationService();
  });

  group('UkStationService (public surface)', () {
    test('implements StationService interface', () {
      expect(service, isA<StationService>());
    });

    test('getStationDetail throws ApiException', () {
      expect(
        () => service.getStationDetail('uk-123'),
        throwsA(isA<Exception>()),
      );
    });

    test('getPrices returns empty map with correct source', () async {
      final result = await service.getPrices(['uk-1', 'uk-2']);
      expect(result.data, isEmpty);
      expect(result.source, ServiceSource.ukApi);
      expect(result.isStale, isFalse);
    });

    test('getPrices returns empty map for empty id list', () async {
      final result = await service.getPrices([]);
      expect(result.data, isEmpty);
      expect(result.source, ServiceSource.ukApi);
    });
  });

  group('CMA / checkfuelprices.co.uk response parsing', () {
    late _TestableUkParser parser;

    setUp(() {
      parser = _TestableUkParser();
    });

    test('parses a well-formed response with prices in pence', () {
      // Realistic CMA-style payload: prices are in pence (e.g. 145.9 = £1.459)
      final data = {
        'stations': [
          {
            'id': 'ABC123',
            'name': 'BP Victoria Street',
            'brand': 'BP',
            'address': '123 Victoria Street',
            'postcode': 'SW1E 6DE',
            'town': 'London',
            'location': {'latitude': 51.4975, 'longitude': -0.1357},
            'prices': {
              'E10': 145.9,
              'E5': 155.9,
              'B7': 152.9,
            },
          },
        ],
      };

      final stations = parser.parseResponse(data, lat: 51.4975, lng: -0.1357, radiusKm: 10);

      expect(stations, hasLength(1));
      final s = stations.first;
      expect(s.id, 'uk-ABC123');
      expect(s.name, 'BP Victoria Street');
      expect(s.brand, 'BP');
      expect(s.street, '123 Victoria Street');
      expect(s.postCode, 'SW1E 6DE');
      expect(s.place, 'London');
      // Pence -> pounds conversion
      expect(s.e10, closeTo(1.459, 0.0001));
      expect(s.e5, closeTo(1.559, 0.0001));
      expect(s.diesel, closeTo(1.529, 0.0001));
      expect(s.isOpen, isTrue);
    });

    test('keeps prices under 10 as-is (already in pounds)', () {
      final data = {
        'stations': [
          {
            'id': 1,
            'name': 'Already pounds',
            'brand': 'Shell',
            'location': {'latitude': 51.5, 'longitude': -0.12},
            'prices': {
              'E10': 1.459,
              'B7': 1.529,
            },
          },
        ],
      };

      final stations = parser.parseResponse(data, lat: 51.5, lng: -0.12, radiusKm: 10);

      expect(stations.first.e10, 1.459);
      expect(stations.first.diesel, 1.529);
    });

    test('supports alternate field names (site_id, site_name, lat/lng, unleaded)', () {
      final data = {
        'data': [
          {
            'site_id': 'SITE42',
            'site_name': 'Tesco Extra',
            'brand': 'Tesco',
            'address': 'Retail Park',
            'postcode': 'M1 1AA',
            'locality': 'Manchester',
            'lat': 53.4808,
            'lng': -2.2426,
            'prices': {
              'unleaded': 144.9,
              'E10': 142.9,
              'diesel': 151.9,
              'super_unleaded': 158.9,
            },
          },
        ],
      };

      final stations = parser.parseResponse(data, lat: 53.4808, lng: -2.2426, radiusKm: 20);

      expect(stations, hasLength(1));
      final s = stations.first;
      expect(s.id, 'uk-SITE42');
      expect(s.name, 'Tesco Extra');
      expect(s.place, 'Manchester');
      expect(s.lat, closeTo(53.4808, 0.0001));
      expect(s.e5, closeTo(1.449, 0.0001)); // unleaded
      expect(s.e10, closeTo(1.429, 0.0001));
      expect(s.diesel, closeTo(1.519, 0.0001));
      expect(s.e98, closeTo(1.589, 0.0001)); // super_unleaded
    });

    test('accepts a top-level list payload', () {
      final data = [
        {
          'id': 1,
          'name': 'Station A',
          'lat': 51.5,
          'lng': -0.12,
          'prices': <String, dynamic>{},
        },
      ];

      final stations = parser.parseResponse(data, lat: 51.5, lng: -0.12, radiusKm: 5);
      expect(stations, hasLength(1));
      expect(stations.first.name, 'Station A');
    });

    test('skips stations with missing coordinates', () {
      final data = {
        'stations': [
          {
            'id': 1,
            'name': 'No coords',
            'prices': <String, dynamic>{},
          },
          {
            'id': 2,
            'name': 'With coords',
            'lat': 51.5,
            'lng': -0.12,
            'prices': <String, dynamic>{},
          },
        ],
      };

      final stations = parser.parseResponse(data, lat: 51.5, lng: -0.12, radiusKm: 5);
      expect(stations, hasLength(1));
      expect(stations.first.name, 'With coords');
    });

    test('skips stations outside the search radius', () {
      final data = {
        'stations': [
          {
            'id': 1,
            'name': 'London',
            'lat': 51.5,
            'lng': -0.12,
            'prices': <String, dynamic>{},
          },
          {
            'id': 2,
            'name': 'Edinburgh',
            'lat': 55.9533,
            'lng': -3.1883,
            'prices': <String, dynamic>{},
          },
        ],
      };

      final stations = parser.parseResponse(data, lat: 51.5, lng: -0.12, radiusKm: 50);
      expect(stations, hasLength(1));
      expect(stations.first.name, 'London');
    });

    test('returns empty list for empty stations list', () {
      final stations = parser.parseResponse(
        {'stations': <dynamic>[]},
        lat: 51.5,
        lng: -0.12,
        radiusKm: 10,
      );
      expect(stations, isEmpty);
    });

    test('handles missing prices map without crashing', () {
      final data = {
        'stations': [
          {
            'id': 1,
            'name': 'No prices key',
            'lat': 51.5,
            'lng': -0.12,
          },
        ],
      };

      final stations = parser.parseResponse(data, lat: 51.5, lng: -0.12, radiusKm: 5);

      expect(stations, hasLength(1));
      final s = stations.first;
      expect(s.e5, isNull);
      expect(s.e10, isNull);
      expect(s.e98, isNull);
      expect(s.diesel, isNull);
    });

    test('sorts stations by distance ascending', () {
      final data = {
        'stations': [
          {
            'id': 1,
            'name': 'Far',
            'lat': 51.52,
            'lng': -0.12,
            'prices': <String, dynamic>{},
          },
          {
            'id': 2,
            'name': 'Near',
            'lat': 51.5001,
            'lng': -0.12,
            'prices': <String, dynamic>{},
          },
        ],
      };

      final stations = parser.parseResponse(data, lat: 51.5, lng: -0.12, radiusKm: 50);
      expect(stations, hasLength(2));
      expect(stations.first.name, 'Near');
      expect(stations.last.name, 'Far');
    });

    test('caps results at 50 stations', () {
      final list = <Map<String, dynamic>>[];
      for (var i = 0; i < 120; i++) {
        list.add({
          'id': i,
          'name': 'S$i',
          'lat': 51.5 + i * 0.0001,
          'lng': -0.12,
          'prices': <String, dynamic>{},
        });
      }

      final stations = parser.parseResponse(
        {'stations': list},
        lat: 51.5,
        lng: -0.12,
        radiusKm: 50,
      );

      expect(stations.length, lessThanOrEqualTo(50));
    });

    test('_parsePence returns null for null value', () {
      expect(parser.parsePence(null), isNull);
    });

    test('_parsePence returns null for non-numeric value', () {
      expect(parser.parsePence('abc'), isNull);
    });

    test('_parsePence converts pence (>10) to pounds', () {
      expect(parser.parsePence(145.9), closeTo(1.459, 0.0001));
      expect(parser.parsePence('155'), closeTo(1.55, 0.0001));
    });

    test('_parsePence keeps values <=10 unchanged (already in pounds)', () {
      expect(parser.parsePence(1.459), 1.459);
      expect(parser.parsePence('2.5'), 2.5);
    });
  });
}

/// Mirror of [UkStationService]'s parsing logic for unit-testing without HTTP.
class _TestableUkParser {
  List<Station> parseResponse(
    dynamic data, {
    required double lat,
    required double lng,
    required double radiusKm,
  }) {
    List<dynamic> stationList;
    if (data is Map<String, dynamic>) {
      stationList = data['stations'] as List<dynamic>? ??
          data['data'] as List<dynamic>? ??
          [];
    } else if (data is List) {
      stationList = data;
    } else {
      return [];
    }

    final stations = <Station>[];
    for (final item in stationList) {
      try {
        final location = item['location'] as Map<String, dynamic>?;
        final itemLat =
            (location?['latitude'] as num?)?.toDouble() ?? (item['lat'] as num?)?.toDouble();
        final itemLng =
            (location?['longitude'] as num?)?.toDouble() ?? (item['lng'] as num?)?.toDouble();
        if (itemLat == null || itemLng == null) continue;

        final dist = distanceKm(lat, lng, itemLat, itemLng);
        if (dist > radiusKm) continue;

        final prices = item['prices'] as Map<String, dynamic>? ?? <String, dynamic>{};

        stations.add(Station(
          id: 'uk-${item['id'] ?? item['site_id'] ?? stations.length}',
          name: item['name']?.toString() ?? item['site_name']?.toString() ?? '',
          brand: item['brand']?.toString() ?? '',
          street: item['address']?.toString() ?? '',
          postCode: item['postcode']?.toString() ?? '',
          place: item['town']?.toString() ?? item['locality']?.toString() ?? '',
          lat: itemLat,
          lng: itemLng,
          dist: dist,
          e5: parsePence(prices['E5'] ?? prices['unleaded']),
          e10: parsePence(prices['E10']),
          e98: parsePence(prices['super_unleaded'] ?? prices['E5_97']),
          diesel: parsePence(prices['B7'] ?? prices['diesel']),
          isOpen: true,
        ));
      } catch (_) {
        continue;
      }
    }

    stations.sort((a, b) => a.dist.compareTo(b.dist));
    return stations.take(50).toList();
  }

  double? parsePence(dynamic value) {
    if (value == null) return null;
    final price = double.tryParse(value.toString());
    if (price == null) return null;
    return price > 10 ? price / 100 : price;
  }
}
