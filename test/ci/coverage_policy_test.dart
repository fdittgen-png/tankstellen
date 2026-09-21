// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

// #4347 — the pre-merge changed-line coverage policy, EXECUTED on
// synthetic diffs and lcov reports (in process, no `dart run`), plus the
// whole-project floor script on fixture reports. The workflow wiring is
// pinned separately in coverage_policy_workflow_test.dart.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/coverage_policy.dart';
import '../../tool/test_selector.dart' show DependencyGraph;

/// A `git diff --unified=0` adding [lines] (1-based, contiguous runs are
/// fine as single-line hunks) to [path].
String _diffAdding(String path, List<int> lines, {bool newFile = false}) {
  final b = StringBuffer()
    ..writeln('diff --git a/$path b/$path')
    ..writeln(newFile ? '--- /dev/null' : '--- a/$path')
    ..writeln('+++ b/$path');
  for (final n in lines) {
    b
      ..writeln('@@ -0,0 +$n @@')
      ..writeln('+code();');
  }
  return b.toString();
}

/// lcov for one file: line -> hits.
String _lcov(String path, Map<int, int> hits) => [
      'SF:$path',
      for (final e in hits.entries) 'DA:${e.key},${e.value}',
      'end_of_record',
      '',
    ].join('\n');

CoverageVerdict _judge(
  String diff,
  String lcov, {
  bool Function(String)? reached,
  List<String>? Function(String)? source,
}) =>
    evaluateCoveragePolicy(
      changedLines: parseChangedLines(diff),
      coverage: parseLcov(lcov),
      reachedByTests: reached ?? (_) => true,
      readSource: source ?? (_) => null,
    );

