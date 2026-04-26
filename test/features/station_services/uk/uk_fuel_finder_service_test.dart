import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/features/station_services/uk/uk_fuel_finder_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';

/// Canned reply for a single URL (token or data endpoint).
class _Reply {
  final int status;
  final String body;
  const _Reply(this.status, this.body);
}

/// Fake HTTP adapter — matches by endpoint substring so tests can key on
/// the OAuth path vs the data path without having to match the full URL
/// including query strings.
class _FakeAdapter implements HttpClientAdapter {
  final List<_Matcher> matchers;
  int tokenRequests = 0;
  int stationsRequests = 0;
  final List<String> requestedUrls = [];

  _FakeAdapter(this.matchers);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final url = options.uri.toString();
    requestedUrls.add(url);
    if (url.contains('/oauth/token')) tokenRequests++;
    if (url.contains('/stations')) stationsRequests++;

    for (final m in matchers) {
      if (m.matches(url)) {
        final reply = m.reply();
        return ResponseBody.fromString(
          reply.body,
          reply.status,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      }
    }
    return ResponseBody.fromString('', 404);
  }

  @override
  void close({bool force = false}) {}
}

/// A matcher picks a reply based on the request URL. `reply` is a
/// function so tests can vary the response across retries.
class _Matcher {
  final bool Function(String url) matches;
  final _Reply Function() reply;
  _Matcher(this.matches, this.reply);
}

/// Mock the platform method channel used by `flutter_secure_storage` so
/// tests don't need to touch the real keychain. Pattern mirrors
/// `test/core/storage/stores/settings_hive_store_test.dart`.
void _mockSecureStorage(Map<String, String?> seed) {
  final store = Map<String, String?>.from(seed);
  const channel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    final args = (call.arguments as Map?) ?? {};
    final key = args['key'] as String? ?? '';
    switch (call.method) {
      case 'read':
        return store[key];
      case 'write':
        store[key] = args['value'] as String?;
        return null;
      case 'delete':
        store.remove(key);
        return null;
      case 'readAll':
        return Map<String, String?>.from(store);
      case 'deleteAll':
        store.clear();
        return null;
      case 'containsKey':
        return store.containsKey(key);
    }
    return null;
  });
}

const _tokenUrl = 'https://fake.example/oauth/token';
const _stationsUrl = 'https://fake.example/api/v1/stations';

const _validSearch = SearchParams(lat: 51.5, lng: -0.12, radiusKm: 50);

String _tokenBody({String token = 'TEST-TOKEN', int expiresIn = 3600}) {
  return jsonEncode({
    'access_token': token,
    'token_type': 'Bearer',
    'expires_in': expiresIn,
  });
}

String _stationsBody(List<Map<String, dynamic>> stations) {
  return jsonEncode({'stations': stations});
}

({Dio dio, _FakeAdapter adapter}) _buildDio(List<_Matcher> matchers) {
  final dio = Dio();
  final adapter = _FakeAdapter(matchers);
  dio.httpClientAdapter = adapter;
  return (dio: dio, adapter: adapter);
}

FlutterSecureStorage _storageWithCreds({
  String clientId = 'CID',
  String clientSecret = 'SECRET',
}) {
  _mockSecureStorage({
    UkFuelFinderService.kClientIdStorageKey: clientId,
    UkFuelFinderService.kClientSecretStorageKey: clientSecret,
  });
  return const FlutterSecureStorage();
}

