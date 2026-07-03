// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/synced_data_deletion.dart';

import '../../helpers/silence_error_logger.dart';
import 'fake_sync_transport.dart';

/// #3453 — anonymous own-data deletion, driven through the user-scoped
/// [FakeSyncTransport] "server".
///
/// Pins the three contracts of the issue:
///  1. per-category server-side wipe, RLS/user-scoped (the transport
///     scopes every operation to its user; the delete carries NO extra
///     filters, so `user_id = auth.uid()` is the ONLY predicate);
///  2. tombstone-correctness — every wiped row id lands in `deletions`
///     BEFORE the rows go, so another device's later pull removes its
///     copies instead of resurrecting them (#3078);
///  3. "everything" leaves the identity usable — no `users` mutation,
///     and crucially the `deletions` tombstones themselves survive.
void main() {
  silenceErrorLoggerSpool();

  FakeSyncTransport serverWith({
    List<String> trips = const [],
    List<String> vehicles = const [],
    List<String> fillUps = const [],
  }) =>
      FakeSyncTransport(tables: {
        'trip_summaries': [
          for (final id in trips) {'user_id': 'user-1', 'id': id},
        ],
        'trip_details': [
          for (final id in trips) {'user_id': 'user-1', 'id': id},
        ],
        'vehicles': [
          for (final id in vehicles) {'user_id': 'user-1', 'id': id},
        ],
        'fill_ups': [
          for (final id in fillUps) {'user_id': 'user-1', 'id': id},
        ],
        'users': [
          {'id': 'user-1'},
        ],
      });

  test('trips: wipes trip_summaries + trip_details, tombstone-first, '
      'user-scoped', () async {
    final t = serverWith(trips: ['trip-a', 'trip-b'], vehicles: ['v-1']);

    final ok = await SyncedDataDeletion.delete(SyncedDataCategory.trips,
        transport: t);

    expect(ok, isTrue);
    expect(t.tables['trip_summaries'], isEmpty);
    expect(t.tables['trip_details'], isEmpty);
    expect(t.tables['vehicles'], hasLength(1),
        reason: 'other categories must be untouched');

    // RLS-scoped: the delete carries NO extra filters — the transport's
    // implicit `user_id = auth.uid()` is the only predicate, exactly the
    // RLS shape (#3081), so an anonymous UUID can never reach foreign rows.
    final tripDeletes =
        t.deleteCalls.where((c) => c.table == 'trip_summaries').toList();
    expect(tripDeletes, hasLength(1));
    expect(tripDeletes.single.filters, isEmpty);

    // Tombstones for every wiped id, owned by the caller.
    final tombstones = t.upsertedRows('deletions');
    final tripTombstones = tombstones
        .where((r) => r['table_name'] == 'trip_summaries')
        .toList();
    expect(tripTombstones.map((r) => r['record_id']).toSet(),
        {'trip-a', 'trip-b'});
    expect(tripTombstones.every((r) => r['user_id'] == 'user-1'), isTrue);
    expect(
        tombstones.where((r) => r['table_name'] == 'trip_details'),
        hasLength(2));
  });

  test('vehicles / fill-ups categories wipe exactly their table',
      () async {
    final t = serverWith(trips: ['trip-a'], vehicles: ['v-1'], fillUps: ['f-1']);

    expect(
        await SyncedDataDeletion.delete(SyncedDataCategory.vehicles,
            transport: t),
        isTrue);
    expect(t.tables['vehicles'], isEmpty);
    expect(t.tables['fill_ups'], hasLength(1));

    expect(
        await SyncedDataDeletion.delete(SyncedDataCategory.fillUps,
            transport: t),
        isTrue);
    expect(t.tables['fill_ups'], isEmpty);
    expect(t.tables['trip_summaries'], hasLength(1),
        reason: 'trips untouched by the other categories');
  });

  test('everything wipes every content table but leaves the identity '
      'usable: users untouched, tombstones SURVIVE', () async {
    final t = serverWith(trips: ['trip-a'], vehicles: ['v-1'], fillUps: ['f-1']);
    t.tables['favorites'] = [
      {'user_id': 'user-1', 'station_id': 'de-1'},
    ];

    final ok = await SyncedDataDeletion.delete(SyncedDataCategory.everything,
        transport: t);

    expect(ok, isTrue);
    for (final table in SyncedDataDeletion
        .categoryTables[SyncedDataCategory.everything]!) {
      expect(t.tables[table] ?? const [], isEmpty,
          reason: '"$table" must be wiped by everything');
    }
    // Identity + cross-device correctness survive the wipe:
    expect(t.deleteCalls.map((c) => c.table), isNot(contains('users')));
    expect(t.deleteCalls.map((c) => c.table), isNot(contains('deletions')),
        reason: 'the tombstones ARE the cross-device delete — wiping them '
            'would resurrect everything from another device');
    expect(t.upsertedRows('deletions'), isNotEmpty);
  });

  test('everything covers every table of the id-column map (drift pin)',
      () {
    expect(
      SyncedDataDeletion.categoryTables[SyncedDataCategory.everything]!
          .toSet(),
      SyncedDataDeletion.idColumnByTable.keys.toSet(),
      reason: 'a table in idColumnByTable missing from the everything '
          'wipe silently survives "delete everything"',
    );
  });

  test('unauthenticated → returns false without throwing', () async {
    // No injected transport and no live session → currentOrNull() is null.
    expect(
        await SyncedDataDeletion.delete(SyncedDataCategory.trips), isFalse);
  });

  test('a failing table is isolated: returns false, the rest is still '
      'wiped, nothing throws', () async {
    final t = serverWith(trips: ['trip-a'], vehicles: ['v-1']);
    t.failDeletes = true;

    final ok = await SyncedDataDeletion.delete(SyncedDataCategory.trips,
        transport: t);

    expect(ok, isFalse);
    // Tombstones were still recorded (tombstone-first): even a failed row
    // delete stays dead across devices.
    expect(
        t.upsertedRows('deletions').map((r) => r['record_id']),
        contains('trip-a'));
  });
}
