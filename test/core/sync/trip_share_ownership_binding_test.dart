// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/schema_sql.dart';

/// #4049 — the wizard SQL must bind trip-share grants to trip ownership.
///
/// ## The defect this pins shut
///
/// A `trip_shares` row proved who CREATED a grant and never that the
/// grant's `trip_id` belonged to that creator; the additive read policies
/// then matched a grant on `(trip_id, recipient)` alone. Any authenticated
/// user could name another account's trip id, make themselves both owner
/// and recipient, and read that trip.
///
/// Confirmed by execution against the live project on 2026-09-11 with
/// synthetic actors in a rolled-back transaction — before the fix all four
/// paths worked (INSERT self-grant, UPDATE repoint, the SECURITY DEFINER
/// RPC, and reads of both `trip_summaries` and `trip_details`); after it,
/// all four are blocked and legitimate sharing still works.
///
/// These are STRING assertions on the SQL a self-hoster pastes, not a
/// database test — the behavioural proof lives in the migration's header
/// and cannot run in CI without a Postgres instance. They exist so the
/// binding cannot be dropped from the wizard by a later edit while the
/// versioned migration keeps it, which is exactly how a self-host silently
/// diverges from the maintainer's project (HARD RULE #5).
void main() {
  final sql = buildMigrationSql(const <String, bool>{});

  test('owns_trip is defined BEFORE the policies that call it (#4049)', () {
    final fn = sql.indexOf('FUNCTION public.owns_trip');
    final policy = sql.indexOf('trip_shares_owner_insert');
    expect(fn, greaterThanOrEqualTo(0),
        reason: 'the wizard must emit the ownership oracle at all');
    expect(policy, greaterThanOrEqualTo(0));
    expect(fn, lessThan(policy),
        reason: 'CREATE POLICY resolves the functions in its expression at '
            'creation time — emitting the policy first fails the paste with '
            '"function public.owns_trip(text, uuid) does not exist"');
  });

  test('both WRITE policies require trip ownership (#4049)', () {
    for (final policy in const [
      'trip_shares_owner_insert',
      'trip_shares_owner_update',
    ]) {
      final start = sql.indexOf('CREATE POLICY $policy');
      expect(start, greaterThanOrEqualTo(0), reason: '$policy must exist');
      final body = sql.substring(start, sql.indexOf(';', start));
      expect(body, contains('owns_trip'),
          reason: '$policy must bind the grant to a trip the grantor owns — '
              'owner_id = auth.uid() alone proves authorship of the ROW, '
              'not of the TRIP');
    }
  });

  test('the UPDATE policy checks ownership on BOTH sides (#4049)', () {
    // USING stops an already-foreign grant being touched; WITH CHECK stops
    // a legitimate grant being repointed at someone else's trip. Checking
    // only one half leaves the repoint attack working, which it was.
    final start = sql.indexOf('CREATE POLICY trip_shares_owner_update');
    final body = sql.substring(start, sql.indexOf(';', start));
    expect('owns_trip'.allMatches(body).length, greaterThanOrEqualTo(2),
        reason: 'USING and WITH CHECK must both demand ownership');
  });

  test('both READ policies bind the grant owner to the row owner (#4049)', () {
    for (final table in const ['trip_summaries', 'trip_details']) {
      final start = sql.indexOf('CREATE POLICY ${table}_shared_read');
      expect(start, greaterThanOrEqualTo(0), reason: '$table policy missing');
      final body = sql.substring(start, sql.indexOf(');', start));
      expect(body, contains('s.owner_id = $table.user_id'),
          reason: 'without this, a grant naming a trip its creator does not '
              'own still opens the row — defence in depth for grants written '
              'before the write side was fixed');
    }
  });

  test('share_trip_with_email checks ownership — it bypasses RLS (#4049)', () {
    final start = sql.indexOf('FUNCTION public.share_trip_with_email');
    expect(start, greaterThanOrEqualTo(0));
    final body = sql.substring(start, sql.indexOf(r'$$;', start));
    expect(body, contains('SECURITY DEFINER'));
    expect(body, contains('owns_trip'),
        reason: 'SECURITY DEFINER means the INSERT never consults the write '
            'policies. This was the third surface, and fixing only the '
            'policies would have left it exploitable');
  });

  test('owns_trip is not callable by anon (#4049)', () {
    // Trip ids are wall-clock timestamps, so an unauthenticated
    // "does trip X belong to user Y" is a discovery primitive. The
    // Supabase security advisor flagged exactly this when the explicit
    // anon revoke was first omitted — REVOKE FROM PUBLIC does not cover it.
    expect(sql, contains('REVOKE EXECUTE ON FUNCTION public.owns_trip'),
        reason: 'anon must not be able to call the ownership oracle');
  });

  test('the schema version was bumped so self-hosts are flagged (#4049)', () {
    // Without a bump, SchemaVerifier.isSchemaOutdated stays quiet and a
    // self-host keeps the vulnerable policies with no signal at all.
    expect(kSupabaseSchemaVersion, greaterThanOrEqualTo(10));
  });
}