FlutterSecureStorage _storageEmpty() {
  _mockSecureStorage(const {});
  return const FlutterSecureStorage();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UkFuelFinderService — contract', () {
    test('implements StationService', () {
      final svc = UkFuelFinderService(
        dio: Dio(),
        secureStorage: _storageEmpty(),
      );
      expect(svc, isA<StationService>());
    });

    test('getStationDetail throws ApiException', () async {
      final svc = UkFuelFinderService(
        dio: Dio(),
        secureStorage: _storageEmpty(),
      );
      expect(
        () => svc.getStationDetail('uk-1'),
        throwsA(isA<ApiException>()),
      );
    });

    test('getPrices returns empty map tagged as ukApi', () async {
      final svc = UkFuelFinderService(
        dio: Dio(),
        secureStorage: _storageEmpty(),
      );
      final result = await svc.getPrices(['uk-1']);
      expect(result.data, isEmpty);
      expect(result.source, ServiceSource.ukApi);
    });

    test('secure-storage key constants are stable', () {
      // Guard against accidental rename — settings screen will use
      // exactly these keys to write user-provided credentials.
      expect(UkFuelFinderService.kClientIdStorageKey,
          'uk_fuel_finder_client_id');
      expect(UkFuelFinderService.kClientSecretStorageKey,
          'uk_fuel_finder_client_secret');
    });
  });

  group('OAuth2 token flow', () {
    test('fetches a token with valid creds and caches it across calls',
        () async {
      final built = _buildDio([
        _Matcher(
          (url) => url.contains('/oauth/token'),
          () => _Reply(200, _tokenBody()),
        ),
        _Matcher(
          (url) => url.contains('/stations'),
          () => _Reply(200, _stationsBody(const [])),
        ),
      ]);

      final svc = UkFuelFinderService(
        dio: built.dio,
        secureStorage: _storageWithCreds(),
        tokenUrl: _tokenUrl,
        stationsUrl: _stationsUrl,
      );

      await svc.searchStations(_validSearch);
      await svc.searchStations(_validSearch);

      // Two data requests, but only one token fetch — second call
      // must hit the in-memory cache.
      expect(built.adapter.tokenRequests, 1);
      expect(built.adapter.stationsRequests, 2);
    });

    test('refreshes the token after expiry', () async {
      final built = _buildDio([
        _Matcher(
          (url) => url.contains('/oauth/token'),
          () => _Reply(200, _tokenBody()),
        ),
        _Matcher(
          (url) => url.contains('/stations'),
          () => _Reply(200, _stationsBody(const [])),
        ),
      ]);

      final svc = UkFuelFinderService(
        dio: built.dio,
        secureStorage: _storageWithCreds(),
        tokenUrl: _tokenUrl,
        stationsUrl: _stationsUrl,
      );

      await svc.searchStations(_validSearch);
      expect(built.adapter.tokenRequests, 1);

      // Simulate clock-forward past expiry.
      svc.expireTokenForTest();

      await svc.searchStations(_validSearch);
      expect(built.adapter.tokenRequests, 2,
          reason: 'Expired token must trigger a refresh');
    });

    test('401 on the token endpoint surfaces as an OAuth ApiException',
        () async {
      final built = _buildDio([
        _Matcher(
          (url) => url.contains('/oauth/token'),
          () => const _Reply(401, '{"error":"invalid_client"}'),
        ),
      ]);

      final svc = UkFuelFinderService(
        dio: built.dio,
        secureStorage: _storageWithCreds(),
        tokenUrl: _tokenUrl,
        stationsUrl: _stationsUrl,
      );

      await expectLater(
        svc.searchStations(_validSearch),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('OAuth'),
          ),
        ),
      );
    });

    test('missing credentials throw before any HTTP call', () async {
      final built = _buildDio(const []);
      final svc = UkFuelFinderService(
        dio: built.dio,
        secureStorage: _storageEmpty(),
        tokenUrl: _tokenUrl,
        stationsUrl: _stationsUrl,
      );

      await expectLater(
        svc.searchStations(_validSearch),
        throwsA(isA<ApiException>()),
      );
      // No HTTP traffic — we short-circuit on missing creds.
      expect(built.adapter.tokenRequests, 0);
      expect(built.adapter.stationsRequests, 0);
    });
  });

  group('station list parsing', () {
    test('parses a well-formed station with prices in pence', () async {
      final built = _buildDio([
        _Matcher(
          (url) => url.contains('/oauth/token'),
          () => _Reply(200, _tokenBody()),
        ),
        _Matcher(
          (url) => url.contains('/stations'),
          () => _Reply(
            200,
            _stationsBody([
              {
                'site_id': 'GB1',
                'brand': 'BP',
                'site_name': 'BP Victoria',
                'address': '1 Victoria St',
                'postcode': 'SW1E 6DE',
                'town': 'London',
                'location': {'latitude': 51.4975, 'longitude': -0.1357},
                'prices': {
                  'E5': 155.9,
                  'E10': 145.9,
                  'B7': 152.9,
                  'E98': 158.9,
                  'SDV': 165.9,
                },
              }
            ]),
          ),
        ),
      ]);

      final svc = UkFuelFinderService(
        dio: built.dio,
        secureStorage: _storageWithCreds(),
        tokenUrl: _tokenUrl,
        stationsUrl: _stationsUrl,
      );

      final result = await svc.searchStations(_validSearch);
      expect(result.source, ServiceSource.ukApi);
      expect(result.data, hasLength(1));
      final s = result.data.first;
      expect(s.id, 'uk-GB1');
      expect(s.brand, 'BP');
      expect(s.name, 'BP Victoria');
      expect(s.lat, closeTo(51.4975, 0.0001));
      expect(s.lng, closeTo(-0.1357, 0.0001));
      expect(s.e5, closeTo(1.559, 0.0001));
      expect(s.e10, closeTo(1.459, 0.0001));
      expect(s.diesel, closeTo(1.529, 0.0001));
      expect(s.e98, closeTo(1.589, 0.0001));
      expect(s.dieselPremium, closeTo(1.659, 0.0001));
      expect(s.isOpen, isTrue);
    });

    test('HTTP 500 on the data endpoint throws ApiException', () async {
      final built = _buildDio([
        _Matcher(
          (url) => url.contains('/oauth/token'),
          () => _Reply(200, _tokenBody()),
        ),
        _Matcher(
          (url) => url.contains('/stations'),
          () => const _Reply(500, 'upstream boom'),
        ),
      ]);

      final svc = UkFuelFinderService(
        dio: built.dio,
        secureStorage: _storageWithCreds(),
        tokenUrl: _tokenUrl,
        stationsUrl: _stationsUrl,
      );

      await expectLater(
        svc.searchStations(_validSearch),
        throwsA(isA<ApiException>()),
      );
    });

    test('empty stations list yields empty Station list (does not throw)',
        () async {
      final built = _buildDio([
        _Matcher(
          (url) => url.contains('/oauth/token'),
          () => _Reply(200, _tokenBody()),
        ),
        _Matcher(
          (url) => url.contains('/stations'),
          () => _Reply(200, _stationsBody(const [])),
        ),
      ]);

      final svc = UkFuelFinderService(
        dio: built.dio,
        secureStorage: _storageWithCreds(),
        tokenUrl: _tokenUrl,
        stationsUrl: _stationsUrl,
      );

      final result = await svc.searchStations(_validSearch);
      expect(result.data, isEmpty);
      expect(result.source, ServiceSource.ukApi);
    });

    test('stations outside the search radius are filtered out', () async {
      final built = _buildDio([
        _Matcher(
          (url) => url.contains('/oauth/token'),
          () => _Reply(200, _tokenBody()),
        ),
        _Matcher(
          (url) => url.contains('/stations'),
          () => _Reply(
            200,
            _stationsBody([
              {
                'site_id': 'LON',
                'brand': 'BP',
                'location': {'latitude': 51.5, 'longitude': -0.12},
                'prices': <String, dynamic>{},
              },
              {
                'site_id': 'EDI',
                'brand': 'Shell',
                'location': {'latitude': 55.9533, 'longitude': -3.1883},
                'prices': <String, dynamic>{},
              },
            ]),
          ),
        ),
      ]);

      final svc = UkFuelFinderService(
        dio: built.dio,
        secureStorage: _storageWithCreds(),
        tokenUrl: _tokenUrl,
        stationsUrl: _stationsUrl,
      );

      final result = await svc.searchStations(
        const SearchParams(lat: 51.5, lng: -0.12, radiusKm: 20),
      );
      expect(result.data, hasLength(1));
      expect(result.data.first.id, 'uk-LON');
    });
  });

  group('parseFuelFinderStations (static)', () {
    test('parsePenceForTest handles pence, pounds, and garbage', () {
      expect(UkFuelFinderService.parsePenceForTest(null), isNull);
      expect(UkFuelFinderService.parsePenceForTest('abc'), isNull);
      expect(
        UkFuelFinderService.parsePenceForTest(145.9),
        closeTo(1.459, 0.0001),
      );
      expect(UkFuelFinderService.parsePenceForTest(1.459), 1.459);
      expect(UkFuelFinderService.parsePenceForTest('155'), closeTo(1.55, 0.0001));
    });

    test('dedupes by site_id and caps at 50 results', () {
      final items = <Map<String, dynamic>>[
        for (var i = 0; i < 120; i++)
          {
            'site_id': 'S$i',
            'brand': 'Brand',
            'location': {
              'latitude': 51.5 + i * 0.0001,
              'longitude': -0.12,
            },
            'prices': <String, dynamic>{},
          },
        // Duplicate of S0 — must be skipped.
        {
          'site_id': 'S0',
          'brand': 'Dup',
          'location': {'latitude': 51.5, 'longitude': -0.12},
          'prices': <String, dynamic>{},
        },
      ];

      final stations = UkFuelFinderService.parseFuelFinderStations(
        items,
        lat: 51.5,
        lng: -0.12,
        radiusKm: 500,
      );

      expect(stations.length, 50);
      // First station is the closest (S0) and its duplicate was rejected.
      expect(stations.first.id, 'uk-S0');
      expect(stations.first.brand, 'Brand');
    });
  });
}
