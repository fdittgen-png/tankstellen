// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Pre-merge changed-line coverage policy (#4347).
//
// The whole-project floor (scripts/check_coverage.sh --threshold 40) runs
// only after merge, on the full master/nightly suite, and a broad
// regression can hide under it. This tool judges the ONE thing a pull
// request is responsible for: the executable lib/ lines it adds or
// modifies. It runs on the coverage the PR's affected-test shards already
// produce, so it adds no full-suite run to a PR.
//
//   dart tool/coverage_policy.dart \
//     --diff changed.diff \          # git diff --unified=0 base...HEAD -- lib/
//     --lcov shard0/lcov.info ... \  # one per shard, hits are summed
//     [--summary report.md]          # markdown for the job summary
//
//   [--annotation-level warning]     # default `error`; ci.yml passes
//                                    # `warning` while the gate is advisory
//
//   dart tool/coverage_policy.dart --diff changed.diff --applicable-only
//     # prints `applicable=true|false`: must the shards collect coverage?
//   dart tool/coverage_policy.dart --diff changed.diff --coverage-tests
//     # prints the tests that run WITH --coverage (see [coverageTests])
//
// ## Denominator
//
// A changed executable line is a line number that the diff adds or
// modifies (`+` side of a hunk) in a maintained source file AND that the
// merged lcov reports as a `DA:` record. Maintained source is lib/**.dart
// minus exactly the files scripts/check_coverage.sh filters: `.g.dart`,
// `.freezed.dart` and `l10n/app_localizations*`. Generated and maintained
// percentages are never mixed. Deleted lines are not in the denominator,
// so a deletion or a pure move of tested code cannot fail the policy.
//
// A maintained file with changed lines but NO lcov record is one of two
// things, told apart by the test selector's dependency graph (imports and
// parts — the same graph that picked the PR's tests):
//
//   * no test depends on it → UNTESTED: its changed code-like lines (not
//     blank, not a comment, not a directive, not a lone bracket) count as
//     executable and uncovered. "No test loads it" is not coverage. A
//     file tests reach only through a barrel export lands here too: the
//     selector does not follow exports, so no evidence was collected.
//   * some test depends on it → it has no executable line (an enum, a
//     const table, an abstract interface): Dart emits no record for such
//     a library, so it contributes nothing. Measured on run 35178170681,
//     where the enum-only vehicle_signal.dart has no record although 138
//     tests load it.
//
// ## Allowance
//
//   * Critical paths ([criticalPathPrefixes]: storage, sync, privacy,
//     consent, background work, trip persistence and the OBD2 recording
//     session): at most [criticalUncoveredAllowance] uncovered changed
//     executable lines.
//   * Everywhere else: fails only when BOTH more than
//     [uncoveredLineAllowance] changed executable lines are uncovered AND
//     the changed-line coverage is below [minimumChangedLinePercent]. A
//     small diff is never failed on percentage noise alone.
//
// The numbers were chosen against the full master coverage of run
// 35167458858 (commit 4bc43478e, filtered 62,680 / 72,069 = 86.97 %) and
// the changed-line coverage of the squash-merged PRs measured with this
// tool; see the #4347 commit message for the sample.
//
// ## Outcomes (exit codes)
//
//   0  pass, or NOT APPLICABLE — decided from the diff alone (no changed
//      maintained source line), never from absent coverage data
//   1  policy failure
//   2  missing, empty or corrupt evidence while the diff needs it — never
//      green
//
// Tested in-process by test/ci/coverage_policy_test.dart.

import 'dart:io';

import 'test_selector.dart' show DependencyGraph;

/// Lines a pull request may leave uncovered outside critical paths
/// before the percentage matters.
const uncoveredLineAllowance = 10;

/// Changed-line coverage below this fails once the allowance is exceeded.
const minimumChangedLinePercent = 80;

/// Uncovered changed executable lines tolerated under a critical path.
const criticalUncoveredAllowance = 0;

/// Paths whose failure modes are data loss, privacy or an OS-interrupted
/// lifecycle (#4339): a changed line there must be executed by a test.
const criticalPathPrefixes = <String>[
  'lib/core/storage/',
  'lib/core/sync/',
  'lib/core/privacy/',
  'lib/core/background/',
  'lib/features/consent/',
  'lib/features/trips/data/',
  'lib/features/obd2/data/session/',
  'lib/features/obd2/data/active_trip_',
];

/// Whether [path] is maintained source in the policy's denominator.
bool isMaintainedSource(String path) =>
    path.startsWith('lib/') &&
    path.endsWith('.dart') &&
    !path.contains('.g.dart') &&
    !path.contains('.freezed.dart') &&
    !path.contains('l10n/app_localizations');

bool isCriticalPath(String path) =>
    criticalPathPrefixes.any((prefix) => path.startsWith(prefix));

