import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/language/language_provider.dart';

void main() {
  group('AppLanguages.all', () {
    test('has 23 entries', () {
      expect(AppLanguages.all.length, equals(23));
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
