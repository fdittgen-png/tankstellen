// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A `docs/…` path named in the source must be a file git actually has.
///
/// `.gitignore` ignores `docs/*` and then `docs/guides/*` again, with a
/// per-file allowlist for each document that is meant to ship. That is a
/// deliberate design — most of `docs/` is working material — but it has
/// one sharp edge: a new file under `docs/guides/` exists on disk,
/// satisfies every local test, and is silently skipped by `git add -A`.
///
/// #4161 hit it. The release train's production-artifact gate points at
/// `docs/guides/production-artifact-gate.md`, a test asserted the file
/// exists, the test passed on the machine that wrote it, and CI failed on
/// a checkout where the file had never been committed. The gate pointed
/// at nothing.
///
/// So: every `docs/…` path this repository's own Dart source mentions is
/// checked against git's index, in one batched `git ls-files`. A path
/// that is deliberately local belongs in `localOnly` with its reason.
void main() {
  /// Paths that are referenced but intentionally not tracked.
  const localOnly = <String, String>{};

  final pathPattern =
      RegExp('''['"](docs/[A-Za-z0-9_\\-./]+\\.(?:md|json|html))['"]''');

  test('every docs/ path named in lib/, test/ or tool/ is tracked by git', () {
    final referenced = <String, List<String>>{};
    for (final dir in ['lib', 'test', 'tool']) {
      final root = Directory(dir);
      if (!root.existsSync()) continue;
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        for (final m in pathPattern.allMatches(entity.readAsStringSync())) {
          referenced.putIfAbsent(m.group(1)!, () => []).add(entity.path);
        }
      }
    }

    final toCheck =
        referenced.keys.where((p) => !localOnly.containsKey(p)).toList();
    expect(toCheck, isNotEmpty,
        reason: 'the scan found no docs/ references at all — the pattern '
            'has stopped matching and this gate is asserting nothing');

    // One subprocess for the whole set (#4177: a per-case spawn inside a
    // parallel suite is a flake waiting to happen).
    final result = Process.runSync('git', ['ls-files', '--', ...toCheck]);
    expect(result.exitCode, 0,
        reason: 'git ls-files failed: ${result.stderr}');
    final tracked = (result.stdout as String)
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();

    final missing = [
      for (final path in toCheck)
        if (!tracked.contains(path)) '$path — named in ${referenced[path]}',
    ];

    expect(missing, isEmpty,
        reason: 'These documents are referenced by the source but are not '
            'in git, so they do not exist in a fresh checkout. `.gitignore` '
            'ignores docs/* and docs/guides/* and allows individual files '
            'back in; add a `!docs/...` line for each, or record it in '
            'localOnly with a reason.\n\n${missing.join('\n')}');
  });

  test('the local-only list has no stale entries', () {
    for (final entry in localOnly.entries) {
      expect(File(entry.key).existsSync(), isTrue,
          reason: '${entry.key} is listed as deliberately untracked but '
              'does not exist — drop the entry');
    }
  });
}
