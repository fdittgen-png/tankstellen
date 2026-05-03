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
    final err = errorToThrow;
    if (err != null) throw err;
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

    test('kGlideCoachEnabled remains false (placeholder feature flag)', () {
      expect(kGlideCoachEnabled, isFalse);
    });

    test('boxName matches the constant registered in HiveBoxes', () {
      expect(TrafficSignalRepository.boxName, 'traffic_signals_cache');
    });
  });
}
