// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

/// Shared scanning helpers for the #3985 ratchets.
///
/// Every number these lints carry is MEASURED with the code below, never
/// copied from an audit — the #2348 / #3977 lesson: a baseline taken
/// from a different definition than the one the scanner uses is a
/// baseline that fails for reasons nobody can reproduce. Each lint's
/// docstring states its definition BEFORE its baseline, and each carries
/// a fidelity self-check against synthetic source, so a scanner that
/// silently stops matching cannot pass as an improvement.

/// Every non-generated Dart file under `lib/`.
Iterable<File> libFiles() sync* {
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart') ||
        entity.path.endsWith('.freezed.dart')) {
      continue;
    }
    yield entity;
  }
}

String posixPath(File f) => f.path.replaceAll(r'\', '/');

/// The body of every `Widget build(BuildContext …)` in [src], brace-matched.
///
/// Brace matching rather than a regex: a build method is nested widget
/// trees, and any pattern that stops at the first `}` reads a fraction
/// of the body and reports a clean file.
Iterable<(int, String)> buildBodies(String src) sync* {
  for (final m in RegExp(r'Widget build\(BuildContext[^)]*\)\s*\{')
      .allMatches(src)) {
    var i = m.end;
    var depth = 1;
    while (i < src.length && depth > 0) {
      if (src[i] == '{') depth++;
      if (src[i] == '}') depth--;
      i++;
    }
    yield (m.end, src.substring(m.end, i));
  }
}

/// 1-based line number of [offset] in [src].
int lineAt(String src, int offset) =>
    '\n'.allMatches(src.substring(0, offset)).length + 1;

/// Whether [src]'s first top-level declaration carries a `///` doc.
///
/// Returns true for a file with no top-level declaration (a barrel, a
/// `part` file): there is nothing for a doc to be about.
bool hasHeaderDoc(String src) {
  final lines = src.split('\n');
  final declaration = RegExp(
    r'^(?:abstract\s+|sealed\s+|base\s+|final\s+|interface\s+)?'
    r'(?:class|enum|mixin|extension|typedef)\s'
    r'|^void main\('
    r'|^(?:const|final)\s'
    r'|^[A-Z][\w<>,\s?]*\s+\w+\s*\(',
  );
  var first = -1;
  for (var i = 0; i < lines.length; i++) {
    if (declaration.hasMatch(lines[i])) {
      first = i;
      break;
    }
  }
  if (first < 0) return true;
  // Walk back over annotations and blank lines to the line that would
  // carry the doc.
  var j = first - 1;
  while (j >= 0 && (lines[j].trimLeft().startsWith('@') ||
      lines[j].trim().isEmpty)) {
    if (lines[j].trim().isEmpty && j < first - 1) break;
    j--;
  }
  return j >= 0 && lines[j].trimLeft().startsWith('///');
}

/// `(class name, constructor parameter count)` for every widget in [src].
///
/// A "widget" is a class extending one of the four Flutter/Riverpod
/// widget bases; `super.key` is not counted, since it is not state the
/// caller threads through.
Iterable<({String name, int params})> widgetArities(String src) sync* {
  final base = RegExp(
    r'class\s+(\w+)\s+extends\s+'
    r'(?:StatelessWidget|StatefulWidget|ConsumerWidget|ConsumerStatefulWidget)'
    r'\b',
  );
  for (final m in base.allMatches(src)) {
    final name = m.group(1)!;
    final ctor = RegExp('(?:const\\s+)?$name\\(\\s*\\{')
        .firstMatch(src.substring(m.end));
    if (ctor == null) continue;
    var i = m.end + ctor.end;
    var depth = 1;
    final buffer = StringBuffer();
    while (i < src.length && depth > 0) {
      if (src[i] == '{') depth++;
      if (src[i] == '}') depth--;
      if (depth > 0) buffer.write(src[i]);
      i++;
    }
    final params = RegExp(r'(?:required\s+)?this\.\w+'
            r'|required\s+[\w<>,\s?]+\s+\w+')
        .allMatches(buffer.toString())
        .length;
    yield (name: name, params: params);
  }
}
