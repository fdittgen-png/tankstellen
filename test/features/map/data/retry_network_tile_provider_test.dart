import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tankstellen/features/map/data/retry_network_tile_provider.dart';

/// Unit tests for [RetryNetworkTileProvider] / [RetryingTileHttpClient]
/// (#757).
///
/// The HTTP retry policy is what ultimately decides whether a tile
/// request succeeds before flutter_map's `evictErrorTileStrategy`
/// is invoked. These tests drive the retry client directly — every
/// real tile fetch eventually traverses this exact client, so
/// exercising it is equivalent to exercising the provider from
/// flutter_map's perspective.
///
/// Covers the scenarios called out in the task spec:
///  - 503, 503, 200 → succeeds on third attempt with bytes.
///  - 404 → does NOT retry (permanent failure).
///  - 429 → retries (OSM rate-limit signal, transient).
///  - Connection errors → retry with the same policy.
///  - Total elapsed sleep respects the configured backoff minimums.
void main() {
  group('RetryNetworkTileProvider constructor', () {
    test('instantiates without throwing — flutter_map 8.x surface', () {
      expect(() => RetryNetworkTileProvider(), returnsNormally);
    });
  });

  group('RetryingTileHttpClient retry policy', () {
    test('503, 503, 200 → succeeds after exactly 3 attempts', () async {
      final inner = _FakeClient(responses: [
        _resp(503),
        _resp(503),
        _resp(200, body: 'tile-bytes'),
      ]);
      final slept = <Duration>[];
      final client = RetryingTileHttpClient(
        inner: inner,
        random: math.Random(0),
        sleep: (d) async => slept.add(d),
      );

      final response = await client.get(
          Uri.parse('https://tile.openstreetmap.org/14/8411/5485.png'));

      expect(response.statusCode, 200);
      expect(response.body, 'tile-bytes');
      expect(inner.sentCount, 3,
          reason: 'default maxAttempts=3 → two retries before success');
      expect(slept, hasLength(2),
          reason: 'two sleeps between three attempts');

      // Backoff must at least hit the baseline minimums.
      // Base delays: 200 ms, 800 ms. Jitter is ±20%, so the
      // minimum total is 160 + 640 = 800 ms, maximum 240 + 960
      // = 1200 ms.
      final totalSleepMs =
          slept.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
      expect(totalSleepMs, greaterThanOrEqualTo(800),
          reason: 'backoff minimum — the first retry must wait ≥160 ms, '
              'the second ≥640 ms, totalling ≥800 ms');
      expect(totalSleepMs, lessThanOrEqualTo(1200),
          reason: 'backoff maximum — exponential growth + ±20% jitter');
      // Attempt sleeps grow with the exponential multiplier.
      expect(slept[1].inMilliseconds, greaterThan(slept[0].inMilliseconds),
          reason: 'attempt 2 backoff (~800 ms) must exceed attempt 1 '
              '(~200 ms)');
    });

    test('404 does NOT retry — returned unchanged after 1 attempt',
        () async {
      final inner = _FakeClient(responses: [_resp(404)]);
      final slept = <Duration>[];
      final client = RetryingTileHttpClient(
        inner: inner,
        sleep: (d) async => slept.add(d),
      );

      final response = await client.get(Uri.parse('https://tile/404.png'));
      expect(response.statusCode, 404);
      expect(inner.sentCount, 1,
          reason: '4xx (non-429) is permanent — no retry');
      expect(slept, isEmpty,
          reason: 'no retries → no sleeps');
    });

    test('401 + 403 do NOT retry either', () async {
      // Spot-check a couple more permanent 4xx codes so a future
      // change that adds (say) 401 to the retry list fails loudly.
      for (final code in [401, 403, 418]) {
        final inner = _FakeClient(responses: [_resp(code)]);
        final client = RetryingTileHttpClient(
          inner: inner,
          sleep: (_) async {},
        );
        final response = await client.get(Uri.parse('https://tile'));
        expect(response.statusCode, code);
        expect(inner.sentCount, 1,
            reason: '$code must not retry — it is permanent');
      }
    });

    test('429 retries — built-in RetryClient only handles 5xx', () async {
      final inner = _FakeClient(responses: [
        _resp(429),
        _resp(200, body: 'ok'),
      ]);
      final client = RetryingTileHttpClient(
        inner: inner,
        sleep: (_) async {},
      );

      final response = await client.get(Uri.parse('https://tile'));
      expect(response.statusCode, 200);
      expect(inner.sentCount, 2);
    });

    test('SocketException retries, surfaces after maxAttempts exhausted',
        () async {
      final inner = _FakeClient(errors: [
        const SocketException('blip 1'),
        const SocketException('blip 2'),
        const SocketException('blip 3'),
      ]);
      final client = RetryingTileHttpClient(
        inner: inner,
        sleep: (_) async {},
      );

      await expectLater(
        client.get(Uri.parse('https://tile')),
        throwsA(isA<SocketException>()),
      );
      expect(inner.sentCount, 3,
          reason: 'connection error retried up to maxAttempts');
    });

    test('TimeoutException retries', () async {
      final inner = _FakeClient(responses: [
        // [null, null, _resp(200)] — the FakeClient treats null
        // as "throw the scheduled error at this index".
      ]);
      inner.scheduled = [
        TimeoutException('slow 1'),
        TimeoutException('slow 2'),
        _resp(200, body: 'recovered'),
      ];
      final client = RetryingTileHttpClient(
        inner: inner,
        sleep: (_) async {},
      );

      final response = await client.get(Uri.parse('https://tile'));
      expect(response.statusCode, 200);
      expect(response.body, 'recovered');
      expect(inner.sentCount, 3);
    });

    test('all 3 attempts return 503 → final 503 response surfaces',
        () async {
      final inner = _FakeClient(responses: List.filled(3, _resp(503)));
      final client = RetryingTileHttpClient(
        inner: inner,
        sleep: (_) async {},
      );

      final response = await client.get(Uri.parse('https://tile'));
      expect(response.statusCode, 503,
          reason: 'after retries exhausted, flutter_map sees the last '
              'response — its errorTileCallback + evict strategy '
              'take over');
      expect(inner.sentCount, 3);
    });

    test('custom maxAttempts = 1 disables retry', () async {
      final inner = _FakeClient(responses: [_resp(503), _resp(200)]);
      final client = RetryingTileHttpClient(
        inner: inner,
        maxAttempts: 1,
        sleep: (_) async {},
      );
      final response = await client.get(Uri.parse('https://tile'));
      expect(response.statusCode, 503);
      expect(inner.sentCount, 1);
    });

    test('200 on first try → no retry, no sleep', () async {
      final inner = _FakeClient(responses: [_resp(200, body: 'immediate')]);
      final slept = <Duration>[];
      final client = RetryingTileHttpClient(
        inner: inner,
        sleep: (d) async => slept.add(d),
      );
      final response = await client.get(Uri.parse('https://tile'));
      expect(response.statusCode, 200);
      expect(response.body, 'immediate');
      expect(inner.sentCount, 1);
      expect(slept, isEmpty);
    });

    test('nextDelay grows exponentially and stays non-negative', () {
      final client = RetryingTileHttpClient(
        inner: _FakeClient(),
        random: math.Random(42),
        sleep: (_) async {},
      );
      final d0 = client.nextDelay(0);
      final d1 = client.nextDelay(1);
      final d2 = client.nextDelay(2);
      expect(d0.inMilliseconds, greaterThanOrEqualTo(0));
      expect(d1.inMilliseconds, greaterThan(d0.inMilliseconds));
      expect(d2.inMilliseconds, greaterThan(d1.inMilliseconds));
    });

    test('RetryingTileHttpClient.isRetryableStatusCode matches policy', () {
      // Permanent 4xx — no retry.
      expect(RetryingTileHttpClient.isRetryableStatusCode(400), isFalse);
      expect(RetryingTileHttpClient.isRetryableStatusCode(401), isFalse);
      expect(RetryingTileHttpClient.isRetryableStatusCode(403), isFalse);
      expect(RetryingTileHttpClient.isRetryableStatusCode(404), isFalse);
      // Transient.
      expect(RetryingTileHttpClient.isRetryableStatusCode(429), isTrue);
      expect(RetryingTileHttpClient.isRetryableStatusCode(500), isTrue);
      expect(RetryingTileHttpClient.isRetryableStatusCode(502), isTrue);
      expect(RetryingTileHttpClient.isRetryableStatusCode(503), isTrue);
      expect(RetryingTileHttpClient.isRetryableStatusCode(504), isTrue);
      // Success — no retry.
      expect(RetryingTileHttpClient.isRetryableStatusCode(200), isFalse);
      expect(RetryingTileHttpClient.isRetryableStatusCode(301), isFalse);
    });
  });
}

// --- helpers ----------------------------------------------------------

http.StreamedResponse _resp(
  int status, {
  String body = '',
  Map<String, String> headers = const {},
}) {
  return http.StreamedResponse(
    Stream<List<int>>.value(body.codeUnits),
    status,
    headers: headers,
  );
}

class _FakeClient extends http.BaseClient {
  final List<http.StreamedResponse> responses;
  final List<Object> errors;

  /// Interleaved schedule of responses and errors. Takes precedence
  /// over [responses] / [errors] when non-empty so tests can mix
  /// error-then-success without index-skew bugs.
  List<Object> scheduled = const [];
  int sentCount = 0;

  _FakeClient({
    this.responses = const [],
    this.errors = const [],
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final idx = sentCount++;
    if (scheduled.isNotEmpty) {
      if (idx >= scheduled.length) {
        throw StateError('FakeClient scheduled exhausted after $idx calls');
      }
      final item = scheduled[idx];
      if (item is http.StreamedResponse) return item;
      throw item;
    }
    if (idx < errors.length) throw errors[idx];
    if (idx < responses.length) return responses[idx];
    throw StateError('FakeClient exhausted after $idx calls');
  }
}
