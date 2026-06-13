// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';

/// OAuth 2.0 **client-credentials** token source for the UK statutory Fuel
/// Finder API (#3190).
///
/// The voluntary CMA scheme was withdrawn 2026-05-01 and replaced by the
/// statutory Fuel Finder Scheme (*Motor Fuel Price (Open Data) Regulations
/// 2025*), whose public API (developer.fuel-finder.service.gov.uk) is fronted
/// by OAuth 2.0 client credentials — a `client_id` / `client_secret` pair
/// generated via a GOV.UK One Login. This holds those credentials and the
/// token endpoint, fetches a bearer token on demand (RFC 6749 §4.4), caches it
/// until shortly before it expires, and re-fetches after [invalidate] (called
/// on a 401).
///
/// It is deliberately a small, injectable collaborator — the bulk station
/// service takes one (or null, the unauthenticated pre-credentials path) so the
/// token flow is unit-testable against a mock [Dio] without a live endpoint.
class UkFuelFinderAuth {
  UkFuelFinderAuth({
    required Dio dio,
    required this.tokenUrl,
    required this.clientId,
    required this.clientSecret,
    this.scope,
    DateTime Function() now = DateTime.now,
  })  : _dio = dio,
        _now = now;

  final Dio _dio;
  final DateTime Function() _now;

  /// The OAuth2 token endpoint (the `/token` URL from the Fuel Finder
  /// developer portal). Injected — never guessed in code.
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
    final response = await _dio.post<dynamic>(
      tokenUrl,
      data: {
        'grant_type': 'client_credentials',
        'client_id': clientId,
        'client_secret': clientSecret,
        if (scope != null) 'scope': scope,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
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
    final token = body['access_token'];
    if (token is! String || token.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'OAuth2 token response missing access_token',
      );
    }
    // `expires_in` is seconds (RFC 6749 §5.1). Default to a conservative
    // 5 min when the server omits it so a missing field can't pin a stale
    // token forever.
    final expiresIn = body['expires_in'];
    final seconds = expiresIn is num ? expiresIn.toInt() : 300;
    _cachedToken = token;
    _expiresAt = _now().add(Duration(seconds: seconds));
    return token;
  }
}
