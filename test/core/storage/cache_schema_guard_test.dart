// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #2922 — the station cache served stale/corrupt data (phantom "Super U"
// brand, truncated far-only result sets, missing prices) until the user
// manually cleared app data. Root cause: `Station.openingHours` changed its
// JSON shape (#2722 excluded -> #2776/#2777 serialized) but
// HiveBoxes.currentSchemaVersion was never bumped, so old-format cached Station
// blobs persisted across the upgrade and kept being served.
//
// This file pins two guarantees so the bug cannot silently recur:
//
//   1. SCHEMA GUARD — the set of serialized keys in a cached Station is
//      pinned to currentSchemaVersion. Any future change to the Station cache
//      serialization (add/remove/rename a key) WITHOUT bumping
//      currentSchemaVersion fails this test, forcing the bump + eviction.
//
//   2. OLD-FORMAT EVICTION — an old-format cached blob (no `openingHours`
//      key, stamped at the OLD schema version) is evicted on the version bump
//      and so reads back as a cache miss (triggers a fresh fetch), while the
//      user's saved `itineraries` (and every other user-data box) survive.
//      RED before the eviction logic existed, green after.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/services/station_service_chain_codec.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

void main() {
  // ---------------------------------------------------------------------------
  // 1. SCHEMA GUARD — cached-Station key signature pinned to the schema version.
  // ---------------------------------------------------------------------------
  group('cached-Station schema guard (#2922)', () {
    // The serialized key set of a cached Station AT each schema version. The
    // entry for currentSchemaVersion must match the live Station.toJson() key
    // set. When you change the Station cache serialization you MUST:
    //   (a) bump HiveBoxes.currentSchemaVersion,
    //   (b) add the new key set under the new version here,
    //   (c) add the matching eviction step in HiveSchemaMigration.
    const keySignatureByVersion = <int, Set<String>>{
      // v2 (#2776/#2777): openingHours now serialized.
      2: {
        'id',
        'name',
        'brand',
        'street',
        'houseNumber',
        'postCode',
        'place',
        'lat',
        'lng',
        'dist',
        'e5',
        'e10',
        'e98',
        'diesel',
        'dieselPremium',
        'e85',
        'lpg',
        'cng',
        'isOpen',
        'updatedAt',
        'openingHoursText',
        'openingHours',
        'is24h',
        'services',
        'availableFuels',
        'unavailableFuels',
        'stationType',
        'department',
        'region',
        'amenities',
      },
    };

    test('currentSchemaVersion has a pinned cached-Station key signature', () {
      expect(
        keySignatureByVersion.containsKey(HiveBoxes.currentSchemaVersion),
        isTrue,
        reason:
            'No pinned cached-Station key signature for schema version '
            '${HiveBoxes.currentSchemaVersion}. When you bump '
            'currentSchemaVersion, add the new version key set to '
            'keySignatureByVersion in this test and the matching eviction step '
            'in HiveSchemaMigration.',
      );
    });

    test('the live Station cache serialization matches the pinned signature '
        'for the current schema version — a change without a version bump '
        'FAILS', () {
      // Build a fully-populated Station so every nullable field also serializes
      // its key (json_serializable emits all keys regardless of value).
      const station = Station(
        id: 's1',
        name: 'Test',
        brand: 'TotalEnergies',
        street: 'Rue Test',
        houseNumber: '12',
        postCode: '75001',
        place: 'Paris',
        lat: 48.8,
        lng: 2.3,
        dist: 1.2,
        e5: 1.8,
        e10: 1.7,
        e98: 1.9,
        diesel: 1.6,
        dieselPremium: 1.65,
        e85: 0.9,
        lpg: 0.8,
        cng: 1.1,
        isOpen: true,
        updatedAt: '2026-06-05T00:00:00Z',
        openingHoursText: 'Lun 07:00-18:30',
        is24h: false,
        services: ['shop'],
        availableFuels: ['e10'],
        unavailableFuels: ['e5'],
        stationType: 'R',
        department: '75',
        region: 'IDF',
      );

      // Drive the REAL cache codec (serializeStationList) — the exact path
      // StationServiceChain persists a search list through.
      final envelope = serializeStationList([station]);
      final cachedStationJson =
          (envelope['stations'] as List).single as Map<String, dynamic>;
      final liveKeys = cachedStationJson.keys.toSet();

      final pinned = keySignatureByVersion[HiveBoxes.currentSchemaVersion]!;

      expect(
        liveKeys,
        equals(pinned),
        reason:
            'The cached-Station JSON key set changed but '
            'HiveBoxes.currentSchemaVersion (${HiveBoxes.currentSchemaVersion}) '
            'was not bumped. A serialization change without a schema-version '
            'bump is exactly the #2922 data regression: old-format cached '
            'Station blobs would keep being served. Bump currentSchemaVersion, '
            'add the eviction step, and update the pinned signature.\n'
            'Added keys:   ${liveKeys.difference(pinned)}\n'
            'Removed keys: ${pinned.difference(liveKeys)}',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 2. OLD-FORMAT EVICTION — version bump evicts stale cache, spares user data.
  // ---------------------------------------------------------------------------
  group('old-format cache eviction on schema-version bump (#2922)', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('cache_evict_test');
      Hive.init(tmp.path);
      await Hive.openBox(HiveBoxes.cache);
      await Hive.openBox<int>(HiveBoxes.boxSchema);
      // The other encrypted-box stamps the migration loop touches.
      await Hive.openBox(HiveBoxes.settings);
      await Hive.openBox(HiveBoxes.favorites);
      await Hive.openBox(HiveBoxes.profiles);
      await Hive.openBox(HiveBoxes.priceHistory);
      await Hive.openBox(HiveBoxes.alerts);
    });

    tearDown(() async {
      await Hive.close();
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });

    test('an OLD-format cached search blob stamped at the old version is '
        'evicted (reads as a miss) after the bump, while saved itineraries '
        'and other user data survive', () async {
      final cacheBox = Hive.box(HiveBoxes.cache);
      final schema = Hive.box<int>(HiveBoxes.boxSchema);

      // Pre-#2922 on-disk state: the cache stamped at the OLD schema version,
      // holding an old-format Station blob (no `openingHours` key) under a
      // real network-cache key, plus the user's saved itineraries.
      const oldVersion = 1;
      await schema.put(HiveBoxes.cache, oldVersion);
      // Stamp the other domain boxes at the old version too (realistic).
      for (final box in [
        HiveBoxes.settings,
        HiveBoxes.favorites,
        HiveBoxes.profiles,
        HiveBoxes.priceHistory,
        HiveBoxes.alerts,
      ]) {
        await schema.put(box, oldVersion);
      }

      const searchKey = 'search:FR:48.800:2.300:5.0:e10';
      await cacheBox.put(searchKey, {
        'data': {
          'payload': {
            'stations': [
              // Old-format Station: NO `openingHours` key.
              {
                'id': 's1',
                'name': 'Old',
                'brand': 'Super U', // the phantom brand that persisted
                'street': 'Rue X',
                'postCode': '75001',
                'place': 'Paris',
                'lat': 48.8,
                'lng': 2.3,
                'isOpen': true,
              }
            ],
          },
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // User data co-resident in the SAME cache box — MUST survive.
      await cacheBox.put('itineraries', [
        {'id': 'i1', 'name': 'Summer trip'},
      ]);
      // User data in OTHER boxes — MUST survive.
      final favorites = Hive.box(HiveBoxes.favorites);
      await favorites.put('fav1', {'id': 'station-7'});
      final settings = Hive.box(HiveBoxes.settings);
      await settings.put('theme', 'dark');
      final profiles = Hive.box(HiveBoxes.profiles);
      await profiles.put('p1', {'name': 'Me'});

      // Run the migration the same way init() does.
      await HiveBoxes.ensureSchemaVersionsForTest();

      // The stale network-cache entry is evicted → reads as a cache MISS,
      // forcing a fresh fetch (this is RED before the eviction logic).
      expect(cacheBox.get(searchKey), isNull,
          reason: 'old-format cached search blob must be evicted on the bump');

      // The cache box is re-stamped at the current version.
      expect(schema.get(HiveBoxes.cache), HiveBoxes.currentSchemaVersion);

      // SAFETY — user data survives the eviction.
      expect(cacheBox.get('itineraries'), isNotNull,
          reason: 'saved itineraries must NEVER be cleared by the eviction');
      expect((cacheBox.get('itineraries') as List).single['name'],
          'Summer trip');
      expect(favorites.get('fav1'), isNotNull, reason: 'favorites must survive');
      expect(settings.get('theme'), 'dark', reason: 'settings must survive');
      expect(profiles.get('p1'), isNotNull, reason: 'profiles must survive');
    });

    test('a fresh install (no stamps) is stamped at the current version and '
        'evicts nothing', () async {
      final cacheBox = Hive.box(HiveBoxes.cache);
      final schema = Hive.box<int>(HiveBoxes.boxSchema);

      // No stamps yet (fresh install). A search entry already in the cache
      // from this very session must NOT be evicted.
      const searchKey = 'search:FR:48.800:2.300:5.0:e10';
      await cacheBox.put(searchKey, {'data': 1, 'timestamp': 0});

      await HiveBoxes.ensureSchemaVersionsForTest();

      expect(schema.get(HiveBoxes.cache), HiveBoxes.currentSchemaVersion);
      expect(cacheBox.get(searchKey), isNotNull,
          reason: 'fresh install must not evict — only an upgrade does');
    });

    test('an up-to-date cache (already at current version) is left untouched',
        () async {
      final cacheBox = Hive.box(HiveBoxes.cache);
      final schema = Hive.box<int>(HiveBoxes.boxSchema);

      await schema.put(HiveBoxes.cache, HiveBoxes.currentSchemaVersion);
      const searchKey = 'search:FR:48.800:2.300:5.0:e10';
      await cacheBox.put(searchKey, {'data': 1, 'timestamp': 0});

      await HiveBoxes.ensureSchemaVersionsForTest();

      expect(cacheBox.get(searchKey), isNotNull,
          reason: 'an already-current cache must not be re-evicted');
    });
  });
}
