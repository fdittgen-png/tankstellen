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
/// scan machinery (`lib/core/background/` and, since the #3131 move,
/// `lib/features/alerts/background/`) are exactly the code that
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
/// - The telemetry pipeline itself (`lib/core/logging/`,
///   `lib/core/telemetry/`): it cannot log through itself, and its
///   `debugPrint` fallbacks ARE the never-throws contract (#3981).
///
/// ## Scope (#3981, Epic #3952)
///
/// This scan used to walk three directories (`lib/app`,
/// `lib/core/background`, `lib/features/alerts/background`) and assert
/// zero. Outside them sat **61** more debugPrint-only catch bodies —
/// 19 in obd2, 15 in feature_management, 10 in trips, 4 in core/storage —
/// each an empty catch in the shipped build. It now walks all of `lib/`
/// with a decrease-only numeric baseline (CLAUDE.md), a parse-fidelity
/// self-check so a matcher drift cannot read as "clean" (#2348), and the
/// ADR 0021 fix: `log.error(e, st, layer: …, context: {…})`.
void main() {
  // `catch (e, st) {` and bare `on TimeoutException {` openers.
  final catchOpener = RegExp(
    r'(?:\bon\s+[\w<>.]+\s*(?:catch\s*\([^)]*\))?|\bcatch\s*\([^)]*\))\s*\{',
  );

  test('matcher fidelity: a debugPrint-only body is found, a logged one is '
      'not (#2348)', () {
    const fixture = '''
      // 1 — swallowed: nothing but a debugPrint
      try { a(); } catch (e, st) {
        debugPrint('x: \$e');
      }
      // 2 — swallowed, with a comment line the scanner must ignore
      try { b(); } on TimeoutException {
        // just a note
        debugPrint('timeout');
      }
      // logged, with a debugPrint alongside: NOT a hit
      try { c(); } catch (e, st) {
        log.error(e, st, layer: ErrorLayer.ui);
        debugPrint('also printed');
      }
      // empty: the OTHER ratchet's business
      try { d(); } catch (_) {}
      /// documented, not written — a `///` sample of the anti-pattern:
      /// } catch (_) { debugPrint('...sync failed'); }
    ''';
    var hits = 0;
    for (final m in catchOpener.allMatches(_stripDocComments(fixture))) {
      final body = _blockBody(fixture, m.end - 1);
      if (body != null && _isDebugPrintOnly(body)) hits++;
    }
    expect(hits, 2,
        reason: 'the scanner found $hits of 2 known sites — it would report '
            'a false green on real code (or count the documented sample as '
            'a real one, #4039)');
  });

  test('debugPrint-only catch handlers in lib/ do not grow (#3143, #3981)',
      () {
    // Allowlisted bodies, matched by substring of the debugPrint message.
    // ⚠️ May only shrink — see the docstring.
    const allowlistedBodyMarkers = <String>[
      '_runEntitySyncMerge', // owned by the in-flight #3077 branch
    ];
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart') ||
          entity.path.endsWith('.freezed.dart')) {
        continue;
      }
      final path = entity.path.replaceAll('\\', '/');
      if (_pipeline.any(path.startsWith)) continue;
      final src = _stripDocComments(entity.readAsStringSync());
      for (final m in catchOpener.allMatches(src)) {
        final body = _blockBody(src, m.end - 1);
        if (body == null) continue;
        if (!_isDebugPrintOnly(body)) continue;
        if (allowlistedBodyMarkers.any(body.contains)) continue;
        final line = src.substring(0, m.start).split('\n').length;
        offenders.add('$path:$line');
      }
    }
    expect(
      offenders.length,
      lessThanOrEqualTo(_baseline),
      reason: 'debugPrint-only catch handlers: ${offenders.length} '
          '(baseline $_baseline, decrease-only). They are invisible in '
          'release builds (debugPrint is no-opped in _bootstrap). Route the '
          'failure through `log.error(e, st, layer: ErrorLayer.<layer>, '
          'context: {...})` (ADR 0021; a debugPrint alongside is fine), or '
          '— for an expected benign race — a BreadcrumbCollector '
          'breadcrumb.\nOffending sites:\n${offenders.join('\n')}',
    );
  });
}

/// The telemetry pipeline cannot log through itself; its `debugPrint`
/// fallbacks are the never-throws contract, not swallowed failures.
const _pipeline = <String>['lib/core/logging/', 'lib/core/telemetry/'];

/// Baseline as of 2026-09-08 (#3981), all of lib/ minus [_pipeline].
/// Only ever decreases; target 0.
///
/// #4039 — reached it. All 61 handlers now route the cause through
/// `log.warn(msg, error: e, stack: st, layer: …)`, so the failure lands
/// in the trace ring instead of a release build's no-opped `debugPrint`.
/// The 61st was never a handler at all: it was the `///` code sample in
/// `SyncHelper`'s docstring showing the very boilerplate that helper
/// replaces, which [_stripDocComments] now excludes. A number this
/// ratchet must never leave.
const _baseline = 0;

/// Strips `///` doc-comment lines, replacing each with an empty line so
/// every offset the scan reports still maps to the real source line.
///
/// #4039 — a `///` block that DOCUMENTS the anti-pattern (SyncHelper's
/// docstring shows the `catch (_) { debugPrint(...); }` boilerplate the
/// helper exists to replace) was counted as an occurrence of it. Same
/// failure class as #2348: the scan measured something other than what
/// it claimed, and the last point of the ratchet's run to zero was a
/// code sample in a comment.
String _stripDocComments(String src) => src
    .split('\n')
    .map((l) => l.trimLeft().startsWith('///') ? '' : l)
    .join('\n');

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
