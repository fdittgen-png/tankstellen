import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/impl/denmark_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

void main() {
  late DenmarkStationService service;

  setUp(() {
    service = DenmarkStationService();
  });

  group('DenmarkStationService', () {
    test('implements StationService interface', () {
      expect(service, isA<StationService>());
    });

    group('getStationDetail', () {
      test('throws ApiException (detail not available)', () {
        expect(
          () => service.getStationDetail('dk-123'),
          throwsA(isA<ApiException>()),
        );
      });

      test('error message mentions Danish APIs', () async {
        try {
          await service.getStationDetail('dk-test');
          fail('Should have thrown');
        } on ApiException catch (e) {
          expect(e.message, contains('Danish'));
        }
      });
    });

    group('getPrices', () {
      test('returns empty map', () async {
        final result = await service.getPrices(['dk-1', 'dk-2']);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.denmarkApi);
      });

      test('returns empty map for empty id list', () async {
        final result = await service.getPrices([]);
        expect(result.data, isEmpty);
      });

      test('result has correct metadata', () async {
        final result = await service.getPrices(['x']);
        expect(result.source, ServiceSource.denmarkApi);
        expect(result.fetchedAt, isA<DateTime>());
        expect(result.isStale, isFalse);
      });
    });
  });

  group('Denmark API parsing edge cases', () {
    late _TestableDenmarkParser parser;

    setUp(() {
      parser = _TestableDenmarkParser();
    });

    group('parseOkResponse additional', () {
      test('handles multiple stations', () {
        final data = {
          'items': [
            {
              'facility_number': '1001',
              'coordinates': {'latitude': 55.6761, 'longitude': 12.5683},
              'prices': [
                {'product_name': 'Blyfri 95', 'price': 13.49},
              ],
              'street': 'Street1',
              'house_number': '1',
              'city': 'City1',
              'postal_code': '1000',
            },
            {
              'facility_number': '1002',
              'coordinates': {'latitude': 56.1500, 'longitude': 10.2000},
              'prices': [
                {'product_name': 'Diesel', 'price': 11.50},
              ],
              'street': 'Street2',
              'house_number': '2',
              'city': 'City2',
              'postal_code': '8000',
            },
          ],
        };

        final stations = parser.parseOkResponse(data);
        expect(stations, hasLength(2));
        expect(stations[0].id, 'ok-1001');
        expect(stations[1].id, 'ok-1002');
        expect(stations[0].e5, closeTo(13.49, 0.01));
        expect(stations[1].diesel, closeTo(11.50, 0.01));
      });

      test('handles missing coordinates map entirely', () {
        final data = {
          'items': [
            {
              'facility_number': '1001',
              'prices': [],
            },
          ],
        };

        final stations = parser.parseOkResponse(data);
        expect(stations, isEmpty); // coords default to 0,0 => skipped
      });

      test('first matching fuel price wins (no overwrite)', () {
        final data = {
          'items': [
            {
              'facility_number': '1001',
              'coordinates': {'latitude': 55.5, 'longitude': 12.5},
              'prices': [
                {'product_name': 'Blyfri 95', 'price': 13.49},
                {'product_name': 'Oktan 95', 'price': 14.00},
              ],
            },
          ],
        };

        final stations = parser.parseOkResponse(data);
        expect(stations[0].e5, closeTo(13.49, 0.01)); // First one wins
      });

      test('unrecognized fuel types are ignored', () {
        final data = {
          'items': [
            {
              'facility_number': '1001',
              'coordinates': {'latitude': 55.5, 'longitude': 12.5},
              'prices': [
                {'product_name': 'LPG', 'price': 8.50},
              ],
            },
          ],
        };

        final stations = parser.parseOkResponse(data);
        expect(stations[0].e5, isNull);
        expect(stations[0].diesel, isNull);
      });

      test('handles house_number as null', () {
        final data = {
          'items': [
            {
              'facility_number': '1001',
              'coordinates': {'latitude': 55.5, 'longitude': 12.5},
              'prices': [],
              'street': 'TestStreet',
              'house_number': null,
              'city': 'TestCity',
            },
          ],
        };

        final stations = parser.parseOkResponse(data);
        expect(stations[0].street, 'TestStreet');
      });
    });

    group('parseShellResponse additional', () {
      test('handles multiple Shell stations', () {
        final data = [
          {
            'stationId': 'S1',
            'brand': 'Shell',
            'coordinates': {'latitude': '55.5', 'longitude': '12.5'},
            'prices': [
              {'productName': 'Blyfri 95', 'price': '13.79', 'lastUpdated': '2026-03-29T10:00:00Z'},
            ],
            'street': 'St1',
            'postalCode': '1000',
            'city': 'City1',
          },
          {
            'stationId': 'S2',
            'brand': 'Shell Express',
            'coordinates': {'latitude': '56.0', 'longitude': '10.0'},
            'prices': [
              {'productName': 'Diesel', 'price': '12.00'},
            ],
            'street': 'St2',
            'postalCode': '8000',
            'city': 'City2',
          },
        ];

        final stations = parser.parseShellResponse(data);
        expect(stations, hasLength(2));
        expect(stations[0].brand, 'Shell');
        expect(stations[1].brand, 'Shell Express');
      });

      test('defaults brand to Shell when missing', () {
        final data = [
          {
            'stationId': 'S1',
            'coordinates': {'latitude': '55.5', 'longitude': '12.5'},
            'prices': [],
          },
        ];

        final stations = parser.parseShellResponse(data);
        expect(stations[0].name, 'Shell');
        expect(stations[0].brand, 'Shell');
      });

      test('handles non-numeric price string gracefully', () {
        final data = [
          {
            'stationId': 'S1',
            'coordinates': {'latitude': '55.5', 'longitude': '12.5'},
            'prices': [
              {'productName': 'Blyfri 95', 'price': 'N/A'},
            ],
          },
        ];

        final stations = parser.parseShellResponse(data);
        expect(stations[0].e5, isNull);
      });

      test('handles missing coordinates values', () {
        final data = [
          {
            'stationId': 'S1',
            'coordinates': <String, dynamic>{},
            'prices': [],
          },
        ];

        final stations = parser.parseShellResponse(data);
        expect(stations, isEmpty); // lat/lng parse to 0
      });

      test('updatedAt comes from first price lastUpdated', () {
        final data = [
          {
            'stationId': 'S1',
            'brand': 'Shell',
            'coordinates': {'latitude': '55.5', 'longitude': '12.5'},
            'prices': [
              {
                'productName': 'Blyfri 95',
                'price': '13.00',
                'lastUpdated': '2026-01-15T09:30:00Z',
              },
            ],
          },
        ];

        final stations = parser.parseShellResponse(data);
        expect(stations[0].updatedAt, '15/01 09:30');
      });
    });

    group('formatIsoTime additional', () {
      test('handles midnight correctly', () {
        expect(
          parser.testFormatIsoTime('2026-12-31T00:00:00Z'),
          '31/12 00:00',
        );
      });

      test('handles end of day correctly', () {
        expect(
          parser.testFormatIsoTime('2026-06-15T23:59:00Z'),
          '15/06 23:59',
        );
      });

      test('returns null for empty string', () {
        expect(parser.testFormatIsoTime(''), isNull);
      });
    });
  });

  group('Denmark API parsing (via _TestableDenmarkParser)', () {
    late _TestableDenmarkParser parser;

    setUp(() {
      parser = _TestableDenmarkParser();
    });

    group('parseOkResponse', () {
      test('parses valid OK API response', () {
        final data = {
          'items': [
            {
              'facility_number': '1001',
              'coordinates': {'latitude': 55.6761, 'longitude': 12.5683},
              'prices': [
                {'product_name': 'Blyfri 95', 'price': 13.49},
                {'product_name': 'Diesel', 'price': 11.99},
              ],
              'street': 'Vesterbrogade',
              'house_number': '42',
              'city': 'København',
              'postal_code': '1620',
              'last_updated_time': '2026-03-29T14:30:00Z',
            },
          ],
        };

        final stations = parser.parseOkResponse(data);
        expect(stations, hasLength(1));

        final s = stations[0];
        expect(s.id, 'ok-1001');
        expect(s.name, 'OK');
        expect(s.brand, 'OK');
        expect(s.street, 'Vesterbrogade 42');
        expect(s.postCode, '1620');
        expect(s.place, 'København');
        expect(s.lat, closeTo(55.6761, 0.001));
        expect(s.lng, closeTo(12.5683, 0.001));
        expect(s.e5, closeTo(13.49, 0.01));
        expect(s.e10, closeTo(13.49, 0.01));
        expect(s.diesel, closeTo(11.99, 0.01));
        expect(s.isOpen, isTrue);
      });

      test('skips stations with zero coordinates', () {
        final data = {
          'items': [
            {
              'facility_number': '1001',
              'coordinates': {'latitude': 0, 'longitude': 0},
              'prices': [],
            },
          ],
        };

        final stations = parser.parseOkResponse(data);
        expect(stations, isEmpty);
      });

      test('returns empty list for non-map data', () {
        final stations = parser.parseOkResponse('not a map');
        expect(stations, isEmpty);
      });

      test('returns empty list for missing items key', () {
        final stations = parser.parseOkResponse(<String, dynamic>{});
        expect(stations, isEmpty);
      });

      test('handles missing optional fields gracefully', () {
        final data = {
          'items': [
            {
              'coordinates': {'latitude': 55.5, 'longitude': 12.5},
              'prices': [],
            },
          ],
        };

        final stations = parser.parseOkResponse(data);
        expect(stations, hasLength(1));
        expect(stations[0].id, 'ok-');
        expect(stations[0].street, '');
        expect(stations[0].postCode, '');
        expect(stations[0].e5, isNull);
        expect(stations[0].diesel, isNull);
      });

      test('matches 95 fuel type from product name', () {
        final data = {
          'items': [
            {
              'coordinates': {'latitude': 55.5, 'longitude': 12.5},
              'prices': [
                {'product_name': 'Oktan 95 Blyfri', 'price': 14.0},
              ],
            },
          ],
        };

        final stations = parser.parseOkResponse(data);
        expect(stations[0].e5, closeTo(14.0, 0.01));
      });
    });

    group('parseShellResponse', () {
      test('parses valid Shell API response', () {
        final data = [
          {
            'stationId': 'S42',
            'brand': 'Shell',
            'coordinates': {
              'latitude': '55.6800',
              'longitude': '12.5700',
            },
            'prices': [
              {
                'productName': 'Blyfri 95',
                'price': '13.79',
                'lastUpdated': '2026-03-29T10:00:00Z',
              },
              {
                'productName': 'Diesel',
                'price': '12.29',
                'lastUpdated': '2026-03-29T10:00:00Z',
              },
            ],
            'street': 'Amagerbrogade',
            'houseNumber': '100',
            'postalCode': '2300',
            'city': 'København S',
          },
        ];

        final stations = parser.parseShellResponse(data);
        expect(stations, hasLength(1));

        final s = stations[0];
        expect(s.id, 'shell-S42');
        expect(s.name, 'Shell');
        expect(s.brand, 'Shell');
        expect(s.street, 'Amagerbrogade 100');
        expect(s.postCode, '2300');
        expect(s.place, 'København S');
        expect(s.lat, closeTo(55.68, 0.001));
        expect(s.lng, closeTo(12.57, 0.001));
        expect(s.e5, closeTo(13.79, 0.01));
        expect(s.diesel, closeTo(12.29, 0.01));
      });

      test('skips stations with zero coordinates', () {
        final data = [
          {
            'stationId': 'S1',
            'coordinates': {'latitude': '0', 'longitude': '0'},
            'prices': [],
          },
        ];

        final stations = parser.parseShellResponse(data);
        expect(stations, isEmpty);
      });

      test('returns empty list for non-list data', () {
        final stations = parser.parseShellResponse({'not': 'a list'});
        expect(stations, isEmpty);
      });

      test('handles missing price fields', () {
        final data = [
          {
            'stationId': 'S1',
            'coordinates': {'latitude': '55.5', 'longitude': '12.5'},
            'prices': [],
          },
        ];

        final stations = parser.parseShellResponse(data);
        expect(stations, hasLength(1));
        expect(stations[0].e5, isNull);
        expect(stations[0].diesel, isNull);
      });
    });

    group('formatIsoTime', () {
      test('formats valid ISO timestamp', () {
        expect(
          parser.testFormatIsoTime('2026-03-29T14:30:00Z'),
          '29/03 14:30',
        );
      });

      test('formats ISO timestamp with offset (converts to UTC)', () {
        // DateTime.parse converts +02:00 offset to UTC: 14:30+02 => 12:30 UTC
        expect(
          parser.testFormatIsoTime('2026-03-29T14:30:00+02:00'),
          '29/03 12:30',
        );
      });

      test('returns null for null input', () {
        expect(parser.testFormatIsoTime(null), isNull);
      });

      test('returns null for invalid timestamp', () {
        expect(parser.testFormatIsoTime('not-a-date'), isNull);
      });

      test('pads single-digit day and month', () {
        expect(
          parser.testFormatIsoTime('2026-01-05T09:05:00Z'),
          '05/01 09:05',
        );
      });
    });
  });
}

