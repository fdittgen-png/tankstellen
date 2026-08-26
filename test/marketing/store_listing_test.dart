// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3821 — store copy is shipped text that no compiler ever sees, so the only
// thing standing between a typo and a public listing is a test.
//
// Two real gaps this closes:
//
//  1. `play-store-listing.yml` validates ONLY en-US, de-DE and fr-FR. An
//     over-length es-ES/it-IT/pt-PT description would sail through CI and be
//     rejected by Play (or silently truncated) at deploy time.
//  2. While writing the pt-PT copy, two Cyrillic characters were typed in
//     place of "não". Nothing in the repo would have caught that before it
//     reached a store listing.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Play + F-Droid share the same Android copy; both trees are checked.
const androidTrees = <String>[
  'docs/play-store/metadata/android',
  'fastlane/metadata/android',
];

const androidLocales = <String>[
  'en-US',
  'de-DE',
  'fr-FR',
  'es-ES',
  'it-IT',
  'pt-PT',
];

/// The App Store tree uses `it`, not `it-IT`.
const iosLocales = <String, String>{
  'en-US': 'en-US',
  'de-DE': 'de-DE',
  'fr-FR': 'fr-FR',
  'es-ES': 'es-ES',
  'it-IT': 'it',
  'pt-PT': 'pt-PT',
};

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('Play / F-Droid listing budgets (#3821)', () {
    for (final tree in androidTrees) {
      for (final locale in androidLocales) {
        test('$tree/$locale fits Play\'s byte budgets', () {
          final short = _read('$tree/$locale/short_description.txt');
          final full = _read('$tree/$locale/full_description.txt');
          final title = _read('$tree/$locale/title.txt');

          // play-store-listing.yml measures with `wc -c`, so the budget is
          // BYTES. Accented locales are exactly where a character count
          // would quietly under-report.
          expect(utf8.encode(title).length, lessThanOrEqualTo(30),
              reason: 'Play title budget is 30');
          expect(utf8.encode(short).length, lessThanOrEqualTo(80),
              reason: 'Play short description budget is 80');
          expect(utf8.encode(full).length, lessThanOrEqualTo(4000),
              reason: 'Play full description budget is 4000');

          expect(short.trim(), isNotEmpty);
          expect(full.trim(), isNotEmpty);
        });
      }
    }

    test('Play and F-Droid ship IDENTICAL copy', () {
      for (final locale in androidLocales) {
        for (final file in ['short_description.txt', 'full_description.txt']) {
          expect(_read('${androidTrees[0]}/$locale/$file'),
              _read('${androidTrees[1]}/$locale/$file'),
              reason: 'the two Android trees drifted for $locale/$file — a '
                  'reader comparing the Play and F-Droid pages sees two '
                  'different pitches for the same app');
        }
      }
    });
  });

  group('App Store listing budgets (#3821)', () {
    iosLocales.forEach((label, dir) {
      test('$label fits Apple\'s character budgets', () {
        // Apple counts characters, not bytes — the opposite of Play.
        expect(_read('ios/fastlane/metadata/$dir/subtitle.txt').length,
            lessThanOrEqualTo(30),
            reason: 'App Store subtitle budget is 30 characters');
        expect(_read('ios/fastlane/metadata/$dir/promotional_text.txt').length,
            lessThanOrEqualTo(170),
            reason: 'App Store promotional text budget is 170 characters');
        expect(_read('ios/fastlane/metadata/$dir/description.txt').length,
            lessThanOrEqualTo(4000),
            reason: 'App Store description budget is 4000 characters');
      });
    });
  });

  group('copy hygiene (#3821)', () {
    Iterable<String> everyCopyFile() sync* {
      for (final tree in androidTrees) {
        for (final locale in androidLocales) {
          yield '$tree/$locale/short_description.txt';
          yield '$tree/$locale/full_description.txt';
        }
      }
      for (final dir in iosLocales.values) {
        yield 'ios/fastlane/metadata/$dir/subtitle.txt';
        yield 'ios/fastlane/metadata/$dir/promotional_text.txt';
        yield 'ios/fastlane/metadata/$dir/description.txt';
      }
    }

    test('no stray Cyrillic or Greek slips into Latin-script copy', () {
      // Caught for real: "не" typed for "não" in the pt-PT copy.
      final nonLatin = RegExp(r'[Ͱ-ϿЀ-ӿ]');
      for (final path in everyCopyFile()) {
        final match = nonLatin.firstMatch(_read(path));
        expect(match, isNull,
            reason: '$path contains non-Latin "${match?.group(0)}" — a '
                'typo of this shape is invisible on review and ships '
                'straight to a public listing');
      }
    });

    test('copy stays currency-neutral', () {
      // None of the 17 supported countries is the US, and they span EUR,
      // GBP, AUD, MXN, CLP and KRW — a hard-coded symbol is wrong for a
      // large share of readers.
      final currency = RegExp(r'[€£$¥₩]');
      for (final path in everyCopyFile()) {
        expect(currency.hasMatch(_read(path)), isFalse,
            reason: '$path names a currency; the savings framing must work '
                'in every supported market');
      }
    });

    test('files carry no trailing newline, matching the tree convention', () {
      for (final path in everyCopyFile()) {
        final text = _read(path);
        expect(text.endsWith('\n'), isFalse,
            reason: '$path gained a trailing newline — it counts against '
                'the byte budget Play enforces');
      }
    });
  });
}
