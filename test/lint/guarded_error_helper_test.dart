// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet: fire-and-forget error logging must go through
/// `logFailure(...)` (`lib/core/error/guarded.dart`), not through a
/// hand-rolled `unawaited(errorLogger.log(...))` block.
///
/// ## Why this exists
///
/// A duplication scan of `lib/` found the identical seven-line block
///
/// ```dart
/// unawaited(
///   errorLogger.log(
///     ErrorLayer.ui,
///     e,
///     st,
///     context: const {'where': '…'},
///   ),
/// );
/// ```
///
/// in **26 files**, 72 times. Seven lines of ceremony around one fact,
/// and the ceremony is where the bugs were: a forgotten `unawaited`
/// trips `discarded_futures`, a forgotten `, st` trips `catch_no_st`,
/// and a forgotten `context.mounted` check throws on an unmounted
/// widget. `logFailure` folds all three in, so the correct call is also
/// the shortest one — which is the only reliable way to make a
/// convention stick.
///
/// ## What is still allowed
///
/// * `await errorLogger.log(...)` — a caller that genuinely needs the
///   write to land before continuing (isolate teardown, tests).
/// * `errorLogger.log(...)` inside `core/` plumbing that must not
///   depend on the widget layer (`guarded.dart` itself, the isolate
///   spool, the trace pipeline).
/// * Anything already listed in [_grandfathered].
///
/// ## Ratchet-down only
///
/// [_grandfathered] is the set of files that still contain the raw
/// shape. It may only ever **shrink**. Removing a file from it (by
/// migrating its call sites) is the goal; adding one is forbidden —
/// new code uses `logFailure`.
void main() {
  /// Files that still hand-roll the shape. Migrate and delete the entry.
  /// NEVER add to this set. EMPTIED 2026-08-01 — all 16 grandfathered
  /// blocks were migrated (extra context keys go through `extra:`,
  /// synthetic errors pass `StackTrace.current` positionally, non-ui
  /// layers pass `layer:`). Keep the set so the ratchet machinery — and
  /// its stale-entry check — stays in place for any future regression.
  final grandfathered = <String>{};

  /// `logFailure` cannot be used here: these define or underpin it, or
  /// run in a background isolate where the widget layer is absent.
  const exempt = <String>{
    'lib/core/error/guarded.dart',
    'lib/core/logging/error_logger.dart',
  };

  final rawShape = RegExp(
    r'unawaited\(\s*\n\s*errorLogger\.log\(',
    multiLine: true,
  );

  test('no new hand-rolled unawaited(errorLogger.log(...)) blocks', () {
    final offenders = <String, int>{};

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart') ||
          entity.path.endsWith('.freezed.dart')) {
        continue;
      }
      final rel = entity.path.replaceAll(r'\', '/');
      if (exempt.contains(rel)) continue;

      final count = rawShape.allMatches(entity.readAsStringSync()).length;
      if (count > 0) offenders[rel] = count;
    }

    final unexpected = offenders.keys.where((f) => !grandfathered.contains(f));
    expect(
      unexpected,
      isEmpty,
      reason: 'These files hand-roll the fire-and-forget error-log block.\n'
          'Use logFailure(e, st, where: "...") from '
          'lib/core/error/guarded.dart instead:\n'
          '${unexpected.map((f) => '  - $f (${offenders[f]}x)').join('\n')}',
    );

    final stale = grandfathered.where((f) => !offenders.containsKey(f));
    expect(
      stale,
      isEmpty,
      reason: 'These files no longer contain the raw shape — remove them '
          'from the grandfathered set so the ratchet stays honest:\n'
          '${stale.map((f) => '  - $f').join('\n')}',
    );
  });

  test('the grandfathered set only ever shrinks', () {
    // Pinned so a future edit that adds an entry fails here rather than
    // quietly widening the allow-list.
    expect(
      grandfathered.length,
      lessThanOrEqualTo(0),
      reason: 'The grandfathered set reached ZERO on 2026-08-01 and must '
          'stay there. Use logFailure/guard/guardAsync/runGuarded from '
          'lib/core/error/guarded.dart instead of re-introducing the raw '
          'block.',
    );
  });
}