/// Raised when coverage evidence cannot be trusted.
class CoverageEvidenceException implements Exception {
  CoverageEvidenceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Parses lcov into `file -> line -> hits`, summing duplicate records
/// (the `lcov -a` merge). Throws [CoverageEvidenceException] on anything
/// malformed: a truncated or garbled report must not read as coverage.
Map<String, Map<int, int>> parseLcov(String content,
    [Map<String, Map<int, int>>? into]) {
  final result = into ?? <String, Map<int, int>>{};
  String? current;
  var lineNo = 0;
  for (final raw in content.split('\n')) {
    lineNo++;
    final line = raw.trimRight();
    if (line.isEmpty) continue;
    if (line.startsWith('SF:')) {
      if (current != null) {
        throw CoverageEvidenceException(
            'lcov line $lineNo: SF before end_of_record of $current');
      }
      current = line.substring(3);
      result.putIfAbsent(current, () => <int, int>{});
    } else if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      final number = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
      final hits = parts.length >= 2 ? int.tryParse(parts[1]) : null;
      if (current == null || number == null || hits == null || hits < 0) {
        throw CoverageEvidenceException('lcov line $lineNo: bad DA "$line"');
      }
      result[current]!.update(number, (h) => h + hits, ifAbsent: () => hits);
    } else if (line == 'end_of_record') {
      if (current == null) {
        throw CoverageEvidenceException(
            'lcov line $lineNo: end_of_record without SF');
      }
      current = null;
    }
    // LF/LH/FN/BRDA and friends carry nothing the policy reads.
  }
  if (current != null) {
    throw CoverageEvidenceException('lcov ends inside the record of $current');
  }
  return result;
}

