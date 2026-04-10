import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/impl/portugal_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/utils/geo_utils.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

/// Tests for [PortugalStationService] and its DGEG JSON parsing logic.
///
/// The service instantiates Dio internally via `DioFactory.create()`, so we
/// can't inject a mock HTTP client directly. Instead, we mirror the parsing
/// logic in a testable helper (`_TestablePortugalParser`) that reproduces the
/// exact transformation from DGEG JSON payload -> [Station], and cover the
/// public surface (interface compliance, unsupported endpoints) on the real
/// service.
void main() {
  late PortugalStationService service;

  setUp(() {
    service = PortugalStationService();
  });

  group('PortugalStationService (public surface)', () {
    test('implements StationService interface', () {
      expect(service, isA<StationService>());
    });

    test('getStationDetail throws ApiException', () {
      expect(
        () => service.getStationDetail('pt-123'),
        throwsA(isA<Exception>()),
      );
    });

    test('getPrices returns empty map with correct source', () async {
      final result = await service.getPrices(['pt-1', 'pt-2']);
      expect(result.data, isEmpty);
      expect(result.source, ServiceSource.portugalApi);
      expect(result.isStale, isFalse);
    });

    test('getPrices returns empty map for empty id list', () async {
      final result = await service.getPrices([]);
      expect(result.data, isEmpty);
      expect(result.source, ServiceSource.portugalApi);
    });
  });

  group('DGEG response parsing', () {
    late _TestablePortugalParser parser;

    setUp(() {
      parser = _TestablePortugalParser();
    });

    test('parses a well-formed DGEG response with all fuel types', () {
      final data = {
        'resultado': [
          {
            'Id': 12345,
            'CodPosto': 'P12345',
            'Nome': 'GALP Lisboa Centro',
            'Marca': 'GALP',
            'Morada': 'Avenida da Liberdade 100',
            'CodPostal': '1250-146',
            'Localidade': 'Lisboa',
            'Latitude': '38.7223',
            'Longitude': '-9.1393',
            'Combustiveis': [
              {'DescritivoCombustivel': 'Gasolina 95', 'Preco': '1.789'},
              {'DescritivoCombustivel': 'Gasolina 98', 'Preco': '1.899'},
              {'DescritivoCombustivel': 'Gasóleo', 'Preco': '1.659'},
              {'DescritivoCombustivel': 'GPL Auto', 'Preco': '0.899'},
            ],
          },
        ],
      };

      final stations = parser.parseResponse(data, lat: 38.7223, lng: -9.1393, radiusKm: 5);

      expect(stations, hasLength(1));
      final s = stations.first;
      expect(s.id, 'pt-12345');
      expect(s.name, 'GALP Lisboa Centro');
      expect(s.brand, 'GALP');
      expect(s.street, 'Avenida da Liberdade 100');
      expect(s.postCode, '1250-146');
      expect(s.place, 'Lisboa');
      expect(s.lat, closeTo(38.7223, 0.0001));
      expect(s.lng, closeTo(-9.1393, 0.0001));
      expect(s.e5, 1.789);
      expect(s.e10, 1.789); // Portugal uses 95 as e10 as well
      expect(s.e98, 1.899);
      expect(s.diesel, 1.659);
      expect(s.lpg, 0.899);
      expect(s.isOpen, isTrue);
    });

    test('skips stations outside the search radius', () {
      final data = {
        'resultado': [
          {
            'Id': 1,
            'Nome': 'Near',
            'Marca': 'BP',
            'Morada': '',
            'CodPostal': '',
            'Localidade': '',
            'Latitude': '38.7223',
            'Longitude': '-9.1393',
            'Combustiveis': <dynamic>[],
          },
          {
            'Id': 2,
            'Nome': 'Far (Porto)',
            'Marca': 'BP',
            'Morada': '',
            'CodPostal': '',
            'Localidade': '',
            'Latitude': '41.1579',
            'Longitude': '-8.6291',
            'Combustiveis': <dynamic>[],
          },
        ],
      };

      final stations = parser.parseResponse(data, lat: 38.7223, lng: -9.1393, radiusKm: 50);

      expect(stations, hasLength(1));
      expect(stations.first.name, 'Near');
    });

    test('skips stations with unparseable coordinates', () {
      final data = {
        'resultado': [
          {
            'Id': 1,
            'Nome': 'Bad coords',
            'Marca': 'REPSOL',
            'Morada': '',
            'CodPostal': '',
            'Localidade': '',
            'Latitude': 'not-a-number',
            'Longitude': 'nope',
            'Combustiveis': <dynamic>[],
          },
          {
            'Id': 2,
            'Nome': 'Good coords',
            'Marca': 'REPSOL',
            'Morada': '',
            'CodPostal': '',
            'Localidade': '',
            'Latitude': '38.7223',
            'Longitude': '-9.1393',
            'Combustiveis': <dynamic>[],
          },
        ],
      };

      final stations = parser.parseResponse(data, lat: 38.7223, lng: -9.1393, radiusKm: 5);

      expect(stations, hasLength(1));
      expect(stations.first.name, 'Good coords');
    });

    test('handles missing Combustiveis array gracefully', () {
      final data = {
        'resultado': [
          {
            'Id': 99,
            'Nome': 'No prices',
            'Marca': 'BP',
            'Morada': 'Rua X',
            'CodPostal': '1000-001',
            'Localidade': 'Lisboa',
            'Latitude': '38.7223',
            'Longitude': '-9.1393',
          },
        ],
      };

      final stations = parser.parseResponse(data, lat: 38.7223, lng: -9.1393, radiusKm: 10);

      expect(stations, hasLength(1));
      final s = stations.first;
      expect(s.e5, isNull);
      expect(s.e10, isNull);
      expect(s.e98, isNull);
      expect(s.diesel, isNull);
      expect(s.lpg, isNull);
    });

    test('falls back through Id -> CodPosto -> index for station id', () {
      final data = {
        'resultado': [
          {
            // No Id, no CodPosto — should fall back to index (0)
            'Nome': 'Unnamed',
            'Marca': '',
            'Morada': '',
            'CodPostal': '',
            'Localidade': '',
            'Latitude': '38.7223',
            'Longitude': '-9.1393',
            'Combustiveis': <dynamic>[],
          },
          {
            'CodPosto': 'POST-42',
            'Nome': 'With CodPosto',
            'Marca': '',
            'Morada': '',
            'CodPostal': '',
            'Localidade': '',
            'Latitude': '38.7223',
            'Longitude': '-9.1393',
            'Combustiveis': <dynamic>[],
          },
        ],
      };

      final stations = parser.parseResponse(data, lat: 38.7223, lng: -9.1393, radiusKm: 10);

      expect(stations, hasLength(2));
      // Stations are sorted by distance; both share coords, so order is insertion
      final ids = stations.map((s) => s.id).toSet();
      expect(ids, contains('pt-0'));
      expect(ids, contains('pt-POST-42'));
    });

    test('returns empty list for empty resultado', () {
      final stations = parser.parseResponse(
        {'resultado': <dynamic>[]},
        lat: 38.7223,
        lng: -9.1393,
        radiusKm: 10,
      );
      expect(stations, isEmpty);
    });

    test('returns empty list when resultado key is missing', () {
      final stations = parser.parseResponse(
        <String, dynamic>{},
        lat: 38.7223,
        lng: -9.1393,
        radiusKm: 10,
      );
      expect(stations, isEmpty);
    });

    test('caps result list at 50 stations', () {
      final resultado = <Map<String, dynamic>>[];
      for (var i = 0; i < 120; i++) {
        resultado.add({
          'Id': i,
          'Nome': 'Station $i',
          'Marca': 'BP',
          'Morada': '',
          'CodPostal': '',
          'Localidade': '',
          // Tiny offset to keep all within radius
          'Latitude': (38.7223 + i * 0.0001).toString(),
          'Longitude': '-9.1393',
          'Combustiveis': <dynamic>[],
        });
      }

      final stations = parser.parseResponse(
        {'resultado': resultado},
        lat: 38.7223,
        lng: -9.1393,
        radiusKm: 50,
      );

      expect(stations.length, lessThanOrEqualTo(50));
    });

    test('sorts stations by distance ascending', () {
      final data = {
        'resultado': [
          {
            'Id': 1,
            'Nome': 'Far',
            'Marca': '',
            'Morada': '',
            'CodPostal': '',
            'Localidade': '',
            'Latitude': '38.7500',
            'Longitude': '-9.1393',
            'Combustiveis': <dynamic>[],
          },
          {
            'Id': 2,
            'Nome': 'Near',
            'Marca': '',
            'Morada': '',
            'CodPostal': '',
            'Localidade': '',
            'Latitude': '38.7230',
            'Longitude': '-9.1393',
            'Combustiveis': <dynamic>[],
          },
        ],
      };

      final stations = parser.parseResponse(data, lat: 38.7223, lng: -9.1393, radiusKm: 50);

      expect(stations, hasLength(2));
      expect(stations.first.name, 'Near');
      expect(stations.last.name, 'Far');
    });

    test('matches Diesel variant spelled "Diesel" as well as "Gasóleo"', () {
      final data = {
        'resultado': [
          {
            'Id': 1,
            'Nome': 'Diesel spelling',
            'Marca': '',
            'Morada': '',
            'CodPostal': '',
            'Localidade': '',
            'Latitude': '38.7223',
            'Longitude': '-9.1393',
            'Combustiveis': [
              {'DescritivoCombustivel': 'Diesel Premium', 'Preco': '1.712'},
            ],
          },
        ],
      };

      final stations = parser.parseResponse(data, lat: 38.7223, lng: -9.1393, radiusKm: 5);

      expect(stations.first.diesel, 1.712);
    });
  });
}

