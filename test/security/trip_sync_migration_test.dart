import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// #1479 phase 1 — static smoke test for the trip-sync migration.
///
/// This is NOT a live Supabase call. It reads the migration SQL file
/// from disk and asserts the four invariants TankSync sync tables
/// MUST satisfy:
///
///   1. Both `public.trip_summaries` AND `public.trip_details` are
///      created.
///   2. RLS is explicitly enabled on each table (no Supabase table is
///      allowed to ship RLS-disabled — see
///      `docs/security/SUPABASE_RLS_MATRIX.md`).
///   3. Each table has a `_own` policy attached. Without a policy the
///      table is read-locked for authenticated users.
///   4. The migration file is referenced from the RLS matrix doc so
///      the audit trail stays in sync.
///
/// If a future migration drops one of these properties, the live
/// `supabase_rls_test.dart` would catch it on next staging run, but
/// that test is `@Tags(['network'])` and only runs on tag releases.
/// This test runs in the default suite and surfaces the regression at
/// PR-time.
void main() {
  group('trip-sync migration (#1479 phase 1)', () {
    final migrationFile = File(
      'supabase/migrations/20260507000001_trip_summaries_and_details.sql',
    );

    test('migration file exists', () {
      expect(
        migrationFile.existsSync(),
        isTrue,
        reason:
            'Expected migration at ${migrationFile.path}. Did the file '
            'get moved or renamed? Update this test in the same PR.',
      );
    });

    test('creates both trip_summaries and trip_details tables', () {
      final sql = migrationFile.readAsStringSync();

      final summariesCreate = RegExp(
        r'CREATE TABLE\s+IF NOT EXISTS\s+public\.trip_summaries',
        caseSensitive: false,
      );
      final detailsCreate = RegExp(
        r'CREATE TABLE\s+IF NOT EXISTS\s+public\.trip_details',
        caseSensitive: false,
      );

      expect(
        summariesCreate.hasMatch(sql),
        isTrue,
        reason: 'public.trip_summaries CREATE TABLE not found in migration.',
      );
      expect(
        detailsCreate.hasMatch(sql),
        isTrue,
        reason: 'public.trip_details CREATE TABLE not found in migration.',
      );
    });

    test('enables RLS on both tables', () {
      final sql = migrationFile.readAsStringSync();

      final summariesRls = RegExp(
        r'ALTER TABLE\s+public\.trip_summaries\s+ENABLE ROW LEVEL SECURITY',
        caseSensitive: false,
      );
      final detailsRls = RegExp(
        r'ALTER TABLE\s+public\.trip_details\s+ENABLE ROW LEVEL SECURITY',
        caseSensitive: false,
      );

      expect(
        summariesRls.hasMatch(sql),
        isTrue,
        reason:
            'trip_summaries is missing `ALTER TABLE ... ENABLE ROW LEVEL '
            'SECURITY`. Without it the anon key reads every row.',
      );
      expect(
        detailsRls.hasMatch(sql),
        isTrue,
        reason:
            'trip_details is missing `ALTER TABLE ... ENABLE ROW LEVEL '
            'SECURITY`. Without it the anon key reads every row.',
      );
    });

    test('creates a per-table _own policy', () {
      final sql = migrationFile.readAsStringSync();

      final summariesPolicy = RegExp(
        r'CREATE POLICY\s+trip_summaries_own\s+ON\s+public\.trip_summaries',
        caseSensitive: false,
      );
      final detailsPolicy = RegExp(
        r'CREATE POLICY\s+trip_details_own\s+ON\s+public\.trip_details',
        caseSensitive: false,
      );

      expect(
        summariesPolicy.hasMatch(sql),
        isTrue,
        reason:
            'trip_summaries_own policy missing — table is RLS-enabled '
            'with zero policies, which read-locks it for authenticated '
            'users.',
      );
      expect(
        detailsPolicy.hasMatch(sql),
        isTrue,
        reason:
            'trip_details_own policy missing — table is RLS-enabled '
            'with zero policies, which read-locks it for authenticated '
            'users.',
      );
    });

    test('migration is referenced from the RLS matrix doc', () {
      final matrix = File('docs/security/SUPABASE_RLS_MATRIX.md');
      expect(
        matrix.existsSync(),
        isTrue,
        reason: 'docs/security/SUPABASE_RLS_MATRIX.md is missing.',
      );

      final body = matrix.readAsStringSync();
      expect(
        body.contains('20260507000001_trip_summaries_and_details.sql'),
        isTrue,
        reason:
            'The trip-sync migration is not listed in the RLS matrix '
            'doc. Add it under "Migrations that touch RLS".',
      );
      expect(
        body.contains('`trip_summaries`'),
        isTrue,
        reason: 'trip_summaries row missing from the RLS matrix table.',
      );
      expect(
        body.contains('`trip_details`'),
        isTrue,
        reason: 'trip_details row missing from the RLS matrix table.',
      );
    });
  });
}