/// `path -> added/modified line numbers (new side)` from a unified diff
/// (`git diff --unified=0`). Deleted files and pure deletions add nothing.
Map<String, Set<int>> parseChangedLines(String diff) {
  final result = <String, Set<int>>{};
  final hunk = RegExp(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@');
  String? current;
  var previous = '';
  for (final line in diff.split('\n')) {
    final afterMinusHeader = previous.startsWith('--- ');
    previous = line;
    // A `+++ ` header only ever follows `--- `; an added content line
    // that happens to read `++ x` must not switch files.
    if (afterMinusHeader && line.startsWith('+++ ')) {
      final target = line.substring(4).trim();
      current = target == '/dev/null'
          ? null
          : (target.startsWith('b/') ? target.substring(2) : target);
      continue;
    }
    final m = hunk.firstMatch(line);
    if (m == null || current == null) continue;
    final start = int.parse(m.group(1)!);
    final count = m.group(2) == null ? 1 : int.parse(m.group(2)!);
    final lines = result.putIfAbsent(current, () => <int>{});
    for (var i = 0; i < count; i++) {
      lines.add(start + i);
    }
  }
  result.removeWhere((_, lines) => lines.isEmpty);
  return result;
}

final _nonCode = RegExp(
    r'^\s*($|//|/\*|\*|\*/|import\s|export\s|part\s|part of\s|library\b|[{}()\[\];,]+\s*$)');

/// Whether a source line could hold executable code — used only for a
/// changed file no test depends on, which has no `DA:` records.
bool looksLikeCode(String line) => !_nonCode.hasMatch(line);

/// The judgement for one pull request.
class CoverageVerdict {
  CoverageVerdict({
    required this.applicable,
    required this.executable,
    required this.covered,
    required this.uncoveredByFile,
    required this.unmeasuredFiles,
    required this.criticalUncovered,
    required this.failures,
  });

  /// False when the diff changes no maintained source line.
  final bool applicable;
  final int executable;
  final int covered;
  final Map<String, List<int>> uncoveredByFile;
  /// Changed files no test depends on (their code-like lines count).
  final List<String> unmeasuredFiles;
  final int criticalUncovered;
  final List<String> failures;

  int get uncovered => executable - covered;
  bool get passed => failures.isEmpty;

  double get percent => executable == 0 ? 100 : covered * 100 / executable;

  String toMarkdown() {
    final b = StringBuffer()..writeln('## Changed-line coverage (#4347)');
    if (!applicable) {
      return (b
            ..writeln()
            ..writeln('NOT APPLICABLE — the diff changes no maintained lib/ '
                'source line (generated, test, docs or deletions only).'))
          .toString();
    }
    b
      ..writeln()
      ..writeln('| Measure | Value |')
      ..writeln('|---|---:|')
      ..writeln('| Changed executable lines | $executable |')
      ..writeln('| Covered | $covered |')
      ..writeln('| Changed-line coverage | ${percent.toStringAsFixed(2)} % |')
      ..writeln('| Uncovered under critical paths | $criticalUncovered |')
      ..writeln()
      ..writeln('Policy: outside critical paths fail when more than '
          '$uncoveredLineAllowance lines are uncovered AND coverage is below '
          '$minimumChangedLinePercent %; critical paths tolerate '
          '$criticalUncoveredAllowance uncovered lines.')
      ..writeln()
      ..writeln(passed ? '**PASS**' : '**FAIL**');
    for (final f in failures) {
      b.writeln('- $f');
    }
    if (unmeasuredFiles.isNotEmpty) {
      b
        ..writeln()
        ..writeln('Changed files no test depends on:');
      for (final f in unmeasuredFiles) {
        b.writeln('- `$f`');
      }
    }
    if (uncoveredByFile.isNotEmpty) {
      b
        ..writeln()
        ..writeln('Uncovered changed lines:');
      for (final e in uncoveredByFile.entries) {
        b.writeln('- `${e.key}`${isCriticalPath(e.key) ? ' (critical)' : ''}: '
            '${e.value.join(', ')}');
      }
    }
    return b.toString();
  }
}

/// Applies the policy. For a changed file without coverage records,
/// [reachedByTests] says whether any test depends on it and [readSource]
/// returns its current lines (null if unreadable). Throws
/// [CoverageEvidenceException] when the diff needs coverage and
/// [coverage] holds no maintained-source record at all.
CoverageVerdict evaluateCoveragePolicy({
  required Map<String, Set<int>> changedLines,
  required Map<String, Map<int, int>> coverage,
  required bool Function(String path) reachedByTests,
  required List<String>? Function(String path) readSource,
}) {
  final changed = {
    for (final e in changedLines.entries)
      if (isMaintainedSource(e.key)) e.key: e.value,
  };
  if (changed.isEmpty) {
    return CoverageVerdict(
      applicable: false,
      executable: 0,
      covered: 0,
      uncoveredByFile: const {},
      unmeasuredFiles: const [],
      criticalUncovered: 0,
      failures: const [],
    );
  }
  final measured = {
    for (final e in coverage.entries)
      if (isMaintainedSource(e.key) && e.value.isNotEmpty) e.key: e.value,
  };
  if (measured.isEmpty) {
    throw CoverageEvidenceException(
        'the diff changes ${changed.length} maintained source file(s) but '
        'the coverage report has no maintained-source line records');
  }

  var executable = 0;
  var covered = 0;
  var criticalUncovered = 0;
  final uncoveredByFile = <String, List<int>>{};
  final unmeasured = <String>[];
  for (final path in changed.keys.toList()..sort()) {
    final lines = changed[path]!.toList()..sort();
    final hits = measured[path];
    final uncovered = <int>[];
    if (hits == null) {
      // Loaded by a test yet no record: no executable line (see header).
      if (reachedByTests(path)) continue;
      final source = readSource(path);
      if (source == null) {
        throw CoverageEvidenceException('cannot read changed file $path');
      }
      final codeLines = [
        for (final n in lines)
          if (n >= 1 && n <= source.length && looksLikeCode(source[n - 1])) n,
      ];
      if (codeLines.isEmpty) continue;
      unmeasured.add(path);
      executable += codeLines.length;
      uncovered.addAll(codeLines);
    } else {
      for (final n in lines) {
        final h = hits[n];
        if (h == null) continue; // not executable
        executable++;
        if (h > 0) {
          covered++;
        } else {
          uncovered.add(n);
        }
      }
    }
    if (uncovered.isNotEmpty) {
      uncoveredByFile[path] = uncovered;
      if (isCriticalPath(path)) criticalUncovered += uncovered.length;
    }
  }

  final failures = <String>[];
  if (criticalUncovered > criticalUncoveredAllowance) {
    failures.add('$criticalUncovered changed executable line(s) under a '
        'critical path are not executed by any test (allowance '
        '$criticalUncoveredAllowance)');
  }
  final nonCriticalUncovered = executable - covered - criticalUncovered;
  final percent = executable == 0 ? 100.0 : covered * 100 / executable;
  if (nonCriticalUncovered > uncoveredLineAllowance &&
      percent < minimumChangedLinePercent) {
    failures.add('$nonCriticalUncovered uncovered changed executable lines '
        '(allowance $uncoveredLineAllowance) and changed-line coverage '
        '${percent.toStringAsFixed(2)} % < $minimumChangedLinePercent %');
  }
  return CoverageVerdict(
    applicable: true,
    executable: executable,
    covered: covered,
    uncoveredByFile: uncoveredByFile,
    unmeasuredFiles: unmeasured,
    criticalUncovered: criticalUncovered,
    failures: failures,
  );
}

/// The tests whose coverage can be evidence for [changedPaths]: every
/// test that depends (imports or parts, the selector's graph) on a
/// changed maintained source file. Sorted. Only these run with
/// `--coverage` in a PR shard — coverage costs 1.8–2.3× test time
/// (matched full-suite PR vs master shards, runs 35164989389/35167458858
/// and 35179469326/35181995111), so the always-run bucket and every
/// other selected test keep running without it.
List<String> coverageTests(Iterable<String> changedPaths, DependencyGraph graph) {
  final changed = changedPaths.where(isMaintainedSource).toSet();
  if (changed.isEmpty) return const [];
  return [
    for (final t in graph.tests)
      if (graph.closureOf(t).any(changed.contains)) t,
  ];
}

/// Runs the policy from command-line arguments; returns the exit code.
int runCoveragePolicy(List<String> args, {StringSink? out}) {
  final StringSink sink = out ?? stdout;
  String? diffPath;
  String? summaryPath;
  var applicableOnly = false;
  var coverageTestsOnly = false;
  // `error` when the gate enforces, `warning` while it is advisory.
  var level = 'error';
  final lcovPaths = <String>[];
  for (var i = 0; i < args.length; i++) {
    final value = i + 1 < args.length ? args[i + 1] : null;
    switch (args[i]) {
      case '--applicable-only':
        applicableOnly = true;
      case '--coverage-tests':
        coverageTestsOnly = true;
      case '--diff' when value != null:
        diffPath = value;
        i++;
      case '--lcov' when value != null:
        lcovPaths.add(value);
        i++;
      case '--summary' when value != null:
        summaryPath = value;
        i++;
      case '--annotation-level'
          when value == 'error' || value == 'warning':
        level = value!;
        i++;
      default:
        sink.writeln('::error::unknown or incomplete argument ${args[i]}');
        return 2;
    }
  }
  if (diffPath == null || !File(diffPath).existsSync()) {
    sink.writeln('::$level::--diff file missing: $diffPath — the changed '
        'lines are the policy input; refusing to guess');
    return 2;
  }
  final changedLines = parseChangedLines(File(diffPath).readAsStringSync());
  final applicable = changedLines.keys.any(isMaintainedSource);
  if (applicableOnly) {
    // GITHUB_OUTPUT line: whether the test shards must collect coverage.
    sink.writeln('applicable=$applicable');
    return 0;
  }
  if (coverageTestsOnly) {
    for (final t in coverageTests(changedLines.keys, DependencyGraph.scan())) {
      sink.writeln(t);
    }
    return 0;
  }

  CoverageVerdict verdict;
  try {
    final coverage = <String, Map<int, int>>{};
    if (applicable) {
      if (lcovPaths.isEmpty) {
        throw CoverageEvidenceException('no --lcov report given');
      }
      for (final p in lcovPaths) {
        final f = File(p);
        // A shard whose tests load no lib/ file writes an empty report;
        // that is allowed per shard. A MISSING report is not, and an
        // all-empty set fails below as "no maintained-source records".
        if (!f.existsSync()) {
          throw CoverageEvidenceException('coverage report $p is missing');
        }
        parseLcov(f.readAsStringSync(), coverage);
      }
    }
    Set<String>? reached;
    verdict = evaluateCoveragePolicy(
      changedLines: changedLines,
      coverage: coverage,
      reachedByTests: (path) => (reached ??=
              DependencyGraph.scan().libFilesReachedByTests())
          .contains(path),
      readSource: (path) {
        final f = File(path);
        return f.existsSync() ? f.readAsLinesSync() : null;
      },
    );
  } on CoverageEvidenceException catch (e) {
    sink.writeln('::$level::Changed-line coverage has no trustworthy '
        'evidence: $e');
    if (summaryPath != null) {
      File(summaryPath).writeAsStringSync(
          '## Changed-line coverage (#4347)\n\n**NO EVIDENCE** — $e\n',
          mode: FileMode.append);
    }
    return 2;
  }

  final markdown = verdict.toMarkdown();
  sink.writeln(markdown);
  if (summaryPath != null) {
    File(summaryPath).writeAsStringSync(markdown, mode: FileMode.append);
  }
  // One annotation per file listing its uncovered changed lines, so they
  // show on the PR diff whether or not the policy fails.
  for (final MapEntry(key: path, value: lines)
      in verdict.uncoveredByFile.entries) {
    final kind = isCriticalPath(path) ? 'critical' : 'other';
    sink.writeln('::warning file=$path,line=${lines.first}::'
        '${lines.length} uncovered changed line(s) ($kind): '
        '${lines.join(', ')}');
  }
  if (!verdict.passed) {
    for (final f in verdict.failures) {
      sink.writeln('::$level::$f');
    }
    return 1;
  }
  return 0;
}

void main(List<String> args) {
  exitCode = runCoveragePolicy(args);
}
