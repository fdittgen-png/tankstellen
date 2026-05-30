// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../feature_management/application/feature_flags_provider.dart';
import '../../feature_management/domain/feature.dart';
import '../../feature_management/domain/feature_dependency_graph.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../domain/entities/fill_up_guidance.dart';
import '../domain/services/fill_up_guidance_predictor.dart';
import 'price_history_provider.dart';

part 'fill_up_guidance_provider.g.dart';

/// On-device "best time to fill up?" guidance for a station + fuel type
/// (#1543, no-ML heuristic).
///
/// Reads the locally collected price history (read-only) and folds it
/// into a [FillUpGuidance] via the pure [FillUpGuidancePredictor]. The
/// computation is entirely on-device — no network, no cloud, no model
/// artifact — so it honours the project's "no costs" constraint.
///
/// Returns `null` when:
///   * the [Feature.tflitePricePrediction] gate is effectively off
///     (this reuses the existing #1117 UI gate, which already cascades
///     through its `requires: {priceHistory}` edge), or
///   * the heuristic reports [FillUpGuidanceKind.insufficientData].
///
/// A non-null result always carries an actionable verdict the
/// [FillUpGuidanceCard] can render.
@riverpod
FillUpGuidance? fillUpGuidance(
  Ref ref,
  String stationId,
  FuelType fuelType,
) {
  // Gate on the existing price-prediction feature flag (#1117/#1543).
  // `isEffectivelyEnabled` walks the `requires` chain, so a disabled
  // `priceHistory` parent cascades through automatically.
  final manifest = ref.watch(featureManifestProvider);
  final enabled = ref.watch(enabledFeaturesProvider);
  if (!isEffectivelyEnabled(
    Feature.tflitePricePrediction,
    manifest,
    enabled,
  )) {
    return null;
  }

  final repo = ref.watch(priceHistoryRepositoryProvider);
  final history = repo.getHistory(stationId, days: 30);

  const predictor = FillUpGuidancePredictor();
  final guidance = predictor.predict(
    history: history,
    fuelType: fuelType,
    now: DateTime.now(),
  );

  return guidance.hasGuidance ? guidance : null;
}
