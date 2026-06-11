// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan guard (#3159): inside widget code in `lib/`, a `ref.read` /
/// `ref.invalidate` / `ref.refresh` must not follow an `await` in the same
/// async method body unless a `mounted` check sits between them.
///
/// **Why:** Riverpod 3 throws a `StateError` ("Using ref when a widget is
/// about to or has been unmounted") when a `WidgetRef` is touched after its
/// element unmounted. `use_build_context_synchronously` does NOT cover
/// `ref`, so the analyzer is silent on these latent crashes. The two
/// sanctioned patterns (both used across the codebase) are:
///
/// 1. **Capture before the await** — read the notifier/service into a local
///    BEFORE the first `await` (see `country_switch_listener.dart` #1808 and
///    `obd2_adapter_picker.dart` errorlog_30); the captured object stays
///    valid for keepAlive providers, so the action still completes on the
///    unmounted path.
/// 2. **Mounted-guard** — `if (!mounted) return;` (ConsumerState) or
///    `if (!context.mounted) return;` (ConsumerWidget helpers) before any
///    post-await ref use (see `price_history_section.dart` #2298).
///
/// **Heuristic mechanics (line-based, tuned to zero false positives):**
/// - Only files mentioning `WidgetRef` / `ConsumerState` are scanned —
///   provider-`Ref` lifecycles are a different concern; `lib/**/providers/`
///   and `lib/**/application/` are excluded for the same reason.
/// - Inside each `) async {` body, an `await` arms a "dirty" flag once its
///   statement completes (so arguments evaluated before the await itself,
///   e.g. `await ref.read(x).save(...)` spanning lines, don't trip it).
/// - Any line containing `mounted` clears the flag (lenient by design: the
///   scan is a backstop, not a proof engine).
/// - A `ref.read|invalidate|refresh` on a dirty line is a violation.
///
/// **Reviewed false positives:** the scan is path-insensitive, so a method
/// whose only `await` lives in an early-returning branch can flag a
/// perfectly synchronous `ref.read`. Each entry below was manually verified
/// (#3159 triage). The set may only SHRINK — if you touch a listed file and
/// the scan flags it, re-verify by reading the method; never add an entry
/// without that review.
void main() {
  // Path-insensitive control-flow false positives, manually verified in the
  // #3159 sweep: in every case the `await` that arms the scan sits in a
  // branch that `return`s before the flagged `ref` use executes.
  const reviewedFalsePositives = <String>{
    // `_start`: the awaits live in the GPS-only branch which returns; the
    // flagged `ref.read(tripRecordingProvider)` runs await-free.
    'lib/features/consumption/presentation/widgets/trajets_record_fab.dart',
    // `submit`: `await _routeToGitHub(...)` is followed by `return;`; the
    // flagged reads execute on the no-await path. The `finally` use is
    // `context.mounted`-guarded.
    'lib/features/report/presentation/screens/report_submit_handler.dart',
  };

  final refUse = RegExp(r'\bref\s*\.\s*(read|invalidate|refresh)\b');
  final awaitRe = RegExp(r'\bawait\b');
  final mountedRe = RegExp(r'\bmounted\b');
  final asyncOpen = RegExp(r'\)\s*async\s*\{');
  final lineComment = RegExp(r'//.*');

  int braces(String s) =>
      '{'.allMatches(s).length - '}'.allMatches(s).length;
  int parens(String s) =>
      '('.allMatches(s).length - ')'.allMatches(s).length;

  bool isScanned(String path) {
    if (!path.endsWith('.dart')) return false;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) {
      return false;
    }
    // Provider/application layers use Riverpod's `Ref`, whose lifecycle is
    // not tied to a widget element — out of scope for this guard.
    if (path.contains('/providers/') || path.contains('/application/')) {
      return false;
    }
    return true;
  }

  List<String> scanFile(String path, String src) {
    final violations = <String>[];
    final lines = src.split('\n');
    var i = 0;
    while (i < lines.length) {
      if (!asyncOpen.hasMatch(lines[i])) {
        i++;
        continue;
      }
      var depth = braces(lines[i]);
      var j = i + 1;
      var dirty = false;
      var pending = false;
      var parenDepth = 0;
      while (j < lines.length && depth > 0) {
        final code = lines[j].replaceAll(lineComment, '');
        if (mountedRe.hasMatch(code)) {
          // A mounted check (or `if (mounted) ...` on the same line as the
          // ref use) re-validates the element for everything below it.
          dirty = false;
          pending = false;
        } else if (dirty && refUse.hasMatch(code)) {
          violations.add('$path:${j + 1}: ${code.trim()}');
        }
        parenDepth += parens(code);
        if (awaitRe.hasMatch(code)) pending = true;
        if (pending && parenDepth <= 0) {
          // The awaited statement has closed: from here on, ref is suspect.
          dirty = true;
          pending = false;
        }
        depth += braces(code);
        j++;
      }
      i = j;
    }
    return violations;
  }

  test(
      'lib/ widget code never uses ref.read/invalidate/refresh after an '
      'await without a mounted check between them (#3159)', () {
    final violations = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => isScanned(f.path.replaceAll(r'\', '/')));
    for (final file in files) {
      final path = file.path.replaceAll(r'\', '/');
      if (reviewedFalsePositives.contains(path)) continue;
      final src = file.readAsStringSync();
      // Only widget-side code holds a WidgetRef.
      if (!src.contains('WidgetRef') && !src.contains('ConsumerState')) {
        continue;
      }
      violations.addAll(scanFile(path, src));
    }

    expect(
      violations,
      isEmpty,
      reason: 'WidgetRef used after an await without a mounted check — '
          'Riverpod 3 throws a StateError if the element unmounted during '
          'the await (#3159). Either capture the notifier/service in a '
          'local BEFORE the first await, or guard with '
          '`if (!mounted) return;` / `if (!context.mounted) return;`.\n'
          'Violations:\n${violations.join('\n')}',
    );
  });

  test('reviewed-false-positive entries still exist and still scan dirty',
      () {
    // Keeps the allowlist honest: if a listed file was refactored so the
    // scan no longer flags it (or the file moved), the entry must be
    // removed rather than rot.
    for (final path in reviewedFalsePositives) {
      final file = File(path);
      expect(file.existsSync(), isTrue,
          reason: '$path is allowlisted but no longer exists — remove it');
      final flagged = scanFile(path, file.readAsStringSync());
      expect(flagged, isNotEmpty,
          reason: '$path no longer trips the scan — remove it from '
              'reviewedFalsePositives');
    }
  });
}
