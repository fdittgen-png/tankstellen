// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/entity_sync.dart';
import 'package:tankstellen/core/sync/locally_retained_ids.dart';
import 'package:tankstellen/core/sync/pending_deletions_journal.dart';

import 'fake_sync_transport.dart';

/// #4046 — "Data stored locally on this device is kept" has to be true.
///
/// The delete-synced-data dialog makes three claims: the server copy
/// goes, other devices do not re-sync it, and **this device keeps its
/// local copy**. The tombstone delivered the first two and broke the
/// third, because `EntitySync.merge` filtered tombstoned ids out of the
/// local set and then persisted the filtered set. The device that was
/// promised its data was the device that deleted it, one sync later.
///
/// The distinction these tests pin: a tombstone written because the USER
/// DELETED A RECORD must still remove the local row everywhere (#3078),
/// while a tombstone written by a SERVER WIPE must not remove it here.
void main() {
  String? retained;
  String? journal;

  EntitySync<String> favorites() =>
      EntitySync.idSet(table: 'favorites', logName: 'FavoritesSync');

  setUp(() {
    retained = null;
    journal = null;
    LocallyRetainedIds.load = () => retained;
    LocallyRetainedIds.persist = (json) async => retained = json;
    PendingDeletionsJournal.load = () => journal;
    PendingDeletionsJournal.persist = (json) async => journal = json;
  });

  tearDown(() {
    LocallyRetainedIds.resetForTest();
    PendingDeletionsJournal.resetForTest();
  });

  test('RED for #4046: a server-wiped id survives the next merge locally',
      () async {
    final fake = FakeSyncTransport(tables: {
      // The wipe already removed the server row and left a tombstone.
      'favorites': const [],
      'deletions': [
        {'record_id': 'st-kept', 'table_name': 'favorites'},
      ],
    });
    await LocallyRetainedIds.retain('favorites', const ['st-kept'],
        transport: fake);

    final result = await favorites().merge(['st-kept'], transport: fake);

    expect(result, contains('st-kept'),
        reason: 'the dialog promised this device keeps its local copy');
    expect(fake.upsertCalls, isEmpty,
        reason: 'and it must still never go back up — the user deleted it '
            'from the server on purpose');
  });

  test('an ordinary record deletion still removes the local row (#3078)',
      () async {
    // Nothing retained: this tombstone came from a real delete, possibly
    // on another device. The local copy must go, or the delete does not
    // stick across devices.
    final fake = FakeSyncTransport(tables: {
      'favorites': const [],
      'deletions': [
        {'record_id': 'st-dead', 'table_name': 'favorites'},
      ],
    });

    final result = await favorites().merge(['st-dead'], transport: fake);

    expect(result, isEmpty,
        reason: 'a genuine record deletion must not be weakened by #4046');
  });

  test('retention is per-table — it cannot leak across tables', () async {
    final fake = FakeSyncTransport(tables: {
      'favorites': const [],
      'deletions': [
        {'record_id': 'shared-id', 'table_name': 'favorites'},
      ],
    });
    // Same id string retained for a DIFFERENT table.
    await LocallyRetainedIds.retain('vehicles', const ['shared-id'],
        transport: fake);

    final result = await favorites().merge(['shared-id'], transport: fake);

    expect(result, isEmpty,
        reason: 'ids are only unique within a table; retention must key on '
            'both or a vehicle wipe would resurrect a deleted favourite');
  });

  test('retention is per-account — B does not inherit A\'s kept rows',
      () async {
    final a = FakeSyncTransport(userId: 'account-A', tables: {
      'favorites': const [],
      'deletions': [
        {'record_id': 'st-kept', 'table_name': 'favorites'},
      ],
    });
    await LocallyRetainedIds.retain('favorites', const ['st-kept'],
        transport: a);

    final b = FakeSyncTransport(userId: 'account-B', tables: {
      'favorites': const [],
      'deletions': [
        {'record_id': 'st-kept', 'table_name': 'favorites'},
      ],
    });
    final result = await favorites().merge(['st-kept'], transport: b);

    expect(result, isEmpty,
        reason: "A's decision to keep a row says nothing about B's data "
            '(#4047 scoping applies here too)');
  });

  test('a retained id is not re-uploaded even when the server is empty',
      () async {
    // The upload path is the one that would undo the whole operation:
    // re-uploading puts back exactly what the user asked to delete.
    final fake = FakeSyncTransport(tables: {
      'favorites': const [],
      'deletions': [
        {'record_id': 'st-kept', 'table_name': 'favorites'},
      ],
    });
    await LocallyRetainedIds.retain('favorites', const ['st-kept'],
        transport: fake);

    await favorites().merge(['st-kept'], transport: fake);

    expect(fake.upsertedRows('favorites'), isEmpty,
        reason: 'server-side deletion must stay deleted');
  });
}