/// Mirror of [PortugalStationService]'s DGEG parsing logic so we can unit
/// test the JSON -> Station mapping without HTTP.
class _TestablePortugalParser {
  List<Station> parseResponse(
    Map<String, dynamic> data, {
    required double lat,
    required double lng,
    required double radiusKm,
  }) {
    final resultado = data['resultado'] as List<dynamic>? ?? [];
    final stations = <Station>[];

    for (final item in resultado) {
      try {
        final itemLat = double.tryParse(item['Latitude']?.toString() ?? '');
        final itemLng = double.tryParse(item['Longitude']?.toString() ?? '');
        if (itemLat == null || itemLng == null) continue;

        final dist = distanceKm(lat, lng, itemLat, itemLng);
        if (dist > radiusKm) continue;

        final combustiveis = item['Combustiveis'] as List<dynamic>? ?? [];
        double? gasolina95, gasolina98, gasoleo, gpl;
        for (final c in combustiveis) {
          final tipo = c['DescritivoCombustivel']?.toString() ?? '';
          final preco = double.tryParse(c['Preco']?.toString() ?? '');
          if (tipo.contains('95')) gasolina95 = preco;
          if (tipo.contains('98')) gasolina98 = preco;
          if (tipo.contains('asóleo') || tipo.contains('Diesel')) gasoleo = preco;
          if (tipo.contains('GPL')) gpl = preco;
        }

        stations.add(Station(
          id: 'pt-${item['Id'] ?? item['CodPosto'] ?? stations.length}',
          name: item['Nome']?.toString() ?? '',
          brand: item['Marca']?.toString() ?? '',
          street: item['Morada']?.toString() ?? '',
          postCode: item['CodPostal']?.toString() ?? '',
          place: item['Localidade']?.toString() ?? '',
          lat: itemLat,
          lng: itemLng,
          dist: dist,
          e5: gasolina95,
          e10: gasolina95,
          e98: gasolina98,
          diesel: gasoleo,
          lpg: gpl,
          isOpen: true,
        ));
      } catch (_) {
        continue;
      }
    }

    stations.sort((a, b) => a.dist.compareTo(b.dist));
    return stations.take(50).toList();
  }
}
