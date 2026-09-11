// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/deletions_sync.dart';
import 'package:tankstellen/core/sync/pending_deletions_journal.dart';
import 'package:tankstellen/core/sync/sync_context_key.dart';

import 'fake_sync_transport.dart';

/// #4047 — queued deletions belong to the account and backend that
/// created them.
///
/// The journal was one global `table → ids` map with no identity in it,
/// and `recordAll` stamps whatever transport is current at drain time. So
/// account A's queued delete replayed under account B. Favourites make it
/// concrete: a favourite's id IS the station id, the same string for
/// every user, so the replay does not fail — it silently deletes B's
/// favourite because A once deleted theirs.
void main() {
  String? stored;

  setUp(() {
    stored = null;
    PendingDeletionsJournal.load = () => stored;
    PendingDeletionsJournal.persist = (json) async => stored = json;
  });

  tearDown(PendingDeletionsJournal.resetForTest);

  test('a delete queued by account A is NOT replayed under account B', () async {
    // A deletes a favourite while offline — the tombstone cannot land.
    final a = FakeSyncTransport(userId: 'account-A')..failUpserts = true;
    await DeletionsSync.recordAll('favorites', const ['de-12345'],
        transport: a);
    expect(PendingDeletionsJournal.pendingIds('favorites', transport: a),
        contains('de-12345'),
        reason: 'the failed tombstone stays queued for A (#3123)');

    // The user switches accounts. B has a working connection.
    final b = FakeSyncTransport(userId: 'account-B');
    await DeletionsSync.drainJournal(transport: b);

    expect(
      b.upsertedRows('deletions').map((r) => r['record_id']),
      isNot(contains('de-12345')),
      reason: "B must not act on A's intent — the station id is shared, so "
          'the replay would succeed and delete B\'s own favourite',
    );
    expect(PendingDeletionsJournal.pendingIds('favorites', transport: a),
        contains('de-12345'),
        reason: "A's intent is quarantined, not discarded — signing back "
            'in must resume it');
  });

  test('the same account on a DIFFERENT backend is also a different context',
      () async {
    // A self-hoster repoints the app at another Supabase project. Account
    // ids can collide across projects, so the user id alone is not enough.
    final hosted = FakeSyncTransport(userId: 'same-uuid')
      ..backendUrl = 'https://alpha.supabase.co'
      ..failUpserts = true;
    await DeletionsSync.recordAll('vehicles', const ['v-1'],
        transport: hosted);

    final selfHosted = FakeSyncTransport(userId: 'same-uuid')
      ..backendUrl = 'https://beta.example.org';
    await DeletionsSync.drainJournal(transport: selfHosted);

    expect(
      selfHosted.upsertedRows('deletions').map((r) => r['record_id']),
      isNot(contains('v-1')),
      reason: 'a different backend is a different context even for the '
          'same account id',
    );
  });

  test('A signing back in resumes its own queued delete', () async {
    final a = FakeSyncTransport(userId: 'account-A')..failUpserts = true;
    await DeletionsSync.recordAll('favorites', const ['de-12345'],
        transport: a);

    // Elsewhere in between.
    await DeletionsSync.drainJournal(transport: FakeSyncTransport(userId: 'B'));

    // A comes back, connection healthy.
    final aAgain = FakeSyncTransport(userId: 'account-A');
    await DeletionsSync.drainJournal(transport: aAgain);
    expect(
      aAgain.upsertedRows('deletions').map((r) => r['record_id']),
      contains('de-12345'),
      reason: 'quarantine must be reversible — the intent was never wrong, '
          'only mis-timed',
    );
  });

  test('a delete queued before ANY sign-in is adopted by the first account',
      () async {
    // The ordinary offline case: no session yet, so there is no identity
    // to attribute the intent to. That is NOT the same as belonging to
    // someone else, and it must not be quarantined away.
    await PendingDeletionsJournal.addAll('favorites', const ['st-orphan']);
    expect(
      PendingDeletionsJournal.pendingIds('favorites',
          transport: FakeSyncTransport(userId: 'first')),
      isEmpty,
      reason: 'not yet attributed',
    );

    final first = FakeSyncTransport(userId: 'first');
    await DeletionsSync.drainJournal(transport: first);
    expect(
      first.upsertedRows('deletions').map((r) => r['record_id']),
      contains('st-orphan'),
      reason: 'an unbound intent belongs to whoever signs in first',
    );
  });

  group('SyncContextKey', () {
    test('separates accounts, backends, and null-vs-empty backend', () {
      final a = SyncContextKey.of(backendUrl: 'https://x.co', userId: 'u1');
      final b = SyncContextKey.of(backendUrl: 'https://x.co', userId: 'u2');
      final c = SyncContextKey.of(backendUrl: 'https://y.co', userId: 'u1');
      expect(a.value, isNot(b.value));
      expect(a.value, isNot(c.value));

      // A null backend must not alias with one literally named "".
      final nul = SyncContextKey.of(backendUrl: null, userId: 'u1');
      final empty = SyncContextKey.of(backendUrl: '', userId: 'u1');
      expect(nul.value, equals(empty.value),
          reason: 'both mean "no backend recorded" and collapse together');
      expect(nul.value, isNot(a.value));
    });

    test('ignores scheme and path, compares host case-insensitively', () {
      expect(
        SyncContextKey.of(backendUrl: 'https://X.CO/rest/v1', userId: 'u')
            .value,
        SyncContextKey.of(backendUrl: 'https://x.co', userId: 'u').value,
        reason: 'the same project reached two ways is one context',
      );
    });
  });
}
