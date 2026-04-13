import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';

/// HiveStorage tests use real Hive boxes initialized with a temp directory.
/// This avoids mocking Hive internals and tests actual read/write behavior.
void main() {
  late HiveStorage storage;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_storage_test_');
    Hive.init(tempDir.path);
    await HiveStorage.initForTest();
    storage = HiveStorage();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // ---------------------------------------------------------------------------
  // Favorites
  // ---------------------------------------------------------------------------
  group('Favorites', () {
    test('getFavoriteIds returns empty list initially', () {
      expect(storage.getFavoriteIds(), isEmpty);
    });

    test('addFavorite adds a station id', () async {
      await storage.addFavorite('station-1');
      expect(storage.getFavoriteIds(), ['station-1']);
    });

    test('addFavorite does not add duplicate', () async {
      await storage.addFavorite('station-1');
      await storage.addFavorite('station-1');
      expect(storage.getFavoriteIds(), ['station-1']);
    });

    test('addFavorite adds multiple distinct ids', () async {
      await storage.addFavorite('station-1');
      await storage.addFavorite('station-2');
      await storage.addFavorite('station-3');
      expect(storage.getFavoriteIds(), ['station-1', 'station-2', 'station-3']);
    });

    test('removeFavorite removes a station id', () async {
      await storage.addFavorite('station-1');
      await storage.addFavorite('station-2');
      await storage.removeFavorite('station-1');
      expect(storage.getFavoriteIds(), ['station-2']);
    });

    test('removeFavorite is a no-op for non-existent id', () async {
      await storage.addFavorite('station-1');
      await storage.removeFavorite('non-existent');
      expect(storage.getFavoriteIds(), ['station-1']);
    });

    test('isFavorite returns true for added station', () async {
      await storage.addFavorite('station-1');
      expect(storage.isFavorite('station-1'), isTrue);
    });

    test('isFavorite returns false for unknown station', () {
      expect(storage.isFavorite('unknown'), isFalse);
    });

    test('setFavoriteIds replaces entire list', () async {
      await storage.addFavorite('station-1');
      await storage.setFavoriteIds(['a', 'b', 'c']);
      expect(storage.getFavoriteIds(), ['a', 'b', 'c']);
    });

    test('favoriteCount reflects number of favorites', () async {
      expect(storage.favoriteCount, 0);
      await storage.addFavorite('station-1');
      await storage.addFavorite('station-2');
      expect(storage.favoriteCount, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // Ignored Stations
  // ---------------------------------------------------------------------------
  group('Ignored Stations', () {
    test('getIgnoredIds returns empty list initially', () {
      expect(storage.getIgnoredIds(), isEmpty);
    });

    test('addIgnored adds a station id', () async {
      await storage.addIgnored('station-1');
      expect(storage.getIgnoredIds(), ['station-1']);
    });

    test('addIgnored does not add duplicate', () async {
      await storage.addIgnored('station-1');
      await storage.addIgnored('station-1');
      expect(storage.getIgnoredIds(), ['station-1']);
    });

    test('removeIgnored removes a station id', () async {
      await storage.addIgnored('station-1');
      await storage.addIgnored('station-2');
      await storage.removeIgnored('station-1');
      expect(storage.getIgnoredIds(), ['station-2']);
    });

    test('removeIgnored is a no-op for non-existent id', () async {
      await storage.addIgnored('station-1');
      await storage.removeIgnored('non-existent');
      expect(storage.getIgnoredIds(), ['station-1']);
    });

    test('isIgnored returns true for ignored station', () async {
      await storage.addIgnored('station-1');
      expect(storage.isIgnored('station-1'), isTrue);
    });

    test('isIgnored returns false for non-ignored station', () {
      expect(storage.isIgnored('unknown'), isFalse);
    });

    test('setIgnoredIds replaces entire list', () async {
      await storage.addIgnored('station-1');
      await storage.setIgnoredIds(['x', 'y']);
      expect(storage.getIgnoredIds(), ['x', 'y']);
    });
  });

  // ---------------------------------------------------------------------------
  // Ratings
  // ---------------------------------------------------------------------------
  group('Ratings', () {
    test('getRatings returns empty map initially', () {
      expect(storage.getRatings(), isEmpty);
    });

    test('setRating stores a rating', () async {
      await storage.setRating('station-1', 4);
      expect(storage.getRatings(), {'station-1': 4});
    });

    test('setRating overwrites existing rating', () async {
      await storage.setRating('station-1', 3);
      await storage.setRating('station-1', 5);
      expect(storage.getRating('station-1'), 5);
    });

    test('setRating stores multiple ratings', () async {
      await storage.setRating('station-1', 3);
      await storage.setRating('station-2', 5);
      expect(storage.getRatings(), {'station-1': 3, 'station-2': 5});
    });

    test('removeRating removes a rating', () async {
      await storage.setRating('station-1', 4);
      await storage.setRating('station-2', 5);
      await storage.removeRating('station-1');
      expect(storage.getRatings(), {'station-2': 5});
    });

    test('removeRating is a no-op for non-existent station', () async {
      await storage.setRating('station-1', 4);
      await storage.removeRating('non-existent');
      expect(storage.getRatings(), {'station-1': 4});
    });

    test('getRating returns null for unknown station', () {
      expect(storage.getRating('unknown'), isNull);
    });

    test('getRating returns stored value', () async {
      await storage.setRating('station-1', 3);
      expect(storage.getRating('station-1'), 3);
    });
  });

  // ---------------------------------------------------------------------------
  // Cache
  // ---------------------------------------------------------------------------
  group('Cache', () {
    test('getCachedData returns null for missing key', () {
      expect(storage.getCachedData('missing'), isNull);
    });

    test('cacheData and getCachedData round-trip a map', () async {
      await storage.cacheData('key-1', {'name': 'Test', 'value': 42});
      final result = storage.getCachedData('key-1');
      expect(result, isNotNull);
      expect(result!['name'], 'Test');
      expect(result['value'], 42);
    });

    test('getCachedData returns null when maxAge is exceeded', () async {
      // Manually insert an entry with old timestamp
      final box = Hive.box('cache');
      box.put('old-key', {
        'data': {'hello': 'world'},
        'timestamp': DateTime.now()
            .subtract(const Duration(hours: 2))
            .millisecondsSinceEpoch,
      });
      final result = storage.getCachedData(
        'old-key',
        maxAge: const Duration(hours: 1),
      );
      expect(result, isNull);
    });

    test('getCachedData returns data when within maxAge', () async {
      await storage.cacheData('fresh-key', {'hello': 'world'});
      final result = storage.getCachedData(
        'fresh-key',
        maxAge: const Duration(hours: 1),
      );
      expect(result, isNotNull);
      expect(result!['hello'], 'world');
    });

    test('getCachedData without maxAge ignores age', () async {
      final box = Hive.box('cache');
      box.put('ancient-key', {
        'data': {'old': true},
        'timestamp': 0, // epoch start
      });
      final result = storage.getCachedData('ancient-key');
      expect(result, isNotNull);
      expect(result!['old'], true);
    });

    test('getCachedData returns null when data is not a Map', () async {
      // cacheData wraps in {data: ..., timestamp: ...}
      // If someone stored a non-map as 'data', getCachedData should return null
      final box = Hive.box('cache');
      box.put('string-data', {
        'data': 'just a string',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      final result = storage.getCachedData('string-data');
      expect(result, isNull);
    });

    test('clearCache removes all cache entries', () async {
      await storage.cacheData('key-1', {'a': 1});
      await storage.cacheData('key-2', {'b': 2});
      expect(storage.cacheEntryCount, 2);
      await storage.clearCache();
      expect(storage.cacheEntryCount, 0);
      expect(storage.getCachedData('key-1'), isNull);
    });

    test('cacheKeys returns all stored keys', () async {
      await storage.cacheData('alpha', {'x': 1});
      await storage.cacheData('beta', {'y': 2});
      expect(storage.cacheKeys, containsAll(['alpha', 'beta']));
    });

    test('deleteCacheEntry removes a single entry', () async {
      await storage.cacheData('keep', {'x': 1});
      await storage.cacheData('remove', {'y': 2});
      await storage.deleteCacheEntry('remove');
      expect(storage.getCachedData('keep'), isNotNull);
      expect(storage.getCachedData('remove'), isNull);
      expect(storage.cacheEntryCount, 1);
    });

    test('cacheEntryCount reflects number of entries', () async {
      expect(storage.cacheEntryCount, 0);
      await storage.cacheData('a', {'v': 1});
      expect(storage.cacheEntryCount, 1);
      await storage.cacheData('b', {'v': 2});
      expect(storage.cacheEntryCount, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------
  group('Settings', () {
    test('getSetting returns null for unset key', () {
      expect(storage.getSetting('nonexistent'), isNull);
    });

    test('putSetting and getSetting round-trip a value', () async {
      await storage.putSetting('theme', 'dark');
      expect(storage.getSetting('theme'), 'dark');
    });

    test('putSetting overwrites existing value', () async {
      await storage.putSetting('count', 1);
      await storage.putSetting('count', 2);
      expect(storage.getSetting('count'), 2);
    });

    test('isSetupSkipped returns false initially', () {
      expect(storage.isSetupSkipped, isFalse);
    });

    test('skipSetup sets isSetupSkipped to true', () async {
      await storage.skipSetup();
      expect(storage.isSetupSkipped, isTrue);
    });

    test('resetSetupSkip clears setup skip flag', () async {
      await storage.skipSetup();
      await storage.resetSetupSkip();
      expect(storage.isSetupSkipped, isFalse);
    });

    test('isSetupComplete returns true when setup is skipped', () async {
      await storage.skipSetup();
      expect(storage.isSetupComplete, isTrue);
    });

    test('isSetupComplete returns false with no api key and no skip', () {
      // API key cache is null by default and setup not skipped
      expect(storage.isSetupComplete, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Profiles
  // ---------------------------------------------------------------------------
  group('Profiles', () {
    test('getActiveProfileId returns null initially', () {
      expect(storage.getActiveProfileId(), isNull);
    });

    test('setActiveProfileId and getActiveProfileId round-trip', () async {
      await storage.setActiveProfileId('profile-1');
      expect(storage.getActiveProfileId(), 'profile-1');
    });

    test('getProfile returns null for unknown id', () {
      expect(storage.getProfile('unknown'), isNull);
    });

    test('saveProfile and getProfile round-trip', () async {
      final profile = {'name': 'Default', 'country': 'DE', 'radius': 10};
      await storage.saveProfile('p1', profile);
      final result = storage.getProfile('p1');
      expect(result, isNotNull);
      expect(result!['name'], 'Default');
      expect(result['country'], 'DE');
      expect(result['radius'], 10);
    });

    test('getAllProfiles returns all saved profiles', () async {
      await storage.saveProfile('p1', {'name': 'A'});
      await storage.saveProfile('p2', {'name': 'B'});
      final profiles = storage.getAllProfiles();
      expect(profiles.length, 2);
      final names = profiles.map((p) => p['name']).toSet();
      expect(names, {'A', 'B'});
    });

    test('getAllProfiles returns empty list when no profiles', () {
      expect(storage.getAllProfiles(), isEmpty);
    });

    test('deleteProfile removes a profile', () async {
      await storage.saveProfile('p1', {'name': 'A'});
      await storage.saveProfile('p2', {'name': 'B'});
      await storage.deleteProfile('p1');
      expect(storage.getProfile('p1'), isNull);
      expect(storage.getProfile('p2'), isNotNull);
    });

    test('saveProfile overwrites existing profile', () async {
      await storage.saveProfile('p1', {'name': 'Old'});
      await storage.saveProfile('p1', {'name': 'New'});
      expect(storage.getProfile('p1')!['name'], 'New');
    });

    test('profileCount reflects number of profiles', () async {
      expect(storage.profileCount, 0);
      await storage.saveProfile('p1', {'name': 'A'});
      expect(storage.profileCount, 1);
      await storage.saveProfile('p2', {'name': 'B'});
      expect(storage.profileCount, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // Price History
  // ---------------------------------------------------------------------------
  group('Price History', () {
    test('getPriceRecords returns empty list for unknown station', () {
      expect(storage.getPriceRecords('unknown'), isEmpty);
    });

    test('savePriceRecords and getPriceRecords round-trip', () async {
      final records = [
        {'date': '2025-01-01', 'price': 1.45, 'fuel': 'e10'},
        {'date': '2025-01-02', 'price': 1.50, 'fuel': 'e10'},
      ];
      await storage.savePriceRecords('station-1', records);
      final result = storage.getPriceRecords('station-1');
      expect(result.length, 2);
      expect(result[0]['price'], 1.45);
      expect(result[1]['date'], '2025-01-02');
    });

    test('getPriceHistoryKeys returns all station ids with history', () async {
      await storage.savePriceRecords('station-1', [{'price': 1.0}]);
      await storage.savePriceRecords('station-2', [{'price': 2.0}]);
      final keys = storage.getPriceHistoryKeys();
      expect(keys, containsAll(['station-1', 'station-2']));
    });

    test('getPriceHistoryKeys returns empty list when no history', () {
      expect(storage.getPriceHistoryKeys(), isEmpty);
    });

    test('clearPriceHistoryForStation removes one station', () async {
      await storage.savePriceRecords('station-1', [{'price': 1.0}]);
      await storage.savePriceRecords('station-2', [{'price': 2.0}]);
      await storage.clearPriceHistoryForStation('station-1');
      expect(storage.getPriceRecords('station-1'), isEmpty);
      expect(storage.getPriceRecords('station-2'), isNotEmpty);
    });

    test('clearPriceHistory removes all history', () async {
      await storage.savePriceRecords('station-1', [{'price': 1.0}]);
      await storage.savePriceRecords('station-2', [{'price': 2.0}]);
      await storage.clearPriceHistory();
      expect(storage.getPriceHistoryKeys(), isEmpty);
      expect(storage.priceHistoryEntryCount, 0);
    });

    test('priceHistoryEntryCount reflects number of stations', () async {
      expect(storage.priceHistoryEntryCount, 0);
      await storage.savePriceRecords('station-1', [{'price': 1.0}]);
      expect(storage.priceHistoryEntryCount, 1);
      await storage.savePriceRecords('station-2', [{'price': 2.0}]);
      expect(storage.priceHistoryEntryCount, 2);
    });

    test('savePriceRecords overwrites existing records', () async {
      await storage.savePriceRecords('station-1', [{'price': 1.0}]);
      await storage.savePriceRecords('station-1', [{'price': 2.0}, {'price': 3.0}]);
      final result = storage.getPriceRecords('station-1');
      expect(result.length, 2);
      expect(result[0]['price'], 2.0);
    });
  });

  // ---------------------------------------------------------------------------
  // Alerts
  // ---------------------------------------------------------------------------
  group('Alerts', () {
    test('getAlerts returns empty list initially', () {
      expect(storage.getAlerts(), isEmpty);
    });

    test('saveAlerts and getAlerts round-trip', () async {
      final alerts = [
        {'stationId': 'st-1', 'targetPrice': 1.40, 'active': true},
        {'stationId': 'st-2', 'targetPrice': 1.30, 'active': false},
      ];
      await storage.saveAlerts(alerts);
      final result = storage.getAlerts();
      expect(result.length, 2);
      expect(result[0]['stationId'], 'st-1');
      expect(result[1]['targetPrice'], 1.30);
    });

    test('clearAlerts removes all alerts', () async {
      await storage.saveAlerts([
        {'stationId': 'st-1', 'targetPrice': 1.40},
      ]);
      await storage.clearAlerts();
      expect(storage.getAlerts(), isEmpty);
    });

    test('alertCount returns number of alerts', () async {
      expect(storage.alertCount, 0);
      await storage.saveAlerts([
        {'stationId': 'st-1', 'targetPrice': 1.40},
        {'stationId': 'st-2', 'targetPrice': 1.30},
      ]);
      expect(storage.alertCount, 2);
    });

    test('saveAlerts overwrites previous alerts', () async {
      await storage.saveAlerts([{'stationId': 'st-1'}]);
      await storage.saveAlerts([{'stationId': 'st-2'}, {'stationId': 'st-3'}]);
      expect(storage.alertCount, 2);
      expect(storage.getAlerts()[0]['stationId'], 'st-2');
    });
  });

  // ---------------------------------------------------------------------------
  // Itineraries
  // ---------------------------------------------------------------------------
  group('Itineraries', () {
    test('getItineraries returns empty list initially', () {
      expect(storage.getItineraries(), isEmpty);
    });

    test('saveItineraries and getItineraries round-trip', () async {
      final itineraries = [
        {'id': 'it-1', 'name': 'Home to Work'},
        {'id': 'it-2', 'name': 'Weekend Trip'},
      ];
      await storage.saveItineraries(itineraries);
      final result = storage.getItineraries();
      expect(result.length, 2);
      expect(result[0]['name'], 'Home to Work');
    });

    test('addItinerary inserts at beginning', () async {
      await storage.addItinerary({'id': 'it-1', 'name': 'First'});
      await storage.addItinerary({'id': 'it-2', 'name': 'Second'});
      final result = storage.getItineraries();
      expect(result.length, 2);
      // Second inserted at index 0
      expect(result[0]['name'], 'Second');
      expect(result[1]['name'], 'First');
    });

    test('addItinerary replaces existing by id', () async {
      await storage.addItinerary({'id': 'it-1', 'name': 'Original'});
      await storage.addItinerary({'id': 'it-1', 'name': 'Updated'});
      final result = storage.getItineraries();
      expect(result.length, 1);
      expect(result[0]['name'], 'Updated');
    });

    test('deleteItinerary removes by id', () async {
      await storage.addItinerary({'id': 'it-1', 'name': 'Keep'});
      await storage.addItinerary({'id': 'it-2', 'name': 'Remove'});
      await storage.deleteItinerary('it-2');
      final result = storage.getItineraries();
      expect(result.length, 1);
      expect(result[0]['name'], 'Keep');
    });

    test('deleteItinerary is a no-op for non-existent id', () async {
      await storage.addItinerary({'id': 'it-1', 'name': 'Only'});
      await storage.deleteItinerary('non-existent');
      expect(storage.getItineraries().length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // Isolate Box Lifecycle
  // ---------------------------------------------------------------------------
  group('Isolate Box Lifecycle', () {
    test('closeIsolateBoxes closes all open boxes without error', () async {
      // Boxes are already open from setUp via initForTest
      await HiveStorage.closeIsolateBoxes();

      // After closing, boxes should not be accessible
      // Re-open for other tests in tearDown
      expect(Hive.isBoxOpen('settings'), isFalse);
      expect(Hive.isBoxOpen('favorites'), isFalse);
      expect(Hive.isBoxOpen('alerts'), isFalse);
      expect(Hive.isBoxOpen('cache'), isFalse);
      expect(Hive.isBoxOpen('price_history'), isFalse);

      // Re-open boxes so tearDown (Hive.close()) works cleanly
      await HiveStorage.initForTest();
    });

    test('closeIsolateBoxes is safe to call when boxes are already closed', () async {
      await HiveStorage.closeIsolateBoxes();

      // Calling again should not throw
      await HiveStorage.closeIsolateBoxes();

      // Re-open for other tests
      await HiveStorage.initForTest();
    });

    test('closeIsolateBoxes does not close profiles box', () async {
      // profiles box is only opened by main isolate init, not initInIsolate
      // closeIsolateBoxes should only close the 5 boxes that initInIsolate opens
      await HiveStorage.closeIsolateBoxes();

      // profiles box should still be open (it was opened by initForTest)
      expect(Hive.isBoxOpen('profiles'), isTrue);

      // Re-open for other tests
      await HiveStorage.initForTest();
    });
  });

  // ---------------------------------------------------------------------------
  // API Key (in-memory cache only — cannot test secure storage in unit tests)
  // ---------------------------------------------------------------------------
  group('API Key (in-memory)', () {
    test('getApiKey returns null by default', () {
      expect(storage.getApiKey(), isNull);
    });

    test('hasApiKey returns false when no key set', () {
      expect(storage.hasApiKey(), isFalse);
    });

    test('hasEvApiKey returns true (default key always available)', () {
      expect(storage.hasEvApiKey(), isTrue);
    });

    test('getEvApiKey returns default key when no custom key set', () {
      expect(storage.getEvApiKey(), isNotNull);
      expect(storage.getEvApiKey(), isNotEmpty);
    });

    test('hasCustomEvApiKey returns false when no custom key set', () {
      expect(storage.hasCustomEvApiKey(), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Storage Statistics
  // ---------------------------------------------------------------------------
  group('Storage Statistics', () {
    test('storageStats reports on-disk size for every populated box', () async {
      // Write something to every box so each `.hive` file exists on disk.
      // (Hive doesn't create the file until the first write.)
      await storage.putSetting('seed', 'value');
      await storage.saveProfile('p1', {'name': 'A'});
      await storage.addFavorite('station-1');
      await storage.cacheData('key-1', {'data': 'value'});
      await storage.savePriceRecords('st-1', [{'price': 1.0}]);
      await storage.saveAlerts([
        {'stationId': 'st-1', 'fuelType': 'e10', 'threshold': 1.7},
      ]);

      final stats = storage.storageStats;
      expect(stats.settings, greaterThan(0));
      expect(stats.profiles, greaterThan(0));
      expect(stats.favorites, greaterThan(0));
      expect(stats.cache, greaterThan(0));
      expect(stats.priceHistory, greaterThan(0));
      expect(stats.alerts, greaterThan(0));
      expect(stats.total, greaterThan(0));
    });

    test('storageStats grows after writing data to a box', () async {
      final beforeProfiles = storage.storageStats.profiles;
      final beforeCache = storage.storageStats.cache;

      // Write a profile + a cache entry with non-trivial payloads so the
      // file growth is comfortably larger than the test tolerance.
      await storage.saveProfile('p1', {
        'name': 'Test Profile',
        'description': 'a' * 1000,
      });
      await storage.cacheData('key-1', {'payload': 'x' * 4096});

      // Hive flushes lazily on some platforms; force one tick.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final after = storage.storageStats;
      expect(after.profiles, greaterThan(beforeProfiles),
          reason: 'profiles file should grow after saveProfile');
      expect(after.cache, greaterThan(beforeCache),
          reason: 'cache file should grow after cacheData');
    });

    test('storageStats.total equals the sum of every box', () {
      final stats = storage.storageStats;
      expect(
        stats.total,
        stats.settings + stats.profiles + stats.favorites +
            stats.cache + stats.priceHistory + stats.alerts,
      );
    });

    // Regression for issue #427: the old implementation multiplied
    // `box.length` by a hardcoded constant, so the reported value diverged
    // wildly from the real file size as compaction kicked in. With the
    // real-bytes implementation the reported value should track
    // `File(box.path).lengthSync()` to within rounding.
    test('storageStats matches File.lengthSync of the underlying box', () {
      final cacheBox = Hive.box('cache');
      final cachePath = cacheBox.path;
      expect(cachePath, isNotNull,
          reason: 'native Hive box should expose a path');
      final fileSize = File(cachePath!).lengthSync();
      final reported = storage.storageStats.cache;
      expect(reported, equals(fileSize));
    });

    test('cacheEntryCount is zero initially', () {
      expect(storage.cacheEntryCount, 0);
    });

    test('profileCount is zero initially', () {
      expect(storage.profileCount, 0);
    });

    test('favoriteCount is zero initially', () {
      expect(storage.favoriteCount, 0);
    });
  });
}
