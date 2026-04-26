@Tags(['network'])
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration tests that verify each country's fuel price API is reachable
/// and returns valid data. Probes Tankerkoenig (DE), Prix-Carburants (FR),
/// E-Control (AT), MITECO (ES), MIMIT (IT), OK + Shell (DK), Argentina
/// Energía, and Nominatim — real endpoints, hence the `network` tag.
///
/// Rerun after any change under `lib/core/services/impl/*_station_service.dart`
/// or before tagging a release. CI excludes the tag (intermittent upstream
/// timeouts cannot block PRs); see `docs/guides/NETWORK_TESTS.md`.
///
///   flutter test test/core/services/api_connectivity_test.dart --tags=network
void main() {
  late Dio dio;

  setUp(() {
    dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'User-Agent': 'de.tankstellen.app/1.0.0'},
    ));
  });

  tearDown(() => dio.close());

  group('API Connectivity', () {
    test('Germany — Tankerkoenig API is reachable', () async {
      // The list endpoint requires an API key, but the status endpoint is open
      // We test that the server responds (even with an auth error = server is up)
      final response = await dio.get(
        'https://creativecommons.tankerkoenig.de/json/list.php',
        queryParameters: {
          'lat': 52.52,
          'lng': 13.405,
          'rad': 5,
          'type': 'all',
          'apikey': 'test',
        },
        options: Options(validateStatus: (_) => true),
      );

      // Server responds (200 with error message about invalid key, or 200 with data)
      expect(response.statusCode, 200);
      expect(response.data, isA<Map>());
      // The API returns ok:false for invalid keys, which proves the server is reachable
      expect(response.data.containsKey('ok'), isTrue);
    });

    test('France — Prix-Carburants API is reachable and returns stations', () async {
      final response = await dio.get(
        'https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets'
        '/prix-des-carburants-en-france-flux-instantane-v2/records',
        queryParameters: {
          'limit': 1,
          'where': 'cp="75001"',
        },
      );

      expect(response.statusCode, 200);
      expect(response.data, isA<Map>());
      expect(response.data['results'], isA<List>());

      // The Paris 75001 query intermittently returns 0 rows as the open-data
      // endpoint rebuilds its index. Reachability + schema is the goal — only
      // validate field shape when the response happens to be non-empty.
      final results = response.data['results'] as List;
      if (results.isNotEmpty) {
        final station = results.first;
        expect(station.containsKey('id'), isTrue);
        expect(station.containsKey('adresse'), isTrue);
        expect(station.containsKey('ville'), isTrue);
        expect(station.containsKey('cp'), isTrue);
      }
    });

    test('Austria — E-Control API is reachable and returns stations', () async {
      final response = await dio.get(
        'https://api.e-control.at/sprit/1.0/search/gas-stations/by-address',
        queryParameters: {
          'latitude': 48.2082,
          'longitude': 16.3738,
          'fuelType': 'DIE',
          'includeClosed': 'true',
        },
      );

      expect(response.statusCode, 200);
      expect(response.data, isA<List>());
      expect((response.data as List).length, greaterThan(0));

      // Verify key fields exist
      final station = (response.data as List).first;
      expect(station.containsKey('id'), isTrue);
      expect(station.containsKey('name'), isTrue);
      expect(station.containsKey('location'), isTrue);
      expect(station['location'].containsKey('latitude'), isTrue);
      expect(station['location'].containsKey('longitude'), isTrue);
      expect(station.containsKey('prices'), isTrue);
      expect(station.containsKey('open'), isTrue);
      expect(station.containsKey('distance'), isTrue);
    });

    test('Spain — MITECO API is reachable and returns stations', () async {
      // Fetch province list first
      final provincesResponse = await dio.get(
        'https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes'
        '/PreciosCarburantes/Listados/Provincias/',
      );

      expect(provincesResponse.statusCode, 200);
      expect(provincesResponse.data, isA<List>());
      expect((provincesResponse.data as List).length, greaterThan(40));

      // Fetch stations for Madrid (province 28)
      final stationsResponse = await dio.get(
        'https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes'
        '/PreciosCarburantes/EstacionesTerrestres/FiltroProvincia/28',
      );

      expect(stationsResponse.statusCode, 200);
      expect(stationsResponse.data, isA<Map>());
      expect(stationsResponse.data['ResultadoConsulta'], 'OK');
      expect(stationsResponse.data['ListaEESSPrecio'], isA<List>());
      expect(
        (stationsResponse.data['ListaEESSPrecio'] as List).length,
        greaterThan(100),
      );

      // Verify key fields exist (Spanish field names with accents)
      final station = (stationsResponse.data['ListaEESSPrecio'] as List).first;
      expect(station.containsKey('IDEESS'), isTrue);
      expect(station.containsKey('Rótulo'), isTrue);
      expect(station.containsKey('Dirección'), isTrue);
      expect(station.containsKey('Localidad'), isTrue);
      expect(station.containsKey('C.P.'), isTrue);
      expect(station.containsKey('Latitud'), isTrue);
      expect(station.containsKey('Longitud (WGS84)'), isTrue);
      expect(station.containsKey('Precio Gasoleo A'), isTrue);
      expect(station.containsKey('Precio Gasolina 95 E5'), isTrue);
    });

    test('Italy — MIMIT station CSV is reachable and parseable', () async {
      final csvDio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'User-Agent': 'de.tankstellen.app/1.0.0'},
        responseType: ResponseType.plain,
      ));

      // Only download first 10KB to verify format (full file is ~5MB)
      final response = await csvDio.get<String>(
        'https://www.mimit.gov.it/images/exportCSV/anagrafica_impianti_attivi.csv',
        options: Options(headers: {'Range': 'bytes=0-10240'}),
      );

      expect(response.statusCode, anyOf(200, 206));
      final csv = response.data!;
      expect(csv, contains('idImpianto'));
      expect(csv, contains('Bandiera'));
      expect(csv, contains('Latitudine'));
      expect(csv, contains('Longitudine'));

      // Parse first data line
      final lines = csv.split('\n');
      expect(lines.length, greaterThan(2));
      final parts = lines[2].split('|');
      expect(parts.length, greaterThanOrEqualTo(10));
      // Verify lat/lng are parseable
      final lat = double.tryParse(parts[8].trim());
      final lng = double.tryParse(parts[9].trim());
      expect(lat, isNotNull);
      expect(lng, isNotNull);
    });

    test('Italy — MIMIT price CSV is reachable and parseable', () async {
      final csvDio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'User-Agent': 'de.tankstellen.app/1.0.0'},
        responseType: ResponseType.plain,
      ));

      final response = await csvDio.get<String>(
        'https://www.mimit.gov.it/images/exportCSV/prezzo_alle_8.csv',
        options: Options(headers: {'Range': 'bytes=0-4096'}),
      );

      expect(response.statusCode, anyOf(200, 206));
      final csv = response.data!;
      expect(csv, contains('idImpianto'));
      expect(csv, contains('descCarburante'));
      expect(csv, contains('prezzo'));

      // Parse first data line
      final lines = csv.split('\n');
      expect(lines.length, greaterThan(2));
      final parts = lines[2].split('|');
      expect(parts.length, greaterThanOrEqualTo(5));
      // Verify price is parseable
      final price = double.tryParse(parts[2].trim());
      expect(price, isNotNull);
      expect(price, greaterThan(0));
    });

    test('Denmark — OK API is reachable and returns stations', () async {
      final response = await dio.get(
        'https://mobility-prices.ok.dk/api/v1/fuel-prices',
      );

      expect(response.statusCode, 200);
      expect(response.data, isA<Map>());
      expect(response.data['items'], isA<List>());
      expect((response.data['items'] as List).length, greaterThan(0));

      final station = (response.data['items'] as List).first;
      expect(station.containsKey('coordinates'), isTrue);
      expect(station['coordinates'].containsKey('latitude'), isTrue);
      expect(station.containsKey('prices'), isTrue);
    });

    test('Denmark — Shell API is reachable and returns stations', () async {
      final response = await dio.get(
        'https://shellpumpepriser.geoapp.me/v1/prices',
      );

      expect(response.statusCode, 200);
      expect(response.data, isA<List>());
      expect((response.data as List).length, greaterThan(0));

      final station = (response.data as List).first;
      expect(station.containsKey('coordinates'), isTrue);
      expect(station.containsKey('prices'), isTrue);
      expect(station.containsKey('brand'), isTrue);
    });

    test('Argentina — Energía CSV is reachable and has coordinates', () async {
      final csvDio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'User-Agent': 'de.tankstellen.app/1.0.0'},
        responseType: ResponseType.plain,
      ));

      final response = await csvDio.get<String>(
        'http://datos.energia.gob.ar/dataset/'
        '1c181390-5045-475e-94dc-410429be4b17/resource/'
        '80ac25de-a44a-4445-9215-090cf55cfda5/download/'
        'precios-en-surtidor-resolucin-3142016.csv',
        options: Options(headers: {'Range': 'bytes=0-4096'}),
      );

      expect(response.statusCode, anyOf(200, 206));
      final csv = response.data!;
      // Verify header contains expected columns
      expect(csv.toLowerCase(), contains('producto'));
      expect(csv.toLowerCase(), contains('precio'));
      expect(csv.toLowerCase(), contains('latitud'));
      expect(csv.toLowerCase(), contains('longitud'));
    }, timeout: const Timeout(Duration(seconds: 90)));
  });

  group('City Search (Nominatim) for all countries', () {
    test('Nominatim finds cities in all supported countries', () async {
      final testCases = {
        'DE': 'Berlin',
        'FR': 'Paris',
        'AT': 'Wien',
        'ES': 'Madrid',
        'IT': 'Roma',
        'DK': 'København',
        'AR': 'Buenos Aires',
      };

      for (final entry in testCases.entries) {
        final response = await dio.get(
          'https://nominatim.openstreetmap.org/search',
          queryParameters: {
            'q': entry.value,
            'countrycodes': entry.key.toLowerCase(),
            'format': 'json',
            'limit': '1',
          },
        );

        expect(response.statusCode, 200,
            reason: '${entry.key}: Nominatim returned non-200');
        expect(response.data, isA<List>(),
            reason: '${entry.key}: Response is not a list');
        expect((response.data as List).length, greaterThan(0),
            reason: '${entry.key}: No results for ${entry.value}');

        final result = (response.data as List).first;
        expect(double.tryParse(result['lat']?.toString() ?? ''), isNotNull,
            reason: '${entry.key}: lat not parseable');
        expect(double.tryParse(result['lon']?.toString() ?? ''), isNotNull,
            reason: '${entry.key}: lon not parseable');
      }
    });
  });

  group('API Response Parsing', () {
    test('Spain — comma decimal separator parsing', () {
      // Verify our parsing approach works for Spanish API's comma decimals
      const latStr = '40,432861';
      const lngStr = '-3,724194';
      const priceStr = '1,817';

      final lat = double.tryParse(latStr.replaceAll(',', '.'));
      final lng = double.tryParse(lngStr.replaceAll(',', '.'));
      final price = double.tryParse(priceStr.replaceAll(',', '.'));

      expect(lat, closeTo(40.432861, 0.000001));
      expect(lng, closeTo(-3.724194, 0.000001));
      expect(price, closeTo(1.817, 0.001));
    });

    test('Spain — empty price string returns null', () {
      const emptyPrice = '';
      final result = emptyPrice.trim().isEmpty
          ? null
          : double.tryParse(emptyPrice.replaceAll(',', '.'));
      expect(result, isNull);
    });

    test('Austria — fuel type code mapping', () {
      const fuelTypes = {'DIE': 'Diesel', 'SUP': 'Super 95', 'GAS': 'CNG'};
      expect(fuelTypes['DIE'], 'Diesel');
      expect(fuelTypes['SUP'], 'Super 95');
      expect(fuelTypes['GAS'], 'CNG');
    });
  });
}
