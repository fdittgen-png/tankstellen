// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Path-affected test selector (#1592 / Epic #1591).
//
// Reads a list of changed paths (one per line, on stdin or from git
// diff), walks the Dart import graph, and emits the set of test files
// whose transitive imports touch any changed `lib/` file.
//
// Two special cases trigger a full-suite run (output: every test
// file under `test/`):
//   1. Any changed file in `lib/main.dart` or `lib/app/router.dart` —
//      these are global entry-points that reach the rest of the tree.
//   2. Any changed file in `pubspec.yaml`, `analysis_options.yaml`,
//      `lib/l10n/_fragments/`, or under `lib/l10n/`. ARB / dep / lint
//      changes can affect everything.
//
// Tests that don't transitively import any `lib/` file are part of
// the **always-run bucket** (test/lint/*, test/security/*, …) — they
// always appear in the output set regardless of the diff. Detected
// automatically: zero overlap between the test's transitive imports
// and `lib/**/*.dart`.
//
// Usage:
//   dart run tool/test_selector.dart                # auto-detect diff
//                                                   # via `git diff
//                                                   # --name-only
//                                                   # master...HEAD`
//   dart run tool/test_selector.dart - < changed.txt # read paths
//                                                   # from stdin
//   dart run tool/test_selector.dart -base origin/master
//
// Exit codes:
//   0 — selector ran (one or more tests on stdout)
//   1 — IO error
//   2 — no diff detected; called when neither stdin nor git-diff
//       returned any paths (caller should run the full suite).
//
// The output is **deterministic** (sorted) so a CI shard split is
// stable across reruns.

import 'dart:io';

const Set<String> _runAllSentinels = {
  'lib/main.dart',
  'lib/app/router.dart',
};

const List<String> _runAllPrefixes = [
  'lib/l10n/',
  'lib/app/app_initializer',
];

const List<String> _runAllExactMatches = [
  'pubspec.yaml',
  'pubspec.lock',
  'analysis_options.yaml',
];

const String _libRoot = 'lib/';
const String _testRoot = 'test/';

Future<void> main(List<String> argv) async {
  String base = 'master';
  bool readStdin = false;
  for (var i = 0; i < argv.length; i++) {
    final a = argv[i];
    if (a == '-') {
      readStdin = true;
    } else if (a == '-base' || a == '--base') {
      base = argv[++i];
    }
  }

  final changed = readStdin ? _readStdinPaths() : _gitDiff(base);
  if (changed.isEmpty) {
    stderr.writeln('test_selector: no changed paths detected, '
        'caller should run the full suite');
    exit(2);
  }

  // Bail-out shortcuts. Anything that can plausibly affect every test
  // tree falls back to the full suite.
  for (final p in changed) {
    if (_runAllSentinels.contains(p) ||
        _runAllExactMatches.contains(p) ||
        _runAllPrefixes.any(p.startsWith)) {
      _emitFullSuite();
      return;
    }
  }

  final libChanged = changed
      .where((p) => p.startsWith(_libRoot) && p.endsWith('.dart'))
      .toSet();

  // Build the file → direct-imports forward edge map for every Dart
  // file under `lib/` and `test/`. The map keys + values are
  // POSIX-style relative paths from the project root.
  final imports = <String, Set<String>>{};
  _scanDartFiles(_libRoot, imports);
  _scanDartFiles(_testRoot, imports);

  // For each test file, compute its transitive lib imports. Only
  // `_test.dart` files are emitted — helpers / fixtures in
  // `test/helpers/`, `test/mocks/`, etc. aren't directly runnable.
  final allTests = imports.keys
      .where((k) => k.startsWith(_testRoot) && k.endsWith('_test.dart'))
      .toList()
    ..sort();

  final affected = <String>{};
  final alwaysRun = <String>{};

  for (final t in allTests) {
    final transitive = _transitiveClosure(t, imports);
    final libDeps =
        transitive.where((f) => f.startsWith(_libRoot)).toSet();

    if (libDeps.isEmpty) {
      // Cross-cutting: no transitive lib import → always-run bucket.
      alwaysRun.add(t);
      continue;
    }
    if (libDeps.any(libChanged.contains)) {
      affected.add(t);
    }
  }

  final out = (<String>{}..addAll(affected)..addAll(alwaysRun)).toList()..sort();
  for (final t in out) {
    stdout.writeln(t);
  }
}

