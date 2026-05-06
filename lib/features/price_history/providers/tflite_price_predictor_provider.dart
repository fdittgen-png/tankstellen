import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tflite_price_predictor.dart';

/// Loads the bundled TFLite predictor (#1117 phase 2 — inference plumbing).
///
/// Returns `null` when:
/// - [kTflitePredictorEnabled] is `false` (the phase-2 default), or
/// - the model asset is missing / unparseable.
///
/// **Not yet consumed.** This provider lives alongside
/// `pricePredictionProvider` so phase 3 can wire it in without touching
/// the heuristic provider; the heuristic stays authoritative until the
/// settings toggle ships. A plain `FutureProvider.autoDispose` is used
/// (not the `@riverpod` codegen) to keep the diff small and avoid a
/// `build_runner` round-trip on every CI run for a feature that is
/// dormant by default.
///
/// `autoDispose` releases the underlying interpreter shortly after the
/// last listener detaches; on a re-listen `fromAsset` reloads the model
/// from the asset bundle. That trade-off favours memory over startup
/// latency — appropriate for a feature gated behind a default-OFF flag.
final tflitePricePredictorProvider =
    FutureProvider.autoDispose<TflitePricePredictor?>((ref) async {
  final predictor =
      await TflitePricePredictor.fromAsset(kTflitePredictorAssetPath);
  if (predictor != null) {
    ref.onDispose(predictor.dispose);
  }
  return predictor;
});
