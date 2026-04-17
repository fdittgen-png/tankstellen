import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/stores/cache_hive_store.dart';

void main() {
  late CacheHiveStore store;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cache_store_test_');
    Hive.init(tempDir.path);
    await HiveStorage.initForTest();
    store = CacheHiveStore();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('CacheHiveStore — cache', () {
    test('empty box returns null, zero count, empty keys', () {
      expect(store.getCachedData('missing'), isNull);
      expect(store.cacheEntryCount, 0);
      expect(store.cacheKeys, isEmpty);
    });

    test('cacheData + getCachedData round-trips a map payload',
        () async {
      await store.cacheData('k1', {'hello': 'world', 'n': 42});
      final round = store.getCachedData('k1');
      expect(round, isNotNull);
      expect(round!['hello'], 'world');
      expect(round['n'], 42);
      expect(store.cacheEntryCount, 1);
    });

    test('maxAge returns null when entry is older than the window',
        () async {
      await store.cacheData('k1', {'x': 1});
      // Wait a tiny bit; older than zero-duration is always true.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(store.getCachedData('k1', maxAge: Duration.zero), isNull);
    });

    test('maxAge returns the entry when within the window', () async {
      await store.cacheData('k1', {'x': 1});
      expect(
        store.getCachedData('k1', maxAge: const Duration(minutes: 5)),
        isNotNull,
      );
    });

    test('cacheData overwrites an existing key with a fresh timestamp',
        () async {
      await store.cacheData('k1', {'v': 1});
      await store.cacheData('k1', {'v': 2});
      expect(store.getCachedData('k1')!['v'], 2);
      expect(store.cacheEntryCount, 1);
    });

    test('deleteCacheEntry removes only the target key', () async {
      await store.cacheData('a', {'x': 1});
      await store.cacheData('b', {'x': 2});
      await store.deleteCacheEntry('a');
      expect(store.getCachedData('a'), isNull);
      expect(store.getCachedData('b'), isNotNull);
    });

    test('clearCache wipes every entry', () async {
      await store.cacheData('a', {'x': 1});
      await store.cacheData('b', {'x': 2});
      await store.clearCache();
      expect(store.cacheEntryCount, 0);
      expect(store.cacheKeys, isEmpty);
    });

    test('non-map stored values round-trip as null (the store only '
        'returns Map<String, dynamic> data)', () async {
      // A legacy caller might have stuffed a list or a String in;
      // the contract is to defensively return null instead of
      // crashing.
      await store.cacheData('list', [1, 2, 3]);
      expect(store.getCachedData('list'), isNull);
    });
  });

  group('CacheHiveStore — itineraries', () {
    test('empty itinerary list', () {
      expect(store.getItineraries(), isEmpty);
    });

    test('saveItineraries persists the list', () async {
      await store.saveItineraries([
        {'id': 'i1', 'name': 'Summer trip'},
        {'id': 'i2', 'name': 'Commute'},
      ]);
      final round = store.getItineraries();
      expect(round, hasLength(2));
      expect(round[0]['name'], 'Summer trip');
    });

    test('addItinerary inserts a new itinerary at the top', () async {
      await store.saveItineraries([
        {'id': 'existing', 'name': 'Old'},
      ]);
      await store.addItinerary({'id': 'new', 'name': 'Fresh'});
      final round = store.getItineraries();
      expect(round.first['id'], 'new');
      expect(round.last['id'], 'existing');
    });

    test('addItinerary updates in place when the id matches',
        () async {
      await store.saveItineraries([
        {'id': 'i1', 'name': 'Original'},
      ]);
      await store.addItinerary({'id': 'i1', 'name': 'Renamed'});
      final round = store.getItineraries();
      expect(round, hasLength(1));
      expect(round.first['name'], 'Renamed');
    });

    test('deleteItinerary removes the matching id', () async {
      await store.saveItineraries([
        {'id': 'i1', 'name': 'A'},
        {'id': 'i2', 'name': 'B'},
      ]);
      await store.deleteItinerary('i1');
      final round = store.getItineraries();
      expect(round, hasLength(1));
      expect(round.first['id'], 'i2');
    });

    test('deleteItinerary on an unknown id is a no-op', () async {
      await store.saveItineraries([
        {'id': 'i1', 'name': 'A'},
      ]);
      await store.deleteItinerary('missing');
      expect(store.getItineraries(), hasLength(1));
    });
  });
}
