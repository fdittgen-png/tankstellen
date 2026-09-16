// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet: user-facing prose must never live in a Dart map keyed by
/// language code (#4271 item 8, epic #4270).
///
/// ## Why this is a separate check from `no_hardcoded_ui_strings_test`
///
/// That gate anchors on **sinks** — the literal has to sit immediately
/// after `Text(`, `label:`, `tooltip:` and friends — and it deliberately
/// exempts map keys so OBD2 PID tables (`'0104': pidName`) stay quiet. A
/// translation table inverts that shape: the language is the *key* and
/// the prose is the *value*, with no sink anywhere near it.
///
/// ```dart
/// const names = {
///   'favorites': {'en': 'Favorites', 'de': 'Favoriten', 'fr': 'Favoris'},
///   ...
/// };
/// ```
///
/// That is exactly how `LandingScreen.localizedName` carried ten
/// languages inside `user_profile.dart` and passed every ratchet in the
/// repository until #4269 removed it.
///
/// ## Why it matters more than an ordinary hard-coded string
///
/// A table like this is invisible to the #1699 ARB coverage gate, because
/// that gate checks ARB keys and these strings are not ARB keys. It ships
/// English to every locale the table forgot — the deleted one covered 10
/// of 23 — while looking fully translated in the languages it did cover.
///
/// It is also expensive to remove safely. `tool/autofill_locales.dart`
/// carries **new** keys outward from English and knows nothing about a
/// table being deleted, so porting the strings to ARB without copying the
/// translations across loses them: #4269 fixed 13 locales and silently
/// regressed 8 to raw English, which #4271 then had to restore.
///
/// ## Parse-fidelity self-check
///
/// A scan that matches nothing passes an `isEmpty` assertion exactly like
/// a scan that works. `guarded_error_helper_test` shipped in precisely
/// that state — "the previous version asserted **zero** raw blocks and
/// passed" while its regex was blind (#3977), the same failure class as
/// #2348 and #4116. So the detector below is a pure function over source
/// text, and the second group drives it with a known-positive fixture
/// (the table #4269 deleted) and known-negative ones. If a future edit
/// blinds the matcher, those tests fail rather than going quietly green.
///
/// ## Exemption
///
/// A legitimate language-keyed map of non-prose values (locale → CLDR
/// pattern, locale → asset id) will not match: the value must look like
/// prose. For anything else, `// i18n-ignore:` on the line skips it, with
/// a reason, exactly as the sibling gate documents.

/// Mirrors `no_hardcoded_ui_strings_test`: a literal counts as prose when
/// it contains whitespace, or is a capitalised word of 4+ letters. Short
/// lowercase tokens (asset ids, keys, CLDR patterns) are skipped.
bool looksLikeProse(String text) {
  if (text.contains(RegExp(r'\s'))) return true;
  return RegExp(r'^[A-Z][a-zA-Z]{3,}$').hasMatch(text);
}

/// The locales Sparkilo ships, plus the codes a hand-rolled table
/// typically reaches for. A two-letter key outside this set is far more
/// likely to be a data key than a language.
const languageCodes = <String>{
  'ar', 'bg', 'cs', 'da', 'de', 'el', 'en', 'es', 'et', 'fi', 'fr',
  'hr', 'hu', 'it', 'ja', 'ko', 'lt', 'lv', 'nb', 'nl', 'no', 'pl',
  'pt', 'ro', 'ru', 'sk', 'sl', 'sv', 'tr', 'uk', 'zh',
};

/// A `'de': 'Favoriten'` pair: quoted two-letter key, quoted value with
/// no interpolation.
final entryPattern = RegExp(
  r'''['"]([a-z]{2})['"]\s*:\s*['"]([^'"$\n]{2,})['"]''',
);

/// Language-keyed prose tables in [source], as `line → locales` records.
///
/// Entries are grouped by the brace-delimited literal they sit in: ONE
/// `'en': 'Some text'` pair is configuration (a default, a single
/// override), whereas two or more language keys carrying prose in the
/// same map is a translation table.
///
/// Pure so the self-check below can drive it with fixtures.
List<String> findLanguageKeyedTables(String source, {String path = '<src>'}) {
  final lines = const LineSplitter().convert(source);
  final found = <String>[];

  var depth = 0;
  var groupStartLine = 0;
  var hits = <String>[];

  void flush() {
    if (hits.length >= 2) {
      found.add(
        '$path:${groupStartLine + 1}  language-keyed table '
        '(${hits.length} locales: ${hits.take(4).join(', ')})',
      );
    }
    hits = <String>[];
  }

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.contains('// i18n-ignore:')) continue;

    final opens = '{'.allMatches(line).length;
    final closes = '}'.allMatches(line).length;
    if (depth == 0 && opens > 0) groupStartLine = i;

    for (final match in entryPattern.allMatches(line)) {
      final code = match.group(1)!;
      final value = match.group(2)!;
      if (!languageCodes.contains(code)) continue;
      if (!looksLikeProse(value)) continue;
      hits.add("'$code'");
    }

    depth += opens - closes;
    if (depth <= 0) {
      flush();
      depth = 0;
    }
  }
  flush();
  return found;
}

