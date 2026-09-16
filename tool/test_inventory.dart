// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Test-suite inventory (#4235).
//
// One row per `*_test.dart` file: the invariant its header comment (or
// first group) names, its layer, the determinism risks a static scan can
// see, and a triage action from #4235's fixed vocabulary. Heuristic by
// design — a KEEP means no risk was DETECTED, not that every case was
// re-read; the REPLACE and KEEP+REFACTOR rows are the work list.
//
// Read-only. Regenerate the committed snapshot with:
//   dart run tool/test_inventory.dart > docs/test-audit-2026-09-15-inventory.md
// The filename keeps its original date: this is a LIVING inventory
// regenerated as the suite changes, not a dated snapshot. The date
// inside the document tracks the last regeneration.
//
// Tested in-process by test/tool/test_inventory_test.dart (never spawned,
// #3752).

import 'dart:io';

void main() => stdout.write(buildTestInventory());

/// #4235's action vocabulary, in triage priority order.
const List<String> kInventoryActions = [
  'REPLACE',
  'KEEP+REFACTOR',
  'MOVE TO TAGGED HEALTH SUITE',
  'DELETE',
  'ADD',
  'KEEP',
];

/// Static-scan flags that make a file non-deterministic in the default run.
const Set<String> kNonDeterministicFlags = {
  'real-sleep',
  'wall-clock',
  'flaky-tagged',
};

class TestInventoryRow {
  const TestInventoryRow({
    required this.path,
    required this.cases,
    required this.layer,
    required this.invariant,
    required this.flags,
    required this.action,
    this.execAsserts = 0,
  });

  final String path;
  final int cases;

  /// How many assertions run the code rather than read its text (#4235).
  final int execAsserts;
  final String layer;
  final String invariant;
  final List<String> flags;
  final String action;
}

final _caseCall = RegExp(r'^\s*(test|testWidgets)\(', multiLine: true);

/// Assertions that EXECUTE the code under test, as opposed to reading its
/// source. Used to tell a scan-only file from one where a residual scan
/// sits beside real behaviour coverage (#4235).
final _execAssert = RegExp(r'^\s*(expect|expectLater|await tester\.)',
    multiLine: true);
final _networkTag =
    RegExp(r'''@Tags\(\s*\[[^\]]*['"]network['"]|tags:\s*['"]network['"]''');
final _flakyTag =
    RegExp(r'''@Tags\(\s*\[[^\]]*['"]flaky['"]|tags:\s*['"]flaky['"]''');
final _sourceScan = RegExp(r'''(File|Directory)\(\s*['"]lib[/'"]''');
final _sleep = RegExp(r'Future(<void>)?\.delayed\(|\bsleep\(');
final _wallClock = RegExp(r'DateTime\.now\(\)');
final _golden = RegExp(r'matchesGoldenFile\(');
final _groupName = RegExp(r'''group\(\s*['"]([^'"]+)['"]''');
final _firstCase = RegExp(r'''(?:test|testWidgets)\(\s*['"]([^'"]+)['"]''');

/// Every test file under `$root/test`, classified.
List<TestInventoryRow> testInventoryRows({String root = '.'}) {
  final dir = Directory('$root/test');
  if (!dir.existsSync()) return const [];
  final rows = <TestInventoryRow>[];
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('_test.dart')) continue;
    final path =
        entity.path.substring(root.length + 1).replaceAll(r'\', '/');
    final source = entity.readAsStringSync();
    final invariant = invariantOf(source);
    final layer = _staticGuardHeader.hasMatch(invariant) ||
            path.endsWith('_completeness_test.dart')
        ? 'architecture-lint'
        : layerOf(path);
    final flags = <String>[
      if (_networkTag.hasMatch(source)) 'network-tagged',
      if (_flakyTag.hasMatch(source)) 'flaky-tagged',
      if (_sourceScan.hasMatch(source)) 'source-scan',
      if (_sleep.hasMatch(source)) 'real-sleep',
      if (_wallClock.hasMatch(source)) 'wall-clock',
      if (_golden.hasMatch(source)) 'golden',
    ];
    final execAsserts = _execAssert.allMatches(source).length;
    rows.add(TestInventoryRow(
      path: path,
      cases: _caseCall.allMatches(source).length,
      layer: layer,
      invariant: invariant,
      flags: flags,
      execAsserts: execAsserts,
      action: actionFor(layer, flags, execAsserts: execAsserts),
    ));
  }
  rows.sort((a, b) {
    final byAction = kInventoryActions
        .indexOf(a.action)
        .compareTo(kInventoryActions.indexOf(b.action));
    return byAction != 0 ? byAction : a.path.compareTo(b.path);
  });
  return rows;
}

/// Trees whose files are static guards by purpose (#4235 keeps a scan
/// "when the invariant is specifically architectural/static").
const List<String> kStaticGuardTrees = [
  'test/lint/',
  'test/security/',
  'test/docs/',
  'test/i18n/',
  'test/accessibility/',
];

/// A header that declares the file a static guard.
final _staticGuardHeader = RegExp(
    r'static[- ]scan|lint[- ]style|drift guard|^enforces\b|completeness',
    caseSensitive: false);

/// The test layer, from the file's place in the tree.
String layerOf(String path) {
  if (kStaticGuardTrees.any(path.startsWith)) return 'architecture-lint';
  if (path.startsWith('test/tool/')) return 'tooling';
  if (path.startsWith('test/l10n/')) return 'l10n';
  if (path.contains('/integration/')) return 'integration';
  if (path.contains('/presentation/') ||
      path.contains('/widgets/') ||
      path.contains('/screens/')) {
    return 'widget';
  }
  if (path.contains('/providers/') || path.contains('/application/')) {
    return 'provider';
  }
  if (path.contains('/data/')) return 'data';
  if (path.contains('/domain/')) return 'domain';
  return 'other';
}

