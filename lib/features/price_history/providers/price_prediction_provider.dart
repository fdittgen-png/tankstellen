// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/country/country_config.dart';
import '../../../core/utils/num_extensions.dart';
import '../../feature_management/application/feature_flags_provider.dart';
import '../../feature_management/domain/feature.dart';
import '../../feature_management/domain/feature_dependency_graph.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../data/models/price_prediction.dart';
import '../domain/entities/feature_vector.dart';
import '../domain/services/holiday_premium.dart';
import '../domain/services/price_feature_extractor.dart';
import 'price_history_provider.dart';
import 'tflite_price_predictor_provider.dart';

part 'price_prediction_provider.g.dart';

/// Day-of-week names used for recommendation text.
const _dayNames = {
  1: 'Monday',
  2: 'Tuesday',
  3: 'Wednesday',
  4: 'Thursday',
  5: 'Friday',
  6: 'Saturday',
  7: 'Sunday',
};

/// Computes "best time to fill" predictions from locally stored price history.
///
/// Returns `null` when fewer than 10 data points are available — not enough
/// data to produce meaningful predictions.
///
/// As of #1117 phase 1, the provider also enriches the result with a
/// [PricePrediction.holidayPremium] derived from the new
/// [PriceFeatureExtractor] / [FeatureVector] contract. The future TFLite
/// phase 2 will replace this heuristic with model inference using the
/// same [FeatureVector] inputs.
@riverpod
PricePrediction? pricePrediction(
  Ref ref,
  String stationId,
  FuelType fuelType,
) {
  final repo = ref.watch(priceHistoryRepositoryProvider);
  final history = repo.getHistory(stationId, days: 30);

  if (history.length < 10) return null;

  // Build per-record feature vectors so the holiday flag (and future
  // brand / country features) flow through the same path that phase-2
  // training data will use. We don't have a Station entity here, so
  // brand stays null; country is derived from the station-id prefix.
  const extractor = PriceFeatureExtractor();
  final country = Countries.countryCodeForStationId(stationId);
  final vectors = extractor.extract(
    records: history,
    fuelType: fuelType,
    countryCodeOverride: country,
  );

  if (vectors.length < 10) return null;

  // --- Group by hour of day ---
  final hourBuckets = <int, List<double>>{};
  for (final v in vectors) {
    hourBuckets.putIfAbsent(v.hourOfDay, () => []).add(v.priceEur);
  }
  final hourlyAverages = hourBuckets.entries.map((e) {
    final avg = e.value.average;
    return HourlyAverage(
      hour: e.key,
      avgPrice: double.parse(avg.toStringAsFixed(4)),
      sampleCount: e.value.length,
    );
  }).toList()
    ..sort((a, b) => a.hour.compareTo(b.hour));

  // --- Group by day of week ---
  final dayBuckets = <int, List<double>>{};
  for (final v in vectors) {
    dayBuckets.putIfAbsent(v.dayOfWeek, () => []).add(v.priceEur);
  }
  final dailyAverages = dayBuckets.entries.map((e) {
    final avg = e.value.average;
    return DayOfWeekAverage(
      dayOfWeek: e.key,
      avgPrice: double.parse(avg.toStringAsFixed(4)),
      sampleCount: e.value.length,
    );
  }).toList()
    ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));

  if (hourlyAverages.isEmpty || dailyAverages.isEmpty) return null;

  // --- Find cheapest / most expensive ---
  final cheapestHour = hourlyAverages.reduce(
    (a, b) => a.avgPrice <= b.avgPrice ? a : b,
  );
  final mostExpensiveHour = hourlyAverages.reduce(
    (a, b) => a.avgPrice >= b.avgPrice ? a : b,
  );
  final cheapestDay = dailyAverages.reduce(
    (a, b) => a.avgPrice <= b.avgPrice ? a : b,
  );

  // --- Potential saving across hours ---
  final hourlySaving = mostExpensiveHour.avgPrice - cheapestHour.avgPrice;
  final potentialSaving =
      hourlySaving > 0.001 ? double.parse(hourlySaving.toStringAsFixed(3)) : null;

  // --- Holiday premium (#1117 phase 1) ---
  final holidayPremium = _computeHolidayPremium(vectors);

  // --- Recommendation text ---
  final dayName = _dayNames[cheapestDay.dayOfWeek] ?? 'Unknown';
  final hourLabel = _formatHourRange(cheapestHour.hour);
  final base = 'Prices typically drop $dayName $hourLabel';
  final recommendation =
      _maybeAppendHolidayHint(base, holidayPremium);

  // --- TFLite model prediction (#1543 — triple-gated) ---
  // Gate 1: user-facing feature flag, walks the `requires` chain so a
  // disabled `priceHistory` parent cascades through automatically.
  // Gate 2: the compile-time `kTflitePredictorEnabled` const lives
  // inside `TflitePricePredictor.fromAsset` and makes the loader
  // return null until a trained artifact ships.
  // Gate 3: `.predict()` itself rejects out-of-band / non-finite
  // outputs and returns null on disposed predictors.
  // When any gate trips, `modelPredictedCents` stays null and the
  // heuristic above is the only output — same UX as before #1543.
  final modelPredictedCents = _maybeModelPredict(
    ref: ref,
    latest: vectors.last,
  );

  return PricePrediction(
    recommendation: recommendation,
    potentialSaving: potentialSaving,
    bestHour: cheapestHour.hour,
    bestDayOfWeek: cheapestDay.dayOfWeek,
    hourlyAverages: hourlyAverages,
    dailyAverages: dailyAverages,
    holidayPremium: holidayPremium,
    modelPredictedCents: modelPredictedCents,
  );
}

