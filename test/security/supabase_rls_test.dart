@Tags(['network'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Verifies the live RLS policy set on the staging Supabase project matches
/// the matrix documented in `docs/security/SUPABASE_RLS_MATRIX.md`.
///
/// Network-tagged: only runs when invoked with `--tags network`. Skips
/// cleanly when `SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY` are absent so
/// it never blocks offline PR checks.
///
/// Run locally:
///
///   `SUPABASE_URL=https://STAGING.supabase.co`
///   `SUPABASE_SERVICE_ROLE_KEY=...`
///   `flutter test test/security/supabase_rls_test.dart --tags network`
///
/// The service-role key is required because anon callers can't read
/// `pg_policies` / `pg_class`. Use a staging project, never production.
///
/// Closes #1110 (audit B7).
void main() {
  final envUrl = Platform.environment['SUPABASE_URL'] ?? '';
  final envKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ?? '';
  final hasCreds = envUrl.isNotEmpty && envKey.isNotEmpty;

  group('Supabase RLS matrix (#1110)', () {
    if (!hasCreds) {
      test(
        'skipped — SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY not set',
        () {},
        skip:
            'Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY to run this '
            'verification against a staging project. See '
            'docs/security/SUPABASE_RLS_MATRIX.md.',
      );
      return;
    }

    final supabaseUrl = envUrl;
    final serviceKey = envKey;

    test('every documented table has RLS enabled', () async {
      final rows = await _runSql(
        supabaseUrl,
        serviceKey,
        '''
        SELECT c.relname AS tablename, c.relrowsecurity AS rls
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
          AND c.relkind = 'r'
        ORDER BY c.relname
        ''',
      );

      final actual = <String, bool>{
        for (final row in rows)
          row['tablename'] as String: row['rls'] as bool,
      };

      for (final table in _expectedTables) {
        expect(
          actual.containsKey(table),
          isTrue,
          reason:
              'Table `public.$table` is missing in the live database — '
              'matrix is out of sync.',
        );
        expect(
          actual[table],
          isTrue,
          reason:
              'Table `public.$table` has RLS DISABLED — this is a '
              'data-leak vulnerability. Re-enable with '
              '`ALTER TABLE public.$table ENABLE ROW LEVEL SECURITY;` '
              'and audit recent migrations.',
        );
      }
    });

    test('policy set matches docs/security/SUPABASE_RLS_MATRIX.md', () async {
      final rows = await _runSql(
        supabaseUrl,
        serviceKey,
        '''
        SELECT tablename, policyname, cmd, qual, with_check
        FROM pg_policies
        WHERE schemaname = 'public'
        ORDER BY tablename, policyname
        ''',
      );

      final actual = <String>{
        for (final row in rows)
          '${row['tablename']}.${row['policyname']}.${row['cmd']}',
      };
      final expected = <String>{
        for (final p in _expectedPolicies) '${p.table}.${p.name}.${p.cmd}',
      };

      final missing = expected.difference(actual);
      final extra = actual.difference(expected);

      expect(
        missing,
        isEmpty,
        reason:
            'Policies expected by the matrix doc are missing from the '
            'live database. Either re-apply migrations or update '
            'docs/security/SUPABASE_RLS_MATRIX.md to match reality.\n'
            'Missing: $missing',
      );
      expect(
        extra,
        isEmpty,
        reason:
            'Policies exist in the live database that are NOT in the '
            'matrix doc. Document them in '
            'docs/security/SUPABASE_RLS_MATRIX.md so the next audit '
            'has a written justification.\n'
            'Extra: $extra',
      );
    });

    test('USING / WITH CHECK clauses match expected expressions', () async {
      final rows = await _runSql(
        supabaseUrl,
        serviceKey,
        '''
        SELECT tablename, policyname, cmd, qual, with_check
        FROM pg_policies
        WHERE schemaname = 'public'
        ORDER BY tablename, policyname
        ''',
      );

      final actual = <String, Map<String, String?>>{};
      for (final row in rows) {
        final key =
            '${row['tablename']}.${row['policyname']}.${row['cmd']}';
        actual[key] = {
          'qual': row['qual'] as String?,
          'with_check': row['with_check'] as String?,
        };
      }

      for (final p in _expectedPolicies) {
        final key = '${p.table}.${p.name}.${p.cmd}';
        final live = actual[key];
        if (live == null) {
          // Missing policies are reported by the previous test; skip.
          continue;
        }
        if (p.expectedUsingContains != null) {
          final qual = live['qual'] ?? '';
          expect(
            _normalize(qual).contains(_normalize(p.expectedUsingContains!)),
            isTrue,
            reason:
                'Policy `$key` has an unexpected USING clause.\n'
                'Expected to contain: ${p.expectedUsingContains}\n'
                'Live: $qual',
          );
        }
        if (p.expectedCheckContains != null) {
          final check = live['with_check'] ?? '';
          expect(
            _normalize(check).contains(_normalize(p.expectedCheckContains!)),
            isTrue,
            reason:
                'Policy `$key` has an unexpected WITH CHECK clause.\n'
                'Expected to contain: ${p.expectedCheckContains}\n'
                'Live: $check',
          );
        }
      }
    });
  });
}

/// POST a raw SQL string to the Supabase database via the PostgREST RPC
/// endpoint exposed by the `pg_meta` style helper. Falls back to using
/// `pg-meta`/SQL through the auth-protected `/pg/query` admin route is
/// not available on the public REST API; instead we rely on the
/// `pg_policies` / `pg_class` system views being readable directly via
/// PostgREST when called with the service-role key.
///
/// Implementation: PostgREST exposes `pg_policies` as
/// `<url>/rest/v1/pg_policies`, but only inside the `public` schema. The
/// system catalogs live in `pg_catalog`, so we use the SQL pass-through
/// the project provides via the `query` RPC. If that RPC is not present,
/// the test setUpAll throws a clear error.
Future<List<Map<String, dynamic>>> _runSql(
  String url,
  String serviceKey,
  String sql,
) async {
  // Supabase ships a `query` RPC out of the box on the
  // service-role-only path `/rest/v1/rpc/query` for some projects, but
  // it is NOT guaranteed. The portable answer is the
  // `/pg/query` PostgREST extension exposed by Supabase Studio:
  //   https://supabase.com/docs/reference/api/select-from-pg-policies
  //
  // PostgREST CAN expose `information_schema.*` views directly on the
  // REST surface; `pg_policies` is in `pg_catalog`. The simplest
  // service-role-authenticated path that works against any Supabase
  // project is the GET on
  // `<url>/rest/v1/<view>?select=*` provided the view is present on
  // the `public` search path. Supabase exposes `pg_policies` via the
  // `extensions` schema on hosted projects, but to keep this test
  // portable we use the SQL-pass-through Edge Function pattern that
  // ships with the Supabase CLI's `db reset` helper.
  //
  // For the common case (a hosted Supabase project), the
  // service-role key has direct database access through the
  // `database` REST endpoint:
  //   POST <url>/database/query  with body { "query": "<sql>" }
  // — this is the same endpoint the dashboard uses.
  final endpoint = Uri.parse(
    '${url.replaceAll(RegExp(r'/$'), '')}/database/query',
  );
  final response = await http
      .post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'apikey': serviceKey,
          'Authorization': 'Bearer $serviceKey',
        },
        body: jsonEncode({'query': sql}),
      )
      .timeout(const Duration(seconds: 30));

  if (response.statusCode == 404) {
    // Project does not expose `/database/query`. Fall back to the
    // PostgREST RPC `exec_sql` if the project has it; otherwise abort
    // with a clear instruction.
    final rpcEndpoint = Uri.parse(
      '${url.replaceAll(RegExp(r'/$'), '')}/rest/v1/rpc/exec_sql',
    );
    final rpcResponse = await http
        .post(
          rpcEndpoint,
          headers: {
            'Content-Type': 'application/json',
            'apikey': serviceKey,
            'Authorization': 'Bearer $serviceKey',
          },
          body: jsonEncode({'query': sql}),
        )
        .timeout(const Duration(seconds: 30));
    if (rpcResponse.statusCode != 200) {
      throw StateError(
        'Could not execute SQL against staging Supabase project. '
        'Neither `/database/query` nor `/rest/v1/rpc/exec_sql` is '
        'available. Add an `exec_sql` RPC to the staging project, or '
        'run the test against a project that exposes the dashboard '
        'query endpoint.\n'
        'Last response: ${rpcResponse.statusCode} ${rpcResponse.body}',
      );
    }
    return List<Map<String, dynamic>>.from(
      jsonDecode(rpcResponse.body) as List<dynamic>,
    );
  }
  if (response.statusCode != 200) {
    throw StateError(
      'SQL query against $endpoint failed: '
      '${response.statusCode} ${response.body}',
    );
  }
  return List<Map<String, dynamic>>.from(
    jsonDecode(response.body) as List<dynamic>,
  );
}

