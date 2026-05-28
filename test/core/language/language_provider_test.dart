// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('AppLanguages.all', () {
    // #2179 — pin the picker to the locales the app actually ships
    // instead of a magic count, so adding/removing an ARB locale that
    // isn't mirrored in AppLanguages.all fails loudly. The en_XA
    // pseudo-locale (text-expansion harness, #1699) is intentionally
    // not user-selectable, so it is excluded.
    test('exactly matches AppLocalizations.supportedLocales (minus en_XA)',
        () {
      final shipped = AppLocalizations.supportedLocales
          .where((l) => l.countryCode != 'XA')
          .map((l) => l.languageCode)
          .toSet();
      final picker = AppLanguages.all.map((l) => l.code).toSet();
      expect(picker, equals(shipped));
    });

    test('length equals the shipped locale count (no magic number)', () {
      final shippedCount = AppLocalizations.supportedLocales
          .where((l) => l.countryCode != 'XA')
          .map((l) => l.languageCode)
          .toSet()
          .length;
      expect(AppLanguages.all.length, equals(shippedCount));
    });

    test('all codes are unique (no duplicates)', () {
      final codes = AppLanguages.all.map((l) => l.code).toList();
      expect(codes.toSet().length, equals(codes.length));
    });

    test('all nativeNames are non-empty', () {
      for (final lang in AppLanguages.all) {
        expect(
          lang.nativeName.isNotEmpty,
          isTrue,
          reason: '${lang.code} should have a non-empty nativeName',
        );
      }
    });

    test('all englishNames are non-empty', () {
      for (final lang in AppLanguages.all) {
        expect(
          lang.englishName.isNotEmpty,
          isTrue,
          reason: '${lang.code} should have a non-empty englishName',
        );
      }
    });

    test('all codes are non-empty', () {
      for (final lang in AppLanguages.all) {
        expect(
          lang.code.isNotEmpty,
          isTrue,
          reason: 'Language should have a non-empty code',
        );
      }
    });
  });

  group('AppLanguages.byCode', () {
    test('returns English for code en', () {
      final en = AppLanguages.byCode('en');
      expect(en, isNotNull);
      expect(en!.code, equals('en'));
      expect(en.nativeName, equals('English'));
      expect(en.englishName, equals('English'));
    });

    test('returns Deutsch for code de', () {
      final de = AppLanguages.byCode('de');
      expect(de, isNotNull);
      expect(de!.code, equals('de'));
      expect(de.nativeName, equals('Deutsch'));
      expect(de.englishName, equals('German'));
    });

    test('returns Francais for code fr', () {
      final fr = AppLanguages.byCode('fr');
      expect(fr, isNotNull);
      expect(fr!.code, equals('fr'));
      expect(fr.englishName, equals('French'));
    });

    test('returns Italiano for code it', () {
      final it = AppLanguages.byCode('it');
      expect(it, isNotNull);
      expect(it!.code, equals('it'));
      expect(it.englishName, equals('Italian'));
    });

    test('returns Espanol for code es', () {
      final es = AppLanguages.byCode('es');
      expect(es, isNotNull);
      expect(es!.code, equals('es'));
      expect(es.englishName, equals('Spanish'));
    });

    test('returns Nederlands for code nl', () {
      final nl = AppLanguages.byCode('nl');
      expect(nl, isNotNull);
      expect(nl!.code, equals('nl'));
      expect(nl.englishName, equals('Dutch'));
    });

    test('returns Dansk for code da', () {
      final da = AppLanguages.byCode('da');
      expect(da, isNotNull);
      expect(da!.code, equals('da'));
      expect(da.englishName, equals('Danish'));
    });

    test('returns Svenska for code sv', () {
      final sv = AppLanguages.byCode('sv');
      expect(sv, isNotNull);
      expect(sv!.code, equals('sv'));
      expect(sv.englishName, equals('Swedish'));
    });

    test('returns Suomi for code fi', () {
      final fi = AppLanguages.byCode('fi');
      expect(fi, isNotNull);
      expect(fi!.code, equals('fi'));
      expect(fi.englishName, equals('Finnish'));
    });

    test('returns Polski for code pl', () {
      final pl = AppLanguages.byCode('pl');
      expect(pl, isNotNull);
      expect(pl!.code, equals('pl'));
      expect(pl.englishName, equals('Polish'));
    });

    test('returns null for unknown code', () {
      expect(AppLanguages.byCode('xx'), isNull);
      expect(AppLanguages.byCode(''), isNull);
      expect(AppLanguages.byCode('zz'), isNull);
    });
  });

  group('AppLanguage.locale', () {
    test('returns correct Locale from code', () {
      final en = AppLanguages.byCode('en')!;
      expect(en.locale.languageCode, equals('en'));

      final de = AppLanguages.byCode('de')!;
      expect(de.locale.languageCode, equals('de'));
    });
  });

  group('AppLanguages.fromSystem', () {
    test('returns a valid AppLanguage', () {
      final lang = AppLanguages.fromSystem();
      expect(lang, isNotNull);
      expect(lang.code.isNotEmpty, isTrue);
      expect(lang.nativeName.isNotEmpty, isTrue);
    });
  });
}
