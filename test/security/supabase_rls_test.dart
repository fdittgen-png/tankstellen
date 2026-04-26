@Tags(['network'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// #1110 — Supabase RLS policy verification. Rerun after any migration
/// under `supabase/migrations/` that touches `CREATE POLICY` or
/// `ENABLE/DISABLE ROW LEVEL SECURITY`, and whenever
/// `docs/security/SUPABASE_RLS_MATRIX.md` is edited (matrix and test
/// move together). See `docs/guides/NETWORK_TESTS.md`.
///
/// Calls the `public.audit_rls_policies()` SQL function (added by
/// migration `20260426000001_rls_audit_function.sql`) against a live
/// Supabase project and asserts:
///
///   1. Every table named in `_expectedPolicies` has every policy
///      named there. The `cmd` (SELECT/INSERT/UPDATE/DELETE/ALL) on
///      the policy is checked too.
///   2. No `public.*` table is RLS-enabled-with-zero-policies.
///      That state is the silent-fail Supabase posture — the table
///      is effectively read-locked for `authenticated` users while
///      remaining writable to `service_role`. Either RLS is wrong
///      or a policy is missing.
///   3. Every table found in the live schema is covered by the
///      matrix. If a new table appears that the matrix doesn't know
///      about, the test fails — forcing a doc + test update before
///      the table can be merged.
///
/// Tagged `network` so the default `flutter test` run skips it. To
/// invoke locally:
///
/// ```bash
/// SUPABASE_TEST_URL='https://<project>.supabase.co' \
/// SUPABASE_TEST_SERVICE_KEY='<service_role_key>' \
/// flutter test --tags network test/security/supabase_rls_test.dart
/// ```
///
/// If the env vars are absent the test prints a clear message and
/// skips — local development without Supabase credentials is not a
/// hard failure. CI runs this on tag releases against the staging
/// project (see `.github/workflows/release.yml`).
///
/// See `docs/security/SUPABASE_RLS_MATRIX.md` for the human-readable
/// policy matrix and the workflow for keeping it in sync with this
/// test.
void main() {
  final supabaseUrl = Platform.environment['SUPABASE_TEST_URL'];
  final serviceKey = Platform.environment['SUPABASE_TEST_SERVICE_KEY'];
  final hasCredentials =
      supabaseUrl != null &&
      supabaseUrl.isNotEmpty &&
      serviceKey != null &&
      serviceKey.isNotEmpty;

  // The matrix the test enforces. Keep in lock-step with
  // `docs/security/SUPABASE_RLS_MATRIX.md` — when a migration adds,
  // removes, or renames a policy, both files change in the same PR.
  //
  // Each entry maps a policy_name to its expected `cmd`. Postgres
  // reports `cmd` as one of: SELECT, INSERT, UPDATE, DELETE, ALL.
  const expectedPolicies = <String, Map<String, String>>{
    'users': {
      'users_own_select': 'SELECT',
      'users_own_insert': 'INSERT',
      'users_own_update': 'UPDATE',
      'users_delete_owner_only': 'DELETE',
    },
    'favorites': {
      'favorites_own': 'ALL',
    },
    'alerts': {
      'alerts_own': 'ALL',
    },
    'price_snapshots': {
      'snapshots_read': 'SELECT',
      'snapshots_insert': 'INSERT',
      'snapshots_delete': 'DELETE',
    },
    'price_reports': {
      'reports_insert': 'INSERT',
      'reports_read': 'SELECT',
      'reports_delete': 'DELETE',
    },
    'push_tokens': {
      'push_own': 'ALL',
    },
    'sync_settings': {
      'sync_own': 'ALL',
    },
    'itineraries': {
      'itineraries_own': 'ALL',
    },
    'ignored_stations': {
      'ignored_own': 'ALL',
    },
    'station_ratings': {
      'ratings_own': 'ALL',
      'ratings_shared_read': 'SELECT',
    },
    'database_owner': {
      'owner_read': 'SELECT',
      'owner_manage': 'ALL',
    },
    'vehicles': {
      'vehicles_own': 'ALL',
    },
    'fill_ups': {
      'fill_ups_own': 'ALL',
    },
    'obd2_baselines': {
      'obd2_baselines_own': 'ALL',
    },
  };

  group('Supabase RLS matrix (#1110)', () {
    if (!hasCredentials) {
      test(
        'skipped — set SUPABASE_TEST_URL + SUPABASE_TEST_SERVICE_KEY to run',
        () {
          // ignore: avoid_print
          print(
            'Skipping Supabase RLS verification: '
            'SUPABASE_TEST_URL and/or SUPABASE_TEST_SERVICE_KEY env '
            'vars are not set. This is expected on local dev machines '
            'without staging credentials. CI sets them on tag releases.',
          );
        },
        skip: 'Supabase test credentials not configured',
      );
      return;
    }

    late List<Map<String, dynamic>> auditRows;

    setUpAll(() async {
      auditRows = await _fetchPolicyAudit(
        supabaseUrl: supabaseUrl,
        serviceKey: serviceKey,
      );
    });

    test('every expected policy is present with the right cmd', () {
      final missing = <String>[];
      final wrongCmd = <String>[];

      for (final entry in expectedPolicies.entries) {
        final tableName = entry.key;
        for (final policy in entry.value.entries) {
          final policyName = policy.key;
          final expectedCmd = policy.value;
          final match = auditRows.firstWhere(
            (row) =>
                row['table_name'] == tableName &&
                row['policy_name'] == policyName,
            orElse: () => <String, dynamic>{},
          );
          if (match.isEmpty) {
            missing.add('$tableName.$policyName');
            continue;
          }
          final actualCmd = (match['policy_cmd'] as String?)?.toUpperCase();
          if (actualCmd != expectedCmd) {
            wrongCmd.add(
              '$tableName.$policyName expected cmd=$expectedCmd, '
              'got cmd=$actualCmd',
            );
          }
        }
      }

      expect(
        missing,
        isEmpty,
        reason:
            'Missing RLS policies (matrix vs. live schema):\n'
            '  ${missing.join('\n  ')}\n'
            'Either a migration dropped them or the matrix in '
            'docs/security/SUPABASE_RLS_MATRIX.md is stale.',
      );
      expect(
        wrongCmd,
        isEmpty,
        reason:
            'RLS policies with wrong cmd:\n  ${wrongCmd.join('\n  ')}',
      );
    });

    test('no public table is RLS-enabled-with-zero-policies', () {
      // Group rows by table_name; a row with policy_name == null AND
      // rls_enabled == true means the table has RLS on but no policies
      // covering any caller — silent-fail posture.
      final byTable = <String, List<Map<String, dynamic>>>{};
      for (final row in auditRows) {
        final t = row['table_name'] as String;
        byTable.putIfAbsent(t, () => []).add(row);
      }

      final silentFails = <String>[];
      for (final entry in byTable.entries) {
        final tableName = entry.key;
        final rows = entry.value;
        final hasAnyPolicy = rows.any((r) => r['policy_name'] != null);
        // The function returns a single row with NULL policy columns
        // when a table has zero policies. If RLS is enabled and there
        // are no policies, surface it.
        final rlsEnabled = rows.any((r) => r['rls_enabled'] == true);
        if (rlsEnabled && !hasAnyPolicy) {
          silentFails.add(tableName);
        }
      }

      expect(
        silentFails,
        isEmpty,
        reason:
            'These public tables have RLS enabled but zero policies, '
            'which read-locks them for authenticated users: '
            '${silentFails.join(', ')}. Either disable RLS (open data) '
            'or add the missing policies. See docs/security/'
            'SUPABASE_RLS_MATRIX.md.',
      );
    });

    test('no public table is RLS-disabled', () {
      // The audit function returns one row per (table, policy) — for
      // tables with zero policies it returns a single row with NULL
      // policy columns. Either way `rls_enabled` reflects the table,
      // so we can collapse to one entry per table_name.
      final byTable = <String, bool>{};
      for (final row in auditRows) {
        final t = row['table_name'] as String;
        final enabled = row['rls_enabled'] == true;
        byTable[t] = byTable[t] == true || enabled;
      }

      final disabled = <String>[];
      for (final entry in byTable.entries) {
        if (!entry.value) disabled.add(entry.key);
      }

      expect(
        disabled,
        isEmpty,
        reason:
            'These public tables have Row Level Security DISABLED — '
            'the anon key can read every row: ${disabled.join(', ')}. '
            'Add `ALTER TABLE public.<name> ENABLE ROW LEVEL SECURITY;` '
            'in a migration.',
      );
    });

    test('every live table is covered by the matrix', () {
      final liveTables = auditRows
          .map((r) => r['table_name'] as String)
          .toSet();
      final knownTables = expectedPolicies.keys.toSet();

      final unknown = liveTables.difference(knownTables);

      expect(
        unknown,
        isEmpty,
        reason:
            'These tables exist in the live schema but are not in '
            'docs/security/SUPABASE_RLS_MATRIX.md: '
            '${unknown.join(', ')}. Add them to the matrix and to '
            '_expectedPolicies in this test.',
      );
    });
  });
}

/// Calls the `public.audit_rls_policies()` SQL function via Supabase
/// PostgREST and returns the rows as JSON-decoded maps.
///
/// Uses the service-role key because the function is locked down to
/// `service_role` (anon callers get an empty result by design).
Future<List<Map<String, dynamic>>> _fetchPolicyAudit({
  required String supabaseUrl,
  required String serviceKey,
}) async {
  final cleanUrl = supabaseUrl.replaceAll(RegExp(r'/+$'), '');
  final endpoint = Uri.parse('$cleanUrl/rest/v1/rpc/audit_rls_policies');

  final response = await http
      .post(
        endpoint,
        headers: {
          'apikey': serviceKey,
          'Authorization': 'Bearer $serviceKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: '{}',
      )
      .timeout(const Duration(seconds: 30));

  if (response.statusCode != 200) {
    fail(
      'audit_rls_policies RPC failed: '
      'HTTP ${response.statusCode} — ${response.body}\n'
      'If the function is missing, apply migration '
      '`supabase/migrations/20260426000001_rls_audit_function.sql` '
      'against the test project first (`supabase db push`).',
    );
  }

  final decoded = json.decode(response.body);
  if (decoded is! List) {
    fail(
      'audit_rls_policies returned non-list payload: $decoded',
    );
  }
  return decoded
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}
