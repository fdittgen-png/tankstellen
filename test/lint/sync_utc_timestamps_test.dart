// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan regression test (#3124): every sync timestamp serialized
/// for Supabase must be UTC.
///
/// `DateTime.now().toIso8601String()` produces an **offset-less LOCAL**
/// time string (`2026-06-10T14:30:00.000` — no `Z`, no `+02:00`).
/// Postgres interprets an offset-less literal in a TIMESTAMPTZ column as
/// UTC, so every `updated_at` / `deleted_at` uploaded this way is skewed
/// by the device's UTC offset — corrupting cross-device ordering,
/// tombstone freshness and retention cutoffs. The fix is
/// `DateTime.now().toUtc().toIso8601String()` (the `Z`-suffixed form).
///
/// What is forbidden (in `lib/core/sync/`):
///   DateTime.now().toIso8601String()
///   (now ?? DateTime.now()).toIso8601String()
///   DateTime.now().subtract(...).toIso8601String()
///   …any `DateTime.now()`-rooted chain reaching `.toIso8601String()`
///   without a `.toUtc()` in between.
///
/// What is allowed:
///   - the same chain with `.toUtc()` anywhere before
///     `.toIso8601String()`.
///   - generated files (`.g.dart`, `.freezed.dart`).
///
/// Baseline is **0** — never add an offender.
void main() {
  test(
      'no offset-less local DateTime.now() timestamps in lib/core/sync '
      '(#3124)', () {
    final offenders = <String>[];

    // A `DateTime.now()`-rooted expression chain that reaches
    // `.toIso8601String` within the same statement. `[^;]*?` tolerates
    // intervening calls (`.subtract(...)`, a `(now ?? …)` null-fallback
    // closing paren) and line breaks.
    final chain = RegExp(r'DateTime\.now\(\)[^;]*?\.toIso8601String');

    final dir = Directory('lib/core/sync');
    expect(dir.existsSync(), isTrue,
        reason: 'run from the repo root (lib/core/sync not found)');

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart') ||
          entity.path.endsWith('.freezed.dart')) {
        continue;
      }

      final content = entity.readAsStringSync();
      for (final match in chain.allMatches(content)) {
        final snippet = match.group(0)!;
        if (snippet.contains('.toUtc()')) continue;
        final line = '\n'.allMatches(content.substring(0, match.start)).length + 1;
        offenders.add(
            '${entity.path}:$line  ${snippet.replaceAll(RegExp(r'\s+'), ' ')}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Local-time timestamps uploaded to TIMESTAMPTZ columns '
          '(#3124). Insert .toUtc() before .toIso8601String():\n'
          '${offenders.join('\n')}',
    );
  });
}
