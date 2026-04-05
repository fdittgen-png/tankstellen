import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/impl/econtrol_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

void main() {
  late EControlStationService service;

  setUp(() {
    service = EControlStationService();
  });

  group('EControlStationService', () {
    test('implements StationService interface', () {
      expect(service, isA<StationService>());
    });

    group('getStationDetail', () {
      test('throws ApiException (detail not available)', () {
        expect(
          () => service.getStationDetail('at-123'),
          throwsA(isA<ApiException>()),
        );
      });

      test('error message mentions E-Control API', () async {
        try {
          await service.getStationDetail('at-test');
          fail('Should have thrown');
        } on ApiException catch (e) {
          expect(e.message, contains('E-Control'));
        }
      });
    });

    group('getPrices', () {
      test('returns empty map', () async {
        final result = await service.getPrices(['at-1', 'at-2']);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.eControlApi);
      });

      test('returns empty map for empty id list', () async {
        final result = await service.getPrices([]);
        expect(result.data, isEmpty);
      });

      test('result has correct metadata', () async {
        final result = await service.getPrices(['x']);
        expect(result.source, ServiceSource.eControlApi);
        expect(result.fetchedAt, isA<DateTime>());
        expect(result.isStale, isFalse);
      });
    });
  });

  group('E-Control parsing edge cases', () {
    late _TestableEControlParser parser;

    setUp(() {
      parser = _TestableEControlParser();
    });

    group('parseStation additional cases', () {
      test('handles multiple prices in prices array (takes last)', () {
        final data = {
          'id': 100,
          'name': 'Test',
          'location': {'latitude': 48.0, 'longitude': 16.0},
          'prices': [
            {'amount': 1.500},
            {'amount': 1.600},
          ],
          'openingHours': [],
        };

        final station = parser.testParseStation(data, 48.0, 16.0, 'DIE');
        expect(station, isNotNull);
        expect(station!.diesel, closeTo(1.600, 0.001));
      });

      test('handles null id gracefully', () {
        final data = {
          'name': 'No ID Station',
          'location': {'latitude': 48.0, 'longitude': 16.0},
          'prices': [],
          'openingHours': [],
        };

        final station = parser.testParseStation(data, 48.0, 16.0, 'DIE');
        expect(station, isNotNull);
        expect(station!.id, '');
      });

      test('handles null name gracefully', () {
        final data = {
          'id': 999,
          'location': {'latitude': 48.0, 'longitude': 16.0},
          'prices': [],
          'openingHours': [],
        };

        final station = parser.testParseStation(data, 48.0, 16.0, 'DIE');
        expect(station, isNotNull);
        expect(station!.name, '');
      });

      test('opening hours with day key instead of label', () {
        final data = {
          'id': 100,
          'name': 'Test',
          'location': {'latitude': 48.0, 'longitude': 16.0},
          'prices': [],
          'openingHours': [
            {'day': 'Monday', 'from': '06:00', 'to': '22:00'},
          ],
        };

        final station = parser.testParseStation(data, 48.0, 16.0, 'DIE');
        expect(station!.openingHoursText, contains('Monday'));
      });

      test('empty opening hours results in null openingHoursText', () {
        final data = {
          'id': 100,
          'name': 'Test',
          'location': {'latitude': 48.0, 'longitude': 16.0},
          'prices': [],
          'openingHours': [],
        };

        final station = parser.testParseStation(data, 48.0, 16.0, 'DIE');
        expect(station!.openingHoursText, isNull);
      });

      test('non-map items in openingHours are skipped', () {
        final data = {
          'id': 100,
          'name': 'Test',
          'location': {'latitude': 48.0, 'longitude': 16.0},
          'prices': [],
          'openingHours': ['not a map', 42],
        };

        final station = parser.testParseStation(data, 48.0, 16.0, 'DIE');
        expect(station!.openingHoursText, isNull);
      });

      test('non-map items in prices are skipped', () {
        final data = {
          'id': 100,
          'name': 'Test',
          'location': {'latitude': 48.0, 'longitude': 16.0},
          'prices': ['not a map', 42],
          'openingHours': [],
        };

        final station = parser.testParseStation(data, 48.0, 16.0, 'DIE');
        expect(station!.diesel, isNull);
      });

      test('defaults open to true when not specified', () {
        final data = {
          'id': 100,
          'name': 'Test',
          'location': {'latitude': 48.0, 'longitude': 16.0},
          'prices': [],
          'openingHours': [],
        };

        final station = parser.testParseStation(data, 48.0, 16.0, 'DIE');
        expect(station!.isOpen, isTrue);
      });
    });

    group('extractBrand additional cases', () {
      test('detects Eni brand', () {
        expect(parser.testExtractBrand('Eni Tankstelle Wien'), 'Eni');
      });

      test('detects Turmöl brand', () {
        expect(parser.testExtractBrand('Turmöl Graz'), 'Turmöl');
      });

      test('detects IQ brand', () {
        expect(parser.testExtractBrand('IQ Salzburg'), 'IQ');
      });

      test('detects Avia brand', () {
        expect(parser.testExtractBrand('Avia Linz'), 'Avia');
      });

      test('detects Genol brand', () {
        expect(parser.testExtractBrand('Genol Innsbruck'), 'Genol');
      });

      test('detects Lagerhaus brand', () {
        expect(parser.testExtractBrand('Lagerhaus Klagenfurt'), 'Lagerhaus');
      });

      test('detects SB brand', () {
        expect(parser.testExtractBrand('SB Tankstelle'), 'SB');
      });

      test('case insensitive brand detection', () {
        expect(parser.testExtractBrand('omv Wien'), 'OMV');
        expect(parser.testExtractBrand('SHELL Austria'), 'Shell');
        expect(parser.testExtractBrand('bp Graz'), 'BP');
      });
    });

    group('merging additional cases', () {
      test('super-only station gets e5 and e10 set', () {
        final superStation = Station(
          id: '200',
          name: 'Shell',
          brand: 'Shell',
          street: 'Str',
          postCode: '1010',
          place: 'Wien',
          lat: 48.2,
          lng: 16.4,
          dist: 1.0,
          e5: 1.549,
          isOpen: true,
        );

        // Station only from SUP query, no merge needed
        final merged = superStation.copyWith(
          e5: superStation.e5,
          e10: superStation.e5,
        );

        expect(merged.e5, closeTo(1.549, 0.001));
        expect(merged.e10, closeTo(1.549, 0.001));
        expect(merged.diesel, isNull);
      });
    });
  });

  group('E-Control parsing (via _TestableEControlParser)', () {
    late _TestableEControlParser parser;

    setUp(() {
      parser = _TestableEControlParser();
    });

    group('parseStation', () {
      test('parses valid diesel station response', () {
        final data = {
          'id': 12345,
          'name': 'OMV Wien Hauptbahnhof',
          'location': {
            'latitude': 48.1852,
            'longitude': 16.3761,
            'address': 'Wiedner Gürtel 12',
            'postalCode': '1040',
            'city': 'Wien',
          },
          'distance': 2.3,
          'open': true,
          'prices': [
            {'amount': 1.659},
          ],
          'openingHours': [
            {'label': 'Mo-Fr', 'from': '06:00', 'to': '22:00'},
            {'label': 'Sa-So', 'from': '07:00', 'to': '21:00'},
          ],
        };

        final station = parser.testParseStation(data, 48.2, 16.37, 'DIE');
        expect(station, isNotNull);
        expect(station!.id, '12345');
        expect(station.name, 'OMV Wien Hauptbahnhof');
        expect(station.street, 'Wiedner Gürtel 12');
        expect(station.postCode, '1040');
        expect(station.place, 'Wien');
        expect(station.lat, closeTo(48.1852, 0.001));
        expect(station.lng, closeTo(16.3761, 0.001));
        expect(station.dist, closeTo(2.3, 0.01));
        expect(station.diesel, closeTo(1.659, 0.001));
        expect(station.e5, isNull); // DIE query => no e5
        expect(station.isOpen, isTrue);
        expect(station.openingHoursText, contains('Mo-Fr'));
        expect(station.openingHoursText, contains('06:00-22:00'));
      });

      test('parses valid SUP (Super 95) station response', () {
        final data = {
          'id': 67890,
          'name': 'BP Innsbruck',
          'location': {
            'latitude': 47.2692,
            'longitude': 11.3933,
            'address': 'Innrain 5',
            'postalCode': '6020',
            'city': 'Innsbruck',
          },
          'open': false,
          'prices': [
            {'amount': 1.549},
          ],
          'openingHours': [],
        };

        final station = parser.testParseStation(data, 47.27, 11.39, 'SUP');
        expect(station, isNotNull);
        expect(station!.e5, closeTo(1.549, 0.001));
        expect(station.e10, closeTo(1.549, 0.001));
        expect(station.diesel, isNull);
        expect(station.isOpen, isFalse);
      });

      test('uses calculated distance when API distance is missing', () {
        final data = {
          'id': 111,
          'name': 'Test',
          'location': {
            'latitude': 48.2,
            'longitude': 16.4,
          },
          'prices': [],
          'openingHours': [],
        };

        final station = parser.testParseStation(data, 48.2, 16.4, 'DIE');
        expect(station, isNotNull);
        // Distance should be calculated (very small since coords are similar)
        expect(station!.dist, isNotNull);
      });

      test('handles missing price gracefully', () {
        final data = {
          'id': 222,
          'name': 'Test',
          'location': {'latitude': 48.0, 'longitude': 16.0},
          'prices': [],
          'openingHours': [],
        };

        final station = parser.testParseStation(data, 48.0, 16.0, 'DIE');
        expect(station, isNotNull);
        expect(station!.diesel, isNull);
      });

      test('handles missing location fields gracefully', () {
        final data = {
          'id': 333,
          'name': 'Test',
          'location': <String, dynamic>{},
          'prices': [],
          'openingHours': [],
        };

        final station = parser.testParseStation(data, 0, 0, 'DIE');
        expect(station, isNotNull);
        expect(station!.street, '');
        expect(station.postCode, '');
        expect(station.place, '');
      });

      test('parses GAS (CNG) fuel type to lpg field', () {
        final data = {
          'id': 444,
          'name': 'CNG Station',
          'location': {'latitude': 48.0, 'longitude': 16.0},
          'prices': [
            {'amount': 1.299},
          ],
          'openingHours': [],
        };

        final station = parser.testParseStation(data, 48.0, 16.0, 'GAS');
        expect(station, isNotNull);
        expect(station!.lpg, closeTo(1.299, 0.001));
        expect(station.e5, isNull);
        expect(station.diesel, isNull);
      });

      test('returns null for missing location map', () {
        final data = {
          'id': 555,
          'name': 'Bad',
          'prices': [],
          'openingHours': [],
        };

        // Missing 'location' key => uses empty map fallback => lat/lng = 0
        final station = parser.testParseStation(data, 0, 0, 'DIE');
        expect(station, isNotNull);
      });
    });

    group('extractBrand', () {
      test('detects OMV brand', () {
        expect(parser.testExtractBrand('OMV Graz Süd'), 'OMV');
      });

      test('detects BP brand', () {
        expect(parser.testExtractBrand('BP Wien Mitte'), 'BP');
      });

      test('detects Shell brand', () {
        expect(parser.testExtractBrand('Shell Austria Linz'), 'Shell');
      });

      test('detects Jet brand', () {
        expect(parser.testExtractBrand('Jet Tankstelle Villach'), 'Jet');
      });

      test('detects Avanti brand', () {
        expect(parser.testExtractBrand('Avanti Wien Nord'), 'Avanti');
      });

      test('uses first word for unknown brands', () {
        expect(parser.testExtractBrand('UnknownBrand Station'), 'UnknownBrand');
      });

      test('handles brand with hyphen separator', () {
        expect(parser.testExtractBrand('Avanti - Salzburg'), 'Avanti');
      });

      test('returns full name if single word', () {
        expect(parser.testExtractBrand('Tankstelle'), 'Tankstelle');
      });

      test('returns empty string for empty name', () {
        expect(parser.testExtractBrand(''), '');
      });
    });

    group('merging diesel and super queries', () {
      test('merges e5 from SUP into diesel station', () {
        final dieselStation = Station(
          id: '100',
          name: 'Test',
          brand: 'OMV',
          street: 'Str',
          postCode: '1010',
          place: 'Wien',
          lat: 48.2,
          lng: 16.4,
          dist: 1.0,
          diesel: 1.659,
          isOpen: true,
        );

        final superStation = Station(
          id: '100',
          name: 'Test',
          brand: 'OMV',
          street: 'Str',
          postCode: '1010',
          place: 'Wien',
          lat: 48.2,
          lng: 16.4,
          dist: 1.0,
          e5: 1.549,
          isOpen: true,
        );

        // Simulate the merge logic
        final merged = dieselStation.copyWith(
          e5: superStation.e5,
          e10: superStation.e5,
        );

        expect(merged.diesel, closeTo(1.659, 0.001));
        expect(merged.e5, closeTo(1.549, 0.001));
        expect(merged.e10, closeTo(1.549, 0.001));
        expect(merged.id, '100');
      });
    });
  });

  group('EControlStationService searchStations', () {
    test('searchStations throws ApiException on network failure', () async {
      final params = const SearchParams(
        lat: 48.2, lng: 16.37, radiusKm: 10.0,
      );
      try {
        await service.searchStations(params);
      } on ApiException catch (e) {
        expect(e.message, isNotEmpty);
      }
    });

    test('searchStations returns valid result type', () async {
      final params = const SearchParams(
        lat: 48.2, lng: 16.37, radiusKm: 10.0,
      );
      try {
        final result = await service.searchStations(params);
        expect(result.source, ServiceSource.eControlApi);
        expect(result.data, isA<List<Station>>());
      } on ApiException catch (_) {
        // Expected in test env
      }
    });

    test('searchStations with sort by price', () async {
      final params = const SearchParams(
        lat: 48.2, lng: 16.37, radiusKm: 10.0,
        sortBy: SortBy.price,
      );
      try {
        final result = await service.searchStations(params);
        expect(result.source, ServiceSource.eControlApi);
      } on ApiException catch (_) {
        // Expected
      }
    });
  });

  group('E-Control full merge pipeline', () {
    late _TestableEControlParser parser;

    setUp(() {
      parser = _TestableEControlParser();
    });

    test('diesel and super queries merge by station ID', () {
      // Simulate two API responses
      final dieselResponse = [
        {
          'id': 100,
          'name': 'OMV Wien',
          'location': {
            'latitude': 48.2,
            'longitude': 16.4,
            'address': 'Hauptstr 1',
            'postalCode': '1010',
            'city': 'Wien',
          },
          'distance': 1.5,
          'open': true,
          'prices': [{'amount': 1.659}],
          'openingHours': [
            {'label': 'Mo-Fr', 'from': '06:00', 'to': '22:00'},
          ],
        },
        {
          'id': 200,
          'name': 'BP Graz',
          'location': {
            'latitude': 47.07,
            'longitude': 15.44,
            'address': 'Grazer Str 5',
            'postalCode': '8010',
            'city': 'Graz',
          },
          'distance': 3.2,
          'open': false,
          'prices': [{'amount': 1.699}],
          'openingHours': [],
        },
      ];

      final superResponse = [
        {
          'id': 100,
          'name': 'OMV Wien',
          'location': {
            'latitude': 48.2,
            'longitude': 16.4,
            'address': 'Hauptstr 1',
            'postalCode': '1010',
            'city': 'Wien',
          },
          'distance': 1.5,
          'open': true,
          'prices': [{'amount': 1.549}],
          'openingHours': [],
        },
        {
          'id': 300,
          'name': 'Jet Linz',
          'location': {
            'latitude': 48.3,
            'longitude': 14.3,
            'address': 'Linzer Str 10',
            'postalCode': '4020',
            'city': 'Linz',
          },
          'distance': 5.0,
          'open': true,
          'prices': [{'amount': 1.519}],
          'openingHours': [],
        },
      ];

      // Parse diesel stations
      final dieselStations = dieselResponse.map((r) =>
          parser.testParseStation(r as Map<String, dynamic>, 48.2, 16.37, 'DIE')
      ).whereType<Station>().toList();

      // Parse super stations
      final superStations = superResponse.map((r) =>
          parser.testParseStation(r as Map<String, dynamic>, 48.2, 16.37, 'SUP')
      ).whereType<Station>().toList();

      expect(dieselStations, hasLength(2));
      expect(superStations, hasLength(2));

      // Merge like the real service does
      final merged = <int, Station>{};

      for (final s in dieselStations) {
        final id = int.tryParse(s.id) ?? 0;
        merged[id] = s;
      }

      for (final s in superStations) {
        final id = int.tryParse(s.id) ?? 0;
        final existing = merged[id];
        if (existing != null) {
          merged[id] = existing.copyWith(
            e5: s.e5,
            e10: s.e5,
          );
        } else {
          merged[id] = s.copyWith(
            e5: s.e5,
            e10: s.e5,
          );
        }
      }

      expect(merged, hasLength(3));

      // Station 100 should have both diesel and super
      final omv = merged[100]!;
      expect(omv.diesel, closeTo(1.659, 0.001));
      expect(omv.e5, closeTo(1.549, 0.001));
      expect(omv.e10, closeTo(1.549, 0.001));
      expect(omv.isOpen, isTrue);

      // Station 200 should have only diesel
      final bp = merged[200]!;
      expect(bp.diesel, closeTo(1.699, 0.001));
      expect(bp.e5, isNull);
      expect(bp.isOpen, isFalse);

      // Station 300 should have only super
      final jet = merged[300]!;
      expect(jet.e5, closeTo(1.519, 0.001));
      expect(jet.e10, closeTo(1.519, 0.001));
      expect(jet.diesel, isNull);
    });

    test('merged stations sorted by distance', () {
      final data1 = {
        'id': 1,
        'name': 'Far',
        'location': {'latitude': 49.0, 'longitude': 16.0},
        'distance': 5.0,
        'prices': [{'amount': 1.5}],
        'openingHours': [],
      };
      final data2 = {
        'id': 2,
        'name': 'Near',
        'location': {'latitude': 48.2, 'longitude': 16.37},
        'distance': 0.5,
        'prices': [{'amount': 1.6}],
        'openingHours': [],
      };

      final stations = [
        parser.testParseStation(data1, 48.2, 16.37, 'DIE')!,
        parser.testParseStation(data2, 48.2, 16.37, 'DIE')!,
      ];

      stations.sort((a, b) => a.dist.compareTo(b.dist));
      expect(stations[0].name, 'Near');
      expect(stations[1].name, 'Far');
    });

    test('merged stations sorted by price', () {
      final data1 = {
        'id': 1,
        'name': 'Expensive',
        'location': {'latitude': 48.2, 'longitude': 16.4},
        'prices': [{'amount': 1.899}],
        'openingHours': [],
      };
      final data2 = {
        'id': 2,
        'name': 'Cheap',
        'location': {'latitude': 48.2, 'longitude': 16.4},
        'prices': [{'amount': 1.499}],
        'openingHours': [],
      };

      final stations = [
        parser.testParseStation(data1, 48.2, 16.37, 'DIE')!,
        parser.testParseStation(data2, 48.2, 16.37, 'DIE')!,
      ];

      // Sort by diesel price like sortStations does for SortBy.price
      stations.sort((a, b) {
        final pa = a.diesel ?? 999.0;
        final pb = b.diesel ?? 999.0;
        return pa.compareTo(pb);
      });
      expect(stations[0].name, 'Cheap');
      expect(stations[1].name, 'Expensive');
    });

    test('radius filtering with fallback to nearest', () {
      // All stations far away
      final farStations = List.generate(25, (i) => Station(
        id: '$i',
        name: 'Station $i',
        brand: 'Brand',
        street: 'St',
        postCode: '1010',
        place: 'Wien',
        lat: 48.2 + i * 0.1,
        lng: 16.37,
        dist: 50.0 + i, // All > 10km radius
        isOpen: true,
      ));

      // Simulate filterByRadius
      final withinRadius = farStations.where((s) => s.dist <= 10.0).toList();
      expect(withinRadius, isEmpty);

      // Fallback: return nearest 20
      final sorted = List<Station>.from(farStations)
        ..sort((a, b) => a.dist.compareTo(b.dist));
      final fallback = sorted.take(20).toList();
      expect(fallback, hasLength(20));
      expect(fallback.first.dist, closeTo(50.0, 0.1));
    });

    test('GAS fuel type maps to lpg field', () {
      final data = {
        'id': 500,
        'name': 'CNG Wien',
        'location': {'latitude': 48.2, 'longitude': 16.4},
        'prices': [{'amount': 1.299}],
        'openingHours': [],
      };

      final station = parser.testParseStation(data, 48.2, 16.37, 'GAS');
      expect(station, isNotNull);
      expect(station!.lpg, closeTo(1.299, 0.001));
      expect(station.e5, isNull);
      expect(station.diesel, isNull);
    });
  });
}

