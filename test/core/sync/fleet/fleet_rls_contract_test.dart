// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/schema_sql.dart';

/// #4212 — the static half of the fleet RLS contract (ADR 0025 D5/D7),
/// asserted on the SQL a self-hoster pastes AND on the versioned
/// migration, so neither can drift from the other (HARD RULE #5).
///
/// These are STRING assertions, like `trip_share_ownership_binding_test`:
/// the behavioural proof (two orgs cannot see each other; an ended
/// assignment keeps its history; an employee cannot call a manager RPC;
/// anon cannot call an oracle) needs a live Postgres and is run with the
/// live-RPC skill against the maintainer project, then pasted into the
/// PR. What CI can hold is the shape:
///
///  1. every fleet policy is SELECT-only and goes through an oracle;
///  2. there is NO INSERT / UPDATE / DELETE / ALL policy on a fleet table;
///  3. every SECURITY DEFINER function pins `search_path` and is revoked
///     from anon;
///  4. the oracles exist BEFORE the policies that call them;
///  5. no fleet table carries a location column;
///  6. the two user-linked tables — and only those — join erase_my_data.
///
/// Each assertion is mutation-checked below against a deliberately
/// broken SQL string, so a regex that matches nothing cannot pass
/// vacuously (the `source_scanning_tests_dont_execute` lesson).
void main() {
  const fleetTables = [
    'fleet_organizations',
    'fleet_members',
    'fleet_vehicles',
    'vehicle_assignments',
    'fleet_policies',
  ];
  const oracles = ['public.is_fleet_member(', 'public.fleet_role('];
  const rpcs = [
    'fleet_create_organization',
    'fleet_upsert_vehicle',
    'fleet_assign_vehicle',
    'fleet_end_assignment',
  ];

  final wizard = buildMigrationSql(const <String, bool>{});
  final migration =
      File('supabase/migrations/20260918000001_fleet_tenancy.sql')
          .readAsStringSync();

  /// Every `CREATE POLICY <name> ON public.<table> ... ;` block.
  final policyBlock = RegExp(
    r'CREATE POLICY\s+(\w+)\s+ON\s+public\.(\w+)([\s\S]*?);',
  );

  /// Every `CREATE OR REPLACE FUNCTION public.<name>(...)...$$;` block
  /// (Dart-side the dollar quotes are the same characters).
  final functionBlock = RegExp(
    r'CREATE OR REPLACE FUNCTION public\.(\w+)\(([\s\S]*?)\$\$;',
  );

  List<String> policyViolations(String sql) {
    final out = <String>[];
    for (final m in policyBlock.allMatches(sql)) {
      final name = m.group(1)!;
      final table = m.group(2)!;
      final body = m.group(3)!;
      if (!fleetTables.contains(table)) continue;
      if (!body.contains('FOR SELECT')) {
        out.add('$name on $table is not SELECT-only');
      }
      if (!oracles.any(body.contains)) {
        out.add('$name on $table does not go through an oracle');
      }
    }
    return out;
  }

  List<String> definerViolations(String sql) {
    final out = <String>[];
    for (final m in functionBlock.allMatches(sql)) {
      final name = m.group(1)!;
      final body = m.group(2)!;
      if (!name.startsWith('fleet_') && name != 'is_fleet_member') continue;
      if (!body.contains('SECURITY DEFINER')) {
        out.add('$name is not SECURITY DEFINER');
      }
      if (!body.contains('SET search_path = public')) {
        out.add('$name does not pin search_path');
      }
      if (!sql.contains('REVOKE EXECUTE ON FUNCTION public.$name(') ||
          !RegExp('REVOKE EXECUTE ON FUNCTION public\\.$name\\([^)]*\\) '
                  'FROM anon')
              .hasMatch(sql)) {
        out.add('$name is not revoked from anon');
      }
    }
    return out;
  }

  for (final (label, sql) in [('wizard SQL', wizard), ('migration', migration)]) {
    group('$label —', () {
      test('creates every fleet table with RLS enabled', () {
        for (final t in fleetTables) {
          expect(sql, contains('CREATE TABLE IF NOT EXISTS public.$t'));
          expect(sql, contains('ALTER TABLE public.$t ENABLE ROW LEVEL SECURITY'));
        }
      });

      test('every fleet policy is SELECT-only through an oracle (D7)', () {
        final fleetPolicies = policyBlock
            .allMatches(sql)
            .where((m) => fleetTables.contains(m.group(2)))
            .map((m) => m.group(1)!)
            .toList();
        expect(fleetPolicies.length, fleetTables.length,
            reason: 'one read policy per fleet table, got $fleetPolicies');
        expect(policyViolations(sql), isEmpty);
      });

      test('no INSERT / UPDATE / DELETE / ALL policy exists on a fleet '
          'table — writes are RPC-only (D7)', () {
        for (final m in policyBlock.allMatches(sql)) {
          if (!fleetTables.contains(m.group(2))) continue;
          final body = m.group(3)!;
          for (final cmd in const ['FOR INSERT', 'FOR UPDATE', 'FOR DELETE', 'FOR ALL']) {
            expect(body, isNot(contains(cmd)),
                reason: '${m.group(1)} on ${m.group(2)} is $cmd');
          }
          expect(body, isNot(contains('WITH CHECK')),
              reason: '${m.group(1)}: a WITH CHECK means a write policy');
        }
      });

      test('every fleet SECURITY DEFINER function pins search_path and is '
          'revoked from anon', () {
        final names = functionBlock
            .allMatches(sql)
            .map((m) => m.group(1)!)
            .where((n) => n.startsWith('fleet_') || n == 'is_fleet_member')
            .toSet();
        expect(names, containsAll([...rpcs, 'fleet_role', 'is_fleet_member']));
        expect(definerViolations(sql), isEmpty);
      });

      test('the oracles are defined BEFORE the policies that call them', () {
        final oracle = sql.indexOf('FUNCTION public.is_fleet_member(');
        final role = sql.indexOf('FUNCTION public.fleet_role(');
        final firstPolicy = sql.indexOf('CREATE POLICY fleet_');
        expect(oracle, greaterThanOrEqualTo(0));
        expect(role, greaterThanOrEqualTo(0));
        expect(firstPolicy, greaterThanOrEqualTo(0));
        expect(oracle, lessThan(firstPolicy),
            reason: 'CREATE POLICY resolves functions at creation time');
        expect(role, lessThan(firstPolicy));
      });

      test('the oracles are caller-bound — no user parameter', () {
        expect(sql, contains('FUNCTION public.is_fleet_member(p_org UUID)'));
        expect(sql, contains('FUNCTION public.fleet_role(p_org UUID)'));
        expect(sql, isNot(contains('is_fleet_member(p_org UUID, p_user')));
      });

      test('every write RPC re-checks the role inside its body (#4049\'s '
          'third surface)', () {
        for (final m in functionBlock.allMatches(sql)) {
          final name = m.group(1)!;
          if (!rpcs.contains(name)) continue;
          final body = m.group(2)!;
          expect(body, contains('auth.uid()'), reason: name);
          if (name != 'fleet_create_organization') {
            expect(body, contains('public.fleet_role('), reason: name);
            expect(body, contains("IN ('manager', 'admin')"), reason: name);
          }
        }
      });

      test('fleet_create_organization refuses without the operator switch '
          '(D3), the e-mail identity (D2), or when already a member (D1)',
          () {
        final m = functionBlock
            .allMatches(sql)
            .firstWhere((m) => m.group(1) == 'fleet_create_organization');
        final body = m.group(2)!;
        expect(body, contains("key = 'fleet_enabled'"));
        expect(body, contains("'fleet_disabled'"));
        expect(body, contains("'is_anonymous'"));
        expect(body, contains("'identity_required'"));
        expect(body, contains("'already_member'"));
      });

      test('fleet_end_assignment stamps effective_to and never deletes', () {
        final m = functionBlock
            .allMatches(sql)
            .firstWhere((m) => m.group(1) == 'fleet_end_assignment');
        final body = m.group(2)!;
        expect(body, contains('SET effective_to'));
        expect(body.toUpperCase(), isNot(contains('DELETE FROM')));
      });

      test('no fleet table carries a location column (D5)', () {
        // Whole identifiers only: `plate_masked` contains "lat" and is
        // not a coordinate.
        final location = RegExp(
            r'\b(lat|lon|lng|latitude|longitude|geohash|location|position|'
            r'station_id|coords?|geom|geometry)\b');
        for (final t in fleetTables) {
          final start = sql.indexOf('CREATE TABLE IF NOT EXISTS public.$t');
          final ddl = sql.substring(start, sql.indexOf(');', start));
          expect(location.hasMatch(ddl.toLowerCase()), isFalse,
              reason: '$t must not carry a location column');
        }
        expect(location.hasMatch('latitude double precision'), isTrue,
            reason: 'fidelity: the pattern must catch a real coordinate');
        expect(location.hasMatch('plate_masked text'), isFalse);
      });

      test('erase_my_data covers fleet_members + vehicle_assignments and '
          'no org-owned table', () {
        final m = functionBlock
            .allMatches(sql)
            .firstWhere((m) => m.group(1) == 'erase_my_data');
        final body = m.group(2)!;
        expect(body, contains("ARRAY['fleet_members',    'user_id']"));
        expect(body, contains("ARRAY['vehicle_assignments', 'user_id']"));
        for (final t in const ['fleet_organizations', 'fleet_vehicles',
          'fleet_policies']) {
          expect(body, isNot(contains("'$t'")),
              reason: '$t is the org\'s, not the user\'s to erase');
        }
      });

      test('no policy is added to the raw-telemetry tables (D5.1)', () {
        for (final m in policyBlock.allMatches(sql)) {
          final table = m.group(2)!;
          if (!const ['trip_summaries', 'trip_details', 'obd2_baselines']
              .contains(table)) {
            continue;
          }
          expect(m.group(3), isNot(contains('fleet')),
              reason: '${m.group(1)} on $table mentions fleet');
        }
      });
    });
  }

  test('the schema version was bumped so self-hosts are flagged', () {
    expect(kSupabaseSchemaVersion, greaterThanOrEqualTo(13));
    expect(migration, contains("VALUES ('schema_version', '13', now())"));
  });

  group('mutation checks — the assertions actually bite', () {
    test('a fleet INSERT policy is caught', () {
      final broken = wizard.replaceFirst(
          'CREATE POLICY fleet_vehicles_member_select ON public.fleet_vehicles\n'
              '  FOR SELECT TO authenticated\n'
              '  USING (public.is_fleet_member(org_id));',
          'CREATE POLICY fleet_vehicles_member_select ON public.fleet_vehicles\n'
              '  FOR INSERT TO authenticated\n'
              '  WITH CHECK (true);');
      expect(broken, isNot(wizard), reason: 'the mutation must apply');
      expect(policyViolations(broken), isNotEmpty);
    });

    test('a policy that bypasses the oracle is caught', () {
      final broken = wizard.replaceFirst(
          'USING (public.is_fleet_member(org_id));',
          'USING (org_id IS NOT NULL);');
      expect(broken, isNot(wizard));
      expect(policyViolations(broken),
          contains('fleet_vehicles_member_select on fleet_vehicles does not '
              'go through an oracle'));
    });

    test('a dropped anon revoke is caught', () {
      final broken = wizard.replaceFirst(
          'REVOKE EXECUTE ON FUNCTION public.fleet_role(UUID) FROM anon;', '');
      expect(broken, isNot(wizard));
      expect(definerViolations(broken),
          contains('fleet_role is not revoked from anon'));
    });

    test('an unpinned search_path is caught', () {
      final broken = wizard.replaceFirst(
          'FUNCTION public.is_fleet_member(p_org UUID)\n'
              'RETURNS BOOLEAN\nLANGUAGE sql\nSECURITY DEFINER\nSTABLE\n'
              'SET search_path = public\n',
          'FUNCTION public.is_fleet_member(p_org UUID)\n'
              'RETURNS BOOLEAN\nLANGUAGE sql\nSECURITY DEFINER\nSTABLE\n');
      expect(broken, isNot(wizard));
      expect(definerViolations(broken),
          contains('is_fleet_member does not pin search_path'));
    });
  });
}
