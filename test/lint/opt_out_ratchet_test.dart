// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Opt-out-comment ratchet (plan R1.4, dimension 11 of
/// `docs/audits/ratchet-all-dimensions-plan.md`).
///
/// ## The failure that motivated it
///
/// Every custom lint ratchet in this directory honors an inline opt-out
/// marker — and until now NOTHING counted the markers themselves. That
/// makes the opt-outs an unratcheted escape hatch: the silent-catch /
/// stacktrace / debugPrint / hardcoded-string baselines can all be held
/// at their pinned numbers while `// ignore:` comments inflate silently,
/// hollowing the ratchets out from the inside (the 2026-08-01 audit
/// measured 43 catch-ratchet opt-outs that no gate had ever seen).
///
/// ## Mechanism
///
/// Counts every occurrence of each marker in handwritten `lib/` sources
/// (no `.g.dart` / `.freezed.dart` / `lib/l10n/` output — the same scan
/// scope as the ratchets the markers opt out of) against an **exact**
/// per-marker baseline:
///
///   1. a count above its baseline fails — a new opt-out was added;
///      remove it (fix the underlying finding) or, when genuinely
///      justified, burn down another occurrence of the same marker in
///      the same PR so the total never rises;
///   2. a count below its baseline ALSO fails ("stale baseline") — lower
///      the entry in the same PR so the win is locked in and can never
///      silently creep back.
///
/// NEVER raise an entry. The markers are enumerated from the enforcing
/// tests; adding a new opt-out marker to a lint test means adding it
/// here at its measured count in the same PR.
void main() {
  // marker (as it appears in source) → pinned occurrence count.
  //   `// ignore: silent_catch`       — test/lint/no_silent_catch_test.dart
  //   `// ignore: catch_no_st`        — catch_block_stacktrace_coverage_test
  //   `// ignore: log_raw_debugprint` — no_raw_debugprint_error_test (at 0:
  //                                      pinned, guarded-ratchet shape)
  //   `// i18n-ignore:`               — no_hardcoded_ui_strings_test (each
  //                                      carries a reason; brand/URL/mask
  //                                      exemptions are legitimate but the
  //                                      TOTAL may still only shrink)
  // Measured 2026-08-17.
  const optOutBaseline = <String, int>{
    '// ignore: silent_catch': 32,
    '// ignore: catch_no_st': 14,
    '// ignore: log_raw_debugprint': 0,
    '// i18n-ignore:': 123,
  };

  bool isScanned(String path) {
    if (!path.endsWith('.dart')) return false;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) {
      return false;
    }
    if (path.startsWith('lib/l10n/')) return false;
    return true;
  }

  test('lint opt-out markers in lib/ never exceed (or silently undershoot) '
      'their per-marker baseline (plan R1.4)', () {
    final occurrences = <String, List<String>>{
      for (final marker in optOutBaseline.keys) marker: [],
    };

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (!isScanned(path)) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final marker in optOutBaseline.keys) {
          for (final _ in marker.allMatches(lines[i])) {
            occurrences[marker]!.add('$path:${i + 1}');
          }
        }
      }
    }

    final regressions = <String>[];
    final stale = <String>[];
    for (final MapEntry(key: marker, value: baseline)
        in optOutBaseline.entries) {
      final found = occurrences[marker]!;
      if (found.length > baseline) {
        regressions.add(
          '`$marker`: ${found.length} (baseline $baseline). All sites:\n'
          '  ${found.join('\n  ')}',
        );
      } else if (found.length < baseline) {
        stale.add('`$marker`: ${found.length} (baseline $baseline)');
      }
    }

    expect(
      regressions,
      isEmpty,
      reason:
          'New lint opt-out comment(s) in lib/ — the opt-outs are the '
          'escape hatch of the catch/string ratchets and may only ever '
          'shrink (plan R1.4). Fix the underlying finding instead of '
          'opting out, or retire another occurrence of the same marker '
          'in the same PR. NEVER raise a baseline entry.\n\n'
          '${regressions.join('\n\n')}',
    );

    expect(
      stale,
      isEmpty,
      reason:
          'Opt-out count(s) dropped below their baseline — lock the win '
          'in by lowering the matching optOutBaseline entry in this test '
          'in the same PR:\n${stale.join('\n')}',
    );
  });
}
