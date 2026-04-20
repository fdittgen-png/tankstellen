import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tankstellen/features/map/data/osm_retry_client.dart';

void main() {
  group('OsmRetryClient (#757)', () {
    test('passes 200 through without retrying', () async {
      final inner = _FakeClient(
        responses: [_resp(200, body: 'tile-bytes')],
      );
      final slept = <Duration>[];
      final client = OsmRetryClient(
        inner: inner,
        sleep: (d) async => slept.add(d),
      );

      final res = await client.get(Uri.parse('https://tile/1/2/3.png'));
      expect(res.statusCode, 200);
      expect(inner.sentCount, 1);
      expect(slept, isEmpty);
    });

    test('retries on 5xx, returns 200 after 2 failures', () async {
      final inner = _FakeClient(responses: [
        _resp(503),
        _resp(500),
        _resp(200, body: 'ok'),
      ]);
      final slept = <Duration>[];
      final client = OsmRetryClient(
        inner: inner,
        random: math.Random(0),
        sleep: (d) async => slept.add(d),
      );

      final res = await client.get(Uri.parse('https://tile'));
      expect(res.statusCode, 200);
      expect(inner.sentCount, 3);
      expect(slept, hasLength(2));
    });

    test('retries on 429 specifically — built-in RetryClient does not',
        () async {
      final inner = _FakeClient(responses: [
        _resp(429),
        _resp(200, body: 'ok'),
      ]);
      final client = OsmRetryClient(
        inner: inner,
        sleep: (_) async {},
      );

      final res = await client.get(Uri.parse('https://tile'));
      expect(res.statusCode, 200);
      expect(inner.sentCount, 2);
    });

    test('honours Retry-After seconds header over exponential backoff',
        () async {
      final inner = _FakeClient(responses: [
        _resp(429, headers: {'retry-after': '7'}),
        _resp(200),
      ]);
      Duration? sleptFor;
      final client = OsmRetryClient(
        inner: inner,
        sleep: (d) async => sleptFor = d,
      );

      await client.get(Uri.parse('https://tile'));
      expect(sleptFor, const Duration(seconds: 7));
    });

    test('Retry-After HTTP-date — sleeps the parsed interval', () async {
      // Use a future time so parseRetryAfter produces a positive delay.
      final future = DateTime.now().toUtc().add(const Duration(seconds: 3));
      final raw = HttpDate.format(future);
      final inner = _FakeClient(responses: [
        _resp(503, headers: {'retry-after': raw}),
        _resp(200),
      ]);
      Duration? sleptFor;
      final client = OsmRetryClient(
        inner: inner,
        sleep: (d) async => sleptFor = d,
      );

      await client.get(Uri.parse('https://tile'));
      expect(sleptFor, isNotNull);
      expect(sleptFor!.inSeconds, inInclusiveRange(0, 4));
    });

    test('surfaces SocketException after exhausting retries', () async {
      final inner = _FakeClient(errors: [
        const SocketException('blip'),
        const SocketException('blip'),
        const SocketException('blip'),
      ]);
      final client = OsmRetryClient(
        inner: inner,
        maxAttempts: 3,
        sleep: (_) async {},
      );

      await expectLater(
        client.get(Uri.parse('https://tile')),
        throwsA(isA<SocketException>()),
      );
      expect(inner.sentCount, 3);
    });

    test('caps attempts at maxAttempts', () async {
      final inner = _FakeClient(responses: List.filled(10, _resp(503)));
      final client = OsmRetryClient(
        inner: inner,
        maxAttempts: 3,
        sleep: (_) async {},
      );

      final res = await client.get(Uri.parse('https://tile'));
      expect(res.statusCode, 503);
      expect(inner.sentCount, 3);
    });

    test('nextDelayForTest grows exponentially and stays non-negative',
        () {
      final client = OsmRetryClient(
        inner: _FakeClient(responses: []),
        random: math.Random(42),
        sleep: (_) async {},
      );
      final d0 = client.nextDelayForTest(0, null);
      final d1 = client.nextDelayForTest(1, null);
      final d2 = client.nextDelayForTest(2, null);
      expect(d0.inMilliseconds, greaterThanOrEqualTo(0));
      expect(d1.inMilliseconds, greaterThan(d0.inMilliseconds));
      expect(d2.inMilliseconds, greaterThan(d1.inMilliseconds));
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
  int sentCount = 0;

  _FakeClient({
    this.responses = const [],
    this.errors = const [],
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final idx = sentCount++;
    if (idx < errors.length) throw errors[idx];
    if (idx < responses.length) return responses[idx];
    throw StateError('FakeClient exhausted after $idx calls');
  }
}