/// Replicates Denmark parsing logic for isolated unit testing.
class _TestableDenmarkParser {
  List<Station> parseOkResponse(dynamic responseData) {
    if (responseData is! Map) return [];
    final items = responseData['items'] as List<dynamic>? ?? [];

    return items.map((r) {
      final coords = r['coordinates'] as Map<String, dynamic>? ?? {};
      final lat = (coords['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (coords['longitude'] as num?)?.toDouble() ?? 0;
      if (lat == 0 || lng == 0) return null;

      final prices = r['prices'] as List<dynamic>? ?? [];
      double? e5, diesel;
      for (final p in prices) {
        final name = (p['product_name']?.toString() ?? '').toLowerCase();
        final price = (p['price'] as num?)?.toDouble();
        if (name.contains('95') || name.contains('blyfri')) {
          e5 ??= price;
        } else if (name.contains('diesel')) {
          diesel ??= price;
        }
      }

      final street = r['street']?.toString() ?? '';
      final houseNr = r['house_number']?.toString() ?? '';
      final city = r['city']?.toString() ?? '';

      return Station(
        id: 'ok-${r['facility_number'] ?? ''}',
        name: 'OK',
        brand: 'OK',
        street: '$street $houseNr'.trim(),
        postCode: r['postal_code']?.toString() ?? '',
        place: city,
        lat: lat,
        lng: lng,
        dist: 0,
        e5: e5,
        e10: e5,
        diesel: diesel,
        isOpen: true,
        updatedAt: testFormatIsoTime(r['last_updated_time']?.toString()),
      );
    }).whereType<Station>().toList();
  }

  List<Station> parseShellResponse(dynamic responseData) {
    if (responseData is! List) return [];

    return responseData.map((r) {
      final coords = r['coordinates'] as Map<String, dynamic>? ?? {};
      final lat = double.tryParse(coords['latitude']?.toString() ?? '') ?? 0;
      final lng = double.tryParse(coords['longitude']?.toString() ?? '') ?? 0;
      if (lat == 0 || lng == 0) return null;

      final prices = r['prices'] as List<dynamic>? ?? [];
      double? e5, diesel;
      for (final p in prices) {
        final name = (p['productName']?.toString() ?? '').toLowerCase();
        final price = double.tryParse(p['price']?.toString() ?? '');
        if (name.contains('95') || name.contains('blyfri')) {
          e5 ??= price;
        } else if (name.contains('diesel')) {
          diesel ??= price;
        }
      }

      return Station(
        id: 'shell-${r['stationId'] ?? ''}',
        name: r['brand']?.toString() ?? 'Shell',
        brand: r['brand']?.toString() ?? 'Shell',
        street: '${r['street'] ?? ''} ${r['houseNumber'] ?? ''}'.trim(),
        postCode: r['postalCode']?.toString() ?? '',
        place: r['city']?.toString() ?? '',
        lat: lat,
        lng: lng,
        dist: 0,
        e5: e5,
        e10: e5,
        diesel: diesel,
        isOpen: true,
        updatedAt: testFormatIsoTime(
          (prices.isNotEmpty ? prices.first['lastUpdated'] : null)?.toString(),
        ),
      );
    }).whereType<Station>().toList();
  }

  String? testFormatIsoTime(String? iso) {
    if (iso == null) return null;
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } on FormatException catch (_) {
      return null;
    }
  }
}
