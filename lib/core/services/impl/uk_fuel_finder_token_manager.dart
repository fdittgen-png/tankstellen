/// OAuth2 client-credentials token lifecycle for the GOV.UK Fuel Finder
/// service (#573, #563 split). Lives separately from
/// [UkFuelFinderService] so the OAuth2 dance — token cache, proactive
/// refresh, secure-storage credential lookup — can be exercised
/// independently of the data-fetch + parse path.
///
/// One instance per service: keeps blast radius local instead of
/// pushing a Dio-wide interceptor that would touch unrelated requests.
///
/// Public surface:
///  - [UkFuelFinderTokenManager.cachedToken] — non-null when the
///    in-memory token is still valid for ≥ 60s.
///  - [UkFuelFinderTokenManager.store] — record a freshly fetched token
///    and its TTL.
///  - [UkFuelFinderTokenManager.forceExpire] — flip the cached expiry
///    into the past so the next [fetchAccessToken] performs a real
///    `/oauth/token` round trip. Test-only escape hatch.
///  - [UkFuelFinderTokenManager.fetchAccessToken] — full
///    cached-or-fetch entry point. Pulls credentials from
///    [FlutterSecureStorage] under the configured keys, posts a
///    `client_credentials` grant, and returns the access token.
library;

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../error/exceptions.dart';

/// OAuth2 client-credentials token lifecycle owner.
class UkFuelFinderTokenManager {
  String? _accessToken;
  DateTime? _expiresAt;

  /// Returns the cached token if it is still valid for at least 60s,
  /// otherwise `null` (caller must fetch a fresh one).
  String? get cachedToken {
    final token = _accessToken;
    final expiry = _expiresAt;
    if (token == null || expiry == null) return null;
    // Refresh one minute before expiry to avoid racing a request against
    // a token that expires mid-flight.
    if (DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 60)))) {
      return null;
    }
    return token;
  }

  /// Persist a freshly fetched token + TTL into the in-memory cache.
  void store(String token, Duration ttl) {
    _accessToken = token;
    _expiresAt = DateTime.now().add(ttl);
  }

  /// Force the cached token to appear expired. Called by the service
  /// shell's `expireTokenForTest()` (itself `@visibleForTesting`) so the
  /// next [fetchAccessToken] call triggers a real token request.
  void forceExpire() {
    _expiresAt = DateTime.now().subtract(const Duration(minutes: 1));
  }

  /// Returns a valid access token — from the in-memory cache when fresh,
  /// otherwise via a `client_credentials` grant against [tokenUrl].
  ///
  /// Reads credentials from [secureStorage] under
  /// [clientIdStorageKey] / [clientSecretStorageKey]. Throws
  /// [ApiException] when credentials are missing, the token endpoint
  /// returns 401/403, or the response payload is malformed.
  Future<String> fetchAccessToken({
    required Dio dio,
    required FlutterSecureStorage secureStorage,
    required String tokenUrl,
    required String clientIdStorageKey,
    required String clientSecretStorageKey,
    CancelToken? cancelToken,
  }) async {
    final cached = cachedToken;
    if (cached != null) return cached;

    final clientId = await secureStorage.read(key: clientIdStorageKey);
    final clientSecret = await secureStorage.read(key: clientSecretStorageKey);
    if (clientId == null ||
        clientId.isEmpty ||
        clientSecret == null ||
        clientSecret.isEmpty) {
      throw const ApiException(
        message:
            'Fuel Finder OAuth credentials missing — set client id and '
            'secret in secure storage before enabling.',
      );
    }

    try {
      final response = await dio.post<Map<String, dynamic>>(
        tokenUrl,
        data: {
          'grant_type': 'client_credentials',
          'client_id': clientId,
          'client_secret': clientSecret,
        },
        cancelToken: cancelToken,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.json,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException(
          message: 'OAuth token response empty for Fuel Finder',
        );
      }
      final accessToken = data['access_token']?.toString();
      final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
      if (accessToken == null || accessToken.isEmpty) {
        throw const ApiException(
          message: 'OAuth token response missing access_token',
        );
      }

      store(accessToken, Duration(seconds: expiresIn));
      return accessToken;
    } on DioException catch (e, st) { // ignore: unused_catch_stack
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        throw ApiException(
          message:
              'OAuth authentication failed for Fuel Finder (HTTP $status) '
              '— check client id and secret.',
          statusCode: status,
        );
      }
      throw ApiException(
        message: 'OAuth token request failed: ${e.type.name}',
        statusCode: status,
      );
    }
  }
}
