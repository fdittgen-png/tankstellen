// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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

    test('returns false when only a postal code is set — needs real GPS '
        '(#2211; postal-only used to save a dead (0,0) alert)', () {
      expect(
        RadiusAlertValidators.canSave(
          label: 'Home diesel',
          thresholdRaw: '1.5',
          centerLat: null,
          centerLng: null,
          postalCode: '34120',
        ),
        isFalse,
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

    test('GPS coordinates are required; postal code alone is not enough '
        '(#2211)', () {
      // GPS but no postal → OK
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
      // Postal but no GPS → not saveable (would be a dead (0,0) alert)
      expect(
        RadiusAlertValidators.canSave(
          label: 'L',
          thresholdRaw: '1.5',
          centerLat: null,
          centerLng: null,
          postalCode: '34120',
        ),
        isFalse,
      );
    });
  });
}
