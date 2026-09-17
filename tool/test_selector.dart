// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Path-affected test selector (#1592 / Epic #1591).
//
// Reads a list of changed paths (one per line, on stdin or from git
// diff), walks the Dart dependency graph, and emits the set of test files
// whose transitive dependencies touch any changed file.
//
// The graph follows `import` directives (every branch of a conditional
// one) and, since #4347, `part` directives: a part is compiled into its
// library, and before #4347 a change to a part file — e.g. one of the ten
// trip_recording_controller parts — selected no test at all. Measured on
// the last 25 master commits, adding parts selects 0–2 more tests per PR.
//
// `export` edges are deliberately NOT followed. Following them is the
// sound compile graph, but barrels export whole features, so every test
// that imports any barrel would depend on most of lib/: measured on the
// same 25 commits, a typical lib/ PR would select ~950 of 1,825 tests
// instead of 94–673. That trade-off is the maintainer's to make. Until
// then a file reached only through a barrel export is not selected for —
// 28 lib/ files on 2026-09-17 — and tool/coverage_policy.dart, which uses
// this same graph, counts such a file as untested rather than assuming
// it was measured.
//
// Special cases trigger a full-suite run (output: every test file under
// `test/`):
//   1. `lib/main.dart`, `lib/app/router.dart`, `lib/app/app_initializer*`
//      — global entry points that reach the rest of the tree.
//   2. `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, anything
//      under `lib/l10n/`. ARB / dep / lint changes can affect everything.
//   3. Shared test infrastructure and runtime-loaded inputs the import
//      graph cannot see (#4347): `dart_test.yaml`,
//      `test/flutter_test_config.dart` and anything under `assets/`.
//
// A changed test file selects itself; a changed non-test Dart file under
// `test/` (a helper, fake or fixture builder) selects every test that
// depends on it. A changed non-Dart file under `test/` (a JSON fixture, a
// golden) is read at run time, so no import names it: every Dart file
// under `test/` whose source mentions its file name counts as changed,
// and if none does the selector falls back to the full suite. Shell tests
// under `test/scripts/` are not Flutter tests and select nothing.
//
// Tests that don't transitively depend on any `lib/` file are part of
// the **always-run bucket** (test/lint/*, test/security/*, …) — they
// always appear in the output set regardless of the diff. Detected
// automatically: zero overlap between the test's transitive dependencies
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

import 'architecture_graph.dart' show parseDirectives;

const Set<String> _runAllSentinels = {
  'lib/main.dart',
  'lib/app/router.dart',
  // #4347 — shared test infrastructure.
  'dart_test.yaml',
  'test/flutter_test_config.dart',
};

const List<String> _runAllPrefixes = [
  'lib/l10n/',
  'lib/app/app_initializer',
  // #4347 — runtime-loaded inputs the import graph cannot see.
  'assets/',
];

const List<String> _runAllExactMatches = [
  'pubspec.yaml',
  'pubspec.lock',
  'analysis_options.yaml',
];

const String _libRoot = 'lib/';
const String _testRoot = 'test/';

/// What the selector decided, split so a caller can inspect either half
/// (#4177).
class TestSelection {
  const TestSelection({required this.affected, required this.alwaysRun});

  /// Tests whose transitive `lib/` dependencies include a changed file.
  final Set<String> affected;

  /// Tests with NO transitive `lib/` import — cross-cutting contracts
  /// that must run on every PR regardless of what changed.
  final Set<String> alwaysRun;
}

/// The whole decision for a list of changed paths (#4347).
class SelectorDecision {
  const SelectorDecision({
    required this.fullSuite,
    required this.reason,
    required this.tests,
  });

  /// Whether every test must run.
  final bool fullSuite;

  /// The changed path that forced [fullSuite], or null.
  final String? reason;

  /// The selected tests when not [fullSuite]: affected ∪ always-run ∪ the
  /// changed test files themselves.
  final Set<String> tests;
}

/// The dependency graph of every Dart file under `lib/` and `test/`, and
/// each test's transitive closure over it. Build once per process.
class DependencyGraph {
  DependencyGraph._(this.edges, this.tests);

  factory DependencyGraph.scan() {
    final edges = <String, Set<String>>{};
    _scanDartFiles(_libRoot, edges);
    _scanDartFiles(_testRoot, edges);
    // Only `_test.dart` files are emitted — helpers / fixtures in
    // `test/helpers/`, `test/mocks/`, etc. aren't directly runnable.
    final tests = edges.keys
        .where((k) => k.startsWith(_testRoot) && k.endsWith('_test.dart'))
        .toList()
      ..sort();
    return DependencyGraph._(edges, tests);
  }

  /// file -> files it imports or includes as a part (exports are not
  /// followed; see the header).
  final Map<String, Set<String>> edges;

  /// Every runnable test, sorted.
  final List<String> tests;

  final _closures = <String, Set<String>>{};

  /// Everything [test] transitively depends on, itself included.
  Set<String> closureOf(String test) =>
      _closures[test] ??= _transitiveClosure(test, edges);

  /// `lib/` files at least one test transitively depends on.
  Set<String> libFilesReachedByTests() => {
        for (final t in tests)
          ...closureOf(t).where((f) => f.startsWith(_libRoot)),
      };
}

