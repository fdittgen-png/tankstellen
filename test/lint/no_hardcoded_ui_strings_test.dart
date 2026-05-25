// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards HARD RULE #1 — no hard-coded user-facing text.
///
/// Scans every UI sink across **all of `lib/`** for a bare string
/// literal that should instead route through `AppLocalizations`:
///
///   * `Text('literal')` / `const Text('literal')`
///   * the named text parameters `hintText:` `labelText:` `helperText:`
///     `errorText:` `semanticLabel:` `tooltip:` carrying a `'literal'`
///
/// `SnackBar` content and `AppBar` titles are `Text(...)` widgets, so
/// the `Text(` sink already covers them.
///
/// ## What is NOT flagged (precision)
///
/// The literal must sit *immediately* after the sink (modulo `const`
/// and whitespace). That single anchor rules out the bulk of false
/// positives for free:
///
///   * the intentional fallback pattern `Text(l?.key ?? 'fallback')` —
///     an expression precedes the literal, so it never matches;
///   * string interpolation `Text('$count items')` — a `$` inside the
///     literal disqualifies it;
///   * enum / data-map keys (`'0104': pidName`, OBD2 PID tables) — a
///     map key is `'k':`, never `sink('k')` or `param: 'k'`.
///
/// A literal is only treated as user-facing text when it *looks* like
/// prose — it contains whitespace, or it is a capitalised word of four
/// or more letters. Short lowercase tokens (route names, keys, asset
/// ids) are skipped.
///
/// ## Exemptions — `// i18n-ignore: <reason>`
///
/// A genuinely non-translatable literal (brand / proper noun, URL,
/// language-neutral format mask) may carry an inline
/// `// i18n-ignore: <reason>` comment on the **same line**; the
/// detector then skips that line. Every exemption MUST state a reason.
/// The mechanism is documented in `docs/guides/ARB_FRAGMENTS.md`.
///
/// ## Baseline
///
/// [_baseline] is the count of pre-existing violations. Per CLAUDE.md
/// it may only ever **decrease** — the target is **0** (epic #1657).
/// Never raise it. The classified worklist of the remaining
/// violations lives in `docs/guides/i18n-hardcoded-worklist.md`.
void main() {
  // The UI sinks. Group 1 of each match is the quoted literal.
  // A literal may not contain `$` (interpolation) or a newline.
  const quoted = r"""('[^'$\n]*'|"[^"$\n]*")""";
  final sinks = <RegExp>[
    // Text('literal') / Text(const 'literal') — quote anchored right
    // after `Text(`, so `Text(l?.x ?? '...')` cannot match.
    RegExp('Text\\(\\s*(?:const\\s+)?$quoted\\s*[,)]'),
    // Named UI-text parameters.
    RegExp(
      '\\b(?:hintText|labelText|helperText|errorText|semanticLabel|tooltip):'
      '\\s*$quoted',
    ),
  ];

  /// True when [literal] (quotes stripped) reads like user-facing prose
  /// rather than an identifier, route name, key or asset id.
  bool looksLikeProse(String literal) {
    final text = literal.substring(1, literal.length - 1).trim();
    if (text.length < 4) return false;
    // URLs and asset paths are not translatable prose.
    if (text.startsWith('http') || text.startsWith('assets/')) return false;
    if (text.contains(RegExp(r'\s'))) return true;
    // A single capitalised word of 4+ letters (e.g. "Cancel").
    return RegExp(r'^[A-Z][a-zA-Z]{3,}$').hasMatch(text);
  }

  test('no new hard-coded user-facing strings (HARD RULE #1)', () {
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

      for (final sink in sinks) {
        for (final match in sink.allMatches(source)) {
          final literal = match.group(1)!;
          if (!looksLikeProse(literal)) continue;
          final firstLine = lineOf(match.start);
          final lastLine = lineOf(match.end);
          final spanEnd = lastLine + 1 < lineStarts.length
              ? lineStarts[lastLine + 1]
              : source.length;
          // Inline exemption — the `// i18n-ignore:` comment may sit on
          // the sink's opening line or on a wrapped literal line.
          final span = source.substring(lineStarts[firstLine], spanEnd);
          if (span.contains('// i18n-ignore:')) continue;
          violations.add('$path:${firstLine + 1}: $literal');
        }
      }
    }

    violations.sort();

    // Baseline as of 2026-05-16 (#1659). Only ever decreases; target 0.
    // See docs/guides/i18n-hardcoded-worklist.md for the classified
    // remediation worklist.
    const baseline = _baseline;

    expect(
      violations.length,
      lessThanOrEqualTo(baseline),
      reason: 'Hard-coded user-facing strings increased to '
          '${violations.length} (baseline: $baseline).\n'
          'Route the new string through AppLocalizations, or — for a '
          'brand / URL / format mask — add an inline '
          '`// i18n-ignore: <reason>` comment.\n'
          'Current violations:\n${violations.join('\n')}',
    );
  });
}

/// Hard-coded-string count. Driven to **0** by #1660–#1662 / #1664 —
/// this is now a hard gate: any new violation fails CI. Never raise it.
const _baseline = 0;
