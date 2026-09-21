// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

// Architecture inventory (#4346, parent #4155).
//
// One command prints the two dependency graphs of lib/ side by side, and
// the Dart libraries that share private state across `part` files:
//
//   dart run tool/architecture_graph.dart
//
// 1. **Reach-in graph (contract compliance).** Cross-feature directives
//    that bypass the target feature's `api.dart`, plus the target-zero
//    core → feature and feature → app-shell directives. This is exactly
//    what test/lint/feature_boundary_test.dart has always ratcheted, and
//    that test now reads its numbers from this scanner.
// 2. **Feature dependency graph (barrel-aware).** EVERY cross-feature
//    directive, api.dart included, with export chains followed. A barrel
//    import is still a dependency: replacing a reach-in with the barrel
//    lowers graph 1 without removing the edge from graph 2. Strongly
//    connected components are reported separately from direct mutual
//    pairs, once for the feature graph and once for the module graph
//    (features + core + app shell). The shell → feature direction is the
//    composition root's job and is reported, never flagged.
// 3. **Shared-state libraries.** Each library with hand-written parts:
//    its root and parts, their lines, the mixins declared in the parts
//    (which share the library's private scope), the classes that mix
//    them in (the state owner), and the private identifiers used in more
//    than one of the library's files. Lines stay descriptive; the mixins,
//    owners and shared private names are the ownership signal.
//
// Scope: hand-written Dart under lib/ — no `.g.dart`, `.freezed.dart` or
// lib/l10n/ output. Root/part aggregation and line counting are the ones
// test/lint/file_length_test.dart enforces its library budget with; that
// test imports them from here.
//
// Pure functions over an in-memory `path -> source` map, so the tests in
// test/tool/architecture_graph_test.dart run on synthetic fixtures. Only
// [ArchitectureInventory.scan] touches the disk. Read-only: this tool
// never writes a file.

import 'dart:convert';
import 'dart:io';

void main() {
  stdout.write(ArchitectureInventory.scan().renderReport());
}

// ── Scope and line counting (shared with file_length_test) ──────────────

/// Whether [path] is hand-written Dart in the scanned scope: a `.dart`
/// file that is not build_runner output (`.g.dart`, `.freezed.dart`) and
/// not `flutter gen-l10n` output under lib/l10n/. Also applied to part
/// URIs, which is how generated parts are left out of a library.
bool isHandwrittenDart(String path) {
  if (!path.endsWith('.dart')) return false;
  if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) {
    return false;
  }
  if (path.startsWith('lib/l10n/')) return false;
  return true;
}

/// Lines of a file minus the 3-line MIT SPDX header (#2053), so the
/// 400-line norm measures content rather than boilerplate. [rawLines] is
/// what `File.readAsLinesSync` returns.
int effectiveLines(List<String> rawLines) {
  final hasHeader = rawLines.length >= 2 &&
      rawLines[0].contains('Copyright (c) 2026 Florian DITTGEN') &&
      rawLines[1].contains('SPDX-License-Identifier');
  return rawLines.length - (hasHeader ? 3 : 0);
}

/// Splits [source] into lines the way `File.readAsLinesSync` does.
List<String> linesOf(String source) => const LineSplitter().convert(source);