void main() {
  group('diff parsing', () {
    test('added and modified lines, not deletions or deleted files', () {
      const diff = '''
diff --git a/lib/a.dart b/lib/a.dart
--- a/lib/a.dart
+++ b/lib/a.dart
@@ -3 +3,2 @@ class A {
-old();
+new1();
+++ a content line that looks like a header
@@ -10,2 +11,0 @@
-gone();
-gone();
diff --git a/lib/gone.dart b/lib/gone.dart
--- a/lib/gone.dart
+++ /dev/null
@@ -1,3 +0,0 @@
-x
-y
-z
''';
      expect(parseChangedLines(diff), {
        'lib/a.dart': {3, 4},
      });
    });
  });

  group('lcov parsing never turns garbage into coverage', () {
    test('merges shards by summing hits', () {
      final merged = parseLcov(_lcov('lib/a.dart', {1: 0, 2: 3}));
      parseLcov(_lcov('lib/a.dart', {1: 2}), merged);
      expect(merged['lib/a.dart'], {1: 2, 2: 3});
    });

    for (final (name, report) in [
      ('a truncated record', 'SF:lib/a.dart\nDA:1,1\n'),
      ('a garbled DA line', 'SF:lib/a.dart\nDA:one,1\nend_of_record\n'),
      ('DA outside a record', 'DA:1,1\n'),
      ('a negative hit count', 'SF:lib/a.dart\nDA:1,-1\nend_of_record\n'),
    ]) {
      test('rejects $name', () {
        expect(() => parseLcov(report),
            throwsA(isA<CoverageEvidenceException>()));
      });
    }
  });

  group('the policy', () {
    const plain = 'lib/features/map/map_view.dart';
    const critical = 'lib/core/storage/box_store.dart';

    test('a fully covered change passes', () {
      final v = _judge(_diffAdding(plain, [1, 2, 3]),
          _lcov(plain, {1: 1, 2: 4, 3: 9}));
      expect(v.passed, isTrue);
      expect(v.executable, 3);
      expect(v.percent, 100);
    });

    test('non-executable changed lines are not in the denominator', () {
      final v = _judge(_diffAdding(plain, [1, 2, 3]), _lcov(plain, {2: 1}));
      expect(v.executable, 1);
      expect(v.passed, isTrue);
    });

    test('ONE uncovered changed line under a critical path fails', () {
      final v = _judge(_diffAdding(critical, [10, 11]),
          _lcov(critical, {10: 5, 11: 0}));
      expect(v.passed, isFalse);
      expect(v.criticalUncovered, 1);
      expect(v.uncoveredByFile, {
        critical: [11],
      });
    });

    test('a small uncovered change outside critical paths is within the '
        'allowance', () {
      final lines = List.generate(uncoveredLineAllowance, (i) => i + 1);
      final v = _judge(
          _diffAdding(plain, lines), _lcov(plain, {for (final n in lines) n: 0}));
      expect(v.percent, 0);
      expect(v.passed, isTrue,
          reason: 'a few lines must not fail on percentage noise');
    });

    test('a broad uncovered change fails once past the allowance and under '
        'the floor', () {
      final lines = List.generate(40, (i) => i + 1);
      // 30 covered, 10 uncovered = 75 %: under the floor but AT the
      // allowance — passes; one more uncovered line fails.
      final atAllowance = _judge(_diffAdding(plain, lines),
          _lcov(plain, {for (final n in lines) n: n <= 30 ? 1 : 0}));
      expect(atAllowance.passed, isTrue);
      final past = _judge(_diffAdding(plain, lines),
          _lcov(plain, {for (final n in lines) n: n <= 29 ? 1 : 0}));
      expect(past.passed, isFalse);
      expect(past.failures.single, contains('72.50 %'));
    });

    test('many uncovered lines still pass when changed-line coverage meets '
        'the floor', () {
      final lines = List.generate(200, (i) => i + 1);
      final v = _judge(_diffAdding(plain, lines),
          _lcov(plain, {for (final n in lines) n: n <= 170 ? 1 : 0}));
      expect(v.uncovered, 30);
      expect(v.percent, 85);
      expect(v.passed, isTrue);
    });

    test('a changed file NO test depends on counts its code lines as '
        'uncovered', () {
      const untested = 'lib/core/sync/new_uploader.dart';
      final v = _judge(
        _diffAdding(untested, [1, 2, 3, 4], newFile: true),
        _lcov(plain, {1: 1}),
        reached: (p) => p != untested,
        source: (_) => ['// doc', 'void upload() {', '  send();', '}'],
      );
      expect(v.unmeasuredFiles, [untested]);
      expect(v.executable, 2, reason: 'the comment and the brace are not code');
      expect(v.criticalUncovered, 2);
      expect(v.passed, isFalse);
    });

    test('a changed file tests DO load but with no record has no executable '
        'line (enum / const table) and contributes nothing', () {
      const enumOnly = 'lib/features/obd2/domain/vehicle_signal.dart';
      final v = _judge(
        _diffAdding(enumOnly, [5, 6, 7]),
        _lcov(plain, {1: 1}),
        reached: (_) => true,
        source: (_) => throw StateError('must not be read'),
      );
      expect(v.applicable, isTrue);
      expect(v.executable, 0);
      expect(v.passed, isTrue);
    });

    test('generated-only, test-only and deletion-only diffs are NOT '
        'APPLICABLE — decided from the diff, not from missing data', () {
      for (final diff in [
        _diffAdding('lib/core/model.g.dart', [1]),
        _diffAdding('lib/core/model.freezed.dart', [1]),
        _diffAdding('lib/l10n/app_localizations_de.dart', [1]),
        _diffAdding('test/core/model_test.dart', [1]),
        '--- a/lib/a.dart\n+++ b/lib/a.dart\n@@ -4,2 +3,0 @@\n-x\n-y\n',
      ]) {
        final v = _judge(diff, '');
        expect(v.applicable, isFalse, reason: diff);
        expect(v.passed, isTrue);
      }
    });

    test('an applicable diff with no maintained-source coverage at all is '
        'NO EVIDENCE, never a pass', () {
      expect(
        () => _judge(_diffAdding(plain, [1]),
            _lcov('lib/core/model.g.dart', {1: 1})),
        throwsA(isA<CoverageEvidenceException>()),
      );
    });
  });

  test('only the tests of changed maintained files run with --coverage',
      () {
    final graph = DependencyGraph.scan();
    const part =
        'lib/features/obd2/data/session/trip_recording_controller_emit.dart';
    final measured = coverageTests(const [part], graph);
    expect(
        measured,
        contains('test/features/obd2/data/'
            'trip_recording_controller_emit_summary_test.dart'));
    expect(measured.where((t) => t.startsWith('test/lint/')), isEmpty,
        reason: 'the always-run bucket loads no lib/ file to measure');
    expect(measured.length, lessThan(graph.tests.length ~/ 2));
    const aTest = 'test/features/obd2/data/'
        'trip_recording_controller_emit_summary_test.dart';
    expect(
        coverageTests(const [
          'lib/features/obd2/data/obd2_connect_trace.g.dart',
          aTest,
        ], graph),
        isEmpty,
        reason: 'generated and test files are not measured source');
  });

  group('the command line (exit codes)', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('cov_policy_'));
    tearDown(() => tmp.deleteSync(recursive: true));

    String write(String name, String content) {
      final f = File('${tmp.path}/$name')..writeAsStringSync(content);
      return f.path;
    }

    int run(List<String> args) => runCoveragePolicy(args, out: StringBuffer());

    const file = 'lib/features/map/map_view.dart';

    test('0 on pass, 1 on policy failure', () {
      final diff = write('d.diff', _diffAdding('lib/core/sync/s.dart', [1]));
      expect(
          run(['--diff', diff, '--lcov',
              write('ok.info', _lcov('lib/core/sync/s.dart', {1: 1}))]),
          0);
      expect(
          run(['--diff', diff, '--lcov',
              write('bad.info', _lcov('lib/core/sync/s.dart', {1: 0}))]),
          1);
    });

    test('2 when a named shard report is missing', () {
      final diff = write('d.diff', _diffAdding(file, [1]));
      expect(
          run(['--diff', diff, '--lcov',
              write('ok.info', _lcov(file, {1: 1})), '--lcov',
              '${tmp.path}/missing.info']),
          2);
    });

    test('2 when every report is empty or fully filtered', () {
      final diff = write('d.diff', _diffAdding(file, [1]));
      expect(run(['--diff', diff, '--lcov', write('e.info', '')]), 2);
      expect(
          run(['--diff', diff, '--lcov',
              write('g.info', _lcov('lib/a.g.dart', {1: 1}))]),
          2);
    });

    test('2 on a corrupt report and when the diff itself is missing', () {
      final diff = write('d.diff', _diffAdding(file, [1]));
      expect(
          run(['--diff', diff, '--lcov', write('c.info', 'SF:$file\nDA:1')]),
          2);
      expect(run(['--diff', '${tmp.path}/none.diff']), 2);
    });

    test('0 without any report when the diff is not applicable', () {
      final diff = write('d.diff', _diffAdding('test/a_test.dart', [1]));
      expect(run(['--diff', diff]), 0);
    });

    test('annotations list uncovered lines; the level follows the switch',
        () {
      const path = 'lib/core/sync/s.dart';
      final diff = write('d.diff', _diffAdding(path, [3, 4]));
      final lcov = write('bad.info', _lcov(path, {3: 0, 4: 0}));

      final advisory = StringBuffer();
      expect(
          runCoveragePolicy(
              ['--diff', diff, '--lcov', lcov, '--annotation-level', 'warning'],
              out: advisory),
          1);
      expect('$advisory',
          contains('::warning file=$path,line=3::2 uncovered changed line(s) '
              '(critical): 3, 4'));
      expect('$advisory', isNot(contains('::error')));

      final enforcing = StringBuffer();
      expect(runCoveragePolicy(['--diff', diff, '--lcov', lcov], out: enforcing),
          1);
      expect('$enforcing', contains('::error::'));

      final noEvidence = StringBuffer();
      expect(
          runCoveragePolicy([
            '--diff', diff, '--lcov', '${tmp.path}/missing.info',
            '--annotation-level', 'warning',
          ], out: noEvidence),
          2);
      expect('$noEvidence', contains('::warning::Changed-line coverage has no'));
    });

    test('--applicable-only prints the GITHUB_OUTPUT line', () {
      final out = StringBuffer();
      final code = runCoveragePolicy([
        '--diff',
        write('d.diff', _diffAdding(file, [1])),
        '--applicable-only',
      ], out: out);
      expect(code, 0);
      expect(out.toString().trim(), 'applicable=true');
    });
  });

  group('scripts/check_coverage.sh — the whole-project floor', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('cov_floor_'));
    tearDown(() => tmp.deleteSync(recursive: true));

    ProcessResult floor(String lcov, int threshold) {
      final f = File('${tmp.path}/lcov.info')..writeAsStringSync(lcov);
      return Process.runSync('bash', [
        'scripts/check_coverage.sh',
        '--threshold',
        '$threshold',
        '--lcov',
        f.path,
      ]);
    }

    test('an empty or fully filtered report fails instead of passing', () {
      final empty = floor(_lcov('lib/l10n/app_localizations.dart', {1: 1}), 40);
      expect(empty.exitCode, isNot(0), reason: '${empty.stdout}');
      expect('${empty.stdout}', contains('No coverage data left'));
    });

    test('reports two decimals and gates on the exact ratio', () {
      // 2 of 3 lines = 66.67 %.
      final report = _lcov('lib/a.dart', {1: 1, 2: 1, 3: 0});
      final pass = floor(report, 66);
      expect(pass.exitCode, 0);
      expect('${pass.stdout}', contains('Coverage: 66.67% (2/3 lines'));
      expect(floor(report, 67).exitCode, isNot(0));
    });

    test('generated files stay out of the denominator', () {
      final report = _lcov('lib/a.dart', {1: 1}) +
          _lcov('lib/a.g.dart', {1: 0, 2: 0, 3: 0});
      final r = floor(report, 100);
      expect(r.exitCode, 0);
      expect('${r.stdout}', contains('(1/1 lines'));
    });
  });
}
