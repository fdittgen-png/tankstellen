// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/entity_sync.dart';
import 'package:tankstellen/core/sync/pending_deletions_journal.dart';
import 'package:tankstellen/core/sync/sync_device_identity.dart';

import '../../helpers/silence_error_logger.dart';
import 'fake_sync_transport.dart';

/// #3127 — the generic [EntitySync] engine the per-entity sync configs
/// delegate to. The entity-level contracts (LWW, tombstones, stamps, run
/// traces) stay pinned by their existing tests
/// (`lww_merge_test.dart`, `sync_forensic_stamps_test.dart`, …); these
/// tests pin the ENGINE-level invariants shared by every config,
/// including the fault paths (offline select/upsert/delete).
void main() {
  silenceErrorLoggerSpool();

  setUp(() {
    SyncDeviceIdentity.resetForTest('device-under-test');
    PendingDeletionsJournal.load = () => null;
    PendingDeletionsJournal.persist = (_) async {};
  });

  tearDown(() {
    SyncDeviceIdentity.resetForTest();
    PendingDeletionsJournal.resetForTest();
  });

  EntitySync<String> idSet() =>
      EntitySync.idSet(table: 'favorites', logName: 'FavoritesSync');

  group('EntitySync.merge — id-set flavour', () {
    test('uploads local-only ids and downloads server-only ids', () async {
      final fake = FakeSyncTransport(tables: {
        'favorites': [
          {'user_id': 'user-1', 'station_id': 'st-server'},
          {'user_id': 'user-1', 'station_id': 'st-both'},
        ],
      });

      final result =
          await idSet().merge(['st-local', 'st-both'], transport: fake);

      expect(fake.upsertedRows('favorites'), [
        {'user_id': 'user-1', 'station_id': 'st-local'},
      ]);
      expect(fake.upsertCalls.single.onConflict, 'user_id,station_id');
      expect(result, containsAll(['st-local', 'st-both', 'st-server']));
      expect(result, hasLength(3));
    });

    test('a tombstoned id is dropped from BOTH sides of the union (#3078)',
        () async {
      final fake = FakeSyncTransport(tables: {
        'favorites': [
          {'user_id': 'user-1', 'station_id': 'st-dead'},
        ],
        'deletions': [
          {'record_id': 'st-dead', 'table_name': 'favorites'},
        ],
      });

      final result = await idSet().merge(['st-dead'], transport: fake);

      expect(result, isEmpty);
      expect(fake.upsertCalls, isEmpty,
          reason: 'a tombstoned local id must not re-upload');
    });

    test('unauthenticated path returns the input unchanged', () async {
      // No transport injected and no live Supabase session in unit tests.
      final local = ['st-1', 'st-2'];
      expect(await idSet().merge(local), equals(local));
    });

    test('an offline select returns the input unchanged (fault path)',
        () async {
      final fake = FakeSyncTransport()..failSelects = true;
      final local = ['st-1'];
      await expectLater(
          idSet().merge(local, transport: fake), completion(equals(local)));
    });

    test('an offline upsert returns the input unchanged (fault path)',
        () async {
      final fake = FakeSyncTransport()..failUpserts = true;
      await expectLater(idSet().merge(['st-1'], transport: fake),
          completion(equals(['st-1'])));
    });
  });

  group('EntitySync.deleteRow', () {
    test('tombstone-first: tombstone lands even when the row delete fails',
        () async {
      final fake = FakeSyncTransport(tables: {
        'favorites': [
          {'user_id': 'user-1', 'station_id': 'st-1'},
        ],
      })
        ..failDeletes = true;

      final ok = await EntitySync.deleteRow(
        table: 'favorites',
        idColumn: 'station_id',
        recordId: 'st-1',
        logContext: 'FavoritesSync.delete',
        transport: fake,
      );

      expect(ok, isFalse);
      expect(
          fake.upsertedRows('deletions').single['record_id'], 'st-1',
          reason: 'the durable tombstone must not depend on the row delete');
    });

    test('deletes the row, scoped to the id column', () async {
      final fake = FakeSyncTransport(tables: {
        'favorites': [
          {'user_id': 'user-1', 'station_id': 'st-1'},
          {'user_id': 'user-1', 'station_id': 'st-2'},
        ],
      });

      final ok = await EntitySync.deleteRow(
        table: 'favorites',
        idColumn: 'station_id',
        recordId: 'st-1',
        logContext: 'FavoritesSync.delete',
        transport: fake,
      );

      expect(ok, isTrue);
      expect(fake.deleteCalls.single.filters, {'station_id': 'st-1'});
      expect(fake.tables['favorites']!.single['station_id'], 'st-2');
    });

    test('tombstone-AFTER ordering (the alerts flavour, #3121) still '
        'records the tombstone on a failed delete', () async {
      final fake = FakeSyncTransport()..failDeletes = true;

      final ok = await EntitySync.deleteRow(
        table: 'alerts',
        idColumn: 'id',
        recordId: 'a-1',
        logContext: 'AlertsSync.delete',
        tombstoneFirst: false,
        transport: fake,
      );

      expect(ok, isFalse);
      expect(fake.upsertedRows('deletions').single['record_id'], 'a-1');
    });

    test('unauthenticated path is a no-op returning false', () async {
      await expectLater(
        EntitySync.deleteRow(
          table: 'favorites',
          idColumn: 'station_id',
          recordId: 'st-1',
          logContext: 'FavoritesSync.delete',
        ),
        completion(isFalse),
      );
    });
  });

  group('EntitySync shared codec helpers', () {
    test('forensicStamps carries the #3125 device identity', () {
      expect(EntitySync.forensicStamps(), {
        'device_id': 'device-under-test',
        'app_version': SyncDeviceIdentity.appVersion,
      });
    });

    test('lwwStamp carries the local edit stamp in UTC (#3124)', () {
      final edited = DateTime.utc(2026, 6, 1, 12);
      expect(EntitySync.lwwStamp(edited), edited.toIso8601String());
      // Legacy unstamped record → upload-time fallback, still UTC.
      expect(EntitySync.lwwStamp(null), endsWith('Z'));
    });

    test('jsonbDataDecoder skips a corrupt row instead of throwing', () {
      final decode = EntitySync.jsonbDataDecoder<String>(
        (json) => json['name'] as String,
        where: 'EntitySyncTest decode failed',
      );
      expect(decode({'data': {'name': 'ok'}}), 'ok');
      expect(decode({'data': {'name': 42}}), isNull,
          reason: 'a throwing fromJson must degrade to a skipped row');
      expect(decode({'data': 'not-a-map'}), isNull);
      expect(decode(const {}), isNull);
    });
  });
}