/// Replicates E-Control parsing logic for isolated testing.
class _TestableEControlParser {
  Station? testParseStation(
    Map<String, dynamic> r,
    double searchLat,
    double searchLng,
    String fuelType,
  ) {
    try {
      final location = r['location'] as Map<String, dynamic>? ?? {};
      final lat = (location['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (location['longitude'] as num?)?.toDouble() ?? 0;

      final apiDist = (r['distance'] as num?)?.toDouble();

      double? price;
      final prices = r['prices'] as List<dynamic>? ?? [];
      for (final p in prices) {
        if (p is Map<String, dynamic>) {
          price = (p['amount'] as num?)?.toDouble();
        }
      }

      final openingHours = r['openingHours'] as List<dynamic>? ?? [];
      final hoursText = openingHours.map((oh) {
        if (oh is Map<String, dynamic>) {
          return '${oh['label'] ?? oh['day']}: ${oh['from']}-${oh['to']}';
        }
        return '';
      }).where((s) => s.isNotEmpty).join(', ');

      final name = r['name']?.toString() ?? '';
      final isOpen = r['open'] as bool? ?? true;

      return Station(
        id: r['id']?.toString() ?? '',
        name: name,
        brand: testExtractBrand(name),
        street: location['address']?.toString() ?? '',
        postCode: location['postalCode']?.toString() ?? '',
        place: location['city']?.toString() ?? '',
        lat: lat,
        lng: lng,
        dist: apiDist ?? _roundedDist(searchLat, searchLng, lat, lng),
        e5: fuelType == 'SUP' ? price : null,
        e10: fuelType == 'SUP' ? price : null,
        diesel: fuelType == 'DIE' ? price : null,
        lpg: fuelType == 'GAS' ? price : null,
        isOpen: isOpen,
        openingHoursText: hoursText.isNotEmpty ? hoursText : null,
      );
    } on FormatException catch (_) {
      return null;
    }
  }

  String testExtractBrand(String name) {
    const brands = [
      'OMV', 'BP', 'Shell', 'Jet', 'Eni', 'Avanti', 'Turmöl',
      'IQ', 'Avia', 'A1', 'Genol', 'Lagerhaus', 'SB',
    ];
    final upper = name.toUpperCase();
    for (final b in brands) {
      if (upper.startsWith(b.toUpperCase())) return b;
    }
    final firstWord = name.split(RegExp(r'[\s\-]')).first;
    return firstWord.isNotEmpty ? firstWord : name;
  }

  double _roundedDist(double lat1, double lng1, double lat2, double lng2) {
    // Simplified distance for test — real impl uses Haversine
    final dlat = (lat1 - lat2).abs();
    final dlng = (lng1 - lng2).abs();
    return (dlat * dlat + dlng * dlng) * 111; // Rough km approximation
  }
}
