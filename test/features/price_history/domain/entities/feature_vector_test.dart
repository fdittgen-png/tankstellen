// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/price_history/domain/entities/feature_vector.dart';

/// Verifies the [FeatureVector] contract that the future TFLite phase-2
/// model will consume (#1117). These assertions are deliberately rigid:
/// any change to map keys, types, or equality semantics requires
/// bumping [FeatureVector.schemaVersion] and is a model-breaking
/// change.
void main() {
  group('FeatureVector — value semantics', () {
    test('two vectors with the same fields are equal', () {
      final t = DateTime.utc(2026, 5, 1, 14, 30);
      final a = FeatureVector(
        hourOfDay: 14,
        dayOfWeek: 5,
        brand: 'Aral',
        countryCode: 'DE',
        isHoliday: false,
        priceEur: 1.789,
        observedAt: t,
      );
      final b = FeatureVector(
        hourOfDay: 14,
        dayOfWeek: 5,
        brand: 'Aral',
        countryCode: 'DE',
        isHoliday: false,
        priceEur: 1.789,
        observedAt: t,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('any field mismatch breaks equality', () {
      final t = DateTime.utc(2026, 5, 1, 14);
      final base = FeatureVector(
        hourOfDay: 14,
        dayOfWeek: 5,
        brand: 'Aral',
        countryCode: 'DE',
        isHoliday: false,
        priceEur: 1.789,
        observedAt: t,
      );

      expect(
        base ==
            FeatureVector(
              hourOfDay: 15,
              dayOfWeek: 5,
              brand: 'Aral',
              countryCode: 'DE',
              isHoliday: false,
              priceEur: 1.789,
              observedAt: t,
            ),
        isFalse,
      );
      expect(
        base ==
            FeatureVector(
              hourOfDay: 14,
              dayOfWeek: 5,
              brand: 'Shell',
              countryCode: 'DE',
              isHoliday: false,
              priceEur: 1.789,
              observedAt: t,
            ),
        isFalse,
      );
      expect(
        base ==
            FeatureVector(
              hourOfDay: 14,
              dayOfWeek: 5,
              brand: 'Aral',
              countryCode: 'DE',
              isHoliday: true,
              priceEur: 1.789,
              observedAt: t,
            ),
        isFalse,
      );
    });

    test('toString includes all field values for debugging', () {
      final v = FeatureVector(
        hourOfDay: 8,
        dayOfWeek: 1,
        brand: 'Total',
        countryCode: 'FR',
        isHoliday: true,
        priceEur: 1.65,
        observedAt: DateTime.utc(2026, 7, 14, 8),
      );
      final s = v.toString();
      expect(s, contains('hourOfDay: 8'));
      expect(s, contains('dayOfWeek: 1'));
      expect(s, contains('brand: Total'));
      expect(s, contains('countryCode: FR'));
      expect(s, contains('isHoliday: true'));
      expect(s, contains('priceEur: 1.65'));
    });
  });

  group('FeatureVector — toFeatureMap contract (TFLite-facing)', () {
    test('emits the documented stable key set', () {
      final v = FeatureVector(
        hourOfDay: 14,
        dayOfWeek: 5,
        brand: 'Aral',
        countryCode: 'DE',
        isHoliday: false,
        priceEur: 1.789,
        observedAt: DateTime.utc(2026, 5, 1, 14, 30),
      );
      final map = v.toFeatureMap();
      // Phase-2 model-breaking: any change to this set requires a
      // schemaVersion bump.
      expect(
        map.keys.toSet(),
        equals(<String>{
          'brand',
          'country_code',
          'day_of_week',
          'hour_of_day',
          'is_holiday',
          'observed_at',
          'price_eur',
        }),
      );
      expect(map['brand'], 'Aral');
      expect(map['country_code'], 'DE');
      expect(map['day_of_week'], 5);
      expect(map['hour_of_day'], 14);
      expect(map['is_holiday'], false);
      expect(map['observed_at'], '2026-05-01T14:30:00.000Z');
      expect(map['price_eur'], 1.789);
    });

    test('observedAt is normalised to UTC ISO-8601', () {
      // Construct in local time and ensure UTC normalisation.
      final v = FeatureVector(
        hourOfDay: 14,
        dayOfWeek: 5,
        brand: null,
        countryCode: null,
        isHoliday: false,
        priceEur: 1.0,
        observedAt: DateTime.utc(2026, 5, 1, 14, 30, 0),
      );
      final s = v.toFeatureMap()['observed_at'] as String;
      // Always ends with Z when properly normalised.
      expect(s.endsWith('Z'), isTrue);
    });

    test('null brand and null countryCode pass through as null', () {
      final v = FeatureVector(
        hourOfDay: 0,
        dayOfWeek: 7,
        brand: null,
        countryCode: null,
        isHoliday: false,
        priceEur: 1.0,
        observedAt: DateTime.utc(2026, 1, 4),
      );
      final map = v.toFeatureMap();
      expect(map['brand'], isNull);
      expect(map['country_code'], isNull);
    });

    test('schemaVersion is exposed and starts at 1', () {
      // The phase-2 model file embeds this constant; bumping it is a
      // deliberate breaking change requiring retrain.
      expect(FeatureVector.schemaVersion, 1);
    });
  });

  group('FeatureVector — JSON round-trip', () {
    test('toJson → fromJson reproduces the original vector', () {
      final original = FeatureVector(
        hourOfDay: 18,
        dayOfWeek: 6,
        brand: 'Carrefour',
        countryCode: 'FR',
        isHoliday: true,
        priceEur: 1.612,
        observedAt: DateTime.utc(2026, 7, 14, 18, 0),
      );
      final encoded = jsonEncode(original.toJson());
      final decoded =
          FeatureVector.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
      expect(decoded, equals(original));
    });

    test('fromJson tolerates int prices (e.g. 2 vs 2.0) for robustness', () {
      // jsonDecode emits int when the value happens to be whole. The
      // reader must still accept it without crashing.
      final decoded = FeatureVector.fromJson(<String, dynamic>{
        'hour_of_day': 0,
        'day_of_week': 1,
        'brand': null,
        'country_code': null,
        'is_holiday': false,
        'observed_at': '2026-01-04T00:00:00.000Z',
        'price_eur': 2, // int, not double
      });
      expect(decoded.priceEur, 2.0);
    });

    test('fromJson throws FormatException on missing required keys', () {
      expect(
        () => FeatureVector.fromJson(<String, dynamic>{
          'hour_of_day': 8,
          // missing day_of_week, etc.
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJson throws FormatException on wrong value type', () {
      expect(
        () => FeatureVector.fromJson(<String, dynamic>{
          'hour_of_day': '8', // String, not int
          'day_of_week': 1,
          'brand': null,
          'country_code': null,
          'is_holiday': false,
          'observed_at': '2026-01-04T00:00:00.000Z',
          'price_eur': 1.5,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
