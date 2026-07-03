// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_events.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';

import '../../fakes/fake_hive_storage.dart';

/// Regression tests for #3076 — TankSync was upload-only.
///
/// [FavoritesSync.merge] / [IgnoredStationsSync.merge] each return the
/// union (server ∪ local), but `_performInitialSync` discarded the
/// return value — so server-side rows added on another device never
/// reached this device. It also skipped the merge entirely when the
/// local set was empty, so a fresh install never pulled the server set.
///
/// These tests drive the [SyncState.syncAndPersistIds] seam with an
/// injected fake merge that simulates server rows, and assert the union
/// is **persisted back to local storage**. They FAIL against the
/// pre-fix code (discarded return + `isNotEmpty` guard) and PASS after.
void main() {
  late FakeHiveStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeHiveStorage();
  });

  ProviderContainer createContainer() {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
      syncStateProvider.overrideWith(() => _FakeSyncState(const SyncConfig(
            enabled: true,
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'key',
            userId: 'user-123',
            mode: SyncMode.community,
          ))),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  /// Builds a fake merge that simulates the server returning [serverIds]
  /// in addition to whatever the device sends up — the real merge's
  /// "return local ∪ server" contract.
  IdMergeFn fakeMergeWithServer(List<String> serverIds) {
    return (localIds) async => {...localIds, ...serverIds}.toList();
  }

  group('SyncState.syncAndPersistIds (#3076 pull-persist)', () {
    test('persists a server-only favorite into LOCAL storage', () async {
      await fakeStorage.setFavoriteIds(['local-1']);

      final container = createContainer();
      final notifier = container.read(syncStateProvider.notifier);

      await notifier.syncAndPersistIds(
        fakeStorage,
        mergeFavorites: fakeMergeWithServer(['server-only-id']),
        mergeIgnored: fakeMergeWithServer(const []),
      );

      // The discarded-return bug would leave this as just ['local-1'].
      expect(
        fakeStorage.getFavoriteIds(),
        containsAll(<String>['local-1', 'server-only-id']),
        reason: 'server-only favorite must be written to local storage',
      );
    });

    test('persists a server-only ignored station into LOCAL storage',
        () async {
      await fakeStorage.setIgnoredIds(['ignored-local']);

      final container = createContainer();
      final notifier = container.read(syncStateProvider.notifier);

      await notifier.syncAndPersistIds(
        fakeStorage,
        mergeFavorites: fakeMergeWithServer(const []),
        mergeIgnored: fakeMergeWithServer(['ignored-server']),
      );

      expect(
        fakeStorage.getIgnoredIds(),
        containsAll(<String>['ignored-local', 'ignored-server']),
        reason: 'server-only ignored id must be written to local storage',
      );
    });

    test('empty local + server rows → local gets the server rows', () async {
      // No local favorites/ignored at all — proves the removed
      // `isNotEmpty` guard: an empty device must still PULL the server set.
      expect(fakeStorage.getFavoriteIds(), isEmpty);
      expect(fakeStorage.getIgnoredIds(), isEmpty);

      final container = createContainer();
      final notifier = container.read(syncStateProvider.notifier);

      await notifier.syncAndPersistIds(
        fakeStorage,
        mergeFavorites: fakeMergeWithServer(['srv-fav-a', 'srv-fav-b']),
        mergeIgnored: fakeMergeWithServer(['srv-ign-a']),
      );

      expect(
        fakeStorage.getFavoriteIds(),
        containsAll(<String>['srv-fav-a', 'srv-fav-b']),
        reason: 'empty device must pull server favorites',
      );
      expect(
        fakeStorage.getIgnoredIds(),
        contains('srv-ign-a'),
        reason: 'empty device must pull server ignored stations',
      );
    });

    test('no-op merge leaves local storage unchanged', () async {
      await fakeStorage.setFavoriteIds(['keep-1', 'keep-2']);
      await fakeStorage.setIgnoredIds(['keep-ign']);

      final container = createContainer();
      final notifier = container.read(syncStateProvider.notifier);

      // identity merge — simulates an unauthenticated/empty server.
      await notifier.syncAndPersistIds(
        fakeStorage,
        mergeFavorites: (ids) async => ids,
        mergeIgnored: (ids) async => ids,
      );

      expect(fakeStorage.getFavoriteIds(), ['keep-1', 'keep-2']);
      expect(fakeStorage.getIgnoredIds(), ['keep-ign']);
    });
  });

  // #3077 — ratings were upload-only: `_performInitialSync` called
  // `RatingsSync.upsertAll` (push) but never consumed `RatingsSync.fetchAll`,
  // so a rating made on another device never reached this one. These drive
  // the new `syncAndPersistRatings` seam and assert the server-only rating
  // is written to LOCAL storage. They FAIL on master (the method doesn't
  // exist / nothing persisted the fetch) and PASS after.
  group('SyncState.syncAndPersistRatings (#3077 ratings pull-persist)', () {
    test('persists a server-only rating into LOCAL storage', () async {
      await fakeStorage.setRating('st-local', 4);

      final container = createContainer();
      final notifier = container.read(syncStateProvider.notifier);

      await notifier.syncAndPersistRatings(
        fakeStorage,
        fetchRatings: () async => {'st-local': 4, 'st-server': 5},
      );

      expect(fakeStorage.getRating('st-server'), 5,
          reason: 'server-only rating must be written to local storage');
      expect(fakeStorage.getRating('st-local'), 4);
    });

    test('local wins on id collision (in-flight edit not clobbered)',
        () async {
      await fakeStorage.setRating('st-1', 5); // local edit: 5 stars

      final container = createContainer();
      final notifier = container.read(syncStateProvider.notifier);

      // server still has the stale 2-star value for the same station.
      await notifier.syncAndPersistRatings(
        fakeStorage,
        fetchRatings: () async => {'st-1': 2},
      );

      expect(fakeStorage.getRating('st-1'), 5,
          reason: 'local rating must win — server value must not overwrite it');
    });

    test('empty server fetch leaves local ratings unchanged', () async {
      await fakeStorage.setRating('keep', 3);

      final container = createContainer();
      final notifier = container.read(syncStateProvider.notifier);

      await notifier.syncAndPersistRatings(
        fakeStorage,
        fetchRatings: () async => const <String, int>{},
      );

      expect(fakeStorage.getRatings(), {'keep': 3});
    });
  });

  // #3446 — every pull that persists rows must announce it on the
  // SyncEvents bus AFTER the write, so the subscribed providers re-read
  // storage in-session instead of one restart late.
  group('SyncEvents emits from the pull-persist seams (#3446)', () {
    Future<void> flush() => Future<void>.delayed(Duration.zero);

    test('syncAndPersistIds emits favorites + ignored deltas', () async {
      await fakeStorage.setFavoriteIds(['local-1']);

      final events = <SyncTableChanged>[];
      final sub = SyncEvents.instance.stream.listen(events.add);
      addTearDown(sub.cancel);

      final container = createContainer();
      await container.read(syncStateProvider.notifier).syncAndPersistIds(
            fakeStorage,
            mergeFavorites: fakeMergeWithServer(['server-fav']),
            mergeIgnored: fakeMergeWithServer(['server-ign']),
          );
      await flush();

      expect(
        events.map((e) => '${e.table}:${e.changedCount}'),
        containsAll(<String>[
          '${SyncTables.favorites}:1',
          '${SyncTables.ignoredStations}:1',
        ]),
      );
    });

    test('no-op id merge emits nothing', () async {
      await fakeStorage.setFavoriteIds(['keep']);

      final events = <SyncTableChanged>[];
      final sub = SyncEvents.instance.stream.listen(events.add);
      addTearDown(sub.cancel);

      final container = createContainer();
      await container.read(syncStateProvider.notifier).syncAndPersistIds(
            fakeStorage,
            mergeFavorites: (ids) async => ids,
            mergeIgnored: (ids) async => ids,
          );
      await flush();

      expect(events, isEmpty);
    });

    test('syncAndPersistRatings returns + emits the written count',
        () async {
      await fakeStorage.setRating('st-local', 4);

      final events = <SyncTableChanged>[];
      final sub = SyncEvents.instance
          .forTable(SyncTables.stationRatings)
          .listen(events.add);
      addTearDown(sub.cancel);

      final container = createContainer();
      final written = await container
          .read(syncStateProvider.notifier)
          .syncAndPersistRatings(
            fakeStorage,
            // local id collides (skipped), two server-only rows land.
            fetchRatings: () async => {'st-local': 1, 'a': 5, 'b': 2},
          );
      await flush();

      expect(written, 2);
      expect(events.single.changedCount, 2);
    });

    test('empty ratings fetch emits nothing and returns 0', () async {
      final events = <SyncTableChanged>[];
      final sub = SyncEvents.instance.stream.listen(events.add);
      addTearDown(sub.cancel);

      final container = createContainer();
      final written = await container
          .read(syncStateProvider.notifier)
          .syncAndPersistRatings(
            fakeStorage,
            fetchRatings: () async => const <String, int>{},
          );
      await flush();

      expect(written, 0);
      expect(events, isEmpty);
    });
  });
}

/// Fake [SyncState] that returns a fixed [SyncConfig] without touching
/// Supabase — the seam under test (`syncAndPersistIds`) is inherited.
class _FakeSyncState extends SyncState {
  final SyncConfig _config;
  _FakeSyncState(this._config);

  @override
  SyncConfig build() => _config;
}
