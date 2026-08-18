// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Ratchet dashboard (plan R0.1 — docs/audits/ratchet-all-dimensions-plan.md).
//
// One command that prints a markdown table of every ratcheted quality
// dimension's CURRENT value next to its pinned BASELINE, so drift is
// visible in seconds and the quarterly known-gaps audit becomes
// `dart run tool/ratchet_report.dart` + diff.
//
// Current values are RECOMPUTED from the working tree with the same scan
// rules the enforcing lint tests use (lib/ handwritten Dart only — no
// `.g.dart` / `.freezed.dart` / `lib/l10n/` output). Baselines are read
// from the enforcing tests themselves (`test/lint/*.dart`) — those files
// ARE the pinned baselines, so parsing them can never disagree with what
// CI enforces. Dimensions whose recomputation needs the full lint-test
// engine (hardcoded strings, inline radii) show their pinned baseline
// with the current value marked as gate-enforced.
//
// Pure read-only reporting: this tool never writes anything and must
// never become a gate itself (the standing autonomy constraint — new
// enforcement starts advisory or post-merge, never here).
//
// Usage:
//   dart run tool/ratchet_report.dart
//
// Tested in-process by test/tool/ratchet_report_test.dart (import + call
// — never spawned via `dart run`, #3752).

import 'dart:io';

void main() {
  stdout.write(buildRatchetReport());
}

/// The opt-out markers the custom lint ratchets honor, i.e. the escape
/// hatches of dimension 11 (plan R1.4). Enumerated from the enforcing
/// tests:
///   * `// ignore: silent_catch`       — test/lint/no_silent_catch_test.dart
///   * `// ignore: catch_no_st`        — test/lint/catch_block_stacktrace_coverage_test.dart
///   * `// ignore: log_raw_debugprint` — test/lint/no_raw_debugprint_error_test.dart
///   * `// i18n-ignore:`               — test/lint/no_hardcoded_ui_strings_test.dart
const List<String> optOutMarkers = [
  '// ignore: silent_catch',
  '// ignore: catch_no_st',
  '// ignore: log_raw_debugprint',
  '// i18n-ignore:',
];

