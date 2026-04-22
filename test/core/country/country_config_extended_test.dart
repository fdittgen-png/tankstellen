import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';

void main() {
  group('Countries.byCode for all 13 countries', () {
    final expectedCodes = [
      'DE', 'FR', 'AT', 'ES', 'IT', 'DK', 'AR', 'PT', 'GB', 'AU', 'MX', 'LU', 'SI',
    ];

    for (final code in expectedCodes) {
      test('byCode("$code") returns non-null config with matching code', () {
        final config = Countries.byCode(code);
        expect(config, isNotNull, reason: '$code should be found');
        expect(config!.code, code);
      });
    }

    test('byCode returns null for unknown codes', () {
      expect(Countries.byCode('XX'), isNull);
      expect(Countries.byCode('US'), isNull);
      expect(Countries.byCode('CN'), isNull);
      expect(Countries.byCode(''), isNull);
      expect(Countries.byCode('ZZ'), isNull);
    });

    test('byCode is case-sensitive', () {
      expect(Countries.byCode('de'), isNull);
      expect(Countries.byCode('fr'), isNull);
      expect(Countries.byCode('De'), isNull);
    });
  });

  group('Country configs have correct API providers', () {
    test('Germany uses Tankerkonig', () {
      expect(Countries.germany.apiProvider, contains('Tankerkönig'));
    });

    test('France uses Prix-Carburants', () {
      expect(Countries.france.apiProvider, contains('Prix-Carburants'));
    });

    test('Austria uses E-Control', () {
      expect(Countries.austria.apiProvider, contains('E-Control'));
    });

    test('Spain uses MITECO', () {
      expect(Countries.spain.apiProvider, contains('MITECO'));
    });

    test('Italy uses MISE', () {
      expect(Countries.italy.apiProvider, contains('MISE'));
    });

    test('Denmark has an API provider set', () {
      expect(Countries.denmark.apiProvider, isNotNull);
      expect(Countries.denmark.apiProvider!.isNotEmpty, isTrue);
    });

    test('Argentina uses Secretaria de Energia', () {
      expect(Countries.argentina.apiProvider, contains('Energía'));
    });

    test('Portugal uses DGEG', () {
      expect(Countries.portugal.apiProvider, contains('DGEG'));
    });

    test('UK uses CMA Fuel Finder', () {
      expect(Countries.unitedKingdom.apiProvider, contains('CMA'));
    });

    test('Australia uses FuelCheck NSW', () {
      expect(Countries.australia.apiProvider, contains('FuelCheck'));
    });

    test('Mexico uses CRE', () {
      expect(Countries.mexico.apiProvider, contains('CRE'));
    });

    test('Slovenia uses goriva.si', () {
      expect(Countries.slovenia.apiProvider, contains('goriva.si'));
    });
  });

  group('Country configs currency correctness', () {
    test('Eurozone countries all use EUR', () {
      final euroCountries = [
        Countries.germany,
        Countries.france,
        Countries.austria,
        Countries.spain,
        Countries.italy,
        Countries.portugal,
      ];
      for (final c in euroCountries) {
        expect(c.currency, 'EUR', reason: '${c.code} should use EUR');
        expect(c.currencySymbol, '\u20ac',
            reason: '${c.code} should use euro sign');
      }
    });

    test('Non-euro countries have correct currencies', () {
      expect(Countries.denmark.currency, 'DKK');
      expect(Countries.argentina.currency, 'ARS');
      expect(Countries.unitedKingdom.currency, 'GBP');
      expect(Countries.australia.currency, 'AUD');
      expect(Countries.mexico.currency, 'MXN');
    });
  });

  group('Postal code regex validation', () {
    test('UK regex accepts valid postcodes', () {
      final regex = RegExp(Countries.unitedKingdom.postalCodeRegex);
      expect(regex.hasMatch('SW1A 1AA'), isTrue);
      expect(regex.hasMatch('EC1A 1BB'), isTrue);
      expect(regex.hasMatch('W1A 0AX'), isTrue);
      expect(regex.hasMatch('M1 1AE'), isTrue);
      expect(regex.hasMatch('B33 8TH'), isTrue);
    });

    test('UK regex rejects invalid postcodes', () {
      final regex = RegExp(Countries.unitedKingdom.postalCodeRegex);
      expect(regex.hasMatch('12345'), isFalse);
      expect(regex.hasMatch(''), isFalse);
    });

    test('PT regex accepts both 4-digit and 7-digit formats', () {
      final regex = RegExp(Countries.portugal.postalCodeRegex);
      expect(regex.hasMatch('1000'), isTrue);
      expect(regex.hasMatch('1000-001'), isTrue);
      expect(regex.hasMatch('4200-072'), isTrue);
    });

    test('PT regex rejects invalid formats', () {
      final regex = RegExp(Countries.portugal.postalCodeRegex);
      expect(regex.hasMatch('100'), isFalse);
      expect(regex.hasMatch('ABCD'), isFalse);
    });

    test('AU regex matches 4-digit codes', () {
      final regex = RegExp(Countries.australia.postalCodeRegex);
      expect(regex.hasMatch('2000'), isTrue);
      expect(regex.hasMatch('3000'), isTrue);
      expect(regex.hasMatch('200'), isFalse);
      expect(regex.hasMatch('20000'), isFalse);
    });

    test('MX regex matches 5-digit codes', () {
      final regex = RegExp(Countries.mexico.postalCodeRegex);
      expect(regex.hasMatch('06600'), isTrue);
      expect(regex.hasMatch('01000'), isTrue);
      expect(regex.hasMatch('0660'), isFalse);
    });
  });

  group('Countries.fromLocale for new countries', () {
    test('pt_PT maps to Portugal', () {
      final config = Countries.fromLocale('pt_PT');
      expect(config.code, 'PT');
    });

    test('en_GB maps to United Kingdom', () {
      final config = Countries.fromLocale('en_GB');
      expect(config.code, 'GB');
    });

    test('en_AU maps to Australia', () {
      final config = Countries.fromLocale('en_AU');
      expect(config.code, 'AU');
    });

    test('es_MX maps to Mexico', () {
      final config = Countries.fromLocale('es_MX');
      expect(config.code, 'MX');
    });

    test('es_AR maps to Argentina', () {
      final config = Countries.fromLocale('es_AR');
      expect(config.code, 'AR');
    });

    test('unknown locale falls back to Germany', () {
      expect(Countries.fromLocale('ja_JP').code, 'DE');
      expect(Countries.fromLocale('zh_CN').code, 'DE');
      expect(Countries.fromLocale('en_US').code, 'DE');
    });
  });

  group('CountryConfig requiresApiKey', () {
    test('only Germany requires an API key', () {
      for (final country in Countries.all) {
        if (country.code == 'DE') {
          expect(country.requiresApiKey, isTrue,
              reason: 'DE requires API key');
          expect(country.apiKeyRegistrationUrl, isNotNull);
        } else {
          expect(country.requiresApiKey, isFalse,
              reason: '${country.code} should not require API key');
        }
      }
    });
  });

  group('CountryConfig attribution', () {
    test('every country has attribution text', () {
      for (final country in Countries.all) {
        expect(country.attribution, isNotNull,
            reason: '${country.code} should have attribution');
        expect(country.attribution!.isNotEmpty, isTrue,
            reason: '${country.code} attribution should not be empty');
      }
    });
  });

  group('CountryConfig postalCodeLength', () {
    test('matches example postal code length (excluding separators)', () {
      for (final country in Countries.all) {
        // UK and PT have variable-length postcodes, skip strict check.
        if (country.code == 'GB' || country.code == 'PT') continue;

        expect(
          country.examplePostalCode.length,
          country.postalCodeLength,
          reason:
              '${country.code} example "${country.examplePostalCode}" '
              'should be ${country.postalCodeLength} chars',
        );
      }
    });
  });
}
