// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/deletions_sync.dart';
import 'package:tankstellen/core/sync/pending_deletions_journal.dart';

import 'fake_sync_transport.dart';

/// #3123 — durable pending-deletions journal.
///
/// Tombstone writes were fail-open: a network blip during a delete
/// swallowed the tombstone with a log and the next union merge
/// resurrected exactly the row #3078 was built to keep dead. These tests
/// drive [DeletionsSync] through an in-memory journal + a
/// [FakeSyncTransport] and pin the fix: journal-first writes, drain on
/// the next sync, and locally-honoured pending ids in the meantime.
void main() {
  String? stored;

  setUp(() {
    stored = null;
    PendingDeletionsJournal.load = () => stored;
    PendingDeletionsJournal.persist = (json) async => stored = json;
  });

  tearDown(PendingDeletionsJournal.resetForTest);

  group('journal-first tombstone writes (#3123)', () {
    test(
        'RED for #3123: a tombstone write that fails offline is journaled '
        'and replayed by the next successful sync', () async {
      // The delete happens while the network is flaky — the tombstone
      // upsert fails. Before #3123 this was swallowed forever.
      final offline = FakeSyncTransport()..failUpserts = true;
      final ok = await DeletionsSync.recordAll(
        'favorites',
        const ['st-dead'],
        transport: offline,
      );
      expect(ok, isFalse);
      expect(PendingDeletionsJournal.pendingIds('favorites'),
          contains('st-dead'),
          reason: 'the failed tombstone must stay journaled, not be lost');

      // Next sync: the merge's tombstone fetch drains the journal first.
      final online = FakeSyncTransport();
      final tombstoned = await DeletionsSync.fetchTombstonedIds(
        'favorites',
        transport: online,
      );
      expect(tombstoned, contains('st-dead'),
          reason: 'the replayed tombstone must reach the union filter');
      expect(
        online.upsertedRows('deletions').map((r) => r['record_id']),
        contains('st-dead'),
        reason: 'the journaled tombstone must reach the server on drain',
      );
      expect(PendingDeletionsJournal.pendingIds('favorites'), isEmpty,
          reason: 'a confirmed tombstone leaves the journal');
    });

    test('an unauthenticated delete is journaled for later replay',
        () async {
      // No transport + no Supabase client in unit tests → unauthenticated.
      final ok =
          await DeletionsSync.recordAll('vehicles', const ['veh-gone']);
      expect(ok, isFalse);
      expect(PendingDeletionsJournal.pendingIds('vehicles'),
          contains('veh-gone'));
    });

    test('a confirmed tombstone write clears its journal entry', () async {
      final fake = FakeSyncTransport();
      final ok = await DeletionsSync.recordAll(
        'fill_ups',
        const ['f-1', 'f-2'],
        transport: fake,
      );
      expect(ok, isTrue);
      expect(PendingDeletionsJournal.pendingIds('fill_ups'), isEmpty);
      expect(fake.upsertedRows('deletions'), hasLength(2));
    });

    test(
        'fetchTombstonedIds unions still-pending ids while the server '
        'write keeps failing', () async {
      await PendingDeletionsJournal.addAll('alerts', const ['a-dead']);
      // Selects work but the tombstone upsert keeps failing → the drain
      // can't confirm, yet the local merge must still treat the id as dead.
      final flaky = FakeSyncTransport()..failUpserts = true;
      final tombstoned =
          await DeletionsSync.fetchTombstonedIds('alerts', transport: flaky);
      expect(tombstoned, contains('a-dead'));
      expect(PendingDeletionsJournal.pendingIds('alerts'),
          contains('a-dead'),
          reason: 'the unconfirmed id stays journaled for the next sync');
    });

    test('drainJournal replays every table\'s pending ids', () async {
      await PendingDeletionsJournal.addAll('favorites', const ['st-1']);
      await PendingDeletionsJournal.addAll('vehicles', const ['v-1']);
      final fake = FakeSyncTransport();

      await DeletionsSync.drainJournal(transport: fake);

      expect(
        fake.upsertedRows('deletions').map((r) => r['record_id']),
        containsAll(<String>['st-1', 'v-1']),
      );
      expect(PendingDeletionsJournal.snapshot(), isEmpty);
    });
  });

  group('journal store contract', () {
    test('add/remove round-trip and per-table isolation', () async {
      await PendingDeletionsJournal.addAll('favorites', const ['a', 'b']);
      await PendingDeletionsJournal.addAll('vehicles', const ['v']);
      expect(PendingDeletionsJournal.pendingIds('favorites'), {'a', 'b'});
      expect(PendingDeletionsJournal.pendingIds('vehicles'), {'v'});

      await PendingDeletionsJournal.removeAll('favorites', const ['a']);
      expect(PendingDeletionsJournal.pendingIds('favorites'), {'b'});
      expect(PendingDeletionsJournal.pendingIds('vehicles'), {'v'});

      await PendingDeletionsJournal.removeAll('favorites', const ['b']);
      expect(PendingDeletionsJournal.snapshot(),
          isNot(contains('favorites')),
          reason: 'an emptied table key is pruned from the journal');
    });

    test('survives a corrupt persisted payload (returns empty, no throw)',
        () {
      stored = 'not-json{{';
      expect(PendingDeletionsJournal.snapshot(), isEmpty);
      expect(PendingDeletionsJournal.pendingIds('favorites'), isEmpty);
    });

    // #2349 never-throws ratchet — the docstring promises journalling can
    // never derail the local delete, so inject persistence faults.
    test('fault injection: a throwing persist seam never escapes', () async {
      PendingDeletionsJournal.persist =
          (_) async => throw Exception('disk full');
      await expectLater(
        PendingDeletionsJournal.addAll('favorites', const ['x']),
        completes,
      );
      await expectLater(
        PendingDeletionsJournal.removeAll('favorites', const ['x']),
        completes,
      );
    });

    test('fault injection: a throwing load seam never escapes', () {
      PendingDeletionsJournal.load = () => throw Exception('box closed');
      expect(PendingDeletionsJournal.snapshot(), isEmpty);
    });

    test('fault injection: recordAll completes when the journal is faulty',
        () async {
      PendingDeletionsJournal.persist =
          (_) async => throw Exception('disk full');
      final fake = FakeSyncTransport();
      // Degrades to the pre-#3123 fail-open behaviour: the tombstone
      // still reaches the server even when journalling is broken.
      final ok = await DeletionsSync.recordAll(
        'favorites',
        const ['st-1'],
        transport: fake,
      );
      expect(ok, isTrue);
      expect(fake.upsertedRows('deletions'), hasLength(1));
    });
  });
}
