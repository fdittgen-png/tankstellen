import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';

void main() {
  group('Countries.all', () {
    test('contains exactly 17 countries', () {
      expect(Countries.all.length, equals(17));
    });

    test('contains all expected country codes', () {
      final codes = Countries.all.map((c) => c.code).toSet();
      expect(codes, containsAll(
        ['DE', 'FR', 'AT', 'ES', 'IT', 'DK', 'AR', 'PT', 'GB', 'AU', 'MX', 'LU', 'SI', 'KR', 'CL', 'GR', 'RO'],
      ));
    });

    test('Germany is first in the list', () {
      expect(Countries.all.first.code, equals('DE'));
    });
  });

  group('Countries.byCode', () {
    test('returns correct config for DE', () {
      final de = Countries.byCode('DE');
      expect(de, isNotNull);
      expect(de!.code, equals('DE'));
      expect(de.name, equals('Deutschland'));
    });

    test('returns correct config for FR', () {
      final fr = Countries.byCode('FR');
      expect(fr, isNotNull);
      expect(fr!.code, equals('FR'));
      expect(fr.name, equals('France'));
    });

    test('returns correct config for AT', () {
      final at = Countries.byCode('AT');
      expect(at, isNotNull);
      expect(at!.code, equals('AT'));
      expect(at.name, contains('sterreich'));
    });

    test('returns correct config for ES', () {
      final es = Countries.byCode('ES');
      expect(es, isNotNull);
      expect(es!.code, equals('ES'));
    });

    test('returns correct config for IT', () {
      final it = Countries.byCode('IT');
      expect(it, isNotNull);
      expect(it!.code, equals('IT'));
    });

    test('returns correct config for DK', () {
      final dk = Countries.byCode('DK');
      expect(dk, isNotNull);
      expect(dk!.code, equals('DK'));
      expect(dk.currency, equals('DKK'));
    });

    test('returns correct config for AR', () {
      final ar = Countries.byCode('AR');
      expect(ar, isNotNull);
      expect(ar!.code, equals('AR'));
      expect(ar.currency, equals('ARS'));
    });

    test('returns null for unknown code', () {
      expect(Countries.byCode('XX'), isNull);
      expect(Countries.byCode('US'), isNull);
      expect(Countries.byCode(''), isNull);
    });

    test('is case-sensitive (lowercase returns null)', () {
      expect(Countries.byCode('de'), isNull);
      expect(Countries.byCode('fr'), isNull);
    });
  });

  group('Countries.fromLocale', () {
    test('extracts country from locale string like de_DE', () {
      final config = Countries.fromLocale('de_DE');
      expect(config.code, equals('DE'));
    });

    test('extracts country from locale string like fr_FR', () {
      final config = Countries.fromLocale('fr_FR');
      expect(config.code, equals('FR'));
    });

    test('extracts country from locale string like es_ES', () {
      final config = Countries.fromLocale('es_ES');
      expect(config.code, equals('ES'));
    });

    test('extracts country from locale string like it_IT', () {
      final config = Countries.fromLocale('it_IT');
      expect(config.code, equals('IT'));
    });

    test('extracts country from locale string like da_DK', () {
      final config = Countries.fromLocale('da_DK');
      expect(config.code, equals('DK'));
    });

    test('falls back to Germany for unknown locale', () {
      final config = Countries.fromLocale('en_US');
      expect(config.code, equals('DE'));
    });

    test('falls back to Germany for short/invalid locale', () {
      final config = Countries.fromLocale('xx');
      expect(config.code, equals('DE'));
    });

    test('handles uppercase two-letter code directly', () {
      final config = Countries.fromLocale('FR');
      expect(config.code, equals('FR'));
    });
  });

  group('CountryConfig fields', () {
    test('each country has non-empty code, name, flag', () {
      for (final country in Countries.all) {
        expect(
          country.code.isNotEmpty,
          isTrue,
          reason: 'Country should have a non-empty code',
        );
        expect(
          country.name.isNotEmpty,
          isTrue,
          reason: '${country.code} should have a non-empty name',
        );
        expect(
          country.flag.isNotEmpty,
          isTrue,
          reason: '${country.code} should have a non-empty flag',
        );
      }
    });

    test('each country has non-empty fuelTypes list', () {
      for (final country in Countries.all) {
        expect(
          country.fuelTypes.isNotEmpty,
          isTrue,
          reason: '${country.code} should have at least one fuel type',
        );
      }
    });

    test('each country has non-empty examplePostalCode', () {
      for (final country in Countries.all) {
        expect(
          country.examplePostalCode.isNotEmpty,
          isTrue,
          reason: '${country.code} should have a non-empty examplePostalCode',
        );
      }
    });

    test('each country has non-empty exampleCity', () {
      for (final country in Countries.all) {
        expect(
          country.exampleCity.isNotEmpty,
          isTrue,
          reason: '${country.code} should have a non-empty exampleCity',
        );
      }
    });

    test('Germany requires API key', () {
      expect(Countries.germany.requiresApiKey, isTrue);
    });

    test('France does not require API key', () {
      expect(Countries.france.requiresApiKey, isFalse);
    });

    test('most European countries use EUR', () {
      expect(Countries.germany.currency, equals('EUR'));
      expect(Countries.france.currency, equals('EUR'));
      expect(Countries.austria.currency, equals('EUR'));
      expect(Countries.spain.currency, equals('EUR'));
      expect(Countries.italy.currency, equals('EUR'));
    });

    test('Denmark uses DKK with kr symbol', () {
      expect(Countries.denmark.currency, equals('DKK'));
      expect(Countries.denmark.currencySymbol, equals('kr'));
    });

    test('Argentina uses ARS', () {
      expect(Countries.argentina.currency, equals('ARS'));
    });
  });

  group('CountryConfig postal code regex', () {
    test('each example postal code matches its own regex', () {
      for (final country in Countries.all) {
        final regex = RegExp(country.postalCodeRegex);
        expect(
          regex.hasMatch(country.examplePostalCode),
          isTrue,
          reason:
              '${country.code} examplePostalCode "${country.examplePostalCode}" '
              'should match regex "${country.postalCodeRegex}"',
        );
      }
    });

    test('DE regex matches 5-digit codes', () {
      final regex = RegExp(Countries.germany.postalCodeRegex);
      expect(regex.hasMatch('10115'), isTrue);
      expect(regex.hasMatch('80331'), isTrue);
      expect(regex.hasMatch('1011'), isFalse);
      expect(regex.hasMatch('101156'), isFalse);
      expect(regex.hasMatch('ABCDE'), isFalse);
    });

    test('FR regex matches 5-digit codes', () {
      final regex = RegExp(Countries.france.postalCodeRegex);
      expect(regex.hasMatch('75001'), isTrue);
      expect(regex.hasMatch('34120'), isTrue);
      expect(regex.hasMatch('7500'), isFalse);
    });

    test('AT regex matches 4-digit codes', () {
      final regex = RegExp(Countries.austria.postalCodeRegex);
      expect(regex.hasMatch('1010'), isTrue);
      expect(regex.hasMatch('5020'), isTrue);
      expect(regex.hasMatch('10100'), isFalse);
      expect(regex.hasMatch('101'), isFalse);
    });

    test('ES regex matches 5-digit codes', () {
      final regex = RegExp(Countries.spain.postalCodeRegex);
      expect(regex.hasMatch('28001'), isTrue);
      expect(regex.hasMatch('2800'), isFalse);
    });

    test('IT regex matches 5-digit codes', () {
      final regex = RegExp(Countries.italy.postalCodeRegex);
      expect(regex.hasMatch('00100'), isTrue);
      expect(regex.hasMatch('20121'), isTrue);
    });

    test('DK regex matches 4-digit codes', () {
      final regex = RegExp(Countries.denmark.postalCodeRegex);
      expect(regex.hasMatch('1000'), isTrue);
      expect(regex.hasMatch('100'), isFalse);
    });

    test('AR regex matches 4-digit codes', () {
      final regex = RegExp(Countries.argentina.postalCodeRegex);
      expect(regex.hasMatch('1000'), isTrue);
      expect(regex.hasMatch('10000'), isFalse);
    });
  });
}