/// Builds the full markdown dashboard. [root] is the repo root (defaults
/// to the current working directory, which is the project root both under
/// `dart run` and `flutter test`).
String buildRatchetReport({String root = '.'}) {
  final libFiles = _scannedLibFiles(root);
  final fileLength = _fileLengthCurrent(libFiles);
  final fileLengthBaseline = _fileLengthBaseline(root);
  final boundary = _boundaryCurrent(libFiles);
  final boundaryBaseline = _boundaryBaseline(root);
  final optOutBaseline = _optOutBaseline(root);
  final tests = _testCounts(root);

  final rows = <_Row>[
    _Row(
      'File length — grandfathered files > 400 lines',
      '${fileLength.count}',
      _fmt(fileLengthBaseline?.count),
      'decrease',
      'test/lint/file_length_test.dart',
    ),
    _Row(
      'File length — debt lines over the 400 cap',
      '${fileLength.debtLines}',
      _fmt(fileLengthBaseline?.debtLines),
      'decrease',
      'sum of (lines − 400) over grandfathered files',
    ),
    _Row(
      'Feature boundary — non-barrel cross-feature pairs',
      '${boundary.pairCount}',
      _fmt(boundaryBaseline?.pairCount),
      'decrease',
      'test/lint/feature_boundary_test.dart',
    ),
    _Row(
      'Feature boundary — bidirectional cycles',
      '${boundary.cycleCount}',
      _fmt(boundaryBaseline?.cycleCount),
      'decrease (target 0)',
      'test/lint/feature_boundary_test.dart',
    ),
    _Row(
      'Feature boundary — core → feature imports',
      '${boundary.coreImports}',
      _fmt(boundaryBaseline?.coreImports),
      'decrease (target 0)',
      'test/lint/feature_boundary_test.dart',
    ),
    _Row(
      'Feature boundary — feature → app-shell imports',
      '${boundary.shellImports}',
      _fmt(boundaryBaseline?.shellImports),
      'decrease (target 0)',
      'test/lint/feature_boundary_test.dart',
    ),
    for (final marker in optOutMarkers)
      _Row(
        'Lint opt-outs — `$marker`',
        '${_countMarker(libFiles, marker)}',
        _fmt(optOutBaseline?[marker]),
        'decrease',
        optOutBaseline == null
            ? 'baseline pending (plan R1.4)'
            : 'test/lint/opt_out_ratchet_test.dart',
      ),
    _Row(
      'Hardcoded UI strings',
      'gate-enforced ≤ baseline',
      _fmt(_pinnedBaseline(root, 'test/lint/no_hardcoded_ui_strings_test.dart')),
      'decrease (pinned)',
      'test/lint/no_hardcoded_ui_strings_test.dart',
    ),
    _Row(
      'Inline border radii',
      'gate-enforced ≤ baseline',
      _fmt(_pinnedBaseline(root, 'test/lint/no_inline_border_radius_test.dart')),
      'decrease',
      'test/lint/no_inline_border_radius_test.dart',
    ),
    _duplicationRow(root),
    _Row(
      'Test files (test/**/*_test.dart)',
      '${tests.files}',
      '—',
      'increase (informational)',
      'no pinned baseline',
    ),
    _Row(
      'Test cases (test/testWidgets call sites)',
      '${tests.cases}',
      '—',
      'increase (informational)',
      'no pinned baseline',
    ),
    _Row(
      'TODO/FIXME comments in lib/',
      '${_countTodos(libFiles)}',
      '—',
      'decrease (target ~0)',
      'unratcheted — plan R1.5',
    ),
  ];

  final buffer = StringBuffer()
    ..writeln('# Ratchet dashboard (plan R0.1)')
    ..writeln()
    ..writeln('| Dimension | Current | Baseline | Direction | Enforcement |')
    ..writeln('|---|---:|---:|---|---|');
  for (final row in rows) {
    buffer.writeln(
      '| ${row.dimension} | ${row.current} | ${row.baseline} '
      '| ${row.direction} | ${row.enforcement} |',
    );
  }
  return buffer.toString();
}

class _Row {
  const _Row(
    this.dimension,
    this.current,
    this.baseline,
    this.direction,
    this.enforcement,
  );

  final String dimension;
  final String current;
  final String baseline;
  final String direction;
  final String enforcement;
}

String _fmt(int? value) => value == null ? '—' : '$value';

// ── Shared scan rules (mirrors the lint tests') ─────────────────────────

/// Handwritten lib/ Dart files: no codegen output, no gen-l10n output.
List<File> _scannedLibFiles(String root) {
  final libDir = Directory('$root/lib');
  if (!libDir.existsSync()) return const [];
  final files = <File>[];
  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (!path.endsWith('.dart')) continue;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
    if (path.contains('/lib/l10n/')) continue;
    files.add(entity);
  }
  return files;
}

/// Line count minus the 3-line SPDX header, same as file_length_test.
int _effectiveLines(File file) {
  final rawLines = file.readAsLinesSync();
  final hasHeader = rawLines.length >= 2 &&
      rawLines[0].contains('Copyright (c) 2026 Florian DITTGEN') &&
      rawLines[1].contains('SPDX-License-Identifier');
  return rawLines.length - (hasHeader ? 3 : 0);
}

// ── File length (dimension 3) ───────────────────────────────────────────

({int count, int debtLines}) _fileLengthCurrent(List<File> libFiles) {
  const cap = 400;
  var count = 0;
  var debt = 0;
  for (final file in libFiles) {
    final lines = _effectiveLines(file);
    if (lines > cap) {
      count += 1;
      debt += lines - cap;
    }
  }
  return (count: count, debtLines: debt);
}

