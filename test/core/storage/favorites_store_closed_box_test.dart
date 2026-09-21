// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/stores/favorites_hive_store.dart';

import '../../helpers/hive_temp_dir.dart';

/// #4190 — every [FavoritesHiveStore] entry point survives a closed box.
///
/// The fault-injection shape #2349 established, for a real failure: a
/// fire-and-forget home-widget refresh outlived its test, the boxes had
/// already closed, and `Hive.box()` threw. It only ever showed in a full
/// local run — CI's four shards never produce that interleaving — and
/// the same throw happens in production, where a caller's guard
/// swallows it.
///
/// This store was the only one of its kind that threw there.
/// `BackgroundScanDedupStore`, `RadiusAlertDedup`, `BudgetStateStore`
/// and `OpportunityFeedStore` all degrade. Now so does this one.
void main() {
  late Directory tmpDir;
  final store = FavoritesHiveStore();

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('favorites_closed_box_');
    Hive.init(tmpDir.path);
  });

  tearDown(() async {
    await closeHiveAndDeleteTemp(tmpDir);
  });

  group('with the box CLOSED', () {
    test('every read returns its empty value rather than throwing', () {
      expect(store.getFavoriteIds(), isEmpty);
      expect(store.getFavoriteStationData('de-1'), isNull);
      expect(store.getEvFavoriteIds(), isEmpty);
      expect(store.getEvFavoriteStationData('ocm-1'), isNull);
      expect(store.getIgnoredIds(), isEmpty);
      expect(store.getRatings(), isEmpty);
    });

    test('every write drops rather than throwing', () async {
      // The late-refresh case: the app is shutting down, the work is
      // already in flight, and nothing it does can matter any more.
      await expectLater(store.setFavoriteIds(['de-1']), completes);
      await expectLater(store.setEvFavoriteIds(['ocm-1']), completes);
      await expectLater(store.setIgnoredIds(['de-2']), completes);
      await expectLater(
          store.removeEvFavoriteStationData('ocm-1'), completes);
    });
  });

  group('with the box OPEN, behaviour is unchanged', () {
    setUp(() async {
      await Hive.openBox<dynamic>(HiveBoxes.favorites);
    });

    test('favorite ids round-trip', () async {
      await store.setFavoriteIds(['de-1', 'de-2']);
      expect(store.getFavoriteIds(), ['de-1', 'de-2']);
    });

    test('ignored ids round-trip', () async {
      await store.setIgnoredIds(['de-9']);
      expect(store.getIgnoredIds(), ['de-9']);
    });

    test('EV favorite ids round-trip', () async {
      await store.setEvFavoriteIds(['ocm-7']);
      expect(store.getEvFavoriteIds(), ['ocm-7']);
    });

    test('a read of an absent key is still empty, not an error', () {
      expect(store.getFavoriteIds(), isEmpty);
      expect(store.getEvFavoriteStationData('nope'), isNull);
    });

    test('and closing the box mid-life degrades rather than throwing',
        () async {
      await store.setFavoriteIds(['de-1']);
      expect(store.getFavoriteIds(), ['de-1']);

      await Hive.box<dynamic>(HiveBoxes.favorites).close();

      expect(store.getFavoriteIds(), isEmpty,
          reason: 'this is the exact sequence #4190 hit: a live store, a '
              'teardown, and a late read');
      await expectLater(store.setFavoriteIds(['de-2']), completes);
    });
  });
}