/// Runs the on-device TFLite predictor against the most recent
/// feature vector when every gate from #1543 passes. Returns `null`
/// in every failure path so the caller can fall back to the
/// heuristic-only [PricePrediction] shape without a try/catch.
double? _maybeModelPredict({
  required Ref ref,
  required FeatureVector latest,
}) {
  final manifest = ref.watch(featureManifestProvider);
  final enabled = ref.watch(enabledFeaturesProvider);
  if (!isEffectivelyEnabled(
    Feature.tflitePricePrediction,
    manifest,
    enabled,
  )) {
    return null;
  }
  // `AsyncValue.value` returns the resolved data when present, or
  // `null` while the asset is still loading or has errored — the
  // predictor is opportunistic, never blocking.
  final predictor =
      ref.watch(tflitePricePredictorProvider).value;
  if (predictor == null) return null;
  final result = predictor.predict(latest);
  return result?.predictedPriceCents;
}

/// Average EUR/L delta between holiday and non-holiday samples in
/// [vectors], delegating the maths to the shared [HolidayPremium]
/// helper so this provider and the [FillUpGuidancePredictor] heuristic
/// share exactly one implementation (#2570). Returns `null` when the
/// signal is too thin to trust (see [HolidayPremium.compute]).
double? _computeHolidayPremium(List<FeatureVector> vectors) {
  final holidayPrices = <double>[];
  final nonHolidayPrices = <double>[];
  for (final v in vectors) {
    if (v.isHoliday) {
      holidayPrices.add(v.priceEur);
    } else {
      nonHolidayPrices.add(v.priceEur);
    }
  }
  return HolidayPremium.compute(
    holidayPrices: holidayPrices,
    nonHolidayPrices: nonHolidayPrices,
  );
}

/// Optionally appends a one-sentence holiday hint to [base] when the
/// computed [holidayPremium] is large enough to be actionable.
String _maybeAppendHolidayHint(String base, double? holidayPremium) {
  if (!HolidayPremium.isActionable(holidayPremium)) return base;
  final cents = (holidayPremium!.abs() * 100).toStringAsFixed(1);
  final direction = holidayPremium > 0 ? 'higher' : 'lower';
  return '$base. Holidays trend $cents ct/L $direction';
}

/// Formats an hour (0-23) as a human-readable time range, e.g. "6-8 PM".
String _formatHourRange(int hour) {
  final startLabel = _formatHour(hour);
  final endLabel = _formatHour((hour + 2) % 24);
  return '$startLabel-$endLabel';
}

String _formatHour(int hour) {
  if (hour == 0) return '12 AM';
  if (hour < 12) return '$hour AM';
  if (hour == 12) return '12 PM';
  return '${hour - 12} PM';
}
