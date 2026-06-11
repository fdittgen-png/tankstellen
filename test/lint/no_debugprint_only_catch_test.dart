// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan regression test (#3143): no catch block in the startup /
/// background layers may have `debugPrint` as its ONLY statement.
///
/// ## Why
/// `AppInitializer._bootstrap()` no-ops `debugPrint` in release builds,
/// so a catch handler whose only action is `debugPrint(...)` is a
/// SILENT swallow in production — the failure never reaches the
/// `errorLogger` / TraceRecorder / Sentry pipeline and is invisible to
/// field triage. The startup phases (`lib/app/`) and the background
/// scan machinery (`lib/core/background/`) are exactly the code that
/// runs when nobody is watching, so they get a hard gate.
///
/// ## What is forbidden
/// A `catch (...) { ... }` or `on Type { ... }` block (in the scanned
/// directories) whose body contains nothing but `debugPrint(...)`
/// statement(s) and comments.
///
/// ## What is allowed
/// - A body that ALSO calls `errorLogger.log(...)` (or anything else) —
///   keeping a `debugPrint` alongside the structured log is fine.
/// - A breadcrumb-only body for expected, benign races (the breadcrumb
///   ring is drained into every error trace, so it is release-visible).
/// - Generated files (`.g.dart`, `.freezed.dart`).
/// - The catch inside `AppInitializer._runEntitySyncMerge` — that
///   method is owned by the in-flight #3077 follow-up branch
///   (file-ownership boundary); it is allowlisted below until that
///   branch lands and the entry can be removed. The allowlist may only
///   ever SHRINK.
void main() {
  test(
      'no debugPrint-only catch handlers in lib/app + lib/core/background '
      '(#3143)', () {
    // Allowlisted bodies, matched by substring of the debugPrint message.
    // ⚠️ May only shrink — see the docstring.
    const allowlistedBodyMarkers = <String>[
      '_runEntitySyncMerge', // owned by the in-flight #3077 branch
    ];

    final offenders = <String>[];
    // `catch (e, st) {` and bare `on TimeoutException {` openers.
    final catchOpener = RegExp(
      r'(?:\bon\s+[\w<>.]+\s*(?:catch\s*\([^)]*\))?|\bcatch\s*\([^)]*\))\s*\{',
    );

    for (final dir in ['lib/app', 'lib/core/background']) {
      for (final entity in Directory(dir).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('.g.dart') ||
            entity.path.endsWith('.freezed.dart')) {
          continue;
        }
        final src = entity.readAsStringSync();
        for (final m in catchOpener.allMatches(src)) {
          final body = _blockBody(src, m.end - 1);
          if (body == null) continue;
          if (!_isDebugPrintOnly(body)) continue;
          if (allowlistedBodyMarkers.any(body.contains)) continue;
          final line = src.substring(0, m.start).split('\n').length;
          final path = entity.path.replaceAll('\\', '/');
          offenders.add('$path:$line');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'debugPrint-only catch handlers are invisible in release '
          'builds (debugPrint is no-opped in _bootstrap). Route the '
          'failure through `errorLogger.log(ErrorLayer.<layer>, e, st, '
          'context: {...})` (a debugPrint alongside is fine), or — for an '
          'expected benign race — a BreadcrumbCollector breadcrumb.\n'
          'Offending sites:\n${offenders.join('\n')}',
    );
  });
}

/// Returns the text between the brace at [openBraceIdx] and its matching
/// close brace, or null when unbalanced.
String? _blockBody(String src, int openBraceIdx) {
  var depth = 0;
  for (var i = openBraceIdx; i < src.length; i++) {
    final ch = src[i];
    if (ch == '{') depth++;
    if (ch == '}') {
      depth--;
      if (depth == 0) return src.substring(openBraceIdx + 1, i);
    }
  }
  return null;
}

/// True when [body], stripped of comments and blank lines, consists of
/// nothing but `debugPrint(...)` statement(s).
bool _isDebugPrintOnly(String body) {
  final withoutComments = body
      .split('\n')
      .where((l) {
        final t = l.trim();
        return t.isNotEmpty && !t.startsWith('//');
      })
      .join('\n')
      .trim();
  if (withoutComments.isEmpty) return false;
  if (!withoutComments.contains('debugPrint')) return false;
  final residue = withoutComments
      .replaceAll(RegExp(r'debugPrint\s*\([^;]*\)\s*;', dotAll: true), '')
      .trim();
  return residue.isEmpty;
}
