// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan ratchet (#4398): a test file that mentions `Hive` may not
/// remove a directory recursively from its own `tearDown`/`tearDownAll`.
/// It must call `closeHiveAndDeleteTemp` from
/// `test/helpers/hive_temp_dir.dart` instead.
///
/// **Why.** `Hive.close()` deletes each open box's `.lock` file from
/// inside `StorageBackendVm._closeInternal`. A teardown that removes the
/// temp directory while any part of that is still in flight makes Hive's
/// own delete throw `PathNotFoundException`, failing a test that was only
/// tidying up. That race took down three CI shards
/// (`service_reminder_evaluator_test` twice, `opportunity_stores_test`
/// once) on diffs that touched no storage code, and passed standalone
/// every time. `test/helpers/hive_temp_dir_test.dart` reproduces it
/// deterministically.
///
/// **What counts as a violation** (the scanner's own definition, which is
/// what the baseline below is measured with):
/// - the file is under `test/`, ends in `.dart`, and its source contains
///   the string `Hive` in CODE (comments are stripped first) — a test
///   with no Hive in it cannot lose this race, and naming Hive in prose
///   is not using it;
///   This file itself is excluded: its mutation-check fixtures are
///   offender *string literals*, not teardowns;
/// - a line matching `tearDown(` or `tearDownAll(` opens a brace on that
///   same line (a `tearDown(someFunction);` reference has no body here
///   and is skipped);
/// - somewhere inside that body, up to the matching closing brace, a line
///   matches `.delete(recursive: true)` or `.deleteSync(recursive: true)`
///   after `//` line comments have been stripped.
///
/// Each such line is one violation, and the count is exact both ways: the
/// baseline is **0** and may never be raised. If a teardown genuinely
/// cannot use the helper, fix the helper — do not re-open the ratchet.
void main() {
  const expectedViolations = 0;

  final tearDownOpen = RegExp(r'\btearDown(All)?\(');
  final recursiveDelete =
      RegExp(r'\.delete(Sync)?\(\s*recursive:\s*true\s*\)');
  final lineComment = RegExp(r'//.*');

  int braces(String s) => '{'.allMatches(s).length - '}'.allMatches(s).length;

  /// Violations in [src], attributed to [path]. Pure — it takes the
  /// source as a string so the mutation check below can feed it a
  /// synthetic offender rather than writing a file.
  List<String> scanSource(String path, String src) {
    final violations = <String>[];
    final lines = src.split('\n');
    // The Hive gate reads CODE, not prose. A file that only names Hive
    // in a doc comment (explaining a race it does not run) is not
    // Hive-backed, and pulling it in here would force a meaningless
    // `Hive.close()` into a teardown that never opened a box.
    final code = lines.map((l) => l.replaceAll(lineComment, '')).join('\n');
    if (!code.contains('Hive')) return violations;
    var i = 0;
    while (i < lines.length) {
      if (!tearDownOpen.hasMatch(lines[i])) {
        i++;
        continue;
      }
      var depth = braces(lines[i]);
      if (depth <= 0) {
        // `tearDown(someFunction);` — the body, if any, is elsewhere.
        i++;
        continue;
      }
      var j = i + 1;
      while (j < lines.length && depth > 0) {
        final code = lines[j].replaceAll(lineComment, '');
        if (recursiveDelete.hasMatch(code)) {
          violations.add('$path:${j + 1}: ${code.trim()}');
        }
        depth += braces(code);
        j++;
      }
      i = j;
    }
    return violations;
  }

  /// This file holds the offender fixtures as string literals, so a
  /// whole-file scan would flag itself.
  const selfPath = 'test/lint/no_hand_rolled_hive_teardown_test.dart';

  List<File> testFiles() => Directory('test')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.replaceAll(r'\', '/').endsWith(selfPath))
      .toList();

  test('no test file hand-rolls a Hive temp-dir teardown (#4398)', () {
    final violations = <String>[];
    for (final file in testFiles()) {
      final path = file.path.replaceAll(r'\', '/');
      violations.addAll(scanSource(path, file.readAsStringSync()));
    }

    expect(
      violations.length,
      expectedViolations,
      reason: 'A tearDown that deletes its temp directory can get ahead of '
          'Hive.close(), which unlinks each box\'s .lock file — the #4398 '
          'CI flake. Call `await closeHiveAndDeleteTemp(dir)` from '
          'test/helpers/hive_temp_dir.dart instead. The baseline is 0 and '
          'may never be raised.\nViolations:\n${violations.join('\n')}',
    );
  });

  test('the scan actually reaches the Hive-backed teardowns', () {
    // Guard against a vacuous green: if the cwd, the walk or the `Hive`
    // filter broke, the assertion above would pass while proving nothing.
    final hiveTeardownFiles = testFiles().where((f) {
      final src = f.readAsStringSync();
      return src.contains('Hive') && tearDownOpen.hasMatch(src);
    }).length;
    expect(hiveTeardownFiles, greaterThan(100),
        reason: 'expected the ~160 Hive-backed test files migrated in '
            '#4398 to be in scope, found $hiveTeardownFiles');

    // And the fleet really does route through the helper now.
    final helperUsers = testFiles()
        .where((f) => f.readAsStringSync().contains('closeHiveAndDeleteTemp'))
        .length;
    expect(helperUsers, greaterThan(100),
        reason: 'only $helperUsers files call closeHiveAndDeleteTemp — the '
            '#4398 migration has been partly reverted');
  });

  test('MUTATION CHECK: the scanner flags an injected offender', () {
    const offender = '''
import 'package:hive/hive.dart';
void main() {
  late Directory dir;
  tearDown(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });
}
''';
    expect(scanSource('synthetic.dart', offender), hasLength(1),
        reason: 'the scanner must see a plain hand-rolled teardown');

    const wrappedOffender = '''
import 'package:hive/hive.dart';
void main() {
  tearDownAll(() async {
    await Hive.close();
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });
}
''';
    expect(scanSource('synthetic.dart', wrappedOffender), hasLength(1),
        reason: 'the `if (exists)` and `await delete` spellings count too');
  });

  test('MUTATION CHECK: the scanner does not flag the sanctioned shapes',
      () {
    const compliant = '''
import 'package:hive/hive.dart';
void main() {
  tearDown(() async {
    await closeHiveAndDeleteTemp(dir);
  });
}
''';
    expect(scanSource('synthetic.dart', compliant), isEmpty);

    // A delete outside a teardown (a test body driving the race on
    // purpose, as hive_temp_dir_test.dart does) is not this lint's
    // business.
    const inTestBody = '''
import 'package:hive/hive.dart';
void main() {
  test('the race', () async {
    dir.deleteSync(recursive: true);
  });
}
''';
    expect(scanSource('synthetic.dart', inTestBody), isEmpty);

    // A test with no Hive in it cannot lose this race.
    const noHive = '''
void main() {
  tearDown(() {
    dir.deleteSync(recursive: true);
  });
}
''';
    expect(scanSource('synthetic.dart', noHive), isEmpty);

    // Naming Hive in PROSE is not using it. #4357's WAL fault test
    // explains the Hive snapshot race in a doc comment while opening no
    // box at all; forcing `closeHiveAndDeleteTemp` on it would add a
    // `Hive.close()` to a teardown that never opened one.
    const hiveOnlyInAComment = '''
/// The caller must not write the Hive snapshot row on a failed write.
void main() {
  tearDown(() {
    dir.deleteSync(recursive: true);
  });
}
''';
    expect(scanSource('synthetic.dart', hiveOnlyInAComment), isEmpty);

    // …but the gate must still catch real use, including when a comment
    // is the first mention. This is the pair that keeps the strip honest.
    const hiveInCommentAndCode = '''
/// Mentions Hive in prose first.
import 'package:hive/hive.dart';
void main() {
  tearDown(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });
}
''';
    expect(scanSource('synthetic.dart', hiveInCommentAndCode), hasLength(1));
  });
}
