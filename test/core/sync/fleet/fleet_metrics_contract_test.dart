// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fleet/emission_factor_registry.dart';
import 'package:tankstellen/core/sync/schema_sql.dart';

/// #4216 — the static contract of `fleet_period_metrics`, asserted on
/// the SQL a self-hoster pastes AND on the versioned migration, so the
/// two cannot drift (HARD RULE #5).
///
/// Third sibling of `fleet_rls_contract_test.dart` (#4212's org-owned
/// invariant) and `fleet_expense_rls_contract_test.dart` (#4215's
/// user-owned pair). What this file pins is a function rather than a
/// policy, and the properties are ADR 0025's privacy rules:
///
///  1. the caller's role is re-checked INSIDE the definer body;
///  2. every call writes a `fleet_audit_events` row (D5.4);
///  3. per-vehicle rows below the org's `aggregationMinSamples` come
///     back suppressed, with the sample count NULL too (D5.3);
///  4. no journey / telemetry table is named anywhere, and no result
///     column is a location (D5.1, D5.2);
///  5. the three refusals — mixed currency, one odometer reading, an
///     unpriced grade — are NULLs and not invented numbers;
///  6. the seven per-litre CO2 factors are byte-for-byte the WtW half
///     of `EmissionFactorRegistry.ademeBaseCarbone` (#4392's sourced
///     values), and CNG is absent because ADEME publishes it per
///     kilogram while an expense carries litres.
///
/// Every assertion is mutation-checked at the bottom against a
/// deliberately broken SQL string: a regex that matches nothing must
/// not pass vacuously (`source_scanning_tests_dont_execute`).
void main() {
  final wizard = buildMigrationSql(const <String, bool>{});
  final migration =
      File('supabase/migrations/20260919000001_fleet_period_metrics.sql')
          .readAsStringSync();

  /// Every `CREATE OR REPLACE FUNCTION public.<name>(…)…$$;` block.
  final functionBlock = RegExp(
    r'CREATE OR REPLACE FUNCTION public\.(\w+)\(([\s\S]*?)\$\$;',
  );

  String functionBody(String sql, String name) => functionBlock
      .allMatches(sql)
      .firstWhere((m) => m.group(1) == name,
          orElse: () => throw StateError('no function $name'))
      .group(2)!;

  /// The `(key, number)` pairs of the `factor` CTE inside
  /// `fleet_period_metrics`, as the SQL states them.
  Map<String, double> sqlFactors(String sql) {
    final body = functionBody(sql, 'fleet_period_metrics');
    final start = body.indexOf('WITH factor(fuel_key, kg_per_litre) AS (');
    if (start < 0) return const {};
    // The CTE's own terminator, not the first `),` — that one closes
    // the first VALUES tuple and would cut the block in half.
    final end = body.indexOf('\n  ),', start);
    final block = body.substring(start, end < 0 ? body.length : end);
    return {
      for (final m
          in RegExp(r"\('([a-z0-9_]+)',\s*([0-9.]+)\)").allMatches(block))
        m.group(1)!: double.parse(m.group(2)!),
    };
  }

  /// The privacy violations of [sql]: the ways `fleet_period_metrics`
  /// could stop being the aggregate-first read ADR 0025 describes.
  List<String> privacyViolations(String sql) {
    final out = <String>[];
    final body = functionBody(sql, 'fleet_period_metrics');
    if (!body.contains('SECURITY DEFINER')) {
      out.add('not SECURITY DEFINER');
    }
    if (!body.contains('SET search_path = public')) {
      out.add('search_path is not pinned');
    }
    if (!body.contains(
        "coalesce(public.fleet_role(p_org), '') NOT IN ('manager', 'admin')")) {
      out.add('does not re-check the caller role');
    }
    if (!body.contains('INSERT INTO public.fleet_audit_events')) {
      out.add('does not audit the read');
    }
    if (!body.contains("'metrics_read'")) {
      out.add('does not name the audited action');
    }
    if (!body.contains("(data ->> 'aggregationMinSamples')::int")) {
      out.add('does not read the org threshold');
    }
    if (!body.contains('a.n < min_samples AS sup')) {
      out.add('does not suppress below the threshold');
    }
    if (!body.contains('CASE WHEN t.sup THEN NULL ELSE t.n END')) {
      out.add('returns the sample count of a suppressed row');
    }
    for (final table in const [
      'trip_summaries',
      'trip_details',
      'obd2_baselines',
    ]) {
      if (body.contains(table)) {
        out.add('reads the journey/telemetry table $table');
      }
    }
    for (final column in const [
      'latitude',
      'longitude',
      'geohash',
      ' lat ',
      ' lon ',
    ]) {
      if (body.contains(column)) out.add('carries a location ($column)');
    }
    if (!body.contains("e.status NOT IN ('draft', 'rejected')")) {
      out.add('does not exclude drafts and rejected expenses');
    }
    return out;
  }

  /// The refusals of [sql]: each of the three is a NULL, never a
  /// number the data does not support.
  List<String> refusalViolations(String sql) {
    final out = <String>[];
    final body = functionBody(sql, 'fleet_period_metrics');
    if (!body.contains('CASE WHEN a.ccy_n = 1 THEN a.spend END AS spend')) {
      out.add('sums across currencies');
    }
    if (!body.contains('CASE WHEN a.ccy_n = 1 THEN a.ccy END AS ccy')) {
      out.add('names a currency it cannot name');
    }
    if (!body.contains(
        'CASE WHEN a.odo_n >= 2 AND a.odo_span > 0 THEN a.odo_span END')) {
      out.add('derives a distance from one odometer reading');
    }
    if (!body.contains('CASE WHEN a.unpriced_n = 0 THEN round(a.co2e, 3)')) {
      out.add('emits a partial CO2e sum for an unpriced grade');
    }
    if (!body.contains('CASE WHEN t.sup OR t.co2e IS NULL\n'
        "         THEN NULL ELSE 'ADEME Base Carbone v23.6 (2026) WtW' END")) {
      out.add('does not tie the factor version to an actual CO2e figure');
    }
    return out;
  }

  for (final (label, sql) in [
    ('wizard SQL', wizard),
    ('migration', migration),
  ]) {
    group('$label —', () {
      test('fleet_period_metrics exists with the #4216 signature and the '
          'twelve result columns', () {
        expect(
            sql,
            contains('CREATE OR REPLACE FUNCTION public.fleet_period_metrics('
                '\n  p_org UUID,\n  p_from TIMESTAMPTZ,\n  p_to TIMESTAMPTZ\n)'));
        final body = functionBody(sql, 'fleet_period_metrics');
        for (final column in const [
          'fleet_vehicle_id UUID',
          'spend NUMERIC',
          'litres NUMERIC',
          'km NUMERIC',
          'cost_per_km NUMERIC',
          'l_per_100km NUMERIC',
          'co2e_kg NUMERIC',
          'co2_factor_version TEXT',
          'sample_count INTEGER',
          'measured_share NUMERIC',
          'currency TEXT',
          'suppressed BOOLEAN',
        ]) {
          expect(body, contains(column), reason: 'missing result column');
        }
      });

      test('the aggregate is role-checked, audited, threshold-suppressed '
          'and reads no journey table', () {
        expect(privacyViolations(sql), isEmpty);
      });

      test('it refuses rather than invents — mixed currency, a single '
          'odometer reading, an unpriced grade', () {
        expect(refusalViolations(sql), isEmpty);
      });

      test('an export writes its own audit row, and the logger grants '
          'nothing', () {
        final body = functionBody(sql, 'fleet_log_export');
        expect(body, contains('SECURITY DEFINER'));
        expect(
            body,
            contains("coalesce(public.fleet_role(p_org), '') "
                "NOT IN ('manager', 'admin')"));
        expect(body, contains("'metrics_export'"));
        expect(body, contains('RETURNS BOOLEAN'));
      });

      test('anon can execute neither function, and PUBLIC is revoked '
          'first — the two are not the same grant', () {
        for (final signature in const [
          'public.fleet_period_metrics(UUID, TIMESTAMPTZ, TIMESTAMPTZ)',
          'public.fleet_log_export(UUID, TEXT)',
        ]) {
          expect(sql, contains('REVOKE ALL ON FUNCTION $signature FROM PUBLIC'));
          expect(sql,
              contains('GRANT EXECUTE ON FUNCTION $signature TO authenticated'));
          expect(sql,
              contains('REVOKE EXECUTE ON FUNCTION $signature FROM anon'));
        }
      });

      test('no manager policy was added to a journey or telemetry '
          'table (ADR 0025 D5.1)', () {
        for (final table in const [
          'trip_summaries',
          'trip_details',
          'obd2_baselines',
        ]) {
          final policies = RegExp('CREATE POLICY\\s+(\\w+)\\s+ON\\s+'
                  'public\\.$table')
              .allMatches(sql)
              .map((m) => m.group(1)!)
              .where((n) => n.contains('fleet') || n.contains('manager'))
              .toList();
          expect(policies, isEmpty,
              reason: 'fleet must add nothing to $table: $policies');
        }
      });
    });
  }

  test('the schema version was bumped so self-hosts are flagged — an '
      'RPC alone still counts', () {
    expect(kSupabaseSchemaVersion, greaterThanOrEqualTo(15));
    expect(migration, contains("VALUES ('schema_version', '15', now())"));
    // The wizard records the CURRENT version, not this migration's:
    // #4399 took it to 16, and a literal here would fail every later
    // bump for a reason that has nothing to do with the metrics RPC.
    expect(
      wizard,
      contains("VALUES ('schema_version', '$kSupabaseSchemaVersion', now())"),
    );
  });

  group('CO2 factor parity with the Dart registry (#4392) —', () {
    /// The registry's per-LITRE well-to-wheel factors: exactly what the
    /// SQL table must hold, no more and no less.
    final expected = <String, double>{
      for (final f in EmissionFactorRegistry.ademeBaseCarbone.factors)
        if (f.scope == EmissionScope.wellToWheel &&
            f.unit == EmissionUnit.kgCo2ePerLitre)
          f.fuelKey: f.kgCo2ePerUnit,
    };

    test('sanity: the registry publishes per-litre WtW factors at all', () {
      expect(expected, isNotEmpty);
      expect(expected.keys, contains('diesel'));
    });

    for (final (label, sql) in [
      ('wizard SQL', wizard),
      ('migration', migration),
    ]) {
      test('$label carries every per-litre WtW factor, and only those', () {
        expect(sqlFactors(sql), expected,
            reason: 'the SQL factor table and '
                'EmissionFactorRegistry.ademeBaseCarbone must agree in BOTH '
                'directions — a factor added to one and not the other is a '
                'number on a manager report that no source backs');
      });

      test('$label omits CNG on purpose — ADEME publishes GNC per '
          'kilogram and an expense carries litres', () {
        expect(sqlFactors(sql).containsKey('cng'), isFalse);
        expect(
            EmissionFactorRegistry.ademeBaseCarbone.factors.any((f) =>
                f.fuelKey == 'cng' && f.unit == EmissionUnit.kgCo2ePerKilogram),
            isTrue,
            reason: 'fidelity: the exclusion is a UNIT decision, so the '
                'registry must still publish the per-kilogram factor');
      });

      test('$label prints the factor source, version and scope beside '
          'the number (#4219)', () {
        final diesel = EmissionFactorRegistry.ademeBaseCarbone
            .factors
            .firstWhere((f) =>
                f.fuelKey == 'diesel' && f.scope == EmissionScope.wellToWheel);
        expect(
            sql,
            contains("'${diesel.citation} "
                "${EmissionScope.wellToWheel.label}'"),
            reason: 'the co2_factor_version string must be the registry\'s '
                'own citation plus the boundary, not a hand-typed label');
      });
    }
  });

  group('mutation checks — the assertions actually bite', () {
    test('a dropped role check is caught', () {
      // Anchored on the comment above it: the same role predicate
      // appears in the #4212 write RPCs, which are emitted first, so an
      // unanchored replaceFirst would mutate `fleet_upsert_vehicle`
      // and leave this function untouched.
      final broken = wizard.replaceFirst(
        '  -- Definer bypasses RLS, so the role is checked here or nowhere.\n'
        "  IF coalesce(public.fleet_role(p_org), '') NOT IN "
            "('manager', 'admin') THEN\n"
        "    RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501';\n"
        '  END IF;\n',
        '',
      );
      expect(broken, isNot(wizard), reason: 'the mutation must apply');
      expect(privacyViolations(broken),
          contains('does not re-check the caller role'));
    });

    test('an unaudited read is caught', () {
      final broken = wizard.replaceFirst(
          "    VALUES (p_org, auth.uid(), 'metrics_read',", '    VALUES (');
      expect(broken, isNot(wizard));
      expect(privacyViolations(broken),
          contains('does not name the audited action'));
    });

    test('suppression removed is caught', () {
      final broken =
          wizard.replaceFirst('a.n < min_samples AS sup', 'false AS sup');
      expect(broken, isNot(wizard));
      expect(privacyViolations(broken),
          contains('does not suppress below the threshold'));
    });

    test('a suppressed row that still reveals its sample count is '
        'caught', () {
      final broken =
          wizard.replaceFirst('CASE WHEN t.sup THEN NULL ELSE t.n END', 't.n');
      expect(broken, isNot(wizard));
      expect(privacyViolations(broken),
          contains('returns the sample count of a suppressed row'));
    });

    test('a join onto the journey table is caught', () {
      final broken = wizard.replaceFirst(
        '      FROM public.fleet_expenses e\n',
        '      FROM public.fleet_expenses e\n'
            '      JOIN public.trip_summaries t ON t.user_id = e.user_id\n',
      );
      expect(broken, isNot(wizard));
      expect(privacyViolations(broken),
          contains('reads the journey/telemetry table trip_summaries'));
    });

    test('a draft creeping into the aggregate is caught', () {
      final broken = wizard.replaceFirst(
          "       AND e.status NOT IN ('draft', 'rejected')\n", '');
      expect(broken, isNot(wizard));
      expect(privacyViolations(broken),
          contains('does not exclude drafts and rejected expenses'));
    });

    test('a cross-currency total is caught', () {
      final broken = wizard.replaceFirst(
          'CASE WHEN a.ccy_n = 1 THEN a.spend END AS spend', 'a.spend AS spend');
      expect(broken, isNot(wizard));
      expect(refusalViolations(broken), contains('sums across currencies'));
    });

    test('a distance invented from one odometer reading is caught', () {
      final broken = wizard.replaceFirst(
          'CASE WHEN a.odo_n >= 2 AND a.odo_span > 0 THEN a.odo_span END',
          'a.odo_span');
      expect(broken, isNot(wizard));
      expect(refusalViolations(broken),
          contains('derives a distance from one odometer reading'));
    });

    test('a partial CO2e sum over an unpriced grade is caught', () {
      final broken = wizard.replaceFirst(
          'CASE WHEN a.unpriced_n = 0 THEN round(a.co2e, 3) END',
          'round(a.co2e, 3)');
      expect(broken, isNot(wizard));
      expect(refusalViolations(broken),
          contains('emits a partial CO2e sum for an unpriced grade'));
    });

    test('a factor edited in the SQL and not in the registry is caught', () {
      final broken = wizard.replaceFirst("('diesel', 3.10)", "('diesel', 3.99)");
      expect(broken, isNot(wizard));
      expect(sqlFactors(broken)['diesel'], 3.99);
      expect(
          sqlFactors(broken),
          isNot({
            for (final f in EmissionFactorRegistry.ademeBaseCarbone.factors)
              if (f.scope == EmissionScope.wellToWheel &&
                  f.unit == EmissionUnit.kgCo2ePerLitre)
                f.fuelKey: f.kgCo2ePerUnit,
          }));
    });

    test('a CNG factor smuggled into the per-litre table is caught', () {
      final broken =
          wizard.replaceFirst("('lpg', 1.86)", "('lpg', 1.86), ('cng', 2.96)");
      expect(broken, isNot(wizard));
      expect(sqlFactors(broken).containsKey('cng'), isTrue,
          reason: 'fidelity: the mutation must be the thing the real '
              'assertion forbids');
    });
  });
}