/// Collapses `.` / `..` / empty segments of a `/`-separated path.
String normalizePath(String path) {
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

final _partDirective = RegExp('^\\s*part\\s+[\'"]([^\'"]+)[\'"]\\s*;');

/// The hand-written `part` files [source] declares, resolved against the
/// declaring file at [path]. Generated parts are skipped.
List<String> handwrittenPartPaths(String path, String source) {
  final slash = path.lastIndexOf('/');
  final dir = slash < 0 ? '' : path.substring(0, slash);
  return [
    for (final line in linesOf(source))
      if (_partDirective.firstMatch(line)?.group(1) case final uri?)
        if (isHandwrittenDart(uri)) normalizePath('$dir/$uri'),
  ];
}

// ── Directives ──────────────────────────────────────────────────────────

/// One `import` or `export` directive. A conditional directive
/// (`import 'a.dart' if (dart.library.io) 'b.dart';`) carries every
/// branch in [uris]: each is a real compile-time dependency.
class Directive {
  const Directive(this.kind, this.uris);

  /// `import` or `export`.
  final String kind;
  final List<String> uris;

  bool get isExport => kind == 'export';
}

final _directiveStatement =
    RegExp(r'''^[ \t]*(import|export)\s+(['"][^;]*);''', multiLine: true);
final _condition = RegExp(r'\bif\s*\([^)]*\)');
final _stringLiteral = RegExp(r'''['"]([^'"]+)['"]''');

/// Every import/export directive in [source], multi-line and conditional
/// forms included.
List<Directive> parseDirectives(String source) => [
      for (final m in _directiveStatement.allMatches(source))
        Directive(m.group(1)!, [
          for (final l in _stringLiteral
              .allMatches(m.group(2)!.replaceAll(_condition, ' ')))
            l.group(1)!,
        ]),
    ];

/// Resolves [uri] from the file at [fromPath] to a repo-relative path;
/// null for SDK and third-party URIs.
String? resolveUri(String fromPath, String uri) {
  const self = 'package:tankstellen/';
  if (uri.startsWith(self)) return 'lib/${uri.substring(self.length)}';
  if (uri.startsWith('dart:') || uri.startsWith('package:')) return null;
  final dir = fromPath.substring(0, fromPath.lastIndexOf('/'));
  return normalizePath('$dir/$uri');
}

/// `lib/features/<name>/...` → `<name>`, else null.
String? featureOf(String path) =>
    RegExp(r'^lib/features/([^/]+)/').firstMatch('$path/')?.group(1);

/// The module a lib/ path belongs to: its feature name, or `<core>`,
/// `<l10n>`, or `<shell>` (lib/app/ and lib/main.dart — the composition
/// root).
String moduleOf(String path) {
  final feature = featureOf(path);
  if (feature != null) return feature;
  if (path.startsWith('lib/core/')) return '<core>';
  if (path.startsWith('lib/l10n/')) return '<l10n>';
  return '<shell>';
}

// ── Graph helpers ───────────────────────────────────────────────────────

/// `a <-> b` for every pair with an edge in both directions, sorted.
List<String> mutualPairsOf(Iterable<String> directedPairs) {
  final set = directedPairs.toSet();
  final mutual = <String>{};
  for (final key in set) {
    final parts = key.split(' -> ');
    if (set.contains('${parts[1]} -> ${parts[0]}')) {
      final pair = [parts[0], parts[1]]..sort();
      mutual.add('${pair[0]} <-> ${pair[1]}');
    }
  }
  return mutual.toList()..sort();
}

/// Strongly connected components with more than one member (Tarjan), each
/// sorted, largest first then alphabetical. A cycle through three modules
/// is ONE component here while it is zero mutual pairs.
List<List<String>> stronglyConnectedComponents(Iterable<String> directedPairs) {
  final adjacency = <String, Set<String>>{};
  for (final key in directedPairs) {
    final parts = key.split(' -> ');
    adjacency.putIfAbsent(parts[0], () => <String>{}).add(parts[1]);
    adjacency.putIfAbsent(parts[1], () => <String>{});
  }
  var index = 0;
  final indices = <String, int>{};
  final lowLinks = <String, int>{};
  final stack = <String>[];
  final onStack = <String>{};
  final components = <List<String>>[];

  void connect(String node) {
    indices[node] = index;
    lowLinks[node] = index;
    index++;
    stack.add(node);
    onStack.add(node);
    for (final next in adjacency[node]!.toList()..sort()) {
      if (!indices.containsKey(next)) {
        connect(next);
        lowLinks[node] = [lowLinks[node]!, lowLinks[next]!].reduce(
          (a, b) => a < b ? a : b,
        );
      } else if (onStack.contains(next)) {
        lowLinks[node] = [lowLinks[node]!, indices[next]!].reduce(
          (a, b) => a < b ? a : b,
        );
      }
    }
    if (lowLinks[node] == indices[node]) {
      final component = <String>[];
      String member;
      do {
        member = stack.removeLast();
        onStack.remove(member);
        component.add(member);
      } while (member != node);
      if (component.length > 1) components.add(component..sort());
    }
  }

  for (final node in adjacency.keys.toList()..sort()) {
    if (!indices.containsKey(node)) connect(node);
  }
  return components
    ..sort((a, b) => a.length != b.length
        ? b.length.compareTo(a.length)
        : a.join(',').compareTo(b.join(',')));
}

void _bump(Map<String, int> map, String key) =>
    map.update(key, (v) => v + 1, ifAbsent: () => 1);

int _sum(Map<String, int> map) => map.values.fold(0, (a, b) => a + b);

// ── Shared-state libraries ──────────────────────────────────────────────

/// A library whose declaring file has hand-written parts.
class SharedStateLibrary {
  const SharedStateLibrary({
    required this.root,
    required this.parts,
    required this.lines,
    required this.partMixins,
    required this.owners,
    required this.crossFilePrivates,
  });

  /// The declaring file.
  final String root;

  /// Its hand-written parts that exist (generated parts excluded).
  final List<String> parts;

  /// Effective lines across root + [parts] (the file_length_test count).
  final int lines;

  /// Mixins declared in the parts: they reach the library's private
  /// members, so each is a slice of one shared state, not a collaborator.
  final List<String> partMixins;

  /// Classes in the library that mix in any of [partMixins] — the owner
  /// of that shared state. Empty when nothing names one.
  final List<String> owners;

  /// Private identifiers (`_name`) that occur in more than one file of
  /// the library, comments and plain string literals ignored.
  final List<String> crossFilePrivates;
}

final _mixinDeclaration = RegExp(
  r'^(?:base\s+)?mixin\s+([A-Za-z_]\w*)',
  multiLine: true,
);
final _classWith = RegExp(
  r'\bclass\s+([A-Za-z_]\w*)[^{;]*?\bwith\b([^{;]*)\{',
);
final _lineComment = RegExp(r'//[^\n]*');
final _blockComment = RegExp(r'/\*[\s\S]*?\*/');
final _plainString = RegExp('\'[^\'\\n\$]*\'|"[^"\\n\$]*"');
final _privateIdentifier = RegExp(r'(?<![\w$])_[A-Za-z]\w*');

/// [source] without comments, so prose never reads as a declaration.
String _code(String source) =>
    source.replaceAll(_blockComment, ' ').replaceAll(_lineComment, ' ');

Set<String> _privateIdentifiersIn(String code) => _privateIdentifier
    .allMatches(code.replaceAll(_plainString, "''"))
    .map((m) => m.group(0)!)
    .toSet();

/// The libraries in [sources] that declare hand-written parts, largest
/// shared private surface first.
List<SharedStateLibrary> sharedStateLibraries(Map<String, String> sources) {
  final declared = <String, List<String>>{
    for (final MapEntry(key: path, value: source) in sources.entries)
      if (handwrittenPartPaths(path, source) case final parts
          when parts.isNotEmpty)
        path: parts,
  };
  final allParts = declared.values.expand((p) => p).toSet();
  declared.removeWhere((path, _) => allParts.contains(path));

  final libraries = <SharedStateLibrary>[];
  for (final MapEntry(key: root, value: declaredParts) in declared.entries) {
    final parts = [
      for (final p in declaredParts)
        if (sources.containsKey(p)) p,
    ];
    final files = [root, ...parts];
    final code = {for (final f in files) f: _code(sources[f]!)};
    final mixins = <String>[
      for (final p in parts)
        for (final m in _mixinDeclaration.allMatches(code[p]!)) m.group(1)!,
    ]..sort();
    final owners = <String>{
      for (final f in files)
        for (final m in _classWith.allMatches(code[f]!))
          if (RegExp(r'[A-Za-z_]\w*')
              .allMatches(m.group(2)!)
              .any((w) => mixins.contains(w.group(0))))
            m.group(1)!,
    }.toList()
      ..sort();
    final seenIn = <String, int>{};
    for (final f in files) {
      for (final id in _privateIdentifiersIn(code[f]!)) {
        _bump(seenIn, id);
      }
    }
    libraries.add(SharedStateLibrary(
      root: root,
      parts: parts,
      lines: files.fold(
        0,
        (sum, f) => sum + effectiveLines(linesOf(sources[f]!)),
      ),
      partMixins: mixins,
      owners: owners,
      crossFilePrivates: [
        for (final MapEntry(key: id, value: n) in seenIn.entries)
          if (n > 1) id,
      ]..sort(),
    ));
  }
  return libraries
    ..sort((a, b) {
      final byShared =
          b.crossFilePrivates.length.compareTo(a.crossFilePrivates.length);
      return byShared != 0 ? byShared : a.root.compareTo(b.root);
    });
}

/// Existing implementation owners for known shared-state responsibilities
/// (#4339 S2/S13). A library missing here has no owner yet: it needs a
/// bounded follow-up before the architecture work is called complete.
const implementationOwners = <String, String>{
  'lib/features/obd2/data/session/trip_recording_controller.dart':
      '#4162 (single state owner), #4344',
  'lib/features/trips/providers/trip_recording_provider.dart': '#4344',
};

// ── The inventory ───────────────────────────────────────────────────────

/// Both dependency graphs and the shared-state libraries of one source
/// tree. Build it with [ArchitectureInventory.fromSources] (fixtures) or
/// [ArchitectureInventory.scan] (the repository).
class ArchitectureInventory {
  ArchitectureInventory._(this.fileCount);

  /// Scans the hand-written Dart under `<root>/lib`.
  factory ArchitectureInventory.scan({String root = '.'}) {
    final sources = <String, String>{};
    final libDir = Directory('$root/lib');
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      var path = entity.path.replaceAll(r'\', '/');
      path = path.substring(path.indexOf('lib/', root.length));
      if (!isHandwrittenDart(path)) continue;
      sources[path] = entity.readAsStringSync();
    }
    return ArchitectureInventory.fromSources(sources);
  }

  /// Builds the inventory from repo-relative `lib/...` paths to sources.
  factory ArchitectureInventory.fromSources(Map<String, String> sources) {
    final inventory = ArchitectureInventory._(sources.length);
    final directives = {
      for (final MapEntry(key: path, value: source) in sources.entries)
        path: parseDirectives(source),
    };

    // Files made visible by importing [file]: itself plus every file its
    // export chain re-exports.
    final closures = <String, Set<String>>{};
    Set<String> exportClosure(String file) {
      final cached = closures[file];
      if (cached != null) return cached;
      final visible = <String>{file};
      closures[file] = visible; // an export cycle terminates here
      for (final d in directives[file] ?? const <Directive>[]) {
        if (!d.isExport) continue;
        for (final uri in d.uris) {
          final target = resolveUri(file, uri);
          if (target != null) visible.addAll(exportClosure(target));
        }
      }
      return visible;
    }

    for (final MapEntry(key: path, value: fileDirectives)
        in directives.entries) {
      final fromModule = moduleOf(path);
      final fromFeature = featureOf(path);
      final isCore = path.startsWith('lib/core/');
      for (final directive in fileDirectives) {
        for (final uri in directive.uris) {
          final target = resolveUri(path, uri);
          if (target == null || !target.startsWith('lib/')) continue;
          final toModule = moduleOf(target);
          final toFeature = featureOf(target);

          // Graph 2 — every edge, barrels included.
          if (toModule != fromModule) {
            _bump(inventory.moduleEdges, '$fromModule -> $toModule');
            if (fromFeature != null && toFeature != null) {
              _bump(inventory.featureEdges, '$fromFeature -> $toFeature');
            }
          }
          if (fromFeature != null) {
            for (final visible in exportClosure(target)) {
              final visibleFeature = featureOf(visible);
              if (visibleFeature != null && visibleFeature != fromFeature) {
                inventory.exportExpandedFeaturePairs
                    .add('$fromFeature -> $visibleFeature');
              }
            }
          }

          // Graph 1 — the reach-in rules feature_boundary_test ratchets.
          if (fromFeature == null && !isCore) continue; // shell: composes
          if (toFeature == null) {
            if (fromFeature != null &&
                !target.startsWith('lib/core/') &&
                !target.startsWith('lib/l10n/')) {
              _bump(inventory.shellImportsByFeature, fromFeature);
              inventory.reachInLines.add('$path -> $target');
            }
            continue;
          }
          if (fromFeature == toFeature) continue;
          if (isCore) {
            _bump(inventory.coreImportsByFeature, toFeature);
            inventory.reachInLines.add('$path -> $target');
          } else if (target != 'lib/features/$toFeature/api.dart') {
            _bump(inventory.reachInPairs, '$fromFeature -> $toFeature');
            inventory.reachInLines.add('$path -> $target');
          }
        }
      }
    }
    inventory.libraries.addAll(sharedStateLibraries(sources));
    return inventory;
  }

  /// Hand-written files scanned.
  final int fileCount;

  // Graph 1 — contract compliance.

  /// `a -> b` → cross-feature directives that bypass `b`'s api.dart.
  final reachInPairs = <String, int>{};

  /// Imported feature → lib/core/ directives reaching it (target 0).
  final coreImportsByFeature = <String, int>{};

  /// Importing feature → its directives into the app shell (target 0).
  final shellImportsByFeature = <String, int>{};

  /// `file -> target` for every graph-1 violation.
  final reachInLines = <String>[];

  // Graph 2 — actual dependencies.

  /// `a -> b` → every feature → feature directive, api.dart included.
  final featureEdges = <String, int>{};

  /// `a -> b` → directives between modules (features, `<core>`,
  /// `<shell>`, `<l10n>`).
  final moduleEdges = <String, int>{};

  /// `a -> b` for every feature whose files an import of `a` makes
  /// visible once export chains are followed.
  final exportExpandedFeaturePairs = <String>{};

  /// Libraries with hand-written parts.
  final libraries = <SharedStateLibrary>[];

  List<String> get reachInMutualPairs => mutualPairsOf(reachInPairs.keys);
  List<String> get featureMutualPairs => mutualPairsOf(featureEdges.keys);
  List<List<String>> get featureSccs =>
      stronglyConnectedComponents(featureEdges.keys);
  List<List<String>> get moduleSccs =>
      stronglyConnectedComponents(moduleEdges.keys);

  /// The markdown report `dart run tool/architecture_graph.dart` prints.
  String renderReport() {
    final exportOnly = exportExpandedFeaturePairs
        .difference(featureEdges.keys.toSet())
        .toList()
      ..sort();
    final shellToFeature = {
      for (final e in moduleEdges.entries)
        if (e.key.startsWith('<shell> -> ') && !e.key.endsWith('>')) e.key:
          e.value,
    };
    final b = StringBuffer()
      ..writeln('# Architecture graph (#4346)')
      ..writeln()
      ..writeln('$fileCount hand-written Dart files under lib/ '
          '(.g.dart, .freezed.dart and lib/l10n/ output excluded). Counts '
          'are directives and direct pairs, not runtime calls.')
      ..writeln()
      ..writeln('## Graph 1 — contract-compliance reach-ins')
      ..writeln()
      ..writeln('Ratcheted by test/lint/feature_boundary_test.dart.')
      ..writeln()
      ..writeln('| Scope | Count |')
      ..writeln('|---|---:|')
      ..writeln('| Cross-feature directives bypassing the target api.dart '
          '| ${_sum(reachInPairs)} |')
      ..writeln('| Directed feature pairs for those directives '
          '| ${reachInPairs.length} |')
      ..writeln('| Bidirectional pairs in that restricted graph '
          '| ${reachInMutualPairs.length} |')
      ..writeln('| core → feature directives '
          '| ${_sum(coreImportsByFeature)} |')
      ..writeln('| feature → app-shell directives '
          '| ${_sum(shellImportsByFeature)} |')
      ..writeln()
      ..writeln('## Graph 2 — feature dependency graph (barrel-aware)')
      ..writeln()
      ..writeln('| Scope | Count |')
      ..writeln('|---|---:|')
      ..writeln('| All cross-feature directives including api.dart '
          '| ${_sum(featureEdges)} |')
      ..writeln('| Directed pairs including api.dart '
          '| ${featureEdges.length} |')
      ..writeln('| Bidirectional pairs including api.dart '
          '| ${featureMutualPairs.length} |')
      ..writeln('| Directed pairs once export chains are followed '
          '| ${exportExpandedFeaturePairs.length} |')
      ..writeln('| … of which visible only through an export chain '
          '| ${exportOnly.length} |')
      ..writeln('| shell → feature directives (composition root, not a '
          'violation) | ${_sum(shellToFeature)} |')
      ..writeln()
      ..writeln('### Strongly connected components — feature graph')
      ..writeln();
    _writeComponents(b, featureSccs);
    b
      ..writeln('### Strongly connected components — module graph '
          '(features + core + app shell)')
      ..writeln();
    _writeComponents(b, moduleSccs);
    b
      ..writeln('### Direct mutual pairs including api.dart')
      ..writeln();
    for (final pair in featureMutualPairs) {
      b.writeln('- $pair');
    }
    if (featureMutualPairs.isEmpty) b.writeln('- none');
    b
      ..writeln()
      ..writeln('## Shared-state libraries (root + hand-written parts)')
      ..writeln()
      ..writeln('Lines are descriptive. Part mixins share the library\'s '
          'private scope; cross-file private identifiers are the state that '
          'scope actually shares.')
      ..writeln()
      ..writeln('| Library | Files | Lines | Part mixins | State owner '
          '| Cross-file private identifiers | Implementation owner |')
      ..writeln('|---|---:|---:|---:|---|---:|---|');
    for (final lib in libraries) {
      b.writeln('| ${lib.root} | ${lib.parts.length + 1} | ${lib.lines} '
          '| ${lib.partMixins.length} '
          '| ${lib.owners.isEmpty ? '—' : lib.owners.join(', ')} '
          '| ${lib.crossFilePrivates.length} '
          '| ${implementationOwners[lib.root] ?? 'unassigned'} |');
    }
    return b.toString();
  }

  static void _writeComponents(StringBuffer b, List<List<String>> sccs) {
    if (sccs.isEmpty) b.writeln('- none');
    for (final (i, scc) in sccs.indexed) {
      b.writeln('${i + 1}. (${scc.length}) ${scc.join(', ')}');
    }
    b.writeln();
  }
}