/// Strip whitespace + parentheses for tolerant string matching of
/// PostgreSQL-stored expressions. PG re-parses and re-prints USING /
/// WITH CHECK clauses, so `user_id = auth.uid()` may come back as
/// `(user_id = auth.uid())` or with extra spaces.
String _normalize(String s) =>
    s.replaceAll(RegExp(r'\s+'), '').replaceAll('(', '').replaceAll(')', '');

const _expectedTables = <String>[
  'alerts',
  'database_owner',
  'favorites',
  'fill_ups',
  'ignored_stations',
  'itineraries',
  'obd2_baselines',
  'price_reports',
  'price_snapshots',
  'push_tokens',
  'station_ratings',
  'sync_settings',
  'users',
  'vehicles',
];

class _ExpectedPolicy {
  const _ExpectedPolicy({
    required this.table,
    required this.name,
    required this.cmd,
    this.expectedUsingContains,
    this.expectedCheckContains,
  });

  final String table;
  final String name;
  final String cmd; // 'SELECT' / 'INSERT' / 'UPDATE' / 'DELETE' / 'ALL'
  final String? expectedUsingContains;
  final String? expectedCheckContains;
}

/// The policies we expect to find in the live database. Cmd values use
/// the spelling `pg_policies.cmd` returns: `SELECT`, `INSERT`, `UPDATE`,
/// `DELETE`, `ALL`. Keep this in lockstep with
/// `docs/security/SUPABASE_RLS_MATRIX.md`.
const _expectedPolicies = <_ExpectedPolicy>[
  // users (split policies after 20260401000001_owner_protection.sql)
  _ExpectedPolicy(
    table: 'users',
    name: 'users_own_select',
    cmd: 'SELECT',
    expectedUsingContains: 'id = auth.uid()',
  ),
  _ExpectedPolicy(
    table: 'users',
    name: 'users_own_insert',
    cmd: 'INSERT',
    expectedCheckContains: 'id = auth.uid()',
  ),
  _ExpectedPolicy(
    table: 'users',
    name: 'users_own_update',
    cmd: 'UPDATE',
    expectedUsingContains: 'id = auth.uid()',
  ),
  _ExpectedPolicy(
    table: 'users',
    name: 'users_delete_owner_only',
    cmd: 'DELETE',
    expectedUsingContains: 'is_database_owner',
  ),

  // favorites
  _ExpectedPolicy(
    table: 'favorites',
    name: 'favorites_own',
    cmd: 'ALL',
    expectedUsingContains: 'user_id = auth.uid()',
  ),

  // alerts
  _ExpectedPolicy(
    table: 'alerts',
    name: 'alerts_own',
    cmd: 'ALL',
    expectedUsingContains: 'user_id = auth.uid()',
  ),

  // price_snapshots
  _ExpectedPolicy(
    table: 'price_snapshots',
    name: 'snapshots_read',
    cmd: 'SELECT',
    expectedUsingContains: 'true',
  ),
  _ExpectedPolicy(
    table: 'price_snapshots',
    name: 'snapshots_insert',
    cmd: 'INSERT',
    expectedCheckContains: "auth.role() = 'service_role'",
  ),
  _ExpectedPolicy(
    table: 'price_snapshots',
    name: 'snapshots_delete',
    cmd: 'DELETE',
    expectedUsingContains: "auth.role() = 'service_role'",
  ),

  // price_reports
  _ExpectedPolicy(
    table: 'price_reports',
    name: 'reports_insert',
    cmd: 'INSERT',
    expectedCheckContains: 'reporter_id = auth.uid()',
  ),
  _ExpectedPolicy(
    table: 'price_reports',
    name: 'reports_read',
    cmd: 'SELECT',
    expectedUsingContains: 'true',
  ),
  _ExpectedPolicy(
    table: 'price_reports',
    name: 'reports_delete',
    cmd: 'DELETE',
    expectedUsingContains: 'reporter_id = auth.uid()',
  ),

  // push_tokens
  _ExpectedPolicy(
    table: 'push_tokens',
    name: 'push_own',
    cmd: 'ALL',
    expectedUsingContains: 'user_id = auth.uid()',
  ),

  // sync_settings
  _ExpectedPolicy(
    table: 'sync_settings',
    name: 'sync_own',
    cmd: 'ALL',
    expectedUsingContains: 'user_id = auth.uid()',
  ),

  // itineraries
  _ExpectedPolicy(
    table: 'itineraries',
    name: 'itineraries_own',
    cmd: 'ALL',
    expectedUsingContains: 'user_id = auth.uid()',
  ),

  // ignored_stations
  _ExpectedPolicy(
    table: 'ignored_stations',
    name: 'ignored_own',
    cmd: 'ALL',
    expectedUsingContains: 'user_id = auth.uid()',
  ),

  // station_ratings
  _ExpectedPolicy(
    table: 'station_ratings',
    name: 'ratings_own',
    cmd: 'ALL',
    expectedUsingContains: 'user_id = auth.uid()',
  ),
  _ExpectedPolicy(
    table: 'station_ratings',
    name: 'ratings_shared_read',
    cmd: 'SELECT',
    expectedUsingContains: 'is_shared',
  ),

  // database_owner
  _ExpectedPolicy(
    table: 'database_owner',
    name: 'owner_read',
    cmd: 'SELECT',
    expectedUsingContains: 'true',
  ),
  _ExpectedPolicy(
    table: 'database_owner',
    name: 'owner_manage',
    cmd: 'ALL',
    expectedUsingContains: "auth.role() = 'service_role'",
  ),

  // vehicles
  _ExpectedPolicy(
    table: 'vehicles',
    name: 'vehicles_own',
    cmd: 'ALL',
    expectedUsingContains: 'user_id = auth.uid()',
  ),

  // fill_ups
  _ExpectedPolicy(
    table: 'fill_ups',
    name: 'fill_ups_own',
    cmd: 'ALL',
    expectedUsingContains: 'user_id = auth.uid()',
  ),

  // obd2_baselines
  _ExpectedPolicy(
    table: 'obd2_baselines',
    name: 'obd2_baselines_own',
    cmd: 'ALL',
    expectedUsingContains: 'user_id = auth.uid()',
  ),
];