List<String> _readStdinPaths() => stdin
    .readLineSync(retainNewlines: false)
    ?.split('\n')
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList() ??
    <String>[];

List<String> _gitDiff(String base) {
  final r = Process.runSync(
    'git',
    ['diff', '--name-only', '$base...HEAD'],
    runInShell: false,
  );
  if (r.exitCode != 0) {
    stderr.writeln('git diff failed: ${r.stderr}');
    return const [];
  }
  return (r.stdout as String)
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

void _emitFullSuite() {
  final tests = <String>[];
  _walk(_testRoot, (p) {
    if (p.endsWith('_test.dart')) tests.add(p);
  });
  tests.sort();
  for (final t in tests) {
    stdout.writeln(t);
  }
}

void _scanDartFiles(String root, Map<String, Set<String>> imports) {
  _walk(root, (p) {
    if (!p.endsWith('.dart')) return;
    final content = File(p).readAsStringSync();
    imports[p] = _extractImports(p, content);
  });
}

void _walk(String root, void Function(String) visit) {
  final dir = Directory(root);
  if (!dir.existsSync()) return;
  for (final ent in dir.listSync(recursive: true, followLinks: false)) {
    if (ent is! File) continue;
    final p = ent.path.replaceAll(r'\', '/');
    visit(p);
  }
}

// Matches `import '...';` and `import "...";` at the start of a line
// (no leading whitespace permitted — Dart imports live at file top).
final RegExp _importRe = RegExp(
  r'''^\s*import\s+["']([^"']+)["']''',
  multiLine: true,
);

Set<String> _extractImports(String file, String content) {
  final result = <String>{};
  for (final m in _importRe.allMatches(content)) {
    final uri = m.group(1)!;
    final resolved = _resolve(file, uri);
    if (resolved != null) result.add(resolved);
  }
  return result;
}

/// Resolve an `import 'foo';` directive to a project-relative path.
/// Returns `null` for SDK imports (`dart:io`) and third-party
/// (`package:flutter/...`) — those don't affect the local file graph.
String? _resolve(String fromFile, String uri) {
  if (uri.startsWith('dart:')) return null;
  if (uri.startsWith('package:')) {
    // `package:tankstellen/foo/bar.dart` → `lib/foo/bar.dart`.
    if (uri.startsWith('package:tankstellen/')) {
      return 'lib/${uri.substring('package:tankstellen/'.length)}';
    }
    // Third-party package — outside our graph.
    return null;
  }
  // Relative — resolve against the importing file's directory.
  final fromDir = fromFile.contains('/')
      ? fromFile.substring(0, fromFile.lastIndexOf('/'))
      : '';
  final parts = <String>[];
  for (final seg in fromDir.split('/')) {
    if (seg.isNotEmpty) parts.add(seg);
  }
  for (final seg in uri.split('/')) {
    if (seg == '.') continue;
    if (seg == '..') {
      if (parts.isNotEmpty) parts.removeLast();
      continue;
    }
    parts.add(seg);
  }
  return parts.join('/');
}

/// Transitive closure of imports starting from [start].
///
/// Iterative BFS — Dart import graphs can have cycles (test helpers
/// importing each other), so the visited set prevents infinite loops.
Set<String> _transitiveClosure(String start, Map<String, Set<String>> imports) {
  final visited = <String>{start};
  final queue = <String>[start];
  while (queue.isNotEmpty) {
    final current = queue.removeLast();
    final next = imports[current];
    if (next == null) continue;
    for (final n in next) {
      if (visited.add(n)) queue.add(n);
    }
  }
  return visited;
}
