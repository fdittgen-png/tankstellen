import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/services/location_search_service.dart';

/// Tests for input validation: postal code regex, input type detection,
/// and URL/input sanitization patterns used across the app.
void main() {
  // -------------------------------------------------------------------------
  // Postal code validation per country
  // -------------------------------------------------------------------------
  group('Postal code validation', () {
    group('DE (5 digits)', () {
      final regex = RegExp(Countries.germany.postalCodeRegex);

      test('valid codes', () {
        expect(regex.hasMatch('10115'), isTrue);
        expect(regex.hasMatch('80331'), isTrue);
        expect(regex.hasMatch('01067'), isTrue);
        expect(regex.hasMatch('99999'), isTrue);
      });

      test('invalid codes', () {
        expect(regex.hasMatch('1011'), isFalse); // too short
        expect(regex.hasMatch('101156'), isFalse); // too long
        expect(regex.hasMatch('ABCDE'), isFalse); // letters
        expect(regex.hasMatch('1011 5'), isFalse); // space
        expect(regex.hasMatch(''), isFalse);
      });
    });

    group('FR (5 digits)', () {
      final regex = RegExp(Countries.france.postalCodeRegex);

      test('valid codes', () {
        expect(regex.hasMatch('75001'), isTrue);
        expect(regex.hasMatch('34120'), isTrue);
        expect(regex.hasMatch('00100'), isTrue);
      });

      test('invalid codes', () {
        expect(regex.hasMatch('7500'), isFalse);
        expect(regex.hasMatch('750011'), isFalse);
        expect(regex.hasMatch('ABCDE'), isFalse);
      });
    });

    group('AT (4 digits)', () {
      final regex = RegExp(Countries.austria.postalCodeRegex);

      test('valid codes', () {
        expect(regex.hasMatch('1010'), isTrue);
        expect(regex.hasMatch('5020'), isTrue);
        expect(regex.hasMatch('9999'), isTrue);
      });

      test('invalid codes', () {
        expect(regex.hasMatch('101'), isFalse);
        expect(regex.hasMatch('10100'), isFalse);
        expect(regex.hasMatch('ABCD'), isFalse);
      });
    });

    group('GB (alphanumeric)', () {
      final regex = RegExp(Countries.unitedKingdom.postalCodeRegex);

      test('valid postcodes', () {
        expect(regex.hasMatch('SW1A 1AA'), isTrue);
        expect(regex.hasMatch('EC1A 1BB'), isTrue);
        expect(regex.hasMatch('W1A 0AX'), isTrue);
        expect(regex.hasMatch('M1 1AE'), isTrue);
        expect(regex.hasMatch('B33 8TH'), isTrue);
        // Without space
        expect(regex.hasMatch('SW1A1AA'), isTrue);
      });

      test('invalid postcodes', () {
        expect(regex.hasMatch('12345'), isFalse);
        expect(regex.hasMatch(''), isFalse);
        expect(regex.hasMatch('INVALID'), isFalse);
      });
    });

    group('ES (5 digits)', () {
      final regex = RegExp(Countries.spain.postalCodeRegex);

      test('valid codes', () {
        expect(regex.hasMatch('28001'), isTrue);
        expect(regex.hasMatch('08001'), isTrue);
      });

      test('invalid codes', () {
        expect(regex.hasMatch('2800'), isFalse);
        expect(regex.hasMatch('280011'), isFalse);
      });
    });

    group('IT (5 digits)', () {
      final regex = RegExp(Countries.italy.postalCodeRegex);

      test('valid codes', () {
        expect(regex.hasMatch('00100'), isTrue);
        expect(regex.hasMatch('20121'), isTrue);
      });

      test('invalid codes', () {
        expect(regex.hasMatch('0010'), isFalse);
        expect(regex.hasMatch('ABCDE'), isFalse);
      });
    });

    group('DK (4 digits)', () {
      final regex = RegExp(Countries.denmark.postalCodeRegex);

      test('valid codes', () {
        expect(regex.hasMatch('1000'), isTrue);
        expect(regex.hasMatch('8000'), isTrue);
      });

      test('invalid codes', () {
        expect(regex.hasMatch('100'), isFalse);
        expect(regex.hasMatch('10000'), isFalse);
      });
    });

    group('AR (4 digits)', () {
      final regex = RegExp(Countries.argentina.postalCodeRegex);

      test('valid codes', () {
        expect(regex.hasMatch('1000'), isTrue);
        expect(regex.hasMatch('5000'), isTrue);
      });

      test('invalid codes', () {
        expect(regex.hasMatch('10000'), isFalse);
        expect(regex.hasMatch('100'), isFalse);
      });
    });

    group('PT (4 digits or 4-3 format)', () {
      final regex = RegExp(Countries.portugal.postalCodeRegex);

      test('valid codes', () {
        expect(regex.hasMatch('1000'), isTrue);
        expect(regex.hasMatch('1000-001'), isTrue);
        expect(regex.hasMatch('4200-072'), isTrue);
      });

      test('invalid codes', () {
        expect(regex.hasMatch('100'), isFalse);
        expect(regex.hasMatch('ABCD'), isFalse);
        expect(regex.hasMatch('1000-'), isFalse);
        expect(regex.hasMatch('1000-01'), isFalse);
      });
    });

    group('AU (4 digits)', () {
      final regex = RegExp(Countries.australia.postalCodeRegex);

      test('valid codes', () {
        expect(regex.hasMatch('2000'), isTrue);
        expect(regex.hasMatch('3000'), isTrue);
      });

      test('invalid codes', () {
        expect(regex.hasMatch('200'), isFalse);
        expect(regex.hasMatch('20000'), isFalse);
      });
    });

    group('MX (5 digits)', () {
      final regex = RegExp(Countries.mexico.postalCodeRegex);

      test('valid codes', () {
        expect(regex.hasMatch('06600'), isTrue);
        expect(regex.hasMatch('01000'), isTrue);
      });

      test('invalid codes', () {
        expect(regex.hasMatch('0660'), isFalse);
        expect(regex.hasMatch('066001'), isFalse);
      });
    });
  });

  // -------------------------------------------------------------------------
  // LocationSearchService.detectInputType
  // -------------------------------------------------------------------------
  group('LocationSearchService.detectInputType', () {
    // We cannot instantiate LocationSearchService without a CacheManager,
    // but we can test the static-like logic by creating a minimal wrapper.
    late _TestableInputDetector detector;

    setUp(() {
      detector = _TestableInputDetector();
    });

    test('empty input returns GPS', () {
      expect(
        detector.detectInputType('', Countries.germany),
        LocationInputType.gps,
      );
      expect(
        detector.detectInputType('   ', Countries.france),
        LocationInputType.gps,
      );
    });

    test('valid postal code returns ZIP', () {
      expect(
        detector.detectInputType('10115', Countries.germany),
        LocationInputType.zip,
      );
      expect(
        detector.detectInputType('75001', Countries.france),
        LocationInputType.zip,
      );
      expect(
        detector.detectInputType('1010', Countries.austria),
        LocationInputType.zip,
      );
      expect(
        detector.detectInputType('SW1A 1AA', Countries.unitedKingdom),
        LocationInputType.zip,
      );
    });

    test('partial numeric input returns ZIP (user still typing)', () {
      expect(
        detector.detectInputType('101', Countries.germany),
        LocationInputType.zip,
      );
      expect(
        detector.detectInputType('7', Countries.france),
        LocationInputType.zip,
      );
    });

    test('text input returns city', () {
      expect(
        detector.detectInputType('Berlin', Countries.germany),
        LocationInputType.city,
      );
      expect(
        detector.detectInputType('Paris', Countries.france),
        LocationInputType.city,
      );
      expect(
        detector.detectInputType('London', Countries.unitedKingdom),
        LocationInputType.city,
      );
    });
  });

  // -------------------------------------------------------------------------
  // URL sanitization patterns
  // -------------------------------------------------------------------------
  group('URL sanitization', () {
    test('stripping whitespace from URLs', () {
      const rawUrl = '  https://example.com/path  \n';
      final sanitized = rawUrl.trim().replaceAll('\n', '').replaceAll('\r', '');
      expect(sanitized, 'https://example.com/path');
    });

    test('rejecting URLs with invalid schemes', () {
      final validSchemes = ['http', 'https'];
      bool isValidScheme(String url) {
        final uri = Uri.tryParse(url);
        if (uri == null) return false;
        return validSchemes.contains(uri.scheme);
      }

      expect(isValidScheme('https://example.com'), isTrue);
      expect(isValidScheme('http://example.com'), isTrue);
      expect(isValidScheme('ftp://example.com'), isFalse);
      expect(isValidScheme('javascript:alert(1)'), isFalse);
      expect(isValidScheme(''), isFalse);
      expect(isValidScheme('not-a-url'), isFalse);
    });

    test('Uri.tryParse handles malformed URLs gracefully', () {
      // These should not throw, just return null or an invalid Uri.
      expect(Uri.tryParse(''), isNotNull); // Empty string is valid empty URI
      expect(Uri.tryParse('http://'), isNotNull);
      // '://' is truly malformed -- tryParse returns null, not an exception.
      expect(Uri.tryParse('://'), isNull);
    });
  });
}

/// Replicates LocationSearchService.detectInputType logic for unit testing
/// without requiring CacheManager/Dio dependencies.
class _TestableInputDetector {
  LocationInputType detectInputType(String input, CountryConfig country) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return LocationInputType.gps;
    if (RegExp(country.postalCodeRegex).hasMatch(trimmed)) {
      return LocationInputType.zip;
    }
    if (trimmed.codeUnitAt(0) >= 48 && trimmed.codeUnitAt(0) <= 57) {
      return LocationInputType.zip;
    }
    return LocationInputType.city;
  }
}
