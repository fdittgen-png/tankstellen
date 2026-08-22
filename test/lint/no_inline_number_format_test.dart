// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan ratchet (#3743): no *new* `toStringAsFixed(` call in a
/// presentation layer, and every grandfathered file may only ever
/// **shrink** its count.
///
/// `toStringAsFixed` hard-codes the **dot** decimal separator, so a
/// German or French user reads `1.5` where their locale writes `1,5`
/// (and `formatDistance`-bypassing sites also show km to UK users who
/// expect miles). Every user-visible number in a widget must instead
/// route through the locale-aware helpers:
///
///   * `UnitFormatter.formatDecimal(v, fractionDigits: n)` — bare
///     figures whose unit comes from the surrounding string / label
///     (percentages, litres, kWh, L/100 values, file sizes, …);
///   * `UnitFormatter.formatDistance(km, fractionDigits: n)` — any
///     "X km" string (also handles the imperial mi/yd branch);
///   * `PriceFormatter.formatTotal` / `formatPriceCompact` /
///     `UnitFormatter.formatPricePerUnit` — money.
///
/// ## Scope
///
/// `lib/features/*/presentation/**.dart` — the widget layer, where a
/// formatted string is (almost always) user-visible. Domain/data
/// formatting (exporters, CSV, protocol payloads) is out of scope.
///
/// ## Exemptions — `// i18n-ignore-format: <reason>`
///
/// A genuinely locale-neutral `toStringAsFixed` may stay, with the
/// marker comment on the **same line or the line directly above** and
/// a stated reason. Legitimate cases seen so far:
///
///   * machine round-trips — a `TextEditingController` prefill that is
///     re-parsed with `double.tryParse`, a URI parameter, a filename;
///   * developer-facing diagnostics payloads (OCR traces, bad-scan
///     reports) that must stay machine-readable;
///   * the dot-decimal `L/100` consumption mask (#2185) — the shipped
///     `UnitFormatter.formatConsumption` convention; an adjacent
///     estimate figure must match it, not diverge per-locale.
///
/// ## Baseline
///
/// [_baseline] snapshots the files that still carry un-migrated,
/// un-exempted sites. Exact one-way ratchet, same model as
/// `file_length_test.dart`:
///
///   1. **Growth block** — a count above the snapshot fails.
///   2. **Shrink signal** — a count below the snapshot fails too:
///      lower (or remove) the entry in the same PR so the win is
///      locked in.
///   3. Files not listed must be at **zero**.
///
/// Target is an empty map. Never add an entry for new code — use the
/// helpers, or an honest `// i18n-ignore-format: <reason>`.
void main() {
  test('no new inline toStringAsFixed in presentation layers (#3743)', () {
    final featuresDir = Directory('lib/features');
    expect(featuresDir.existsSync(), isTrue);

    final counts = <String, int>{};
    final offendingLines = <String, List<String>>{};

    for (final entity in featuresDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart')) continue;
      if (path.endsWith('.g.dart')) continue;
      if (path.endsWith('.freezed.dart')) continue;
      // Only the presentation layer of each feature is in scope:
      // lib/features/<feature>/presentation/...
      final parts = path.split('/');
      if (parts.length < 5 || parts[3] != 'presentation') continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!line.contains('toStringAsFixed(')) continue;
        // Pure comment lines (docs mentioning the API) don't format.
        if (line.trimLeft().startsWith('//')) continue;
        // Inline exemption — same line or the line directly above.
        if (line.contains('// i18n-ignore-format:')) continue;
        if (i > 0 && lines[i - 1].contains('// i18n-ignore-format:')) {
          continue;
        }
        final n = 'toStringAsFixed('.allMatches(line).length;
        counts[path] = (counts[path] ?? 0) + n;
        (offendingLines[path] ??= <String>[])
            .add('$path:${i + 1}: ${line.trim()}');
      }
    }

    final problems = <String>[];

    for (final entry in counts.entries) {
      final allowed = _baseline[entry.key] ?? 0;
      if (entry.value > allowed) {
        problems.add(
          '${entry.key}: ${entry.value} inline toStringAsFixed sites '
          '(baseline: $allowed).\n'
          'Route the number through UnitFormatter.formatDecimal / '
          'formatDistance (locale-aware), or — for a genuinely '
          'locale-neutral value — add an inline '
          '`// i18n-ignore-format: <reason>` comment.\n'
          '${offendingLines[entry.key]!.join('\n')}',
        );
      } else if (entry.value < allowed) {
        problems.add(
          '${entry.key}: count shrank to ${entry.value} '
          '(baseline: $allowed) — lower or remove its _baseline entry '
          'in this PR to lock the ratchet (one-way, target 0).',
        );
      }
    }

    // Stale entries: baselined file no longer has any site (or is gone).
    for (final entry in _baseline.entries) {
      if (!counts.containsKey(entry.key)) {
        problems.add(
          '${entry.key}: no inline toStringAsFixed sites remain '
          '(baseline: ${entry.value}) — remove its _baseline entry '
          'to lock the ratchet.',
        );
      }
    }

    expect(
      problems,
      isEmpty,
      reason: 'Inline number-format ratchet violations:\n'
          '${problems.join('\n\n')}',
    );
  });
}

/// Files that still carry un-migrated `toStringAsFixed` sites, with the
/// exact remaining count as of the #3743 migration. Only ever shrinks;
/// NEVER add an entry or raise a count.
///
/// The remaining entries are all owned by concurrent work streams:
///   * the chart widgets are being reworked separately (#3743 siblings);
///   * the OBD2 presentation widgets belong to the #3527-family scope.
const _baseline = <String, int>{
  'lib/features/carbon/presentation/widgets/monthly_bar_chart.dart': 1,
  'lib/features/charging/presentation/widgets/charging_cost_trend_chart.dart':
      1,
  'lib/features/charging/presentation/widgets/charging_efficiency_chart.dart':
      1,
  'lib/features/obd2/presentation/widgets/obd2_breadcrumb_row.dart': 2,
  'lib/features/obd2/presentation/widgets/obd2_diagnostics_card.dart': 3,
};