({int count, int debtLines})? _fileLengthBaseline(String root) {
  final source = _read(root, 'test/lint/file_length_test.dart');
  if (source == null) return null;
  final entries = RegExp(r'lines:\s*(\d+),').allMatches(source).toList();
  if (entries.isEmpty) return null;
  var debt = 0;
  for (final match in entries) {
    debt += int.parse(match.group(1)!) - 400;
  }
  return (count: entries.length, debtLines: debt);
}

// ── Feature boundary (dimension 8) ──────────────────────────────────────

({int pairCount, int cycleCount, int coreImports, int shellImports})
    _boundaryCurrent(List<File> libFiles) {
  final directive = RegExp(
    r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );

  String normalize(String path) {
    final parts = <String>[];
    for (final seg in path.split('/')) {
      if (seg == '.' || seg.isEmpty) continue;
      if (seg == '..') {
        if (parts.isNotEmpty) parts.removeLast();
        continue;
      }
      parts.add(seg);
    }
    return parts.join('/');
  }

  String? featureOf(String libPath) =>
      RegExp(r'^lib/features/([^/]+)/').firstMatch('$libPath/')?.group(1);

  final featurePairs = <String>{};
  var coreImports = 0;
  var shellImports = 0;

  for (final file in libFiles) {
    var path = file.path.replaceAll(r'\', '/');
    // Rebase to a lib/-rooted path regardless of [root].
    final libIndex = path.indexOf('lib/');
    if (libIndex < 0) continue;
    path = path.substring(libIndex);

    final fromFeature = featureOf(path);
    final isCore = path.startsWith('lib/core/');
    if (fromFeature == null && !isCore) continue; // shell: out of scope

    final source = file.readAsStringSync();
    final dir = path.substring(0, path.lastIndexOf('/'));
    for (final match in directive.allMatches(source)) {
      final uri = match.group(1)!;
      String target;
      if (uri.startsWith('package:tankstellen/')) {
        target = 'lib/${uri.substring('package:tankstellen/'.length)}';
      } else if (uri.startsWith('dart:') || uri.startsWith('package:')) {
        continue;
      } else {
        target = normalize('$dir/$uri');
      }
      final toFeature = featureOf(target);
      if (toFeature == null) {
        if (fromFeature != null &&
            target.startsWith('lib/') &&
            !target.startsWith('lib/core/') &&
            !target.startsWith('lib/l10n/')) {
          shellImports += 1;
        }
        continue;
      }
      if (fromFeature == toFeature) continue;
      if (isCore) {
        coreImports += 1;
      } else {
        if (target == 'lib/features/$toFeature/api.dart') continue;
        featurePairs.add('$fromFeature -> $toFeature');
      }
    }
  }

  final cycles = <String>{};
  for (final key in featurePairs) {
    final parts = key.split(' -> ');
    if (featurePairs.contains('${parts[1]} -> ${parts[0]}')) {
      final pair = [parts[0], parts[1]]..sort();
      cycles.add('${pair[0]} <-> ${pair[1]}');
    }
  }

  return (
    pairCount: featurePairs.length,
    cycleCount: cycles.length,
    coreImports: coreImports,
    shellImports: shellImports,
  );
}

({int pairCount, int cycleCount, int coreImports, int shellImports})?
    _boundaryBaseline(String root) {
  final source = _read(root, 'test/lint/feature_boundary_test.dart');
  if (source == null) return null;

  Map<String, int>? mapOf(String name) {
    final block = RegExp(
      '$name = <String, int>\\{(.*?)\\};',
      dotAll: true,
    ).firstMatch(source)?.group(1);
    if (block == null) return null;
    return {
      for (final m
          in RegExp(r"'([^']+)':\s*(\d+),").allMatches(block))
        m.group(1)!: int.parse(m.group(2)!),
    };
  }

  final pairs = mapOf('_featurePairBaseline');
  final core = mapOf('_coreImportBaseline');
  final shell = mapOf('_shellImportBaseline');
  final cycles = RegExp(r'_cycleBaseline\s*=\s*(\d+);').firstMatch(source);
  if (pairs == null || core == null || shell == null || cycles == null) {
    return null;
  }
  int sum(Map<String, int> map) => map.values.fold(0, (a, b) => a + b);
  return (
    pairCount: pairs.length,
    cycleCount: int.parse(cycles.group(1)!),
    coreImports: sum(core),
    shellImports: sum(shell),
  );
}

// ── Lint opt-out markers (dimension 11) ─────────────────────────────────

int _countMarker(List<File> libFiles, String marker) {
  var count = 0;
  for (final file in libFiles) {
    count += marker.allMatches(file.readAsStringSync()).length;
  }
  return count;
}

/// Per-marker baselines pinned by test/lint/opt_out_ratchet_test.dart
/// (plan R1.4). Null until that ratchet exists.
Map<String, int>? _optOutBaseline(String root) {
  final source = _read(root, 'test/lint/opt_out_ratchet_test.dart');
  if (source == null) return null;
  final block = RegExp(
    r'optOutBaseline = <String, int>\{(.*?)\};',
    dotAll: true,
  ).firstMatch(source)?.group(1);
  if (block == null) return null;
  return {
    for (final m in RegExp(r"'([^']+)':\s*(\d+),").allMatches(block))
      m.group(1)!: int.parse(m.group(2)!),
  };
}

// ── Baseline pins parsed from single-number ratchet tests ───────────────

int? _pinnedBaseline(String root, String testPath) {
  final source = _read(root, testPath);
  if (source == null) return null;
  final match =
      RegExp(r'const _baseline\s*=\s*(\d+);').firstMatch(source);
  return match == null ? null : int.parse(match.group(1)!);
}

// ── Duplication (dimension 13) ──────────────────────────────────────────

_Row _duplicationRow(String root) {
  // The plan's scanner (R1.1) has not been ported into the repo yet; if a
  // duplication scanner script ever lands under tool/ or scripts/, this
  // row points at it instead of reporting the gap.
  for (final dir in ['tool', 'scripts']) {
    final directory = Directory('$root/$dir');
    if (!directory.existsSync()) continue;
    for (final entity in directory.listSync()) {
      final name = entity.path.split('/').last.toLowerCase();
      if (name.contains('dup')) {
        return _Row(
          'Cross-file duplication groups',
          'run $dir/$name',
          '—',
          'decrease',
          'scanner present — wire its count here',
        );
      }
    }
  }
  return const _Row(
    'Cross-file duplication groups',
    'n/a',
    '—',
    'decrease',
    'no scanner in repo yet (plan R1.1)',
  );
}

// ── Test suite size (informational) ─────────────────────────────────────

({int files, int cases}) _testCounts(String root) {
  final testDir = Directory('$root/test');
  if (!testDir.existsSync()) return (files: 0, cases: 0);
  final caseCall = RegExp(r'^\s*(test|testWidgets)\(', multiLine: true);
  var files = 0;
  var cases = 0;
  for (final entity in testDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('_test.dart')) continue;
    files += 1;
    cases += caseCall.allMatches(entity.readAsStringSync()).length;
  }
  return (files: files, cases: cases);
}

// ── TODO debt (dimension 16) ────────────────────────────────────────────

int _countTodos(List<File> libFiles) {
  final todo = RegExp(r'//\s*(TODO|FIXME)');
  var count = 0;
  for (final file in libFiles) {
    count += todo.allMatches(file.readAsStringSync()).length;
  }
  return count;
}

String? _read(String root, String relativePath) {
  final file = File('$root/$relativePath');
  return file.existsSync() ? file.readAsStringSync() : null;
}
