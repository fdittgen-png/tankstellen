// Tests for the predictive widget variant (#1121).
//
// Two pure-Dart concerns are exercised here, both running entirely off the
// platform channel so the suite stays under the worker push budget:
//
//   1. `buildPredictivePayload` — the helper that decides whether the widget
//      row should render the second "best time to fill" line at all. Its
//      null-fallback rules are the heart of the "Falls back gracefully if
//      model confidence is low" acceptance bullet.
//
//   2. `HomeWidgetService.compactStationDataForTest` integration — proves the
//      predictive fields actually land in the JSON the Kotlin renderer
//      reads, alongside the existing favourites parity fields.
//
// `widgetVariants` is also covered for the "Variant selectable in widget
// config" round-trip — the const list is what the configure activity
// enumerates, and the values must stay in sync with the Kotlin
// VARIANT_DEFAULT / VARIANT_PREDICTIVE constants.

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/price_history/domain/entities/price_prediction.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/widget/data/home_widget_service.dart';
import 'package:tankstellen/features/widget/data/predictive_payload.dart';
import 'package:tankstellen/features/widget/data/widget_variants.dart';

PricePrediction _prediction({
  required double potentialSaving,
  String recommendation = 'Prices typically drop Tuesday 6-8 PM',
  int bestHour = 18,
  int bestDayOfWeek = 2,
}) =>
    PricePrediction(
      recommendation: recommendation,
      potentialSaving: potentialSaving,
      bestHour: bestHour,
      bestDayOfWeek: bestDayOfWeek,
      hourlyAverages: const [],
      dailyAverages: const [],
    );

