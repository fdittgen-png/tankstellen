// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/stores/favorites_hive_store.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/domain/opening_hours.dart';

void main() {
  late FavoritesHiveStore store;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('favorites_store_test_');
    Hive.init(tempDir.path);
    await HiveStorage.initForTest();
    store = FavoritesHiveStore();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Fuel favorites', () {
    test('empty state', () {
      expect(store.getFavoriteIds(), isEmpty);
      expect(store.favoriteCount, 0);
      expect(store.isFavorite('any'), isFalse);
    });

    test('addFavorite / removeFavorite round-trip', () async {
      await store.addFavorite('st-1');
      expect(store.isFavorite('st-1'), isTrue);
      expect(store.favoriteCount, 1);

      await store.removeFavorite('st-1');
      expect(store.isFavorite('st-1'), isFalse);
      expect(store.favoriteCount, 0);
    });

    test('addFavorite is idempotent — no duplicates', () async {
      await store.addFavorite('st-1');
      await store.addFavorite('st-1');
      expect(store.favoriteCount, 1);
    });

    test('setFavoriteIds replaces the list wholesale', () async {
      await store.addFavorite('st-1');
      await store.setFavoriteIds(['st-2', 'st-3']);
      expect(store.getFavoriteIds(), ['st-2', 'st-3']);
    });
  });

  group('Fuel favorite station data', () {
    test('null when the station id has no saved data', () {
      expect(store.getFavoriteStationData('st-1'), isNull);
    });

    test('save + get round-trip preserves every field', () async {
      await store.saveFavoriteStationData('st-1', {
        'name': 'Shell',
        'brand': 'Shell',
        'lat': 48.85,
        'lng': 2.35,
      });
      final round = store.getFavoriteStationData('st-1')!;
      expect(round['name'], 'Shell');
      expect(round['lat'], 48.85);
    });

    test('getAllFavoriteStationData enumerates every saved station',
        () async {
      await store.saveFavoriteStationData('st-1', {'name': 'Shell'});
      await store.saveFavoriteStationData('st-2', {'name': 'BP'});
      final all = store.getAllFavoriteStationData();
      expect(all.keys.toSet(), {'st-1', 'st-2'});
    });

    test('removeFavoriteStationData removes only the target', () async {
      await store.saveFavoriteStationData('st-1', {'name': 'Shell'});
      await store.saveFavoriteStationData('st-2', {'name': 'BP'});
      await store.removeFavoriteStationData('st-1');
      expect(store.getFavoriteStationData('st-1'), isNull);
      expect(store.getFavoriteStationData('st-2'), isNotNull);
    });

    // #2893 — a favorite carrying the #2777 structured `openingHours` was
    // silently DROPPED on load. Hive round-trips its nested `days`/`ranges`
    // objects as `Map<dynamic, dynamic>`, but the read boundary did only a
    // shallow `Map<String, dynamic>.from`, so `Station.fromJson`'s nested
    // cast (station.g.dart line 34, `openingHours as Map<String, dynamic>`)
    // threw and the whole station was skipped ("Skipping corrupt favorite
    // fr-11130001" — Intermarché Sigean, a real favorite). Drive the REAL
    // Hive write→read→fromJson path, not Station.fromJson in isolation.
    test(
      'a favorite with structured openingHours survives the Hive round-trip '
      'and re-parses via Station.fromJson (regression #2893)',
      () async {
        const id = 'fr-11130001'; // Intermarché Sigean, the dropped favorite.
        const station = Station(
          id: id,
          name: 'Intermarché Sigean',
          brand: 'Intermarché',
          street: 'Avenue de Perpignan',
          postCode: '11130',
          place: 'Sigean',
          lat: 43.0289,
          lng: 2.9756,
          diesel: 1.689,
          e10: 1.799,
          isOpen: true,
          openingHours: WeeklyOpeningHours(
            availability: OpeningHoursAvailability.full,
            days: [
              DayHours(
                day: OpeningDay.mon,
                state: DayState.openRanges,
                ranges: [
                  // Nested object two levels deep — the exact shape Hive
                  // returns as Map<dynamic, dynamic>.
                  TimeRange(startMinutes: 420, endMinutes: 1110),
                ],
              ),
            ],
          ),
        );

        // Real write path: the favorites/widget/refresh code all persist via
        // `saveFavoriteStationData(id, station.toJson())`.
        await store.saveFavoriteStationData(id, station.toJson());

        // Force the on-disk round-trip. Hive only re-types the nested objects
        // as `Map<dynamic, dynamic>` after they are serialised to disk and
        // read back fresh — exactly what happens on a real app cold start.
        // Reading from the still-open in-memory box would hand back the very
        // `Map<String, dynamic>` we wrote and hide the bug.
        await Hive.close();
        Hive.init(tempDir.path);
        await HiveStorage.initForTest();
        store = FavoritesHiveStore();

        // Real read path: Hive hands the nested objects back dynamic-keyed.
        final data = store.getFavoriteStationData(id);
        expect(data, isNotNull,
            reason: 'the favorite must still be readable from storage');

        // Before the fix this threw _TypeError on the nested openingHours
        // cast, so the favorites provider skipped the station entirely.
        late final Station parsed;
        expect(
          () => parsed = Station.fromJson(data!),
          returnsNormally,
          reason: 'nested Hive Map<dynamic,dynamic> must coerce cleanly — '
              'the favorite must NOT be dropped',
        );
        expect(parsed.id, id);
        expect(parsed.name, 'Intermarché Sigean');
        // The structured hours survive the whole loop intact.
        expect(parsed.openingHours, isNotNull);
        expect(parsed.openingHours!.days, hasLength(1));
        expect(parsed.openingHours!.days.first.ranges.first.startMinutes, 420);
      },
    );
  });

  group('EV favorites', () {
    test('addEvFavorite / removeEvFavorite round-trip', () async {
      await store.addEvFavorite('ev-1');
      expect(store.isEvFavorite('ev-1'), isTrue);
      expect(store.evFavoriteCount, 1);

      await store.removeEvFavorite('ev-1');
      expect(store.isEvFavorite('ev-1'), isFalse);
      expect(store.evFavoriteCount, 0);
    });

    test('fuel and EV favorite id spaces are independent', () async {
      await store.addFavorite('shared-id');
      expect(store.isFavorite('shared-id'), isTrue);
      expect(store.isEvFavorite('shared-id'), isFalse);
    });

    test('EV favorite station data round-trips', () async {
      await store.saveEvFavoriteStationData('ev-1', {
        'name': 'IONITY Tournefeuille',
        'maxPowerKw': 350,
      });
      expect(
        store.getEvFavoriteStationData('ev-1')!['maxPowerKw'],
        350,
      );
    });
  });

  group('Ignored stations', () {
    test('addIgnored / removeIgnored / isIgnored cycle', () async {
      expect(store.isIgnored('st-1'), isFalse);
      await store.addIgnored('st-1');
      expect(store.isIgnored('st-1'), isTrue);
      expect(store.getIgnoredIds(), contains('st-1'));
      await store.removeIgnored('st-1');
      expect(store.isIgnored('st-1'), isFalse);
    });

    test('addIgnored is idempotent', () async {
      await store.addIgnored('st-1');
      await store.addIgnored('st-1');
      expect(store.getIgnoredIds(), hasLength(1));
    });
  });

  group('Station ratings', () {
    test('empty when nothing rated', () {
      expect(store.getRatings(), isEmpty);
      expect(store.getRating('st-1'), isNull);
    });

    test('setRating + getRating round-trip', () async {
      await store.setRating('st-1', 4);
      expect(store.getRating('st-1'), 4);
      expect(store.getRatings(), {'st-1': 4});
    });

    test('setRating overwrites an existing rating', () async {
      await store.setRating('st-1', 3);
      await store.setRating('st-1', 5);
      expect(store.getRating('st-1'), 5);
    });

    test('removeRating clears only the target', () async {
      await store.setRating('st-1', 4);
      await store.setRating('st-2', 2);
      await store.removeRating('st-1');
      expect(store.getRating('st-1'), isNull);
      expect(store.getRating('st-2'), 2);
    });
  });
}
