// Generates the `en_XA` pseudo-locale ARB for text-expansion testing
// (#1699).
//
// Pseudo-localization is a synthetic locale used to catch UI that
// truncates or overflows once English is replaced by a longer
// translation. It is NOT a shipped language — `en_XA` is deliberately
// absent from `AppLanguages.all`, so it never appears in the in-app
// language picker; it exists only so widget tests can pump screens
// under deliberately-long, accented strings.
//
// The transform, for every value in `app_en.arb`:
//   * accents ASCII letters (Settings -> Šéttîñgš) — surfaces missing
//     diacritic glyphs and makes pseudo text obvious at a glance;
//   * pads each value ~45% longer — German / Finnish / Slavic
//     translations routinely run that long, so a layout that survives
//     `en_XA` survives them;
//   * brackets the value with ⟦ ⟧ — any clipped edge is then visible
//     as a missing bracket in a golden / screenshot.
//
// `{placeholder}` tokens and ICU `plural` / `select` skeletons are left
// untouched: the transform only rewrites text at brace-depth 0, so
// every `{...}` (and everything nested inside it) passes through
// verbatim and `flutter gen-l10n` placeholder validation still passes.
//
// Usage:  dart tool/gen_pseudo_arb.dart
// Then:   flutter gen-l10n
//
// Re-run both whenever `app_en.arb` changes. The committed
// `app_en_XA.arb` is the source of truth consumed by gen-l10n;
// regenerating it is deterministic.
import 'dart:convert';
import 'dart:io';

const _l10nDir = 'lib/l10n';
const _template = 'app_en.arb';
const _output = 'app_en_XA.arb';

/// ASCII letter -> accented counterpart. Covers the full alphabet so
/// the pseudo text exercises diacritic rendering broadly, not just on
/// vowels.
const Map<String, String> _accents = {
  'a': 'á', 'b': 'ƀ', 'c': 'ç', 'd': 'đ', 'e': 'é', 'f': 'ƒ',
  'g': 'ǧ', 'h': 'ĥ', 'i': 'î', 'j': 'ĵ', 'k': 'ķ', 'l': 'ł',
  'm': 'ɱ', 'n': 'ñ', 'o': 'ó', 'p': 'ƥ', 'q': 'ɋ', 'r': 'ř',
  's': 'š', 't': 'ŧ', 'u': 'ú', 'v': 'ṽ', 'w': 'ŵ', 'x': 'ẋ',
  'y': 'ý', 'z': 'ž',
  'A': 'Á', 'B': 'Ɓ', 'C': 'Ç', 'D': 'Đ', 'E': 'É', 'F': 'Ƒ',
  'G': 'Ǧ', 'H': 'Ĥ', 'I': 'Î', 'J': 'Ĵ', 'K': 'Ķ', 'L': 'Ł',
  'M': 'Ṁ', 'N': 'Ñ', 'O': 'Ó', 'P': 'Ƥ', 'Q': 'Ɋ', 'R': 'Ř',
  'S': 'Š', 'T': 'Ŧ', 'U': 'Ú', 'V': 'Ṽ', 'W': 'Ŵ', 'X': 'Ẋ',
  'Y': 'Ý', 'Z': 'Ž',
};

/// Rewrites [value] into its pseudo form, leaving every `{...}` token
/// (placeholders and ICU skeletons, including nested braces) verbatim.
String pseudoize(String value) {
  final out = StringBuffer('⟦');
  var depth = 0;
  var accentedLetters = 0;
  for (final rune in value.runes) {
    final ch = String.fromCharCode(rune);
    if (ch == '{') {
      depth++;
      out.write(ch);
      continue;
    }
    if (ch == '}') {
      if (depth > 0) depth--;
      out.write(ch);
      continue;
    }
    if (depth > 0) {
      // Inside a placeholder / ICU skeleton — pass through untouched.
      out.write(ch);
      continue;
    }
    final accent = _accents[ch];
    if (accent != null) {
      out.write(accent);
      accentedLetters++;
    } else {
      out.write(ch);
    }
  }
  // Pad ~45% of the accent-bearing length so the value lands in the
  // expansion band real long-locale translations occupy. A single
  // unbroken run maximises width pressure on fixed-size chrome.
  final pad = (accentedLetters * 0.45).round();
  if (pad > 0) {
    out.write(' ');
    out.write('·' * pad);
  }
  out.write('⟧');
  return out.toString();
}

void main() {
  final templateFile = File('$_l10nDir/$_template');
  if (!templateFile.existsSync()) {
    stderr.writeln('error: $_l10nDir/$_template not found — run from repo root');
    exit(1);
  }
  final template =
      jsonDecode(templateFile.readAsStringSync()) as Map<String, dynamic>;

  final pseudo = <String, dynamic>{'@@locale': 'en_XA'};
  var count = 0;
  for (final entry in template.entries) {
    if (entry.key.startsWith('@')) continue; // skip @@locale + metadata
    pseudo[entry.key] = pseudoize(entry.value as String);
    count++;
  }

  final outFile = File('$_l10nDir/$_output');
  outFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(pseudo)}\n',
  );
  stdout.writeln('Wrote $_l10nDir/$_output — $count pseudo-localized keys.');
}