void main() {
  group('widgetVariants (#1121 — variant selectable in config)', () {
    test('exposes default + predictive identifiers', () {
      expect(widgetVariants, hasLength(2));
      expect(
        widgetVariants,
        containsAll(<String>['default', 'predictive']),
      );
    });

    test('defaultWidgetVariant is one of the advertised variants', () {
      expect(widgetVariants, contains(defaultWidgetVariant));
    });

    test('predictiveWidgetVariant is one of the advertised variants', () {
      expect(widgetVariants, contains(predictiveWidgetVariant));
    });

    test('default + predictive constants are stable strings (Kotlin parity)',
        () {
      // The Kotlin StationWidgetRenderer reads these literal values from
      // SharedPreferences. If the strings drift, the configure activity
      // writes one value while the renderer reads another and the variant
      // silently regresses to default. Lock the literals here.
      expect(defaultWidgetVariant, 'default');
      expect(predictiveWidgetVariant, 'predictive');
    });
  });

  group('buildPredictivePayload (#1121 — graceful fallback rules)', () {
    test('renders compact predictive payload when prediction is actionable',
        () {
      final payload = buildPredictivePayload(
        currentPrice: 1.849,
        prediction: _prediction(potentialSaving: 0.05),
      );

      expect(payload, isNotNull);
      expect(payload!['predictive_now_price'], 1.849);
      expect(payload['predictive_best_label'],
          'Prices typically drop Tuesday 6-8 PM');
      // 1.849 - 0.05 = 1.799, rounded to 3 decimals.
      expect(payload['predictive_best_price'], 1.799);
      expect(payload['predictive_potential_saving'], 0.05);
    });

    test('falls back (returns null) when prediction is null', () {
      final payload = buildPredictivePayload(
        currentPrice: 1.849,
        prediction: null,
      );
      expect(payload, isNull,
          reason:
              'Predictor returns null when <10 history records — must signal fallback.');
    });

    test('falls back when potentialSaving is null', () {
      final payload = buildPredictivePayload(
        currentPrice: 1.849,
        // potentialSaving: null is the predictor's "no meaningful swing" signal.
        prediction: const PricePrediction(
          recommendation: 'Prices typically drop Tuesday 6-8 PM',
          potentialSaving: null,
          bestHour: 18,
          bestDayOfWeek: 2,
          hourlyAverages: [],
          dailyAverages: [],
        ),
      );
      expect(payload, isNull);
    });

    test('falls back when potentialSaving is below the 0.001 floor', () {
      // Mirrors the predictor's own filter; we duplicate it here so the
      // fallback contract stands even if the predictor is later relaxed.
      final payload = buildPredictivePayload(
        currentPrice: 1.849,
        prediction: _prediction(potentialSaving: 0.0005),
      );
      expect(payload, isNull);
    });

    test('falls back when current price is unknown', () {
      final payload = buildPredictivePayload(
        currentPrice: null,
        prediction: _prediction(potentialSaving: 0.05),
      );
      expect(payload, isNull,
          reason:
              'Without a current price we cannot render "now …" and the row '
              'must show only the default appearance.');
    });
  });

  group('HomeWidgetService.compactStationDataForTest predictive integration',
      () {
    const station = {
      'brand': 'Shell',
      'name': 'Shell Berlin',
      'street': 'Oranienstr. 138',
      'postCode': '10969',
      'place': 'Berlin',
      'lat': 52.504122,
      'lng': 13.408138,
      'e10': 1.849,
      'isOpen': true,
    };

    test('attaches predictive_* fields when predictor returns a prediction',
        () {
      PricePrediction? predictor(String id, FuelType fuel) {
        expect(id, 'de-abc');
        expect(fuel, FuelType.e10);
        return _prediction(potentialSaving: 0.05);
      }

      final out = HomeWidgetService.compactStationDataForTest(
        'de-abc',
        station,
        preferredFuelType: FuelType.e10,
        pricePredictor: predictor,
      );

      expect(out['predictive_now_price'], 1.849);
      expect(out['predictive_best_label'],
          'Prices typically drop Tuesday 6-8 PM');
      expect(out['predictive_best_price'], 1.799);
      expect(out['predictive_potential_saving'], 0.05);
      // Default fields still present so the renderer can fall back row-by-row.
      expect(out['e10'], 1.849);
      expect(out['preferred_fuel_code'], 'e10');
    });

    test('omits predictive_* fields when predictor returns null', () {
      PricePrediction? predictor(String id, FuelType fuel) => null;

      final out = HomeWidgetService.compactStationDataForTest(
        'de-abc',
        station,
        preferredFuelType: FuelType.e10,
        pricePredictor: predictor,
      );

      expect(out.containsKey('predictive_now_price'), isFalse);
      expect(out.containsKey('predictive_best_label'), isFalse);
      expect(out.containsKey('predictive_best_price'), isFalse);
      expect(out.containsKey('predictive_potential_saving'), isFalse);
    });

    test('omits predictive_* fields when predictor is not supplied at all',
        () {
      // The background isolate path passes pricePredictor: null. Existing
      // (non-predictive) widgets must keep their JSON shape.
      final out = HomeWidgetService.compactStationDataForTest(
        'de-abc',
        station,
        preferredFuelType: FuelType.e10,
      );

      expect(out.containsKey('predictive_now_price'), isFalse);
      expect(out.containsKey('predictive_best_label'), isFalse);
      // Default-variant fields still present — the renderer falls back
      // safely to the price-only line.
      expect(out['e10'], 1.849);
      expect(out['preferred_fuel_code'], 'e10');
    });

    test(
        'omits predictive_* fields when potentialSaving is below the floor '
        '(graceful fallback for low-confidence predictions)', () {
      PricePrediction? predictor(String id, FuelType fuel) =>
          _prediction(potentialSaving: 0.0005);

      final out = HomeWidgetService.compactStationDataForTest(
        'de-abc',
        station,
        preferredFuelType: FuelType.e10,
        pricePredictor: predictor,
      );

      expect(out.containsKey('predictive_now_price'), isFalse);
    });

    test('omits predictive_* fields when fuel price is missing for the '
        'station', () {
      // E10 station, but the user's profile is on LPG which the station
      // doesn't offer. Predictive line cannot render a "now …" half — must
      // fall back even though the predictor itself is healthy.
      PricePrediction? predictor(String id, FuelType fuel) =>
          _prediction(potentialSaving: 0.05);

      final out = HomeWidgetService.compactStationDataForTest(
        'de-abc',
        station,
        preferredFuelType: FuelType.lpg,
        pricePredictor: predictor,
      );

      expect(out['preferred_fuel_price'], isNull);
      expect(out.containsKey('predictive_now_price'), isFalse);
      expect(out.containsKey('predictive_best_label'), isFalse);
    });
  });
}
