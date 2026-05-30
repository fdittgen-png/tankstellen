// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// HTTP conditional-GET + offline-fallback interceptor for the Dio stack
/// (#2249, child of Epic #2249).
///
/// Two complementary jobs, both keyed by request URI:
///
///  1. **Conditional GET (304 revalidation).** When a previous `GET` response
///     carried an `ETag` and/or `Last-Modified`, the next identical `GET`
///     re-sends them as `If-None-Match` / `If-Modified-Since`. If the upstream
///     answers `304 Not Modified`, the interceptor resolves the request with
///     the *cached* body + status `200` instead of an empty 304 — so callers
///     never see a 304 and the bulk daily-file sources (FR/ES/IT/MX/AR) skip
///     re-downloading a multi-MB body that hasn't changed.
///
///  2. **Hit-cache-on-network-failure.** When a `GET` fails with a connection
///     error / timeout (no usable HTTP response), the interceptor serves the
///     last cached body for that URI if one exists — stale-but-online beats a
///     hard failure for a data fetch. Cache misses propagate the error
///     unchanged so the chain's own stale-cache fallback still runs.
///
/// The store is in-memory and per-Dio (each [DioFactory.create] gets its own
/// interceptor instance). It is intentionally *not* persisted: the
/// whole-country datasets already have a disk read-through (PersistentDataset),
/// and per-URI ETags are most valuable within a single app run / background
/// burst. A small [maxEntries] LRU bound keeps memory flat.
///
/// Only `GET` is handled; mutating methods pass through untouched.
class ConditionalGetInterceptor extends Interceptor {
  ConditionalGetInterceptor({this.maxEntries = 64});

  /// Max number of cached responses retained (LRU). Bulk-file sources hit one
  /// or two stable URIs, so this is generous; the bound only guards against an
  /// unexpected fan-out of distinct query strings.
  final int maxEntries;

  /// URI → cached conditional-GET entry. LinkedHashMap iteration order gives a
  /// cheap LRU: re-insert on touch, evict the oldest when over [maxEntries].
  final _store = <String, _CachedResponse>{};

  /// Key a request by its full resolved URI (path + query). Two searches with
  /// different query strings are distinct cache entries.
  String _keyFor(RequestOptions options) => options.uri.toString();

  bool _isGet(RequestOptions options) =>
      options.method.toUpperCase() == 'GET';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isGet(options)) {
      final cached = _store[_keyFor(options)];
      if (cached != null) {
        if (cached.etag != null) {
          options.headers['If-None-Match'] = cached.etag;
        }
        if (cached.lastModified != null) {
          options.headers['If-Modified-Since'] = cached.lastModified;
        }
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final options = response.requestOptions;
    if (!_isGet(options)) {
      handler.next(response);
      return;
    }

    // A 304 can reach onResponse when a caller widens validateStatus to accept
    // it; the default validateStatus (200-299 only) routes it through onError
    // instead, handled below. Cover both.
    if (response.statusCode == 304) {
      final replay = _replay304(options, extra: response.extra);
      if (replay != null) {
        handler.resolve(replay);
        return;
      }
      handler.next(response);
      return;
    }

    _cacheIfValidated(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    if (_isGet(options)) {
      // Default-validateStatus path: a 304 arrives as a badResponse error.
      // Replay the cached body as a 200 so callers never see the 304.
      if (err.response?.statusCode == 304) {
        final replay = _replay304(options, extra: err.response?.extra);
        if (replay != null) {
          handler.resolve(replay);
          return;
        }
      }
      // Hit-cache-on-network-failure: no usable HTTP response (timeout /
      // connection drop) → serve the last cached body if we have one. A real
      // 4xx/5xx with a body is the caller's to interpret, so it's excluded.
      if (_isNetworkFailure(err)) {
        final cached = _store[_keyFor(options)];
        if (cached != null) {
          debugPrint(
            'ConditionalGetInterceptor: network failure on '
            '${options.uri.path} → serving cached body',
          );
          handler.resolve(_synthetic(
            options,
            cached,
            tag: 'offline',
            message: 'OK (served from conditional-GET cache)',
          ));
          return;
        }
      }
    }
    handler.next(err);
  }

  /// Cache a 2xx GET response that carries an ETag and/or Last-Modified.
  void _cacheIfValidated(Response response) {
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) return;
    final etag = response.headers.value('etag');
    final lastModified = response.headers.value('last-modified');
    if (etag == null && lastModified == null) return;
    _touch(
      _keyFor(response.requestOptions),
      _CachedResponse(
        data: response.data,
        etag: etag,
        lastModified: lastModified,
        headers: response.headers,
      ),
    );
  }

  /// Build the replay response for a 304, or null when nothing is cached for
  /// this URI (header survived a store eviction).
  Response? _replay304(RequestOptions options, {Map<String, dynamic>? extra}) {
    final key = _keyFor(options);
    final cached = _store[key];
    if (cached == null) return null;
    _touch(key, cached); // refresh LRU recency
    return _synthetic(
      options,
      cached,
      tag: '304',
      message: 'OK (304 revalidated)',
      extra: extra,
    );
  }

  Response _synthetic(
    RequestOptions options,
    _CachedResponse cached, {
    required String tag,
    required String message,
    Map<String, dynamic>? extra,
  }) =>
      Response(
        requestOptions: options,
        data: cached.data,
        statusCode: 200,
        statusMessage: message,
        headers: cached.headers,
        extra: {...?extra, 'tankstellen.conditionalGet': tag},
      );

  /// A failure with no usable HTTP response — connect/receive/send timeout or a
  /// transport-level connection error. A response-bearing 4xx/5xx is excluded.
  static bool _isNetworkFailure(DioException err) {
    if (err.response != null) return false;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
        return false;
      case DioExceptionType.unknown:
        // `unknown` covers SocketException wrapped by Dio — treat as network.
        return true;
    }
  }

  /// Insert/refresh [key] at the most-recent end and evict the oldest entry
  /// when the store exceeds [maxEntries].
  void _touch(String key, _CachedResponse entry) {
    _store.remove(key);
    _store[key] = entry;
    while (_store.length > maxEntries) {
      _store.remove(_store.keys.first);
    }
  }

  /// Visible for testing: number of cached entries currently held.
  @visibleForTesting
  int get cacheSize => _store.length;
}

/// One cached conditional-GET response: the body plus the validators needed to
/// revalidate it and the headers to replay on a 304 / offline hit.
class _CachedResponse {
  _CachedResponse({
    required this.data,
    required this.etag,
    required this.lastModified,
    required this.headers,
  });

  final dynamic data;
  final String? etag;
  final String? lastModified;
  final Headers headers;
}
