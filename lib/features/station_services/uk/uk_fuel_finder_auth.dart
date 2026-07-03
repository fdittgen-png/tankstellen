// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';

import '../../../core/services/dio_factory.dart';

/// OAuth 2.0 **client-credentials** token source for the UK statutory Fuel
/// Finder API (#3190).
///
/// The voluntary CMA scheme was withdrawn 2026-05-01 and replaced by the
/// statutory Fuel Finder Scheme (*Motor Fuel Price (Open Data) Regulations
/// 2025*), operated by VE3 Global Ltd for DESNZ. Its REST API is fronted by
/// OAuth 2.0 client credentials — a `client_id` / `client_secret` pair issued
/// through the (free) developer portal. This holds those credentials and the
/// token endpoint, fetches a bearer token on demand, caches it until shortly
/// before it expires, and re-fetches after [invalidate] (called on a 401).
///
/// ## Live token contract (verified against the published API, 2026-07-03)
///
/// ```
/// POST https://www.fuel-finder.service.gov.uk/api/v1/oauth/generate_access_token
/// Content-Type: application/json
/// {"client_id": "...", "client_secret": "..."}
/// ```
///
/// answering (the envelope's `data` wrapper may be absent — both shapes are
/// tolerated):
///
/// ```json
/// {"data": {"access_token": "...", "expires_in": 3600}}
/// ```
///
/// Note this is *not* the RFC 6749 §4.4 form-urlencoded `grant_type=`
/// exchange — the Fuel Finder token endpoint takes a JSON body with the two
/// credential fields only. Sources: the GOV.UK developer portal
/// (`developer.fuel-finder.service.gov.uk/apis-ifr/access-token`,
/// `/api-authentication`) and the contract cross-checked against a working
/// third-party consumer of the live API.
///
/// ## Registering for credentials (free)
///
/// 1. Sign in at https://www.developer.fuel-finder.service.gov.uk/ with a
///    GOV.UK One Login (free to create).
/// 2. Create an **Information Recipient** application.
/// 3. Copy the issued `client_id` / `client_secret`.
/// 4. Paste them into Settings → API key while the United Kingdom is the
///    active country, packed as `client_id:client_secret` (see
///    [fromPackedCredentials]).
///
/// The data itself is published under the Open Government Licence v3.0 and is
/// free for third-party use — no paid tier exists.
///
/// It is deliberately a small, injectable collaborator — the bulk station
/// service takes one (or null, the unauthenticated pre-credentials path) so the
/// token flow is unit-testable against a mock [Dio] without a live endpoint.
class UkFuelFinderAuth {
  UkFuelFinderAuth({
    required Dio dio,
    String? tokenUrl,
    required this.clientId,
    required this.clientSecret,
    this.scope,
    DateTime Function() now = DateTime.now,
  })  : _dio = dio,
        tokenUrl = tokenUrl ?? defaultTokenUrl,
        _now = now;

  /// Live OAuth2 token endpoint of the statutory Fuel Finder API (#3190).
  // i18n-ignore: gov.uk API endpoint URL, not user-facing text
  static const String defaultTokenUrl =
      'https://www.fuel-finder.service.gov.uk'
      '/api/v1/oauth/generate_access_token';

  /// Builds an auth from the Settings → API key slot, where the GB
  /// credentials are packed as `client_id:client_secret` (the same
  /// single-string per-country key slot DE/KR/CL already use). Returns null
  /// when [packed] is null, blank, or not two non-empty `:`-separated halves —
  /// the caller then stays on the keyless legacy path.
  static UkFuelFinderAuth? fromPackedCredentials(
    String? packed, {
    Dio? dio,
    String? tokenUrl,
  }) {
    if (packed == null) return null;
    final separator = packed.indexOf(':');
    if (separator <= 0 || separator >= packed.length - 1) return null;
    final clientId = packed.substring(0, separator).trim();
    final clientSecret = packed.substring(separator + 1).trim();
    if (clientId.isEmpty || clientSecret.isEmpty) return null;
    return UkFuelFinderAuth(
      dio: dio ??
          DioFactory.create(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
          ),
      tokenUrl: tokenUrl,
      clientId: clientId,
      clientSecret: clientSecret,
    );
  }

  final Dio _dio;
  final DateTime Function() _now;

  /// The OAuth2 token endpoint. Defaults to [defaultTokenUrl]; injectable for
  /// tests or if the host ever moves.
  final String tokenUrl;
  final String clientId;
  final String clientSecret;

  /// Optional space-delimited scope string, when the API requires one.
  final String? scope;

  String? _cachedToken;
  DateTime? _expiresAt;

  /// A refresh margin so a token that is *about* to expire is treated as
  /// already stale — avoids racing the server clock on a borderline request.
  static const Duration _refreshMargin = Duration(seconds: 30);

  /// Returns a valid bearer token, fetching a fresh one when none is cached or
  /// the cached one is within [_refreshMargin] of expiry. Throws the
  /// underlying [DioException] when the token request itself fails.
  Future<String> accessToken({CancelToken? cancelToken}) async {
    final cached = _cachedToken;
    final expiresAt = _expiresAt;
    if (cached != null &&
        expiresAt != null &&
        _now().isBefore(expiresAt.subtract(_refreshMargin))) {
      return cached;
    }
    return _fetch(cancelToken: cancelToken);
  }

  /// Drop the cached token so the next [accessToken] re-fetches. Called by the
  /// caller on a 401 (the token was revoked / rotated server-side).
  void invalidate() {
    _cachedToken = null;
    _expiresAt = null;
  }

  Future<String> _fetch({CancelToken? cancelToken}) async {
    // #3190 — the live Fuel Finder token endpoint takes a JSON body carrying
    // only the two credential fields (no `grant_type`); see the class docs
    // for the verified contract.
    final response = await _dio.post<dynamic>(
      tokenUrl,
      data: {
        'client_id': clientId,
        'client_secret': clientSecret,
        if (scope != null) 'scope': scope,
      },
      options: Options(
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
      cancelToken: cancelToken,
    );

    final body = response.data;
    if (body is! Map) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Malformed OAuth2 token response (not a JSON object)',
      );
    }
    // The live API wraps the token in a `data` envelope; tolerate a bare
    // top-level shape too so a future envelope removal cannot break auth.
    final data = body['data'];
    final payload = data is Map ? data : body;
    final token = payload['access_token'];
    if (token is! String || token.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'OAuth2 token response missing access_token',
      );
    }
    // `expires_in` is seconds (RFC 6749 §5.1). Default to a conservative
    // 5 min when the server omits it so a missing field can't pin a stale
    // token forever.
    final expiresIn = payload['expires_in'];
    final seconds = expiresIn is num ? expiresIn.toInt() : 300;
    _cachedToken = token;
    _expiresAt = _now().add(Duration(seconds: seconds));
    return token;
  }
}
