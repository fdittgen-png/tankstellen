import '../../price_history/domain/entities/price_prediction.dart';
import '../../search/domain/entities/fuel_type.dart';

/// Callback that produces a [PricePrediction] for a given station + fuel
/// type, or `null` when the predictor can't form an actionable
/// recommendation (insufficient data, low confidence). Wired by the
/// foreground caller — usually as a thin wrapper around
/// `pricePredictionProvider` — so the widget data layer stays free of
/// Riverpod and works inside background isolates that pass `null`.
typedef PricePredictor = PricePrediction? Function(
  String stationId,
  FuelType fuelType,
);

/// Builds the compact "predictive" line the home-screen widget shows under
/// the current price when the predictive variant (#1121) is enabled.
///
/// Returns `null` when the prediction is not actionable — either because
/// the predictor itself returned null (less than 10 history records) or
/// because the inferred saving between worst and best hour is negligible
/// (`potentialSaving == null` or below the 0.001 €/L floor the predictor
/// already filters with). Returning null tells the renderer to fall back
/// to the default price-only line — exactly the "graceful fallback" the
/// acceptance criterion calls for.
///
/// The output is a flat `Map<String, dynamic>` ready to merge into the
/// station JSON entry the Kotlin renderer reads. All values are primitive
/// (no nested maps) so [jsonEncode] is a thin wrapper and the Kotlin side
/// can read each field with `optString` / `optDouble`. The fields are:
///
/// - `predictive_now_price` — the current price the row already renders, in
///   EUR/L (or whatever the station's currency uses), written as a double
///   so the Kotlin side can format it consistently with the existing line.
/// - `predictive_now_label` — "now" as a one-letter prefix the Kotlin
///   renderer prepends. Localised on the Dart side; null when absent.
/// - `predictive_best_label` — pre-built English phrase from the predictor's
///   `recommendation` (e.g. "Prices typically drop Tuesday 6-8 PM"). Already
///   includes the day name + hour range — the predictor formats it once, we
///   just forward it. Locale-isation of the predictor's text is tracked on
///   the predictor itself (#1117 follow-up); the variant wires the same
///   string the in-app banner already shows.
/// - `predictive_best_price` — predicted average at the cheapest hour,
///   in EUR/L. Computed as `now - potentialSaving` so the rendered line
///   reads "now €1.84/L · best Tue eve ~€1.79/L". Returned `null` when
///   we don't know the current price (the row falls back to the default
///   line in that case).
/// - `predictive_potential_saving` — saving in EUR/L (positive double), so
///   the renderer can also surface a "save ~5 ct/L" tag if the layout has
///   room. Mirrors the in-app `BestTimeBanner` field.
///
/// A null return is just as valid as a populated map — it's the fallback
/// signal the renderer must check before drawing the second line.
Map<String, dynamic>? buildPredictivePayload({
  required double? currentPrice,
  required PricePrediction? prediction,
}) {
  if (prediction == null) return null;
  final saving = prediction.potentialSaving;
  if (saving == null || saving < 0.001) return null;
  if (currentPrice == null) return null;

  // Best price = current minus the predicted swing. Round to 3 decimals so
  // the JSON stays compact and the Kotlin formatter prints clean numbers.
  final bestPrice = double.parse(
    (currentPrice - saving).toStringAsFixed(3),
  );

  return <String, dynamic>{
    'predictive_now_price': currentPrice,
    'predictive_best_label': prediction.recommendation,
    'predictive_best_price': bestPrice,
    'predictive_potential_saving': saving,
  };
}
