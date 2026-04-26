import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// HTTP client wrapper that retries failed OSM tile fetches (#757).
///
/// flutter_map 8.x already ships with `http.RetryClient` wrapping the
/// default [http.Client], but that retries only on 5xx — not on 429,
/// connection errors, or timeouts. The OSM tile server issues 429
/// under load and expects clients to obey `Retry-After`.
///
/// This client adds:
/// - Retry on 429, 5xx, [SocketException], and [TimeoutException].
/// - Exponential backoff with ±20% jitter (200 ms, 800 ms, 3.2 s).
/// - `Retry-After` header respected when present (either seconds or
///   an HTTP-date).
/// - Capped at 3 attempts total — beyond that the failed tile goes
///   into [TileLayer.errorTileCallback] and is evicted by the
///   `notVisibleRespectMargin` strategy landed in #758.
///
/// The backoff + Retry-After math is deterministic given a seeded
/// [math.Random], which is what the unit tests inject. In production
/// the seeded constructor is unused; [OsmRetryClient] defaults to an
/// unseeded [math.Random].
class OsmRetryClient extends http.BaseClient {
  final http.Client _inner;
  final int _maxAttempts;
  final Duration _baseDelay;
  final math.Random _random;

  /// Sleep hook, injected so tests can fast-forward without real delays.
  final Future<void> Function(Duration) _sleep;

  OsmRetryClient({
    http.Client? inner,
    int maxAttempts = 3,
    Duration baseDelay = const Duration(milliseconds: 200),
    math.Random? random,
    Future<void> Function(Duration)? sleep,
  })  : _inner = inner ?? http.Client(),
        _maxAttempts = maxAttempts,
        _baseDelay = baseDelay,
        _random = random ?? math.Random(),
        _sleep = sleep ?? _defaultSleep;

  static Future<void> _defaultSleep(Duration d) => Future.delayed(d);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // The `http` package exposes BaseRequest but a streamed request can
    // only be sent once. Materialise it to bytes so each retry rebuilds
    // an identical request — safe for our GET-only tile URLs.
    final bodyBytes = await request.finalize().toBytes();
    Object? lastError;
    http.StreamedResponse? lastResponse;

    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final fresh = http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..bodyBytes = bodyBytes;

      try {
        final response = await _inner.send(fresh);
        if (response.statusCode < 500 && response.statusCode != 429) {
          return response;
        }
        lastResponse = response;
      } on SocketException catch (e, st) { // ignore: unused_catch_stack
        lastError = e;
      } on TimeoutException catch (e, st) { // ignore: unused_catch_stack
        lastError = e;
      } on http.ClientException catch (e, st) { // ignore: unused_catch_stack
        lastError = e;
      }

      if (attempt == _maxAttempts - 1) break;
      final delay = _nextDelay(attempt, lastResponse?.headers);
      debugPrint(
          'OsmRetryClient: ${request.url} attempt ${attempt + 1} failed '
          '(${lastError ?? 'HTTP ${lastResponse?.statusCode}'}), '
          'retry in ${delay.inMilliseconds} ms');
      await _sleep(delay);
    }

    if (lastResponse != null) return lastResponse;
    throw lastError ?? http.ClientException('OsmRetryClient: retries exhausted');
  }

  /// Compute the delay before the next attempt. Honours `Retry-After`
  /// when present (OSM's preferred rate-limit signal), otherwise
  /// exponential backoff with ±20% jitter.
  @visibleForTesting
  Duration nextDelayForTest(int attempt, Map<String, String>? headers) =>
      _nextDelay(attempt, headers);

  Duration _nextDelay(int attempt, Map<String, String>? headers) {
    final retryAfter = _parseRetryAfter(headers?['retry-after']);
    if (retryAfter != null) return retryAfter;
    final baseMs = _baseDelay.inMilliseconds * math.pow(4, attempt).toInt();
    final jitter = (baseMs * 0.2 * (_random.nextDouble() * 2 - 1)).toInt();
    return Duration(milliseconds: math.max(0, baseMs + jitter));
  }

  /// Parse a `Retry-After` header. Accepts either seconds (e.g. `"60"`)
  /// or an HTTP-date (`"Wed, 21 Oct 2026 07:28:00 GMT"`).
  static Duration? _parseRetryAfter(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final seconds = int.tryParse(raw.trim());
    if (seconds != null) return Duration(seconds: seconds);
    try {
      final when = HttpDate.parse(raw);
      final diff = when.difference(DateTime.now());
      return diff.isNegative ? Duration.zero : diff;
    } catch (_) {
      return null;
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
