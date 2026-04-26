import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/domain/radius_alert_form_resolver.dart';

void main() {
  group('parseRadiusAlertThreshold', () {
    test('parses dot-decimal input', () {
      expect(parseRadiusAlertThreshold('1.499'), closeTo(1.499, 1e-9));
    });

    test('normalises comma-decimal input from German/French keypads', () {
      expect(parseRadiusAlertThreshold('1,499'), closeTo(1.499, 1e-9));
    });

    test('trims surrounding whitespace', () {
      expect(parseRadiusAlertThreshold('  2.05  '), closeTo(2.05, 1e-9));
    });

    test('returns null for blank input', () {
      expect(parseRadiusAlertThreshold(''), isNull);
      expect(parseRadiusAlertThreshold('   '), isNull);
    });

    test('returns null for unparseable input', () {
      expect(parseRadiusAlertThreshold('abc'), isNull);
      expect(parseRadiusAlertThreshold('1.2.3'), isNull);
    });

    test('does not clamp negative input — caller decides', () {
      // Keeps the parser pure; canSaveRadiusAlertForm rejects <= 0.
      expect(parseRadiusAlertThreshold('-1.0'), closeTo(-1.0, 1e-9));
    });
  });

  group('canSaveRadiusAlertForm', () {
    test('rejects blank label', () {
      expect(
        canSaveRadiusAlertForm(
          label: '   ',
          thresholdRaw: '1.5',
          centerLat: 48.85,
          centerLng: 2.35,
          postalCode: '',
        ),
        isFalse,
      );
    });

    test('rejects unparseable threshold', () {
      expect(
        canSaveRadiusAlertForm(
          label: 'Home',
          thresholdRaw: 'abc',
          centerLat: 48.85,
          centerLng: 2.35,
          postalCode: '',
        ),
        isFalse,
      );
    });

    test('rejects zero or negative threshold', () {
      expect(
        canSaveRadiusAlertForm(
          label: 'Home',
          thresholdRaw: '0',
          centerLat: 48.85,
          centerLng: 2.35,
          postalCode: '',
        ),
        isFalse,
      );
      expect(
        canSaveRadiusAlertForm(
          label: 'Home',
          thresholdRaw: '-1',
          centerLat: 48.85,
          centerLng: 2.35,
          postalCode: '',
        ),
        isFalse,
      );
    });

    test('rejects when neither GPS nor postal code is set', () {
      expect(
        canSaveRadiusAlertForm(
          label: 'Home',
          thresholdRaw: '1.5',
          centerLat: null,
          centerLng: null,
          postalCode: '',
        ),
        isFalse,
      );
    });

    test('accepts when GPS coordinates are set', () {
      expect(
        canSaveRadiusAlertForm(
          label: 'Home',
          thresholdRaw: '1.5',
          centerLat: 48.85,
          centerLng: 2.35,
          postalCode: '',
        ),
        isTrue,
      );
    });

    test('accepts when postal code is set without GPS', () {
      expect(
        canSaveRadiusAlertForm(
          label: 'Home',
          thresholdRaw: '1.5',
          centerLat: null,
          centerLng: null,
          postalCode: '34120',
        ),
        isTrue,
      );
    });

    test('accepts when both GPS and postal code are present', () {
      expect(
        canSaveRadiusAlertForm(
          label: 'Home',
          thresholdRaw: '1.5',
          centerLat: 48.85,
          centerLng: 2.35,
          postalCode: '75001',
        ),
        isTrue,
      );
    });

    test('treats whitespace-only postal code as missing', () {
      expect(
        canSaveRadiusAlertForm(
          label: 'Home',
          thresholdRaw: '1.5',
          centerLat: null,
          centerLng: null,
          postalCode: '   ',
        ),
        isFalse,
      );
    });

    test('rejects when only one of lat/lng is set', () {
      // The form binds lat+lng together, but the helper should not
      // assume that — half a coordinate is unusable.
      expect(
        canSaveRadiusAlertForm(
          label: 'Home',
          thresholdRaw: '1.5',
          centerLat: 48.85,
          centerLng: null,
          postalCode: '',
        ),
        isFalse,
      );
    });
  });

  group('RadiusAlertCenterBinding.coordinatesOrZero', () {
    test('returns the GPS coordinates when both are set', () {
      const binding = RadiusAlertCenterBinding(
        lat: 48.85,
        lng: 2.35,
        source: 'GPS',
      );
      final coords = binding.coordinatesOrZero();
      expect(coords.lat, closeTo(48.85, 1e-9));
      expect(coords.lng, closeTo(2.35, 1e-9));
    });

    test('parks unbound coordinates at (0, 0) for the geocoder to fill in',
        () {
      const binding = RadiusAlertCenterBinding(
        lat: null,
        lng: null,
        source: '',
      );
      final coords = binding.coordinatesOrZero();
      expect(coords.lat, 0.0);
      expect(coords.lng, 0.0);
    });

    test('treats half-bound coordinates as unbound on the missing axis', () {
      const binding = RadiusAlertCenterBinding(
        lat: 48.85,
        lng: null,
        source: 'GPS',
      );
      final coords = binding.coordinatesOrZero();
      expect(coords.lat, closeTo(48.85, 1e-9));
      expect(coords.lng, 0.0);
    });
  });
}
