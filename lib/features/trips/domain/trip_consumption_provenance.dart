// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/domain/consumption_estimate.dart';
import '../../../core/domain/pump_gain_resolution.dart';
import 'fuzzy_consumption/production_fuzzy_engine.dart';

/// The version a trip figure produced through the fuzzy stage is stamped
/// with (#4233, ADR 0024 §5) — model and rules from the one production
/// engine, plus the calibration generation when it is attributable.
///
/// **Calibration** is the resolved gain's fill-up `samples` only when that
/// gain is calibrated AND is the very gain the trip's figures carry
/// ([pumpGainApplied]). Anything else — no gain on the figure (GPS road-load
/// never takes one), an uncalibrated vehicle, or a gain that has moved since
/// the trip was integrated — is `null`: "not attributable to a fill-anchored
/// generation". A generation number that does not describe the figure would
/// be invented provenance.
///
/// Pure. Called by the stop-time finalisers that produce a fuzzy-era figure
/// (`Obd2GpsEstimateFallback.fillWhenNoFuelPid`, `backfillGpsTripFuel`'s
/// live-folder branch); the lifecycle's `_finaliseSummary` is the documented
/// follow-up.
ConsumptionModelVersion tripConsumptionVersion({
  double? pumpGainApplied,
  PumpGainResolution? resolution,
}) {
  final version = kProductionFuzzyEngine.version;
  final attributable = resolution != null &&
      resolution.isCalibrated &&
      pumpGainApplied != null &&
      resolution.gain == pumpGainApplied;
  return ConsumptionModelVersion(
    model: version.model,
    rules: version.rules,
    calibration: attributable ? resolution.samples : null,
  );
}