/// The action #4235 prescribes for what the scan found.
///
/// A source scan outside the architecture/tooling/l10n layers proves the
/// text, not the behaviour (#4116) → REPLACE. Flaky tags, real sleeps,
/// wall-clock reads and goldens are timing- or platform-dependent →
/// KEEP+REFACTOR. A network tag already keeps the file out of the default
/// suite → KEEP.
String actionFor(String layer, List<String> flags, {int execAsserts = 0}) {
  const staticLayers = {'architecture-lint', 'tooling', 'l10n'};
  if (flags.contains('source-scan') && !staticLayers.contains(layer)) {
    // #4235 — presence of a scan is not the same as a scan-ONLY file.
    //
    // The first version of this rule returned REPLACE for any file
    // containing one `File('lib/…')` read, which mislabelled 27 files
    // whose scans sit BESIDE real behaviour coverage — including
    // `csv_parser_test` (39 executed assertions) and
    // `search_last_search_breadcrumb_test`, whose own header records
    // that #4235 already made its contract executable. A work list that
    // names 27 files when none of them is scan-only is not a work list.
    //
    // So: scan-only is still REPLACE (there is nothing else to trust),
    // while a residual scan beside executed behaviour is
    // KEEP+REFACTOR — the scan should go, but the file is not the
    // false-green risk #4116 describes.
    return execAsserts == 0 ? 'REPLACE' : 'KEEP+REFACTOR';
  }
  if (flags.contains('flaky-tagged')) return 'KEEP+REFACTOR';
  if (flags.contains('network-tagged')) return 'KEEP';
  if (flags.any({'real-sleep', 'wall-clock', 'golden'}.contains)) {
    return 'KEEP+REFACTOR';
  }
  return 'KEEP';
}

/// The invariant a file protects, from its first comment block, else its
/// first group or test name.
String invariantOf(String source) {
  final doc = <String>[];
  for (final raw in source.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('// Copyright') || line.startsWith('// SPDX')) {
      continue;
    }
    if (line.startsWith('//')) {
      final text = line.replaceFirst(RegExp(r'^/{2,3}\s?'), '').trim();
      if (text.isEmpty) {
        if (doc.isNotEmpty) break;
        continue;
      }
      doc.add(text);
      if (doc.join(' ').length > 110) break;
      continue;
    }
    if (line.isEmpty || line.startsWith('import ') || line == 'library;') {
      if (doc.isNotEmpty && line.isEmpty) break;
      continue;
    }
    break;
  }
  var text = doc.join(' ');
  if (text.isEmpty) {
    text = _groupName.firstMatch(source)?.group(1) ??
        _firstCase.firstMatch(source)?.group(1) ??
        '—';
  }
  text = text.replaceAll('|', r'\|');
  return text.length > 110 ? '${text.substring(0, 107)}...' : text;
}

/// The committed markdown snapshot.
String buildTestInventory({String root = '.', String date = '2026-09-16'}) {
  final rows = testInventoryRows(root: root);
  final byAction = <String, int>{};
  final byLayer = <String, int>{};
  final byFlag = <String, int>{};
  var cases = 0;
  for (final r in rows) {
    byAction[r.action] = (byAction[r.action] ?? 0) + 1;
    byLayer[r.layer] = (byLayer[r.layer] ?? 0) + 1;
    for (final f in r.flags) {
      byFlag[f] = (byFlag[f] ?? 0) + 1;
    }
    cases += r.cases;
  }
  String counts(Map<String, int> m) => (m.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
      .map((e) => '${e.key} **${e.value}**')
      .join(' · ');

  final b = StringBuffer()
    ..writeln('# Test-suite inventory ($date, #4235)')
    ..writeln()
    ..writeln('Generated by `dart run tool/test_inventory.dart`. One row per '
        'test file — **${rows.length} files, $cases cases**.')
    ..writeln()
    ..writeln('The classification is a static scan. **KEEP** means no determinism '
        'risk was detected, not that every case was re-read. '
        '**REPLACE** names a file that proves the TEXT and nothing else '
        '(a source scan with zero executed assertions); a residual scan '
        'beside real behaviour coverage is **KEEP+REFACTOR** instead — the '
        'scan should go, but the file is not the #4116 false-green risk. '
        '**KEEP+REFACTOR** also covers real sleeps, wall-clock reads, '
        'goldens and flaky tags. Duplicate detection is manual and recorded '
        'as it happens.')
    ..writeln()
    ..writeln('- **Actions:** ${counts(byAction)}')
    ..writeln('- **Layers:** ${counts(byLayer)}')
    ..writeln('- **Risk flags:** ${counts(byFlag)}')
    ..writeln()
    ..writeln('| Test file | Invariant protected | Layer | Cases | '
        'Deterministic? | Risk flags | Duplicate? | Action | '
        'Replacement / issue |')
    ..writeln('|---|---|---|---|---|---|---|---|---|');
  for (final r in rows) {
    final deterministic = r.flags.any(kNonDeterministicFlags.contains)
        ? 'no'
        : r.flags.contains('network-tagged')
            ? 'tagged (off by default)'
            : 'yes';
    final replacement = switch (r.action) {
      'REPLACE' => '#4235 — executable behaviour test',
      'KEEP+REFACTOR' => '#4235 — controllable clock / deterministic seam',
      _ => '',
    };
    b.writeln('| `${r.path}` | ${r.invariant} | ${r.layer} | ${r.cases} | '
        '$deterministic | ${r.flags.join(', ')} | — | ${r.action} | '
        '$replacement |');
  }
  return b.toString();
}
