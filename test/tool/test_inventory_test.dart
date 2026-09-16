// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// #4235 — the test-suite inventory classifies every test file with an
// action from the issue's fixed vocabulary. Runs IN-PROCESS (#3752).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/test_inventory.dart';

void main() {
  final rows = testInventoryRows();

  test('every test file has exactly one row', () {
    final files = Directory('test')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_test.dart'))
        .length;
    expect(rows, hasLength(files));
    expect(rows.map((r) => r.path).toSet(), hasLength(files));
  });

  test('actions come only from #4235\'s vocabulary', () {
    for (final r in rows) {
      expect(kInventoryActions, contains(r.action), reason: r.path);
    }
  });

  test('classification rules', () {
    expect(layerOf('test/lint/file_length_test.dart'), 'architecture-lint');
    expect(layerOf('test/security/no_hardcoded_secrets_test.dart'),
        'architecture-lint');
    expect(layerOf('test/features/x/presentation/y_test.dart'), 'widget');
    expect(layerOf('test/features/x/domain/y_test.dart'), 'domain');
    // #4235 — a scan-ONLY file has nothing executable to trust.
    expect(actionFor('widget', const ['source-scan']), 'REPLACE');
    // …but a residual scan beside real behaviour coverage is not the
    // #4116 false-green risk; it is a cleanup, not a rewrite.
    expect(actionFor('widget', const ['source-scan'], execAsserts: 12),
        'KEEP+REFACTOR');
    expect(actionFor('architecture-lint', const ['source-scan']), 'KEEP');
    expect(actionFor('data', const ['real-sleep']), 'KEEP+REFACTOR');
    expect(actionFor('data', const ['flaky-tagged']), 'KEEP+REFACTOR');
    expect(actionFor('data', const ['network-tagged']), 'KEEP');
    expect(actionFor('domain', const []), 'KEEP');
  });

  test('the invariant comes from the header comment, else the first group',
      () {
    expect(invariantOf('// Copyright x\n// SPDX y\n//\n// #1 — keeps A\n'
            "import 'a.dart';\nvoid main() {}"),
        '#1 — keeps A');
    expect(invariantOf("import 'a.dart';\nvoid main() { group('B holds', () {}); }"),
        'B holds');
  });

  test('a file whose header declares a static guard is not a REPLACE', () {
    final guard = rows.singleWhere((r) =>
        r.path == 'test/features/map/tile_layer_consistency_test.dart');
    expect(guard.layer, 'architecture-lint');
    expect(guard.action, 'KEEP');
  });

  test('#4235 — no REPLACE row still has executable coverage', () {
    // The whole point of the proportional rule: REPLACE must name files
    // that prove the text and nothing else.
    for (final r in rows.where((r) => r.action == 'REPLACE')) {
      expect(r.execAsserts, 0,
          reason: '${r.path} has ${r.execAsserts} executed assertions — it '
              'is a cleanup (KEEP+REFACTOR), not a rewrite');
    }
  });

  test('the snapshot has a table row per file', () {
    final md = buildTestInventory();
    expect(md, contains('| Test file | Invariant protected |'));
    expect(RegExp(r'^\| `test/', multiLine: true).allMatches(md),
        hasLength(rows.length));
  });
}
