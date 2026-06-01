// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the canonical-radius-token mandate
/// (`docs/design/DESIGN_SYSTEM.md`, "Radius scale").
///
/// Scans **all of `lib/`** for an inline corner radius that should instead
/// route through the `AppRadius` tokens in
/// `lib/core/theme/app_radius.dart`:
///
///   * `BorderRadius.circular(<n>)`
///   * a standalone `Radius.circular(<n>)`
///
/// Both forms are matched by the single substring `Radius.circular(` — a
/// `BorderRadius.circular(` line contains it too, so one regex covers the
/// pair. The token file [_radiusTokenFile] is the one place these calls
/// are allowed (it *defines* the helpers), so it is exempt.
///
/// ## Baseline
///
/// [_baseline] is the count of pre-existing inline radii (everything
/// outside the token file). Mirroring `no_hardcoded_ui_strings_test.dart`
/// and HARD RULE #1's pattern, it may only ever **decrease** — the target
/// is **0**. Never raise it. As callers migrate to `AppRadius.sm/md/lg/
/// xl/xxl`, drop the baseline to match.
void main() {
  // Matches both `BorderRadius.circular(` and a bare `Radius.circular(`.
  final inlineRadius = RegExp(r'Radius\.circular\(');

  // The token definition file — the sole legitimate home for
  // `BorderRadius.circular(...)`, since it wraps the raw calls behind the
  // `AppRadius.*` getters that the rest of the app should use instead.
  const radiusTokenFile = _radiusTokenFile;

  test('no new inline BorderRadius/Radius.circular (use AppRadius tokens)',
      () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue);

    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart')) continue;
      if (path.endsWith('.g.dart')) continue;
      if (path.endsWith('.freezed.dart')) continue;
      // Generated localization output is not source.
      if (path.contains('/l10n/app_localizations')) continue;
      // The token file is allowed to call BorderRadius.circular — it is
      // the canonical wrapper every other widget must reuse.
      if (path == radiusTokenFile) continue;

      final source = entity.readAsStringSync();
      final lineStarts = <int>[0];
      for (var i = 0; i < source.length; i++) {
        if (source[i] == '\n') lineStarts.add(i + 1);
      }
      int lineOf(int offset) {
        var lo = 0, hi = lineStarts.length - 1;
        while (lo < hi) {
          final mid = (lo + hi + 1) >> 1;
          if (lineStarts[mid] <= offset) {
            lo = mid;
          } else {
            hi = mid - 1;
          }
        }
        return lo;
      }

      for (final match in inlineRadius.allMatches(source)) {
        final line = lineOf(match.start) + 1;
        violations.add('$path:$line');
      }
    }

    violations.sort();

    // Baseline as of 2026-05-30 (#2494): dropped 129 → 126 by collapsing
    // the two mode pills into `SelectablePill` (AppRadius.xl) and migrating
    // `amenity_chips.dart` onto the new `AppPill` (AppRadius.sm) — four
    // inline radii removed. Only ever decreases; the target is 0. The
    // remainder live under `lib/features/**` and are owned by the Epic
    // #2487 cards/chips children — migrate them down, never raise this.
    const baseline = _baseline;

    expect(
      violations.length,
      lessThanOrEqualTo(baseline),
      reason: 'Inline corner radii increased to ${violations.length} '
          '(baseline: $baseline).\n'
          'Reuse the canonical tokens in '
          'lib/core/theme/app_radius.dart — e.g. `AppRadius.lg` instead of '
          '`BorderRadius.circular(12)`.\n'
          'Current inline radii:\n${violations.join('\n')}',
    );
  });
}

/// The one file allowed to call `BorderRadius.circular(...)` — it defines
/// the `AppRadius` tokens everything else must reuse.
const _radiusTokenFile = 'lib/core/theme/app_radius.dart';

/// Inline-radius count outside the token file. Driven toward **0** by the
/// Epic #2487 cards/chips children. Never raise it.
///
/// #2622 — dropped to 122: the station-card Cheapest badge + loyalty badge
/// migrated their `BorderRadius.circular(8)` onto `AppRadius.sm`, and the
/// pre-existing count had also slipped below the prior 126 baseline.
const _baseline = 122;
