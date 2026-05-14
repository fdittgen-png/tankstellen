// Tests for `tool/test_selector.dart` (#1592 / Epic #1591).
//
// The selector is a CLI tool, not an importable library, so we drive
// it via Process.run with controlled stdin instead of unit-testing
// private helpers. The test relies on the live `lib/` and `test/`
// trees so it can also catch import-graph regressions: if a refactor
// breaks the resolver, the selector's output for a known anchor file
// will visibly drift.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _selectorPath = 'tool/test_selector.dart';

Future<({int exitCode, String stdout, String stderr})> _runSelector({
  required String stdinInput,
}) async {
  final p = await Process.start(
    'dart',
    ['run', _selectorPath, '-'],
    runInShell: false,
  );
  p.stdin.writeln(stdinInput);
  await p.stdin.close();
  final outF = p.stdout.transform(SystemEncoding().decoder).join();
  final errF = p.stderr.transform(SystemEncoding().decoder).join();
  final code = await p.exitCode;
  return (exitCode: code, stdout: await outF, stderr: await errF);
}

void main() {
  group('test_selector — full-suite sentinels (#1592)', () {
    test('lib/main.dart change runs every test under test/', () async {
      final r = await _runSelector(stdinInput: 'lib/main.dart');
      expect(r.exitCode, 0);
      final paths = r.stdout.split('\n').where((s) => s.isNotEmpty).toList();
      expect(paths, isNotEmpty);
      // A spot check from each major area must be present.
      expect(paths.where((p) => p.startsWith('test/features/')),
          isNotEmpty,
          reason: 'main.dart change is a full-suite sentinel — features tests must be in the output');
      expect(paths.where((p) => p.startsWith('test/lint/')),
          isNotEmpty);
    });

    test('pubspec.yaml change runs every test', () async {
      final r = await _runSelector(stdinInput: 'pubspec.yaml');
      expect(r.exitCode, 0);
      expect(r.stdout.split('\n').where((s) => s.isNotEmpty), isNotEmpty);
    });

    test('lib/l10n/ change runs every test (ARB reaches everywhere)',
        () async {
      final r = await _runSelector(
          stdinInput: 'lib/l10n/_fragments/_base_en.arb');
      expect(r.exitCode, 0);
      expect(r.stdout.split('\n').where((s) => s.isNotEmpty), isNotEmpty);
    });
  });

  group('test_selector — empty diff', () {
    test('no changed paths exits 2 (caller falls back to full suite)',
        () async {
      final r = await _runSelector(stdinInput: '');
      expect(r.exitCode, 2,
          reason: 'empty diff signals the caller to run the full suite');
    });
  });

  group('test_selector — narrow lib change includes always-run bucket', () {
    test('change to a tiny leaf file selects always-run + the file\'s '
        'dependents but not the entire suite', () async {
      // Use a real leaf file: conso_mode.dart was added by #1571 and
      // is imported by a small number of tests + production sites.
      // It must NOT pull every test in (otherwise the selector is
      // useless).
      final r = await _runSelector(
        stdinInput: 'lib/features/feature_management/domain/conso_mode.dart',
      );
      expect(r.exitCode, 0);
      final paths = r.stdout.split('\n').where((s) => s.isNotEmpty).toSet();

      // The dedicated unit-test file for conso_mode must be in the
      // affected set.
      expect(
        paths,
        contains('test/features/feature_management/conso_mode_test.dart'),
        reason: 'conso_mode_test.dart imports conso_mode.dart directly — '
            'a change there must select it.',
      );

      // The always-run bucket (lint tests etc.) must also be present.
      expect(
        paths.any((p) => p.startsWith('test/lint/')),
        isTrue,
        reason: 'always-run bucket must be unioned into every selector '
            'output so cross-cutting invariants stay enforced.',
      );

      // Sanity: the selector must NOT pull in every test in the tree.
      // We don't know the exact count but it should be < 50% of the
      // total test file count.
      final totalTests = Directory('test')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('_test.dart'))
          .length;
      expect(paths.length, lessThan(totalTests ~/ 2),
          reason: 'a leaf-file change must select a small subset, '
              'not >half the suite');
    });
  });
}
