// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet: fire-and-forget error logging must go through the façade
/// (`log.error` / `log.warn`, `lib/core/logging/app_log.dart`, ADR 0021),
/// not through a hand-rolled `unawaited(errorLogger.log(...))` block.
///
/// ## Why this exists
///
/// The identical block
///
/// ```dart
/// unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {…}));
/// ```
///
/// is ceremony around one fact, and the ceremony is where the bugs live: a
/// forgotten `unawaited` trips `discarded_futures`, a forgotten `, st`
/// trips `catch_no_st`, and a `const` context map can never carry the
/// station / trip / attempt the failure was about (374 of 520 are `const`).
/// The façade folds the required behaviour in, so the correct call is also
/// the shortest — the only reliable way to make a convention stick.
///
/// ## Why it was rewritten (#3977, Epic #3952)
///
/// The previous version asserted **zero** raw blocks and passed. Its regex
/// required a newline directly after `unawaited(` — the multi-line shape
/// the block had when the ratchet was written — and the formatter later
/// collapsed every site onto one line. Real population on 2026-09-08:
/// **505 sites in 239 files** (trips 82, obd2 70, core/sync 42, alerts 34).
/// Same failure class as #2348: a ratchet that measured something other
/// than what it claimed, reading as "clean".
///
/// Two fixes. The matcher is now format-insensitive (any whitespace,
/// newline or none, between `unawaited(` and `errorLogger.log(`), and it
/// carries a parse-fidelity self-check below so a future formatting change
/// cannot blind it again. The single allow-set became two **decrease-only
/// numeric baselines** (sites and files), because a 239-entry allow-set is
/// not a ratchet, it is a copy of `find`.
///
/// ## What is still allowed
///
/// * `await errorLogger.log(...)` — a caller that genuinely needs the write
///   to land before continuing (isolate teardown, tests). Not matched.
/// * The raw shape inside the files that ARE the façade and its plumbing
///   ([_exempt]) — they cannot log through themselves.
///
/// ## Migration
///
/// One PR per feature, trips → obd2 → sync → alerts (#3978), each lowering
/// [_baselineSites] / [_baselineFiles] in the same PR. Target 0.
void main() {
  /// Any whitespace — including none, or a newline — between the two
  /// calls. The old regex demanded `\s*\n\s*` and matched 1 site in the
  /// whole tree.
  final rawShape = RegExp(r'unawaited\(\s*errorLogger\.log\(');

  test('matcher fidelity: one-line, multi-line, and not the awaited form',
      () {
    const fixture = '''
      unawaited(errorLogger.log(ErrorLayer.ui, e, st));      // 1 one-line
      unawaited(
        errorLogger.log(                                      // 2 multi-line
          ErrorLayer.ui, e, st, context: const {'where': 'x'},
        ),
      );
      unawaited(  errorLogger.log(ErrorLayer.sync, e, st));   // 3 spaces
      await errorLogger.log(ErrorLayer.ui, e, st);            // allowed
      log.error(e, st, layer: ErrorLayer.ui);                 // the façade
    ''';
    final found = rawShape.allMatches(fixture).length;
    expect(found, 3,
        reason: 'the matcher found $found of 3 known sites — it would report '
            'a false green on real code (#3977, #2348)');
  });

  test('raw unawaited(errorLogger.log(...)) does not grow (#3977)', () {
    final offenders = <String, int>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart') ||
          entity.path.endsWith('.freezed.dart')) {
        continue;
      }
      final rel = entity.path.replaceAll(r'\', '/');
      if (_exempt.contains(rel)) continue;
      final count = rawShape.allMatches(entity.readAsStringSync()).length;
      if (count > 0) offenders[rel] = count;
    }
    final sites = offenders.values.fold<int>(0, (a, b) => a + b);
    final listing = (offenders.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .map((e) => '  - ${e.key} (${e.value}x)')
        .join('\n');

    expect(
      sites,
      lessThanOrEqualTo(_baselineSites),
      reason: 'Hand-rolled unawaited(errorLogger.log(...)) sites: $sites '
          '(baseline $_baselineSites, decrease-only). Use log.error / '
          'log.warn from lib/core/logging/app_log.dart with a non-const '
          'context map (ADR 0021, #3977).\n$listing',
    );
    expect(
      offenders.length,
      lessThanOrEqualTo(_baselineFiles),
      reason: 'Files hand-rolling the block: ${offenders.length} '
          '(baseline $_baselineFiles, decrease-only).\n$listing',
    );
  });
}

/// The façade and its plumbing: they cannot log through themselves.
const _exempt = <String>{
  'lib/core/error/guarded.dart',
  'lib/core/logging/error_logger.dart',
  'lib/core/logging/app_log.dart',
};

/// Baselines as of 2026-09-08 (#3977). Only ever decrease; target 0.
const _baselineSites = 505;
const _baselineFiles = 239;
