// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// HARD RULE #1's blind spot (#3982, epic #3952).
///
/// `no_hardcoded_ui_strings_test` matches a `Text('…')` whose literal is
/// a plain string. It cannot see `Text('Version $x')` or
/// `Text('Error: $e')` — an interpolated literal — so an entire class of
/// hard-coded English slipped past it. That class is where raw
/// exceptions surface too: `'Error: $error'` shows a French user a Dart
/// stack fragment.
///
/// ## The rule
///
/// An interpolated `Text('…')` is a violation when the parts OUTSIDE the
/// interpolations contain a run of three or more ASCII letters — i.e.
/// an English *word*.
///
/// Deliberately NOT violations, because they carry no language:
///
///   * `Text('$dateStr · $distance')` — separators only;
///   * `Text('$rating/5')`, `Text('${n.round()} km')`, `Text('$x €')` —
///     unit and symbol suffixes, which are the same in every locale the
///     app ships (and the *number* is already locale-formatted by
///     `UnitFormatter` / `PriceFormatter`);
///   * `Text('${l10n.routeSegment}:')` — a translated string plus
///     punctuation.
///
/// Two letters is the cutoff so `km`, `mi`, `Wh` and `kWh` pass while
/// `Version`, `Error`, `Failed to load` do not. A genuine two-letter
/// English word in UI copy would be caught by the sibling lint, which
/// sees non-interpolated literals.
///
/// ## The ratchet
///
/// The baseline is **0**: the three pre-existing sites were fixed in
/// #3982 and the fourth in #3993. This lint starts at target, so any new
/// violation fails CI outright. NEVER raise it.
void main() {
  test(
    "interpolated Text('…\$x') never carries hard-coded words (#3982)",
    () {
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final posix = entity.path.replaceAll(r'\', '/');
        // Generated bindings ARE the translations; scanning them is
        // circular.
        if (posix.contains('/l10n/') ||
            posix.endsWith('.g.dart') ||
            posix.endsWith('.freezed.dart')) {
          continue;
        }
        final src = entity.readAsStringSync();
        for (final (offset, literal) in _textLiterals(src)) {
          if (!literal.contains(r'$')) continue;
          if (!_word.hasMatch(_stripInterpolations(literal))) continue;
          final line = '\n'.allMatches(src.substring(0, offset)).length + 1;
          offenders.add('$posix:$line  $literal');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Interpolated Text() with hard-coded words (HARD RULE #1). Move '
            'the wording into an ARB key with a placeholder, and pass a '
            'LOCALIZED value — for an error, `ErrorLocalizer.localize(e, '
            'l10n)`, never the raw exception. See #3982.\n'
            'Offending sites:\n${offenders.join("\n")}',
      );
    },
  );
}

final _word = RegExp('[A-Za-z]{3,}');

/// The string literal of every `Text('…')` / `Text("…")` in [src], with
/// its offset.
///
/// Hand-walked rather than regexed: an interpolation may itself contain
/// quotes (`'${x.isEmpty ? '' : x}'`), and a regex that stops at the
/// first matching quote reads the ternary's own text as literal — which
/// is exactly the false positive this scan must not produce.
Iterable<(int, String)> _textLiterals(String src) sync* {
  for (final m in RegExp(r'Text\(\s*').allMatches(src)) {
    var i = m.end;
    if (i >= src.length) continue;
    final quote = src[i];
    // Quote characters are matched by hand rather than in the pattern:
    // a regex carrying both ' and " has to be escaped through two
    // layers and becomes unreadable.
    if (quote != "'" && quote != '"') continue;
    i++;
    var depth = 0;
    final buffer = StringBuffer();
    var closed = false;
    while (i < src.length) {
      final c = src[i];
      if (c == r'\') {
        if (i + 1 < src.length) buffer.write(src.substring(i, i + 2));
        i += 2;
        continue;
      }
      if (c == r'$' && i + 1 < src.length && src[i + 1] == '{') {
        depth++;
        buffer.write(r'${');
        i += 2;
        continue;
      }
      if (depth > 0 && c == '{') depth++;
      if (depth > 0 && c == '}') depth--;
      if (depth == 0 && (c == quote || c == '\n')) {
        closed = c == quote;
        break;
      }
      buffer.write(c);
      i++;
    }
    if (closed) yield (m.start, buffer.toString());
  }
}

/// [literal] with every `$name` and `${expr}` removed, leaving only the
/// parts the reader sees as words.
String _stripInterpolations(String literal) {
  final out = StringBuffer();
  var i = 0;
  while (i < literal.length) {
    if (literal[i] == r'$' &&
        i + 1 < literal.length &&
        literal[i + 1] == '{') {
      var depth = 1;
      i += 2;
      while (i < literal.length && depth > 0) {
        if (literal[i] == '{') depth++;
        if (literal[i] == '}') depth--;
        i++;
      }
      continue;
    }
    if (literal[i] == r'$') {
      i++;
      while (i < literal.length &&
          (RegExp('[A-Za-z0-9_]').hasMatch(literal[i]))) {
        i++;
      }
      continue;
    }
    out.write(literal[i]);
    i++;
  }
  return out.toString();
}
