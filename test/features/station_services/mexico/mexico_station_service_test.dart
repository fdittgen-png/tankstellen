import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/features/station_services/mexico/mexico_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';

/// Fake HTTP adapter that maps request URLs to canned XML responses.
class _FakeCreAdapter implements HttpClientAdapter {
  _FakeCreAdapter({required this.responses});

  final Map<String, _CannedResponse> responses;
  final List<String> requestedUrls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final url = options.uri.toString();
    requestedUrls.add(url);
    final canned = responses[url];
    if (canned == null) {
      return ResponseBody.fromString('not mapped', 404);
    }
    return ResponseBody.fromString(
      canned.body,
      canned.statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/xml; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _CannedResponse {
  final String body;
  final int statusCode;
  const _CannedResponse(this.body, {this.statusCode = 200});
}

const _placesUrl =
    'https://fake.cre/publicaciones/places';
const _pricesUrl =
    'https://fake.cre/publicaciones/prices';

MexicoStationService _serviceWith({
  required String placesXml,
  required String pricesXml,
  int placesStatus = 200,
  int pricesStatus = 200,
}) =>
    _serviceAndAdapter(
      placesXml: placesXml,
      pricesXml: pricesXml,
      placesStatus: placesStatus,
      pricesStatus: pricesStatus,
    ).service;

({MexicoStationService service, _FakeCreAdapter adapter}) _serviceAndAdapter({
  required String placesXml,
  required String pricesXml,
  int placesStatus = 200,
  int pricesStatus = 200,
}) {
  final adapter = _FakeCreAdapter(responses: {
    _placesUrl: _CannedResponse(placesXml, statusCode: placesStatus),
    _pricesUrl: _CannedResponse(pricesXml, statusCode: pricesStatus),
  });
  final dio = Dio();
  dio.httpClientAdapter = adapter;
  return (
    service: MexicoStationService(
      dio: dio,
      baseUrl: 'https://fake.cre/publicaciones',
    ),
    adapter: adapter,
  );
}

const _cdmxParams = SearchParams(
  lat: 19.43,
  lng: -99.13,
  radiusKm: 10,
);

String _placesXml(List<({String id, String name, double x, double y})> places) {
  final buf = StringBuffer('<?xml version="1.0" encoding="utf-8"?>\n<places>');
  for (final p in places) {
    buf.write('''
  <place place_id="${p.id}">
    <name>${p.name}</name>
    <cre_id>PL/${p.id}/EXP/ES/2015</cre_id>
    <location>
      <x>${p.x}</x>
      <y>${p.y}</y>
    </location>
  </place>
''');
  }
  buf.write('</places>');
  return buf.toString();
}

String _pricesXml(
    List<({String id, double? regular, double? premium, double? diesel})>
        prices) {
  final buf = StringBuffer('<?xml version="1.0" encoding="utf-8"?>\n<places>');
  for (final p in prices) {
    buf.write('  <place place_id="${p.id}">');
    if (p.regular != null) {
      buf.write('<gas_price type="regular">${p.regular}</gas_price>');
    }
    if (p.premium != null) {
      buf.write('<gas_price type="premium">${p.premium}</gas_price>');
    }
    if (p.diesel != null) {
      buf.write('<gas_price type="diesel">${p.diesel}</gas_price>');
    }
    buf.write('</place>\n');
  }
  buf.write('</places>');
  return buf.toString();
}

void main() {
  group('MexicoStationService (public surface)', () {
    test('implements StationService interface', () {
      expect(MexicoStationService(), isA<StationService>());
    });

    test('getStationDetail throws ApiException', () {
      expect(
        () => MexicoStationService().getStationDetail('mx-123'),
        throwsA(isA<ApiException>()),
      );
    });

    test('getPrices returns empty map with correct source', () async {
      final result = await MexicoStationService().getPrices(['mx-1']);
      expect(result.data, isEmpty);
      expect(result.source, ServiceSource.mexicoApi);
    });
  });

  group('searchStations (CRE azure feeds — #505 fix)', () {
    test('fetches /places and /prices and joins by place_id', () async {
      final service = _serviceWith(
        placesXml: _placesXml([
          (id: '11702', name: 'Gasolinera Centro', x: -99.13, y: 19.43),
        ]),
        pricesXml: _pricesXml([
          (id: '11702', regular: 22.95, premium: 24.89, diesel: 23.45),
        ]),
      );

      final result = await service.searchStations(_cdmxParams);
      expect(result.source, ServiceSource.mexicoApi);
      expect(result.data, hasLength(1));
      final s = result.data.first;
      expect(s.id, 'mx-11702');
      expect(s.name, 'Gasolinera Centro');
      expect(s.brand, 'Gasolinera');
      expect(s.lat, 19.43);
      expect(s.lng, closeTo(-99.13, 0.0001));
      expect(s.e5, 22.95);
      expect(s.e10, 24.89);
      expect(s.diesel, 23.45);
      expect(s.isOpen, isTrue);
    });

    test('location.x is longitude and y is latitude (never swapped)',
        () async {
      // Regression guard: CRE's <location> is <x>LNG</x><y>LAT</y>, which
      // is backwards from the usual (lat, lng) convention.
      final service = _serviceWith(
        placesXml: _placesXml([
          (id: '1', name: 'LNG first', x: -99.13, y: 19.43),
        ]),
        pricesXml: _pricesXml([
          (id: '1', regular: 20.0, premium: null, diesel: null),
        ]),
      );
      final result = await service.searchStations(_cdmxParams);
      expect(result.data.first.lat, 19.43);
      expect(result.data.first.lng, closeTo(-99.13, 0.0001));
    });

    test('stations without a matching price row still render (no prices)',
        () async {
      final service = _serviceWith(
        placesXml: _placesXml([
          (id: '42', name: 'No prices here', x: -99.13, y: 19.43),
        ]),
        pricesXml: _pricesXml([
          // 42 not listed
          (id: '99', regular: 22.0, premium: null, diesel: null),
        ]),
      );
      final result = await service.searchStations(_cdmxParams);
      expect(result.data, hasLength(1));
      final s = result.data.first;
      expect(s.e5, isNull);
      expect(s.e10, isNull);
      expect(s.diesel, isNull);
    });

    test('filters stations outside the search radius', () async {
      final service = _serviceWith(
        placesXml: _placesXml([
          (id: '1', name: 'Cerca', x: -99.13, y: 19.43),
          (id: '2', name: 'Lejos Monterrey', x: -100.31, y: 25.67),
        ]),
        pricesXml: _pricesXml([
          (id: '1', regular: 22.0, premium: null, diesel: null),
          (id: '2', regular: 22.0, premium: null, diesel: null),
        ]),
      );

      final result = await service.searchStations(_cdmxParams);
      expect(result.data, hasLength(1));
      expect(result.data.first.name, 'Cerca');
    });

    test('sorts stations by distance ascending', () async {
      final service = _serviceWith(
        placesXml: _placesXml([
          (id: '1', name: 'Far', x: -99.13, y: 19.49),
          (id: '2', name: 'Near', x: -99.13, y: 19.431),
        ]),
        pricesXml: _pricesXml([
          (id: '1', regular: 22.0, premium: null, diesel: null),
          (id: '2', regular: 22.0, premium: null, diesel: null),
        ]),
      );

      final result = await service.searchStations(_cdmxParams);
      expect(result.data, hasLength(2));
      expect(result.data.first.name, 'Near');
      expect(result.data.last.name, 'Far');
    });

    test('caps results at 50', () async {
      final places = List.generate(
        80,
        (i) => (
          id: '$i',
          name: 'S$i',
          x: -99.13,
          y: 19.43 + i * 0.0001,
        ),
      );
      final prices = List.generate(
        80,
        (i) => (
          id: '$i',
          regular: 22.0 as double?,
          premium: null as double?,
          diesel: null as double?,
        ),
      );
      final service = _serviceWith(
        placesXml: _placesXml(places),
        pricesXml: _pricesXml(prices),
      );
      final result = await service.searchStations(
        const SearchParams(lat: 19.43, lng: -99.13, radiusKm: 500),
      );
      expect(result.data, hasLength(50));
    });

    test('throws ApiException on /places HTTP error (never silent)',
        () async {
      final service = _serviceWith(
        placesXml: '<error/>',
        pricesXml: _pricesXml([]),
        placesStatus: 500,
      );
      expect(
        () => service.searchStations(_cdmxParams),
        throwsA(isA<ApiException>()),
      );
    });

    test('throws ApiException on /prices HTTP error', () async {
      final service = _serviceWith(
        placesXml: _placesXml(
          [(id: '1', name: 'X', x: -99.13, y: 19.43)],
        ),
        pricesXml: '<error/>',
        pricesStatus: 503,
      );
      expect(
        () => service.searchStations(_cdmxParams),
        throwsA(isA<ApiException>()),
      );
    });

    test('throws when the merged dataset is empty (schema change guard)',
        () async {
      final service = _serviceWith(
        placesXml: '<?xml version="1.0"?><places></places>',
        pricesXml: '<?xml version="1.0"?><places></places>',
      );
      expect(
        () => service.searchStations(_cdmxParams),
        throwsA(isA<ApiException>()),
      );
    });

    test('skips <place> entries without a valid location (x/y)', () async {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<places>
  <place place_id="1">
    <name>No location</name>
    <cre_id>PL/1/EXP/ES/2015</cre_id>
  </place>
  <place place_id="2">
    <name>Good</name>
    <cre_id>PL/2/EXP/ES/2015</cre_id>
    <location>
      <x>-99.13</x>
      <y>19.43</y>
    </location>
  </place>
</places>
''';
      final service = _serviceWith(
        placesXml: xml,
        pricesXml: _pricesXml([
          (id: '1', regular: 22.0, premium: null, diesel: null),
          (id: '2', regular: 22.0, premium: null, diesel: null),
        ]),
      );
      final result = await service.searchStations(_cdmxParams);
      expect(result.data, hasLength(1));
      expect(result.data.first.name, 'Good');
    });

    test('second searchStations call within TTL reuses cached feeds',
        () async {
      final bundle = _serviceAndAdapter(
        placesXml: _placesXml([
          (id: '1', name: 'Cached', x: -99.13, y: 19.43),
        ]),
        pricesXml: _pricesXml([
          (id: '1', regular: 22.0, premium: null, diesel: null),
        ]),
      );

      await bundle.service.searchStations(_cdmxParams);
      final firstCount = bundle.adapter.requestedUrls.length;
      expect(firstCount, 2,
          reason: 'first search fetches /places + /prices');

      await bundle.service.searchStations(_cdmxParams);
      expect(
        bundle.adapter.requestedUrls.length,
        firstCount,
        reason: 'second search within TTL must NOT hit the network',
      );
    });
  });
}
