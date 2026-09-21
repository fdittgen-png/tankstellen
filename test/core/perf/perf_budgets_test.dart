// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4163 — every surface has a budget, or an explicit reason it has none.
///
/// The ledger half. The two STRUCTURAL budgets are asserted against the
/// real widgets in `station_row_budget_test.dart` and
/// `map_marker_budget_test.dart`; this file guards the list itself, so a
/// surface cannot quietly lose its entry.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/perf/perf_budgets.dart';

void main() {
  test('every budget states where its number came from', () {
    // "A budget nobody can defend is worse than none." A constant with
    // no provenance is a number someone will later "optimise" against
    // without knowing what it protects.
    for (final b in kPerfBudgets) {
      expect(b.measuredOn.trim(), isNotEmpty, reason: b.surface);
      expect(b.measuredOn.length, greaterThan(30),
          reason: '${b.surface}: "${b.measuredOn}" is not a justification');
    }
  });

  test('an unmeasured surface has NO limit — not a placeholder', () {
    // A made-up ceiling is worse than an admitted gap: it looks
    // enforced, and the first person to hit it will raise it rather
    // than measure.
    for (final b in kPerfBudgets.where((b) => !b.isMeasured)) {
      expect(b.limit, isNull, reason: b.surface);
    }
  });

  test('only structural budgets claim to be asserted in CI', () {
    // A runner has no mid-range Android GPU: a frame-time assertion
    // there measures the runner and calls it the app.
    const structural = {'station list row', 'map markers'};
    for (final b in kPerfBudgets) {
      if (b.assertedInCi) {
        expect(structural, contains(b.surface),
            reason: '${b.surface} claims a CI assertion but is a timing '
                'budget — CI cannot hold it honestly');
      }
    }
  });

  test('the nine surfaces the review named are all accounted for', () {
    final surfaces = kPerfBudgets.map((b) => b.surface).toList();
    expect(surfaces.toSet().length, surfaces.length,
        reason: 'a duplicated surface means one of them is not read');
    expect(kPerfBudgets, hasLength(9));
  });

  test('the export carries limit AND basis together', () {
    // A phase list without its ceilings asks the reader to remember
    // what "slow" means.
    final rows = perfBudgetExportRows();
    expect(rows, hasLength(kPerfBudgets.length));
    for (final r in rows) {
      expect(r.containsKey('limit'), isTrue);
      expect(r['basis'], isNotNull);
      expect(r.containsKey('measured'), isTrue);
    }
  });
}
