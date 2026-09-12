// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/glide_coach/data/osm_traffic_signal_client.dart';
import 'package:tankstellen/features/glide_coach/data/traffic_signal_repository.dart';
import 'package:tankstellen/features/glide_coach/domain/entities/traffic_signal.dart';

/// Hand-rolled fake of [OsmTrafficSignalClient] (#1125 phase 1).
///
/// Records every call so the cache-hit tests can assert "client was
/// only invoked once". A mocktail mock would also work but a fake
/// keeps the test free of `when(() => ...).thenAnswer(...)` boilerplate
/// for what is otherwise a one-method surface.
class _FakeOsmClient implements OsmTrafficSignalClient {
  int callCount = 0;
  List<TrafficSignal> Function() responder;
  Object? errorToThrow;

  /// #4109 — when set, the fake parks the probe on it, so a test can
  /// have a request genuinely IN FLIGHT while it makes another call.
  Completer<void>? gate;

  _FakeOsmClient({List<TrafficSignal>? response, this.errorToThrow})
      : responder = (() => response ?? const <TrafficSignal>[]);

  @override
  Future<List<TrafficSignal>> fetchInBoundingBox({
    required double south,
    required double west,
    required double north,
    required double east,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    callCount++;
    final held = gate;
    if (held != null) await held.future;
    final err = errorToThrow;
    if (err != null) throw err; // ignore: only_throw_errors
    return responder();
  }
}

void main() {
  group('TrafficSignalRepository (#1125 phase 1)', () {
    late Directory tmpDir;
    late Box<String> box;

    setUp(() async {
      tmpDir =
          Directory.systemTemp.createTempSync('traffic_signal_repo_test_');
      Hive.init(tmpDir.path);
      // Microsecond-suffixed box name avoids cross-test contamination on
      // Windows where deleteFromDisk can race the next setUp.
      box = await Hive.openBox<String>(
        'traffic_signals_${DateTime.now().microsecondsSinceEpoch}',
      );
    });

    tearDown(() async {
      await box.deleteFromDisk();
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    TrafficSignal makeSignal(String id, double lat, double lng) =>
        TrafficSignal(id: id, lat: lat, lng: lng);

    test('cacheKeyFor snaps each corner to 0.01° precision', () {
      expect(
        TrafficSignalRepository.cacheKeyFor(
          south: 43.43699,
          west: 3.43101,
          north: 43.45901,
          east: 3.45299,
        ),
        'bbox:43.44:3.43:43.46:3.45',
      );
    });

    test('miss → fetches client and caches result', () async {
      final client = _FakeOsmClient(response: [
        makeSignal('1', 43.45, 3.44),
        makeSignal('2', 43.46, 3.44),
      ]);
      final repo = TrafficSignalRepository(
        client: client,
        cacheBox: box,
      );

      final first = await repo.getSignalsForBoundingBox(
        south: 43.44,
        west: 3.43,
        north: 43.46,
        east: 3.45,
      );

      expect(first, hasLength(2));
      expect(client.callCount, 1);
      // The cache box now has one envelope under the bbox key.
      expect(box.length, 1);
    });

    test('hit within TTL returns cached value without re-calling client',
        () async {
      final client = _FakeOsmClient(response: [makeSignal('1', 43.45, 3.44)]);
      final repo = TrafficSignalRepository(
        client: client,
        cacheBox: box,
      );

      final first = await repo.getSignalsForBoundingBox(
        south: 43.44,
        west: 3.43,
        north: 43.46,
        east: 3.45,
      );
      final second = await repo.getSignalsForBoundingBox(
        south: 43.44,
        west: 3.43,
        north: 43.46,
        east: 3.45,
      );

      expect(first, hasLength(1));
      expect(second, hasLength(1));
      expect(second.single.id, '1');
      expect(client.callCount, 1, reason: 'second call should hit the cache');
    });

    test('expired entry triggers a fresh fetch', () async {
      final client = _FakeOsmClient(response: [makeSignal('a', 43.45, 3.44)]);

      // Advancing clock: first call uses t0, second uses t0 + 8 days
      // (past the 7-day TTL).
      final t0 = DateTime(2026, 5, 1, 12);
      var now = t0;
      final repo = TrafficSignalRepository(
        client: client,
        cacheBox: box,
        now: () => now,
      );

      await repo.getSignalsForBoundingBox(
        south: 43.44,
        west: 3.43,
        north: 43.46,
        east: 3.45,
      );
      expect(client.callCount, 1);

      now = t0.add(const Duration(days: 8));
      client.responder = () => [makeSignal('b', 43.45, 3.44)];

      final refreshed = await repo.getSignalsForBoundingBox(
        south: 43.44,
        west: 3.43,
        north: 43.46,
        east: 3.45,
      );
      expect(client.callCount, 2);
      expect(refreshed.single.id, 'b');
    });

    test('different bbox keys do not share cache entries', () async {
      final client = _FakeOsmClient(response: [makeSignal('x', 0, 0)]);
      final repo = TrafficSignalRepository(
        client: client,
        cacheBox: box,
      );

      await repo.getSignalsForBoundingBox(
        south: 43.44,
        west: 3.43,
        north: 43.46,
        east: 3.45,
      );
      await repo.getSignalsForBoundingBox(
        south: 48.85,
        west: 2.34,
        north: 48.87,
        east: 2.36,
      );

      expect(client.callCount, 2);
      expect(box.length, 2);
    });

    test('client errors propagate as OsmTrafficSignalException', () async {
      final client = _FakeOsmClient(
        errorToThrow: const OsmTrafficSignalException('boom'),
      );
      final repo = TrafficSignalRepository(
        client: client,
        cacheBox: box,
      );

      expect(
        () => repo.getSignalsForBoundingBox(
          south: 0,
          west: 0,
          north: 1,
          east: 1,
        ),
        throwsA(isA<OsmTrafficSignalException>()),
      );
    });

    test('corrupt cache payload falls back to a fresh fetch', () async {
      final client =
          _FakeOsmClient(response: [makeSignal('fresh', 43.45, 3.44)]);
      final repo = TrafficSignalRepository(
        client: client,
        cacheBox: box,
      );

      // Plant garbage under the bbox key.
      final key = TrafficSignalRepository.cacheKeyFor(
        south: 43.44,
        west: 3.43,
        north: 43.46,
        east: 3.45,
      );
      await box.put(key, 'not json');

      final result = await repo.getSignalsForBoundingBox(
        south: 43.44,
        west: 3.43,
        north: 43.46,
        east: 3.45,
      );

      expect(client.callCount, 1);
      expect(result.single.id, 'fresh');
    });

    test('boxName matches the constant registered in HiveBoxes', () {
      expect(TrafficSignalRepository.boxName, 'traffic_signals_cache');
    });
  });

  group('circuit breaker (#3890)', () {
    late Directory tmpDir;
    late Box<String> box;
    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('traffic_signal_breaker_');
      Hive.init(tmpDir.path);
      box = await Hive.openBox<String>('traffic_signals_breaker');
    });
    tearDown(() async {
      await box.deleteFromDisk();
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    test('a failed Overpass call opens the breaker: no redial for 5 min, '
        'then 10, then 20; a success closes it', () async {
      var now = DateTime(2026, 8, 30, 17);
      final client = _FakeOsmClient(
          errorToThrow: const OsmTrafficSignalException('refused'));
      final repo = TrafficSignalRepository(
          client: client, cacheBox: box, now: () => now);
      Future<List<TrafficSignal>> call() => repo.getSignalsForBoundingBox(
          south: 43, west: 3, north: 43.1, east: 3.1);
      await expectLater(call(), throwsA(isA<OsmTrafficSignalException>()));
      expect(client.callCount, 1);
      expect(repo.breakerHold, const Duration(minutes: 5));
      // Inside the hold: served empty, no network.
      expect(await call(), isEmpty);
      now = now.add(const Duration(minutes: 4));
      expect(await call(), isEmpty);
      expect(client.callCount, 1);
      // Hold elapsed: one probe, fails again → 10 min.
      now = now.add(const Duration(minutes: 2));
      await expectLater(call(), throwsA(isA<OsmTrafficSignalException>()));
      expect(client.callCount, 2);
      expect(repo.breakerHold, const Duration(minutes: 10));
      now = now.add(const Duration(minutes: 11));
      await expectLater(call(), throwsA(isA<OsmTrafficSignalException>()));
      expect(repo.breakerHold, const Duration(minutes: 20));
      // Recovery closes it.
      now = now.add(const Duration(minutes: 21));
      client.errorToThrow = null;
      expect(await call(), isEmpty);
      expect(repo.breakerUntil, isNull);
      expect(repo.breakerHold, Duration.zero);
    });

    test('while open, a stale cache entry is served instead of nothing',
        () async {
      var now = DateTime(2026, 8, 30, 17);
      final client = _FakeOsmClient(
          response: [const TrafficSignal(id: 's1', lat: 43.05, lng: 3.05)]);
      final repo = TrafficSignalRepository(
          client: client,
          cacheBox: box,
          ttl: const Duration(minutes: 30),
          now: () => now);
      Future<List<TrafficSignal>> call() => repo.getSignalsForBoundingBox(
          south: 43, west: 3, north: 43.1, east: 3.1);
      expect(await call(), hasLength(1));
      // Cache expired, Overpass down → the breaker opens on the failure…
      now = now.add(const Duration(hours: 1));
      client.errorToThrow = const OsmTrafficSignalException('timeout');
      await expectLater(call(), throwsA(isA<OsmTrafficSignalException>()));
      // …and the next lookups get the stale signals, not an empty road.
      expect(await call(), hasLength(1));
      expect(client.callCount, 2);
    });
  });


  group('#4109 — single flight, and 429 is not just another failure', () {
    late Directory tmpDir;
    late Box<String> box;
    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('traffic_signal_4109_');
      Hive.init(tmpDir.path);
      box = await Hive.openBox<String>('traffic_signals_4109');
    });
    tearDown(() async {
      await box.deleteFromDisk();
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    test('a second caller while a probe is in flight gets the stale answer '
        'instead of a second socket', () async {
      // The field log had three Overpass failures inside ten seconds,
      // two of them in the same second: the breaker was consulted before
      // the call and tripped after it, so a per-GPS-tick evaluator got
      // several probes past the gate before the first returned.
      final client = _FakeOsmClient(response: const [
        TrafficSignal(id: 'n1', lat: 43.05, lng: 3.05),
      ]);
      final repo = TrafficSignalRepository(client: client, cacheBox: box);
      Future<List<TrafficSignal>> call() => repo.getSignalsForBoundingBox(
          south: 43, west: 3, north: 43.1, east: 3.1);

      client.gate = Completer<void>();
      final first = call();
      await Future<void>.delayed(Duration.zero);
      expect(repo.probeInFlight, isTrue);

      // Three more callers arrive while the first is still on the wire.
      final others = await Future.wait([call(), call(), call()]);
      expect(client.callCount, 1,
          reason: 'one socket at a time — the whole point');
      expect(others, everyElement(isEmpty),
          reason: 'no cache entry yet, so they get the empty answer NOW '
              'rather than joining a 15-second wait; the caller is a '
              'per-GPS-tick evaluator that must not stall');

      client.gate!.complete();
      expect(await first, hasLength(1));
      expect(repo.probeInFlight, isFalse);
    });

    test('a burst counts as ONE failure, so the hold does not over-escalate',
        () async {
      var now = DateTime(2026, 9, 12, 16, 20);
      final client = _FakeOsmClient(
          errorToThrow: const OsmTrafficSignalException('refused'));
      final repo = TrafficSignalRepository(
          client: client, cacheBox: box, now: () => now);
      Future<List<TrafficSignal>> call() => repo.getSignalsForBoundingBox(
          south: 43, west: 3, north: 43.1, east: 3.1);

      client.gate = Completer<void>();
      final failing = call();
      await Future<void>.delayed(Duration.zero);
      final shed = await Future.wait([call(), call()]);
      client.gate!.complete();
      await expectLater(failing, throwsA(isA<OsmTrafficSignalException>()));

      expect(shed, everyElement(isEmpty));
      expect(client.callCount, 1);
      expect(repo.breakerHold, const Duration(minutes: 5),
          reason: 'one bad window is one failure — three concurrent probes '
              'used to escalate it to 20 minutes');
      now = now.add(const Duration(minutes: 1));
    });

    test('a 429 holds for the rate-limited floor, not the generic 5 minutes',
        () async {
      final now = DateTime(2026, 9, 12, 16, 20);
      final client = _FakeOsmClient(
        errorToThrow: const OsmTrafficSignalException(
          'Overpass returned HTTP 429',
          statusCode: 429,
        ),
      );
      final repo = TrafficSignalRepository(
          client: client, cacheBox: box, now: () => now);
      await expectLater(
        repo.getSignalsForBoundingBox(
            south: 43, west: 3, north: 43.1, east: 3.1),
        throwsA(isA<OsmTrafficSignalException>()),
      );

      // Overpass is donated infrastructure; a 429 is it asking to be left
      // alone, and retrying into a rate limit is how an IP earns a longer
      // one.
      expect(repo.breakerUntil,
          now.add(TrafficSignalRepository.rateLimitedHold));
    });

    test('the server\'s own Retry-After wins over both', () async {
      final now = DateTime(2026, 9, 12, 16, 20);
      final client = _FakeOsmClient(
        errorToThrow: const OsmTrafficSignalException(
          'Overpass returned HTTP 429',
          statusCode: 429,
          retryAfterHeader: '2700',
        ),
      );
      final repo = TrafficSignalRepository(
          client: client, cacheBox: box, now: () => now);
      await expectLater(
        repo.getSignalsForBoundingBox(
            south: 43, west: 3, north: 43.1, east: 3.1),
        throwsA(isA<OsmTrafficSignalException>()),
      );
      expect(repo.breakerUntil, now.add(const Duration(minutes: 45)),
          reason: 'nobody knows better than the server how long it wants '
              'to be left alone');
    });

    test('a 504 keeps the generic escalation — a bad minute is not a rate '
        'limit', () async {
      final now = DateTime(2026, 9, 12, 16, 20);
      final client = _FakeOsmClient(
        errorToThrow: const OsmTrafficSignalException(
          'Overpass returned HTTP 504',
          statusCode: 504,
        ),
      );
      final repo = TrafficSignalRepository(
          client: client, cacheBox: box, now: () => now);
      await expectLater(
        repo.getSignalsForBoundingBox(
            south: 43, west: 3, north: 43.1, east: 3.1),
        throwsA(isA<OsmTrafficSignalException>()),
      );
      expect(repo.breakerUntil, now.add(const Duration(minutes: 5)));
    });
  });

  group('#4109 — Retry-After parsing', () {
    final now = DateTime.utc(2026, 9, 12, 16, 20);

    test('delta seconds', () {
      expect(parseRetryAfter('120', now: now), const Duration(seconds: 120));
    });

    test('an HTTP date in the future', () {
      expect(parseRetryAfter(HttpDate.format(now.add(const Duration(minutes: 3))),
              now: now),
          const Duration(minutes: 3));
    });

    test('a date already in the past is no hold at all', () {
      expect(
          parseRetryAfter(
              HttpDate.format(now.subtract(const Duration(minutes: 3))),
              now: now),
          isNull);
    });

    test('garbage, empty and null never take the caller down', () {
      for (final raw in [null, '', '   ', 'soon', '-5', '0']) {
        expect(parseRetryAfter(raw, now: now), isNull, reason: 'raw: $raw');
      }
    });
  });

}
