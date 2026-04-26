import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/domain/radius_alert_validators.dart';

void main() {
  group('RadiusAlertValidators.parseThreshold', () {
    test('parses dot-decimal strings', () {
      expect(RadiusAlertValidators.parseThreshold('1.499'),
          closeTo(1.499, 1e-9));
    });

    test('parses comma-decimal strings (continental keyboards)', () {
      expect(RadiusAlertValidators.parseThreshold('1,499'),
          closeTo(1.499, 1e-9));
    });

    test('trims whitespace before parsing', () {
      expect(RadiusAlertValidators.parseThreshold('  1.5  '),
          closeTo(1.5, 1e-9));
    });

    test('returns null for empty / whitespace-only input', () {
      expect(RadiusAlertValidators.parseThreshold(''), isNull);
      expect(RadiusAlertValidators.parseThreshold('   '), isNull);
    });

    test('returns null for unparseable input', () {
      expect(RadiusAlertValidators.parseThreshold('abc'), isNull);
      expect(RadiusAlertValidators.parseThreshold('1.2.3'), isNull);
    });

    test('parses bare integers as doubles', () {
      expect(RadiusAlertValidators.parseThreshold('2'), closeTo(2.0, 1e-9));
    });
  });

  group('RadiusAlertValidators.canSave', () {
    test('returns false when label is empty', () {
      expect(
        RadiusAlertValidators.canSave(
          label: '',
          thresholdRaw: '1.5',
          centerLat: 48.85,
          centerLng: 2.35,
          postalCode: '',
        ),
        isFalse,
      );
    });

    test('returns false when label is whitespace-only', () {
      expect(
        RadiusAlertValidators.canSave(
          label: '   ',
          thresholdRaw: '1.5',
          centerLat: 48.85,
          centerLng: 2.35,
          postalCode: '',
        ),
        isFalse,
      );
    });

    test('returns false when threshold is unparseable', () {
      expect(
        RadiusAlertValidators.canSave(
          label: 'Home diesel',
          thresholdRaw: 'abc',
          centerLat: 48.85,
          centerLng: 2.35,
          postalCode: '',
        ),
        isFalse,
      );
    });

    test('returns false when threshold is zero or negative', () {
      expect(
        RadiusAlertValidators.canSave(
          label: 'Home diesel',
          thresholdRaw: '0',
          centerLat: 48.85,
          centerLng: 2.35,
          postalCode: '',
        ),
        isFalse,
      );
      expect(
        RadiusAlertValidators.canSave(
          label: 'Home diesel',
          thresholdRaw: '-1.0',
          centerLat: 48.85,
          centerLng: 2.35,
          postalCode: '',
        ),
        isFalse,
      );
    });

    test('returns false when no GPS center AND no postal code', () {
      expect(
        RadiusAlertValidators.canSave(
          label: 'Home diesel',
          thresholdRaw: '1.5',
          centerLat: null,
          centerLng: null,
          postalCode: '',
        ),
        isFalse,
      );
    });

    test('returns true when GPS center is set', () {
      expect(
        RadiusAlertValidators.canSave(
          label: 'Home diesel',
          thresholdRaw: '1.5',
          centerLat: 48.85,
          centerLng: 2.35,
          postalCode: '',
        ),
        isTrue,
      );
    });

    test('returns true when only postal code is set (geocode later)', () {
      expect(
        RadiusAlertValidators.canSave(
          label: 'Home diesel',
          thresholdRaw: '1.5',
          centerLat: null,
          centerLng: null,
          postalCode: '34120',
        ),
        isTrue,
      );
    });

    test('treats whitespace-only postal code as missing', () {
      expect(
        RadiusAlertValidators.canSave(
          label: 'Home diesel',
          thresholdRaw: '1.5',
          centerLat: null,
          centerLng: null,
          postalCode: '   ',
        ),
        isFalse,
      );
    });

    test('accepts comma-decimal threshold', () {
      expect(
        RadiusAlertValidators.canSave(
          label: 'Home diesel',
          thresholdRaw: '1,499',
          centerLat: 48.85,
          centerLng: 2.35,
          postalCode: '',
        ),
        isTrue,
      );
    });

    test('only one of GPS or postal needs to be set', () {
      // GPS but no postal
      expect(
        RadiusAlertValidators.canSave(
          label: 'L',
          thresholdRaw: '1.5',
          centerLat: 1.0,
          centerLng: 1.0,
          postalCode: '',
        ),
        isTrue,
      );
      // Postal but no GPS
      expect(
        RadiusAlertValidators.canSave(
          label: 'L',
          thresholdRaw: '1.5',
          centerLat: null,
          centerLng: null,
          postalCode: '34120',
        ),
        isTrue,
      );
    });
  });
}
