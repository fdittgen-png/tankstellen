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
///   * `Semantics(label: 'literal')` — the positional accessibility
///     label (distinct from the camelCase `semanticLabel:` parameter);
///     this was a screen-reader blind spot across 16 non-English
///     locales until #2305 widened the gate.
///   * a ternary branch that yields a string literal **inside a `${…}`
///     string interpolation** — e.g. `'… ${flag ? ' · no highways' : ''}'`
///     or `'…${sel ? ", selected" : ""}'`. The primary sinks stop at the
///     first `$`, so a translatable word smuggled into an interpolated
///     ternary used to slip through entirely (#2305).
///
/// `SnackBar` content and `AppBar` titles are `Text(...)` widgets, so
/// the `Text(` sink already covers them.
///
/// ## The l10n-fallback pattern (#3162 — gate closed)
///
/// `l10n.yaml` sets `nullable-getter: false`, so
/// `AppLocalizations.of(context)` is non-nullable and the historical
/// `l10n?.key ?? 'English fallback'` convention is dead code — all
/// ~708 fallback literals were removed with it. A dedicated sink keeps
/// the pattern at **zero**: any `l10n.key ?? 'prose'` (or `l?.key`,
/// `loc.key`, … — with or without arguments) is a violation. Code that
/// genuinely runs without a `BuildContext` (background isolates, TTS,
/// notifications) resolves a non-null instance via
/// `lookupAppLocalizations(locale)` (the #2766 pattern) instead of
/// falling back to a literal.
///
/// ## What is NOT flagged (precision)
///
/// For the widget sinks the literal must sit *immediately* after the
/// sink (modulo `const` and whitespace). That single anchor rules out
/// the bulk of false positives for free:
///
///   * string interpolation `Text('$count items')` — a `$` inside the
///     literal disqualifies it;
///   * pure interpolation `Semantics(label: '$a · $b')` that composes
///     only already-localized substrings + runtime data carries no
///     literal prose, so it is not flagged;
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
    // `Semantics(label: '...')` — the positional-style accessibility
    // label on a `Semantics` widget. Unlike the camelCase
    // `semanticLabel:` parameter above, the `Semantics.label`
    // constructor argument was a blind spot: screen readers in every
    // non-English locale heard a bare English literal (#2305).
    //
    // The literal must be the *first quote* after `Semantics(`, modulo
    // a leading run of simple scalar flags (`container: true,`,
    // `button: true,`, `image: true,` …). Those flags carry neither a
    // quote nor a parenthesis, so the anchor still rules out the
    // intentional fallback `Semantics(label: l10n?.x ?? '…')` — an
    // `l10n?…` expression precedes the literal and breaks the match.
    RegExp(
      r'Semantics\(\s*(?:[A-Za-z][A-Za-z0-9]*:\s*[A-Za-z0-9.]+,\s*)*'
      'label:\\s*$quoted',
    ),
    // #3162 — the l10n-fallback blind spot, closed. `nullable-getter:
    // false` makes `AppLocalizations.of(context)` non-nullable, so a
    // `l10n.key ?? 'English fallback'` (let alone `l10n?.key`) is a
    // duplicated English string that silently drifts from the ARB.
    // Matches a member access on the conventional localization
    // identifiers (`l10n`, `l`, `loc`, `localizations`), optionally
    // with arguments, null-coalesced into a quoted literal — across
    // newlines (`\s*` spans the wrap).
    RegExp(
      r'\b(?:l10n|l|loc|localizations)\??\.[a-zA-Z][a-zA-Z0-9_]*'
      r'(?:\([^()]*\))?\s*\?\?\s*'
      '$quoted',
    ),
  ];

  // A ternary *then*-branch that is a bare string literal, sitting
  // inside a `${…}` interpolation — e.g.
  // `'… ${flag ? ' · no highways' : ''}'` or `'…${sel ? ", selected" : ""}'`.
  // The lint's primary sinks all stop at the first `$`, so a translatable
  // word smuggled into an interpolated ternary used to slip through
  // entirely (#2305). Group 1 is the quoted literal.
  //
  // The negative lookbehind `(?<!\?)` excludes the null-coalescing
  // operator `?? 'fallback'` (a single `?` is a ternary; a double `??`
  // is handled by the dedicated #3162 fallback sink above, not this
  // ternary detector). The trailing `:` confirms it is the `then` arm of a
  // conditional rather than a bare expression. The interpolation-context
  // guard below rules out top-level ternaries that are not inside a
  // `${…}` block.
  final ternaryInInterpolation =
      RegExp('(?<!\\?)\\?\\s*$quoted\\s*:');

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

      void recordIfProse(RegExpMatch match) {
        final literal = match.group(1)!;
        if (!looksLikeProse(literal)) return;
        final firstLine = lineOf(match.start);
        final lastLine = lineOf(match.end);
        final spanEnd = lastLine + 1 < lineStarts.length
            ? lineStarts[lastLine + 1]
            : source.length;
        // Inline exemption — the `// i18n-ignore:` comment may sit on
        // the sink's opening line or on a wrapped literal line.
        final span = source.substring(lineStarts[firstLine], spanEnd);
        if (span.contains('// i18n-ignore:')) return;
        violations.add('$path:${firstLine + 1}: $literal');
      }

      for (final sink in sinks) {
        for (final match in sink.allMatches(source)) {
          recordIfProse(match);
        }
      }

      // Ternary-inside-interpolation literals. Only a match that sits
      // inside an open `${…}` block on its own line counts — a plain
      // top-level ternary (`x ? 'a' : 'b'` assigned to a variable) is
      // out of scope for this detector and handled, if user-facing, by
      // the `Text(`/`Semantics(` sinks above. The guard scans the line
      // up to the match for an unbalanced `${` (more `${` than `}`).
      for (final match in ternaryInInterpolation.allMatches(source)) {
        final line = lineOf(match.start);
        final lineStr =
            source.substring(lineStarts[line], match.start);
        final opens = '\${'.allMatches(lineStr).length;
        final closes = '}'.allMatches(lineStr).length;
        if (opens <= closes) continue; // not inside an open interpolation
        recordIfProse(match);
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
