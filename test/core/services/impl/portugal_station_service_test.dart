import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/impl/portugal_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';

/// Fake HTTP adapter returning a canned DGEG payload.
class _FakeDgegAdapter implements HttpClientAdapter {
  _FakeDgegAdapter({required this.reply, this.statusCode = 200});

  final Object reply;
  final int statusCode;
  final List<RequestOptions> calls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    final body = reply is String ? reply as String : jsonEncode(reply);
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(_FakeDgegAdapter adapter) {
  final dio = Dio();
  dio.httpClientAdapter = adapter;
  return dio;
}

PortugalStationService _serviceWith(_FakeDgegAdapter adapter) {
  return PortugalStationService(
    dio: _dioWith(adapter),
    baseUrl: 'https://fake.dgeg/api/PrecoComb',
  );
}

/// Shorthand for a DGEG row.
Map<String, dynamic> _row({
  required int id,
  required String name,
  required double lat,
  required double lng,
  required String fuel,
  required String preco,
  String brand = 'GALP',
  String morada = 'Avenida da Liberdade 100',
  String codPostal = '1250-146',
  String localidade = 'Lisboa',
}) {
  return {
    'Id': id,
    'Nome': name,
    'Marca': brand,
    'Morada': morada,
    'CodPostal': codPostal,
    'Localidade': localidade,
    'Municipio': 'Lisboa',
    'Distrito': 'Lisboa',
    'Latitude': lat,
    'Longitude': lng,
    'Combustivel': fuel,
    'Preco': preco,
    'DataAtualizacao': '2026-04-14 08:00',
    'Quantidade': 6051,
  };
}

const _lisboaParams = SearchParams(
  lat: 38.7223,
  lng: -9.1393,
  radiusKm: 10,
);

void main() {
  group('PortugalStationService (public surface)', () {
    test('implements StationService interface', () {
      expect(PortugalStationService(), isA<StationService>());
    });

    test('getStationDetail throws ApiException', () {
      expect(
        () => PortugalStationService().getStationDetail('pt-123'),
        throwsA(isA<Exception>()),
      );
    });

    test('getPrices returns empty map with correct source', () async {
      final result = await PortugalStationService().getPrices(['pt-1']);
      expect(result.data, isEmpty);
      expect(result.source, ServiceSource.portugalApi);
    });

    test('defaultFuelTypeIds covers 95 simples + gasoleo simples', () {
      expect(PortugalStationService.defaultFuelTypeIds, '3201,2101');
    });
  });

  group('searchStations (PesquisarPostos — #503 fix)', () {
    test('hits PesquisarPostos with the default fuel ids', () async {
      final adapter = _FakeDgegAdapter(reply: {
        'status': true,
        'mensagem': 'sucesso',
        'resultado': [
          _row(
            id: 1,
            name: 'GALP Lisboa',
            lat: 38.7223,
            lng: -9.1393,
            fuel: 'Gasolina simples 95',
            preco: '1,719 €',
          ),
        ],
      });
      final service = _serviceWith(adapter);

      await service.searchStations(_lisboaParams);

      expect(adapter.calls, hasLength(1));
      final call = adapter.calls.single;
      expect(call.uri.path, endsWith('/PesquisarPostos'));
      expect(call.uri.queryParameters['idsTiposComb'], '3201,2101');
      expect(call.uri.queryParameters['pagina'], '1');
    });

    test('merges fuel prices across multiple rows for the same station',
        () async {
      final adapter = _FakeDgegAdapter(reply: {
        'status': true,
        'mensagem': 'sucesso',
        'resultado': [
          _row(
            id: 42,
            name: 'GALP Lisboa',
            lat: 38.7223,
            lng: -9.1393,
            fuel: 'Gasolina simples 95',
            preco: '1,719 €',
          ),
          _row(
            id: 42,
            name: 'GALP Lisboa',
            lat: 38.7223,
            lng: -9.1393,
            fuel: 'Gasóleo simples',
            preco: '1,599 €',
          ),
        ],
      });
      final service = _serviceWith(adapter);

      final result = await service.searchStations(_lisboaParams);
      expect(result.data, hasLength(1));
      final s = result.data.first;
      expect(s.id, 'pt-42');
      expect(s.e5, closeTo(1.719, 0.0001));
      expect(s.e10, closeTo(1.719, 0.0001),
          reason: 'PT 95 simples is mirrored into e10 for the UI');
      expect(s.diesel, closeTo(1.599, 0.0001));
    });

    test('parses comma-decimal Portuguese prices (1,719 € -> 1.719)',
        () async {
      final adapter = _FakeDgegAdapter(reply: {
        'resultado': [
          _row(
            id: 1,
            name: 'X',
            lat: 38.7223,
            lng: -9.1393,
            fuel: 'Gasolina simples 95',
            preco: '1,899 €',
          ),
        ],
      });
      final result = await _serviceWith(adapter).searchStations(_lisboaParams);
      expect(result.data.first.e5, closeTo(1.899, 0.0001));
    });

    test('filters stations outside the search radius', () async {
      final adapter = _FakeDgegAdapter(reply: {
        'resultado': [
          _row(
            id: 1,
            name: 'Near',
            lat: 38.7223,
            lng: -9.1393,
            fuel: 'Gasolina simples 95',
            preco: '1,7 €',
          ),
          _row(
            id: 2,
            name: 'Porto',
            lat: 41.1579, // ~280km from Lisbon
            lng: -8.6291,
            fuel: 'Gasolina simples 95',
            preco: '1,8 €',
          ),
        ],
      });
      final result = await _serviceWith(adapter).searchStations(_lisboaParams);
      expect(result.data, hasLength(1));
      expect(result.data.first.name, 'Near');
    });

    test('returns an empty list (not an error) when the API reply '
        'contains no stations inside the radius', () async {
      final adapter = _FakeDgegAdapter(reply: {
        'resultado': [
          _row(
            id: 1,
            name: 'Far away',
            lat: 41.1579,
            lng: -8.6291,
            fuel: 'Gasolina simples 95',
            preco: '1,8 €',
          ),
        ],
      });
      final result = await _serviceWith(adapter).searchStations(_lisboaParams);
      expect(result.data, isEmpty);
      expect(result.source, ServiceSource.portugalApi);
    });

    test('throws ApiException on HTTP error (never silent)', () async {
      final adapter = _FakeDgegAdapter(
        reply: '<html>500</html>',
        statusCode: 500,
      );
      expect(
        () => _serviceWith(adapter).searchStations(_lisboaParams),
        throwsA(isA<ApiException>()),
      );
    });

    test('throws when the response is not a JSON object', () async {
      final adapter = _FakeDgegAdapter(reply: '[]');
      expect(
        () => _serviceWith(adapter).searchStations(_lisboaParams),
        throwsA(isA<ApiException>()),
      );
    });

    test('throws when resultado is missing or not a list', () async {
      final adapter = _FakeDgegAdapter(reply: {
        'status': true,
        'mensagem': 'sucesso',
        // resultado absent
      });
      expect(
        () => _serviceWith(adapter).searchStations(_lisboaParams),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('parseAndFilter (exposed parser)', () {
    test('skips rows missing Latitude / Longitude', () {
      final stations = PortugalStationService.parseAndFilter(
        [
          {
            'Id': 1,
            'Nome': 'No coords',
            'Combustivel': 'Gasolina simples 95',
            'Preco': '1,7 €',
          },
          {
            'Id': 2,
            'Nome': 'Good',
            'Latitude': 38.7223,
            'Longitude': -9.1393,
            'Combustivel': 'Gasolina simples 95',
            'Preco': '1,7 €',
          },
        ],
        lat: 38.7223,
        lng: -9.1393,
        radiusKm: 5,
      );
      expect(stations, hasLength(1));
      expect(stations.first.name, 'Good');
    });

    test('sorts by distance ascending', () {
      final stations = PortugalStationService.parseAndFilter(
        [
          {
            'Id': 1,
            'Nome': 'Far',
            'Latitude': 38.7500,
            'Longitude': -9.1393,
            'Combustivel': 'Gasolina simples 95',
            'Preco': '1,7 €',
          },
          {
            'Id': 2,
            'Nome': 'Near',
            'Latitude': 38.7230,
            'Longitude': -9.1393,
            'Combustivel': 'Gasolina simples 95',
            'Preco': '1,7 €',
          },
        ],
        lat: 38.7223,
        lng: -9.1393,
        radiusKm: 50,
      );
      expect(stations.first.name, 'Near');
      expect(stations.last.name, 'Far');
    });

    test('caps results at 50', () {
      final rows = List.generate(
        120,
        (i) => {
          'Id': i,
          'Nome': 'S$i',
          'Latitude': 38.7223 + i * 0.0001,
          'Longitude': -9.1393,
          'Combustivel': 'Gasolina simples 95',
          'Preco': '1,7 €',
        },
      );
      final stations = PortugalStationService.parseAndFilter(
        rows,
        lat: 38.7223,
        lng: -9.1393,
        radiusKm: 500,
      );
      expect(stations, hasLength(50));
    });

    test('fuel label dispatch: 98 before 95, gasóleo variants, GPL', () {
      final stations = PortugalStationService.parseAndFilter(
        [
          {
            'Id': 1,
            'Nome': 'All fuels',
            'Latitude': 38.7223,
            'Longitude': -9.1393,
            'Combustivel': 'Gasolina simples 98',
            'Preco': '1,899 €',
          },
          {
            'Id': 1,
            'Latitude': 38.7223,
            'Longitude': -9.1393,
            'Combustivel': 'Gasolina simples 95',
            'Preco': '1,799 €',
          },
          {
            'Id': 1,
            'Latitude': 38.7223,
            'Longitude': -9.1393,
            'Combustivel': 'Gasóleo simples',
            'Preco': '1,599 €',
          },
          {
            'Id': 1,
            'Latitude': 38.7223,
            'Longitude': -9.1393,
            'Combustivel': 'GPL Auto',
            'Preco': '0,899 €',
          },
        ],
        lat: 38.7223,
        lng: -9.1393,
        radiusKm: 5,
      );
      expect(stations, hasLength(1));
      final s = stations.first;
      expect(s.e98, closeTo(1.899, 0.0001));
      expect(s.e5, closeTo(1.799, 0.0001));
      expect(s.diesel, closeTo(1.599, 0.0001));
      expect(s.lpg, closeTo(0.899, 0.0001));
    });
  });

  group('parsePriceForTest (comma-decimal)', () {
    test('1,719 € -> 1.719', () {
      expect(
        PortugalStationService.parsePriceForTest('1,719 €'),
        closeTo(1.719, 0.0001),
      );
    });

    test('1.719 (already dot) -> 1.719', () {
      expect(
        PortugalStationService.parsePriceForTest('1.719'),
        closeTo(1.719, 0.0001),
      );
    });

    test('empty / whitespace / null -> null', () {
      expect(PortugalStationService.parsePriceForTest(null), isNull);
      expect(PortugalStationService.parsePriceForTest(''), isNull);
      expect(PortugalStationService.parsePriceForTest('   '), isNull);
    });

    test('non-numeric -> null', () {
      expect(
        PortugalStationService.parsePriceForTest('n.d.'),
        isNull,
      );
    });

    test('strips embedded whitespace and euro symbol', () {
      expect(
        PortugalStationService.parsePriceForTest(' 1 , 5 9 9 € '),
        closeTo(1.599, 0.0001),
      );
    });
  });
}
