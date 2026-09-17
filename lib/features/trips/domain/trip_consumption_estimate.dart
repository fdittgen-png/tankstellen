// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/domain/consumption_estimate.dart';
import '../../../core/domain/data_value.dart';
import '../../../core/domain/vehicle_profile.dart';
import 'calibrated_trip_figures.dart';
import 'trip_consumption_source_class.dart';
import 'trip_fuel_source.dart';
import 'trip_summary.dart';

/// A trip's L/100 km as the canonical [ConsumptionEstimate] (#4233,
/// ADR 0024 §6) — the adapter every trip consumer reads the figure
/// through.
///
/// Built on [CalibratedTripFigures.of], so its number can never disagree
/// with the tank report or the fuel-source chip, and classified by the one
/// existing rule ([tripFuelSourceKind]) rather than a second vocabulary:
///
/// | kind | value | pumpGain |
/// |---|---|---|
/// | measured | `measured(stored)` | null, whatever `pg` says |
/// | estimated | `estimated(re-expressed, derived)` | the gain it is expressed at |
/// | gps | `estimated(avg ?? eAvg, derived)` | null |
/// | none, with a figure (F4) | `estimated(figure, derived)` | null |
/// | none | `unknown(notMeasuredYet)` | null |
///
/// The value is exactly the number a trip surface showed before #4233:
/// the calibrated `lPer100Km`, else the persisted GPS estimate
/// `estimatedAvgLPer100Km`. The version is the trip's stored stamp
/// ([TripSummary.consumptionVersion]; null when none was stamped). When an
/// estimated figure is re-expressed at today's gain, its calibration
/// generation becomes today's fill-up `samples`, because that is the
/// calibration the shown figure now carries.
///
/// Pure. No consumer can select an estimator through it; it only reads what
/// the producer stamped.
ConsumptionEstimate tripConsumptionEstimate(
  TripSummary summary,
  VehicleProfile? vehicle, {
  String? fuelKey,
  String? recordingId,
}) {
  final figures = CalibratedTripFigures.of(summary, vehicle, fuelKey: fuelKey);
  final sourceClass = figures.kind.asConsumptionSourceClass;
  final shown = figures.lPer100Km ?? summary.estimatedAvgLPer100Km;
  final stored = summary.consumptionVersion;
  final estimatedGain = figures.kind == TripFuelSourceKind.estimated
      ? (figures.reExpressed ? figures.resolution.gain : summary.pumpGainApplied)
      : null;
  final version = stored != null &&
          figures.kind == TripFuelSourceKind.estimated &&
          figures.reExpressed
      ? ConsumptionModelVersion(
          model: stored.model,
          rules: stored.rules,
          calibration: figures.resolution.isCalibrated
              ? figures.resolution.samples
              : null,
        )
      : stored;
  return ConsumptionEstimate(
    litresPer100Km: shown == null
        ? const DataValue<double>.unknown(
            reason: DataUnknownReason.notMeasuredYet)
        : sourceClass == ConsumptionSourceClass.measured &&
                figures.lPer100Km != null
            ? DataValue<double>.measured(shown, at: summary.startedAt)
            : DataValue<double>.estimated(shown, basis: DataBasis.derived),
    sourceClass: sourceClass,
    version: version,
    pumpGain: estimatedGain,
    recordedAt: summary.startedAt,
    recordingId: recordingId,
  );
}