/// Compute the selection for [libChanged], **in process**.
///
/// Extracted from [main] so `always_run_bucket_test` can call it
/// directly instead of spawning `dart run` (#4177). That subprocess
/// competes for the pub / build-hook lock with everything else a full
/// parallel `flutter test` has in flight, and went red twice for that
/// reason — a contract guard that fails for a reason unrelated to its
/// contract is worse than no guard, because the third red gets ignored.
///
/// [libChanged] may also hold changed Dart files under `test/` (helpers):
/// every test depending on one is affected (#4347).
TestSelection selectTests(Set<String> libChanged, {DependencyGraph? graph}) {
  final g = graph ?? DependencyGraph.scan();
  final affected = <String>{};
  final alwaysRun = <String>{};

  for (final t in g.tests) {
    final transitive = g.closureOf(t);
    final libDeps = transitive.where((f) => f.startsWith(_libRoot)).toSet();

    if (libDeps.isEmpty) {
      // Cross-cutting: no transitive lib import → always-run bucket.
      alwaysRun.add(t);
      // A changed helper it depends on still makes it affected — it runs
      // anyway, so recording that changes nothing but the bookkeeping.
      continue;
    }
    if (transitive.any(libChanged.contains)) {
      affected.add(t);
    }
  }
  return TestSelection(affected: affected, alwaysRun: alwaysRun);
}

/// The selector's full decision for [changed] repo-relative paths, in
/// process (#4347). [main] prints exactly this.
SelectorDecision selectForChangedPaths(
  Iterable<String> changed, {
  DependencyGraph? graph,
}) {
  for (final p in changed) {
    final fullSuite = _runAllSentinels.contains(p) ||
        _runAllExactMatches.contains(p) ||
        _runAllPrefixes.any(p.startsWith);
    if (fullSuite) {
      return SelectorDecision(fullSuite: true, reason: p, tests: const {});
    }
  }

  final dartChanged = changed
      .where((p) =>
          (p.startsWith(_libRoot) || p.startsWith(_testRoot)) &&
          p.endsWith('.dart'))
      .toSet();
  final g = graph ?? DependencyGraph.scan();

  // Runtime-loaded test data: the files that name it stand in for it.
  final data = changed.where((p) =>
      p.startsWith(_testRoot) &&
      !p.endsWith('.dart') &&
      !p.startsWith('${_testRoot}scripts/'));
  for (final p in data) {
    final name = p.substring(p.lastIndexOf('/') + 1);
    final readers = g.edges.keys
        .where((f) => f.startsWith(_testRoot))
        .where((f) => File(f).readAsStringSync().contains(name))
        .toSet();
    if (readers.isEmpty) {
      return SelectorDecision(fullSuite: true, reason: p, tests: const {});
    }
    dartChanged.addAll(readers);
  }

  final selection = selectTests(dartChanged, graph: g);
  final changedTests = dartChanged
      .where((p) => p.endsWith('_test.dart') && g.tests.contains(p))
      .toSet();
  return SelectorDecision(
    fullSuite: false,
    reason: null,
    tests: {...selection.affected, ...selection.alwaysRun, ...changedTests},
  );
}

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

  final decision = selectForChangedPaths(changed);
  if (decision.fullSuite) {
    stderr.writeln('test_selector: ${decision.reason} forces the full suite');
    _emitFullSuite();
    return;
  }
  for (final t in decision.tests.toList()..sort()) {
    stdout.writeln(t);
  }
}

/// Every non-empty line on stdin (#4347: previously only the first line
/// was read, so a multi-path list silently selected for one path).
List<String> _readStdinPaths() {
  final paths = <String>[];
  for (String? line = stdin.readLineSync();
      line != null;
      line = stdin.readLineSync()) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) paths.add(trimmed);
  }
  return paths;
}

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

void _scanDartFiles(String root, Map<String, Set<String>> edges) {
  _walk(root, (p) {
    if (!p.endsWith('.dart')) return;
    final content = File(p).readAsStringSync();
    edges[p] = extractDependencies(p, content);
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

// `part 'x.dart';` — a part is compiled into the declaring library.
final RegExp _partRe = RegExp(
  r'''^\s*part\s+["']([^"']+)["']\s*;''',
  multiLine: true,
);

/// The edges the selector follows from [file]: every branch of its
/// `import` directives and its `part` files (#4347). `export` directives
/// are skipped on purpose — see the header for the measured cost.
Set<String> extractDependencies(String file, String content) {
  final result = <String>{};
  for (final directive in parseDirectives(content)) {
    if (directive.isExport) continue;
    for (final uri in directive.uris) {
      final resolved = _resolve(file, uri);
      if (resolved != null) result.add(resolved);
    }
  }
  for (final m in _partRe.allMatches(content)) {
    final resolved = _resolve(file, m.group(1)!);
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

/// Transitive closure of dependencies starting from [start].
///
/// Iterative BFS — Dart import graphs can have cycles (test helpers
/// importing each other), so the visited set prevents infinite loops.
Set<String> _transitiveClosure(String start, Map<String, Set<String>> edges) {
  final visited = <String>{start};
  final queue = <String>[start];
  while (queue.isNotEmpty) {
    final current = queue.removeLast();
    final next = edges[current];
    if (next == null) continue;
    for (final n in next) {
      if (visited.add(n)) queue.add(n);
    }
  }
  return visited;
}
