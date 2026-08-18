// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Smoke test for the ratchet dashboard (plan R0.1,
// docs/audits/ratchet-all-dimensions-plan.md).
//
// Runs the report IN-PROCESS (import + call, capture the returned string)
// — never via a spawned `dart run` (#3752: spawned tool processes are
// slow and flaky on the contended runner). Asserts the table shape and a
// few rows whose presence/shape is stable, NOT exact counts (counts move
// with every burn-down slice; the enforcing lint tests own exactness).

import 'package:flutter_test/flutter_test.dart';

import '../../tool/ratchet_report.dart';

void main() {
  // Build once — the report scans lib/ + test/, which is the expensive
  // part; every case below asserts against the same capture.
  final report = buildRatchetReport();
  final lines = report.split('\n');

  String rowFor(String dimensionPrefix) => lines.firstWhere(
        (l) => l.startsWith('| $dimensionPrefix'),
        orElse: () => '',
      );

  /// The `Current` (2nd) cell of the row starting with [dimensionPrefix].
  String currentCellOf(String dimensionPrefix) {
    final row = rowFor(dimensionPrefix);
    expect(row, isNotEmpty, reason: 'missing row: $dimensionPrefix');
    return row.split('|')[2].trim();
  }

  test('prints the dashboard header + markdown table header', () {
    expect(lines.first, '# Ratchet dashboard (plan R0.1)');
    expect(
      report,
      contains('| Dimension | Current | Baseline | Direction | Enforcement |'),
    );
  });

  test('file-length rows report integer current values', () {
    final count =
        int.tryParse(currentCellOf('File length — grandfathered files'));
    expect(count, isNotNull);
    expect(count, greaterThan(0), reason: 'grandfathered set is not empty');
    final debt =
        int.tryParse(currentCellOf('File length — debt lines over the'));
    expect(debt, isNotNull);
    expect(debt, greaterThan(count!),
        reason: 'each grandfathered file carries >= 1 debt line');
  });

  test('feature-boundary rows recompute pair + cycle counts', () {
    final pairs = int.tryParse(
        currentCellOf('Feature boundary — non-barrel cross-feature pairs'));
    expect(pairs, isNotNull);
    expect(pairs, greaterThan(0));
    final cycles =
        int.tryParse(currentCellOf('Feature boundary — bidirectional cycles'));
    expect(cycles, isNotNull);
    expect(cycles, lessThanOrEqualTo(pairs!),
        reason: 'a cycle needs two pairs');
  });

  test('every enumerated opt-out marker has a row with an integer count', () {
    for (final marker in optOutMarkers) {
      final current = currentCellOf('Lint opt-outs — `$marker`');
      expect(int.tryParse(current), isNotNull,
          reason: 'opt-out row for $marker must recompute a count');
    }
  });

  test('gate-pinned dimensions surface their baselines', () {
    // Hardcoded strings reached zero (#1657) and the baseline may only
    // ever decrease — so 0 is a stable expectation, not a moving count.
    final hardcoded = rowFor('Hardcoded UI strings');
    expect(hardcoded, contains('| 0 |'));
    final radii = rowFor('Inline border radii');
    expect(radii, isNotEmpty);
    expect(radii.split('|')[3].trim(), isNot('—'),
        reason: 'border-radius baseline must parse from its lint test');
  });

  test('unratcheted dimensions are visible as gaps, not omitted', () {
    expect(rowFor('Cross-file duplication groups'), contains('R1.1'));
    expect(rowFor('TODO/FIXME comments in lib/'), contains('R1.5'));
  });

  test('test-suite size rows are informational and plausible', () {
    final files = int.tryParse(currentCellOf('Test files'));
    expect(files, isNotNull);
    expect(files, greaterThan(100));
    final cases = int.tryParse(currentCellOf('Test cases'));
    expect(cases, isNotNull);
    expect(cases, greaterThan(files!),
        reason: 'there are more test cases than test files');
  });
}
