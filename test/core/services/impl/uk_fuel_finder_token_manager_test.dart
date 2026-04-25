import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/impl/uk_fuel_finder_token_manager.dart';

/// Canned reply for a single endpoint match.
class _Reply {
  final int status;
  final String body;
  const _Reply(this.status, this.body);
}

/// Fake HTTP adapter — increments call counter and returns a configured
/// reply. If [error] is non-null the adapter throws that DioException
/// instead of returning a body, mirroring upstream network errors.
class _FakeAdapter implements HttpClientAdapter {
  _Reply Function() reply;
  DioException Function(RequestOptions options)? error;
  int requestCount = 0;
  RequestOptions? lastOptions;

  _FakeAdapter({required this.reply, this.error});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    lastOptions = options;
    final err = error;
    if (err != null) {
      throw err(options);
    }
    final r = reply();
    return ResponseBody.fromString(
      r.body,
      r.status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Mock the platform method channel used by `flutter_secure_storage`.
/// Mirrors the pattern in `uk_fuel_finder_service_test.dart`.
void _mockSecureStorage(Map<String, String?> seed) {
  final store = Map<String, String?>.from(seed);
  const channel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
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
const _clientIdKey = 'uk_fuel_finder_client_id';
const _clientSecretKey = 'uk_fuel_finder_client_secret';

String _tokenBody({
  String? token = 'TEST-TOKEN',
  Object? expiresIn = 3600,
  bool includeAccessToken = true,
  bool includeExpiresIn = true,
}) {
  final body = <String, dynamic>{'token_type': 'Bearer'};
  if (includeAccessToken) body['access_token'] = token;
  if (includeExpiresIn) body['expires_in'] = expiresIn;
  return jsonEncode(body);
}

({Dio dio, _FakeAdapter adapter}) _buildDio({
  _Reply Function()? reply,
  DioException Function(RequestOptions options)? error,
}) {
  final dio = Dio();
  final adapter = _FakeAdapter(
    reply: reply ?? () => _Reply(200, _tokenBody()),
    error: error,
  );
  dio.httpClientAdapter = adapter;
  return (dio: dio, adapter: adapter);
}

FlutterSecureStorage _storageWithCreds({
  String? clientId = 'CID',
  String? clientSecret = 'SECRET',
}) {
  _mockSecureStorage({
    _clientIdKey: clientId,
    _clientSecretKey: clientSecret,
  });
  return const FlutterSecureStorage();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('cachedToken — in-memory cache semantics', () {
    test('cold cache returns null', () {
      final mgr = UkFuelFinderTokenManager();
      expect(mgr.cachedToken, isNull);
    });

    test('store() with 1h TTL → cachedToken returns the token', () {
      final mgr = UkFuelFinderTokenManager();
      mgr.store('AAA', const Duration(hours: 1));
      expect(mgr.cachedToken, 'AAA');
    });

    test('store() with sub-60s TTL falls inside refresh window → null', () {
      final mgr = UkFuelFinderTokenManager();
      // 30s TTL is shorter than the 60s refresh-early threshold, so the
      // cache should report stale immediately.
      mgr.store('BBB', const Duration(seconds: 30));
      expect(mgr.cachedToken, isNull);
    });

    test('store() then forceExpire() returns null', () {
      final mgr = UkFuelFinderTokenManager();
      mgr.store('CCC', const Duration(hours: 1));
      expect(mgr.cachedToken, 'CCC');
      mgr.forceExpire();
      expect(mgr.cachedToken, isNull);
    });

    test('store() overwrite returns the new token', () {
      final mgr = UkFuelFinderTokenManager();
      mgr.store('FIRST', const Duration(hours: 1));
      mgr.store('SECOND', const Duration(hours: 2));
      expect(mgr.cachedToken, 'SECOND');
    });
  });

  group('fetchAccessToken — cache short-circuit', () {
    test('returns cached token without hitting Dio when cache is fresh',
        () async {
      final built = _buildDio();
      final mgr = UkFuelFinderTokenManager()
        ..store('CACHED', const Duration(hours: 1));

      final result = await mgr.fetchAccessToken(
        dio: built.dio,
        secureStorage: _storageWithCreds(),
        tokenUrl: _tokenUrl,
        clientIdStorageKey: _clientIdKey,
        clientSecretStorageKey: _clientSecretKey,
      );

      expect(result, 'CACHED');
      expect(
        built.adapter.requestCount,
        0,
        reason: 'Cache hit must not perform any HTTP request',
      );
    });
  });

  group('fetchAccessToken — credential validation', () {
    Future<void> expectMissingCredsThrows({
      String? clientId,
      String? clientSecret,
    }) async {
      final built = _buildDio();
      final mgr = UkFuelFinderTokenManager();

      await expectLater(
        mgr.fetchAccessToken(
          dio: built.dio,
          secureStorage: _storageWithCreds(
            clientId: clientId,
            clientSecret: clientSecret,
          ),
          tokenUrl: _tokenUrl,
          clientIdStorageKey: _clientIdKey,
          clientSecretStorageKey: _clientSecretKey,
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('credentials missing'),
          ),
        ),
      );
      expect(
        built.adapter.requestCount,
        0,
        reason: 'Missing creds must short-circuit before any HTTP traffic',
      );
    }

    test('clientId null throws ApiException', () async {
      await expectMissingCredsThrows(clientId: null, clientSecret: 'SECRET');
    });

    test('clientSecret null throws ApiException', () async {
      await expectMissingCredsThrows(clientId: 'CID', clientSecret: null);
    });

    test('clientId empty string throws ApiException', () async {
      await expectMissingCredsThrows(clientId: '', clientSecret: 'SECRET');
    });

    test('clientSecret empty string throws ApiException', () async {
      await expectMissingCredsThrows(clientId: 'CID', clientSecret: '');
    });
  });

  group('fetchAccessToken — response payload validation', () {
    test('null response data throws ApiException "response empty"', () async {
      // Returning an empty body with content-type JSON yields a null
      // decoded payload, which is exactly the branch we want to exercise.
      final built = _buildDio(reply: () => const _Reply(200, ''));
      final mgr = UkFuelFinderTokenManager();

      await expectLater(
        mgr.fetchAccessToken(
          dio: built.dio,
          secureStorage: _storageWithCreds(),
          tokenUrl: _tokenUrl,
          clientIdStorageKey: _clientIdKey,
          clientSecretStorageKey: _clientSecretKey,
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('empty'),
          ),
        ),
      );
    });

    test('null access_token throws ApiException "missing access_token"',
        () async {
      final built = _buildDio(
        reply: () => _Reply(200, _tokenBody(token: null)),
      );
      final mgr = UkFuelFinderTokenManager();

      await expectLater(
        mgr.fetchAccessToken(
          dio: built.dio,
          secureStorage: _storageWithCreds(),
          tokenUrl: _tokenUrl,
          clientIdStorageKey: _clientIdKey,
          clientSecretStorageKey: _clientSecretKey,
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('access_token'),
          ),
        ),
      );
    });

    test('empty-string access_token throws ApiException', () async {
      final built = _buildDio(
        reply: () => _Reply(200, _tokenBody(token: '')),
      );
      final mgr = UkFuelFinderTokenManager();

      await expectLater(
        mgr.fetchAccessToken(
          dio: built.dio,
          secureStorage: _storageWithCreds(),
          tokenUrl: _tokenUrl,
          clientIdStorageKey: _clientIdKey,
          clientSecretStorageKey: _clientSecretKey,
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('access_token'),
          ),
        ),
      );
    });

    test('expires_in absent → defaults to 3600s and token is cached',
        () async {
      final built = _buildDio(
        reply: () => _Reply(
          200,
          _tokenBody(token: 'NOEXP', includeExpiresIn: false),
        ),
      );
      final mgr = UkFuelFinderTokenManager();

      final token = await mgr.fetchAccessToken(
        dio: built.dio,
        secureStorage: _storageWithCreds(),
        tokenUrl: _tokenUrl,
        clientIdStorageKey: _clientIdKey,
        clientSecretStorageKey: _clientSecretKey,
      );

      expect(token, 'NOEXP');
      // 3600s default puts expiry comfortably outside the 60s refresh
      // window, so the cache reports the token as fresh.
      expect(mgr.cachedToken, 'NOEXP');
    });
  });

  group('fetchAccessToken — DioException mapping', () {
    test('401 surfaces as ApiException with statusCode 401', () async {
      final built = _buildDio(
        error: (options) => DioException(
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 401,
            data: '{"error":"invalid_client"}',
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      final mgr = UkFuelFinderTokenManager();

      await expectLater(
        mgr.fetchAccessToken(
          dio: built.dio,
          secureStorage: _storageWithCreds(),
          tokenUrl: _tokenUrl,
          clientIdStorageKey: _clientIdKey,
          clientSecretStorageKey: _clientSecretKey,
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', contains('401')),
        ),
      );
    });

    test('403 surfaces as ApiException with statusCode 403', () async {
      final built = _buildDio(
        error: (options) => DioException(
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 403,
            data: '{"error":"forbidden"}',
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      final mgr = UkFuelFinderTokenManager();

      await expectLater(
        mgr.fetchAccessToken(
          dio: built.dio,
          secureStorage: _storageWithCreds(),
          tokenUrl: _tokenUrl,
          clientIdStorageKey: _clientIdKey,
          clientSecretStorageKey: _clientSecretKey,
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', contains('403')),
        ),
      );
    });

    test(
        'connectionTimeout (no response) → ApiException null statusCode + '
        'message contains "connectionTimeout"', () async {
      final built = _buildDio(
        error: (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        ),
      );
      final mgr = UkFuelFinderTokenManager();

      await expectLater(
        mgr.fetchAccessToken(
          dio: built.dio,
          secureStorage: _storageWithCreds(),
          tokenUrl: _tokenUrl,
          clientIdStorageKey: _clientIdKey,
          clientSecretStorageKey: _clientSecretKey,
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', isNull)
              .having(
                (e) => e.message,
                'message',
                contains('connectionTimeout'),
              ),
        ),
      );
    });
  });

  group('fetchAccessToken — happy path', () {
    test('returns access_token and populates cache', () async {
      final built = _buildDio(
        reply: () => _Reply(200, _tokenBody(token: 'GOOD-TOKEN')),
      );
      final mgr = UkFuelFinderTokenManager();

      final token = await mgr.fetchAccessToken(
        dio: built.dio,
        secureStorage: _storageWithCreds(),
        tokenUrl: _tokenUrl,
        clientIdStorageKey: _clientIdKey,
        clientSecretStorageKey: _clientSecretKey,
      );

      expect(token, 'GOOD-TOKEN');
      expect(mgr.cachedToken, 'GOOD-TOKEN');
      expect(built.adapter.requestCount, 1);
    });
  });
}
