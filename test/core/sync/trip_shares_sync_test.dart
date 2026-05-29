// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/trip_shares_sync.dart';
import '../../helpers/silence_error_logger.dart';

/// #2240 — coverage of [TripSharesSync] (cross-account trip sharing).
///
/// Like [TripsSync], this reads the static `TankSyncClient.client`
/// directly, so the live wire `insert` / `rpc` / `select` calls can't
/// be exercised in a unit test without a real Supabase client. The
/// strategy mirrors `trips_sync_test.dart`: pin the pure,
/// `@visibleForTesting` decode / token seams plus the unauthenticated
/// do-no-harm guards, rather than mocking the brittle query-builder
/// chain.
///
/// ── RLS CONTRACT (documented, enforced server-side) ──────────────────
/// The security guarantees this client depends on live in
/// `supabase/migrations/20260529000001_trip_shares.sql`, NOT in Dart —
/// RLS is the actual boundary. They are restated here so a future
/// refactor of this client knows exactly what the server promises:
///
///   1. A recipient (`shared_with_id = auth.uid()`) can SELECT the
///      grant row AND, via the additive `trip_summaries_shared_read` /
///      `trip_details_shared_read` policies, the shared trip itself.
///      → `fetchSharedWithMe()` relies on this: it filters
///        `trip_summaries` by id, NOT by user_id, trusting RLS to
///        expose exactly the rows shared with the caller.
///   2. A NON-recipient sees neither the grant nor the trip — the
///      EXISTS sub-query in the additive policy returns no row, and the
///      own-row policy gates on `user_id = auth.uid()`, which is the
///      OWNER's id, not theirs. There is no client code path that can
///      widen this; the negative case is purely an RLS guarantee.
///   3. Only the owner (`owner_id = auth.uid()`) can INSERT / DELETE a
///      grant — `revoke()` filters by `owner_id` so even a leaked id
///      can't delete another user's share, and the RLS DELETE policy
///      backstops it.
///   4. Sharing only WIDENS read access — no policy added by the
///      migration grants INSERT/UPDATE/DELETE on trip_summaries /
///      trip_details to a recipient, so a shared trip is strictly
///      read-only for the recipient.
void main() {
  silenceErrorLoggerSpool();

  group('TripSharesSync — unauthenticated do-no-harm guards', () {
    test('shareWithEmail returns notAuthenticated when not signed in',
        () async {
      final result =
          await TripSharesSync.shareWithEmail('trip-1', 'a@example.com');
      expect(result, TripShareResult.notAuthenticated);
    });

    test('createShareLink returns null when not signed in', () async {
      expect(await TripSharesSync.createShareLink('trip-1'), isNull);
    });

    test('claimShareLink returns false when not signed in', () async {
      expect(await TripSharesSync.claimShareLink('some-token'), isFalse);
    });

    test('listSharesForTrip returns empty when not signed in', () async {
      expect(await TripSharesSync.listSharesForTrip('trip-1'), isEmpty);
    });

    test('fetchSharedWithMe returns empty when not signed in', () async {
      // Mirrors RLS contract #1/#2: with no session there's no
      // auth.uid(), so the recipient policy matches nothing.
      expect(await TripSharesSync.fetchSharedWithMe(), isEmpty);
    });

    test('revoke is a no-op when not signed in', () async {
      await TripSharesSync.revoke('share-1');
    });
  });

  group('TripSharesSync.parseShareRows', () {
    test('decodes a direct share and a link share, drops malformed rows',
        () {
      final shares = TripSharesSync.parseShareRows([
        {
          'id': 's1',
          'trip_id': 't1',
          'owner_id': 'owner',
          'shared_with_id': 'recipient',
          'share_token': null,
        },
        {
          'id': 's2',
          'trip_id': 't1',
          'owner_id': 'owner',
          'shared_with_id': null,
          'share_token': 'tok123',
        },
        // Malformed: missing the non-null trip_id — must be dropped, not
        // throw, so one bad row never blanks the whole list.
        {'id': 's3', 'owner_id': 'owner'},
      ]);
      expect(shares, hasLength(2));
      expect(shares[0].id, 's1');
      expect(shares[0].sharedWithId, 'recipient');
      expect(shares[0].shareToken, isNull);
      expect(shares[1].sharedWithId, isNull);
      expect(shares[1].shareToken, 'tok123');
    });

    test('empty rows decode to empty list', () {
      expect(TripSharesSync.parseShareRows(const []), isEmpty);
    });
  });

  group('TripSharesSync.parseSharedSummaries', () {
    test('decodes a shared trip summary and drops undecodable rows', () {
      // A trip the SERVER returned because RLS exposed it (the row's
      // user_id is the owner's; the recipient reads it by id). The
      // client never inspects user_id — it trusts RLS — so the decode
      // path only cares about the `data` blob shape.
      final rows = <Map<String, dynamic>>[
        {
          'id': 'shared-trip',
          'data': {
            'id': 'shared-trip',
            'vehicleId': null,
            'summary': {
              'startedAt': '2026-05-10T10:00:00.000',
              'endedAt': '2026-05-10T10:30:00.000',
              'distanceKm': 12.5,
              'maxRpm': 3000,
              'highRpmSeconds': 5,
              'idleSeconds': 30,
              'harshBrakes': 0,
              'harshAccelerations': 0,
            },
          },
        },
        // `data` not a Map → skipped.
        {'id': 'bad', 'data': 'not-a-map'},
      ];
      final entries = TripSharesSync.parseSharedSummaries(rows);
      expect(entries, hasLength(1));
      expect(entries.single.id, 'shared-trip');
      expect(entries.single.summary.distanceKm, 12.5);
      // Recipient gets a SUMMARY only — the heavy per-tick samples live
      // in trip_details and arrive on demand. (read-only surface)
      expect(entries.single.samples, isEmpty);
    });
  });

  group('TripSharesSync.generateShareToken', () {
    test('is 32 url-safe lowercase chars', () {
      final token = TripSharesSync.generateShareToken();
      expect(token, hasLength(32));
      expect(RegExp(r'^[a-z0-9]{32}$').hasMatch(token), isTrue);
    });

    test('two consecutive tokens differ (entropy sanity)', () {
      expect(TripSharesSync.generateShareToken(),
          isNot(TripSharesSync.generateShareToken()));
    });

    test('is deterministic under a seeded Random (test seam)', () {
      final a = TripSharesSync.generateShareToken(random: Random(42));
      final b = TripSharesSync.generateShareToken(random: Random(42));
      expect(a, b);
    });
  });
}