void main() {
  test('no language-keyed translation tables in Dart (#4271)', () {
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

      violations.addAll(
        findLanguageKeyedTables(entity.readAsStringSync(), path: path),
      );
    }

    violations.sort();

    expect(
      violations,
      isEmpty,
      reason:
          'A Dart map keyed by language code carrying user-facing prose is a '
          'translation table, and it bypasses the ARB coverage gate '
          'completely — #1699 checks ARB keys, and these are not ARB keys. '
          'It ships English to every locale the table forgot.\n'
          '\n'
          'Move the strings into lib/l10n/_fragments/ and resolve them '
          'through AppLocalizations at the UI boundary (LandingScreenL10n, '
          '#4269, is the pattern).\n'
          '\n'
          'Carry the EXISTING translations across by hand: '
          'tool/autofill_locales.dart propagates new keys outward from '
          'English only, so deleting a table without porting its values '
          'regresses every locale it covered to English (#4271 — that cost '
          '8 locales).\n'
          '\n'
          'Found:\n${violations.join('\n')}',
    );
  });

  // #3977's lesson: an `isEmpty` assertion passes identically whether the
  // scan works or matches nothing at all. These drive the same function
  // the gate above uses, so a blinded matcher fails here.
  group('parse fidelity — the detector actually detects', () {
    test('fires on the exact table #4269 deleted', () {
      // Verbatim shape from user_profile.dart before #4269.
      const source = '''
enum LandingScreen {
  String localizedName(String languageCode) {
    const names = {
      'favorites': {'en': 'Favorites', 'de': 'Favoriten', 'fr': 'Favoris'},
      'map': {'en': 'Map', 'de': 'Karte', 'fr': 'Carte'},
    };
    return names[key]?[languageCode] ?? key;
  }
}
''';
      final found = findLanguageKeyedTables(source, path: 'fixture.dart');
      expect(found, isNotEmpty,
          reason: 'the ten-language table that shipped English to 13 '
              'locales must be detected');
      expect(found.first, contains('language-keyed table'));
    });

    test('fires on a multi-line table', () {
      const source = '''
const labels = <String, String>{
  'en': 'Nearest stations',
  'de': 'Nächste Tankstellen',
  'fr': 'Stations les plus proches',
};
''';
      expect(findLanguageKeyedTables(source), isNotEmpty);
    });

    test('a single language entry is configuration, not a table', () {
      const source = "const fallback = {'en': 'Nearest stations'};";
      expect(findLanguageKeyedTables(source), isEmpty,
          reason: 'one entry is a default or an override, and flagging it '
              'would make the gate unusable');
    });

    test('locale → CLDR pattern maps are not prose', () {
      const source = '''
const patterns = {'en': 'MM/dd/yyyy', 'de': 'dd.MM.yyyy', 'fr': 'dd/MM/yyyy'};
''';
      expect(findLanguageKeyedTables(source), isEmpty,
          reason: 'format masks are language-neutral, not translatable '
              'prose — the same carve-out the sibling gate makes');
    });

    test('non-language two-letter keys are ignored', () {
      // Country codes keyed to prose are a different thing entirely.
      const source = '''
const stationBrands = {'aa': 'Some Brand', 'bb': 'Another Brand'};
''';
      expect(findLanguageKeyedTables(source), isEmpty);
    });

    test('an i18n-ignore line is skipped', () {
      const source = '''
const names = {
  'en': 'Favorites', 'de': 'Favoriten', // i18n-ignore: brand names
};
''';
      expect(findLanguageKeyedTables(source), isEmpty);
    });

    test('interpolated values are not literals', () {
      const source = r'''
const names = {'en': '$count items', 'de': '$count Artikel'};
''';
      expect(findLanguageKeyedTables(source), isEmpty,
          reason: 'interpolation composes runtime data, and the sibling '
              'gate excludes it for the same reason');
    });
  });
}
