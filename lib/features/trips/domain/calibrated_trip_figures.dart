// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../../../core/domain/pump_gain_resolution.dart';
import '../../../core/domain/vehicle_profile.dart';
import 'trip_fuel_source.dart';
import 'trip_summary.dart';

/// A trip's fuel figures re-expressed at the vehicle's CURRENT pump gain
/// (#3918, Epic #3914) — display only, stored data untouched.
///
/// A recording carries the gain it was integrated with
/// ([TripSummary.pumpGainApplied], null ≡ 1.0). When a later full fill
/// re-anchors the gain, the stored litres are stale by exactly the ratio
/// of the two gains, so:
///
///     shownLitres = storedLitres × gainNow / pumpGainApplied
///
/// Only ESTIMATED fuel is eligible ([tripFuelSourceKind] ==
/// [TripFuelSourceKind.estimated]) — ECU-reported fuel was never
/// multiplied by a gain and must never be rescaled. The one helper every
/// surface (trip rows, trip detail, monthly card, tank report) goes
/// through, so they can never disagree on a number.
@immutable
class CalibratedTripFigures {
  const CalibratedTripFigures({
    required this.liters,
    required this.lPer100Km,
    required this.scale,
    required this.reExpressed,
    required this.kind,
    required this.resolution,
    required this.gainApplied,
  });

  /// Litres to show (null when the trip has no fuel figure).
  final double? liters;

  /// L/100 km to show (null when the trip has none).
  final double? lPer100Km;

  /// `gainNow / pumpGainApplied` — 1.0 when nothing changed.
  final double scale;

  /// True when the shown figures differ from the stored ones.
  final bool reExpressed;
  final TripFuelSourceKind kind;

  /// The gain the vehicle applies NOW (the one the figures are
  /// expressed at).
  final PumpGainResolution resolution;

  /// The gain the trip was recorded with (null on legacy trips ≡ 1.0).
  final double? gainApplied;

  /// Whether the shown figures carry any pump calibration at all — a
  /// non-unity gain either recorded in or re-expressed to.
  bool get calibrated =>
      kind == TripFuelSourceKind.estimated &&
      ((gainApplied != null && gainApplied != 1.0) || reExpressed);

  /// Signed correction of the shown figures vs the raw estimator, in
  /// percent — the gain the figures are expressed at.
  int get correctionPercent {
    final g = kind == TripFuelSourceKind.estimated
        ? (reExpressed ? resolution.gain : (gainApplied ?? 1.0))
        : 1.0;
    return ((g - 1.0) * 100).round();
  }

  /// Re-express [summary] at [vehicle]'s current gain for [fuelKey]
  /// (null → the vehicle's tank / default fuel; see
  /// [pumpGainFuelKeyFor]). A null [vehicle] passes the stored figures
  /// through unchanged.
  static CalibratedTripFigures of(
    TripSummary summary,
    VehicleProfile? vehicle, {
    String? fuelKey,
  }) {
    final kind = tripFuelSourceKind(summary);
    final resolution = resolvePumpGain(
      vehicle,
      fuelKey: fuelKey ?? pumpGainFuelKeyFor(vehicle),
    );
    final applied = summary.pumpGainApplied;
    final storedLiters = summary.fuelLitersConsumed;
    final storedAvg = summary.avgLPer100Km;
    var scale = 1.0;
    if (kind == TripFuelSourceKind.estimated && vehicle != null) {
      final pg = applied ?? 1.0;
      if (pg > 0 && (resolution.gain - pg).abs() > 1e-6) {
        scale = resolution.gain / pg;
      }
    }
    final reExpressed = scale != 1.0;
    return CalibratedTripFigures(
      liters: storedLiters == null ? null : storedLiters * scale,
      lPer100Km: storedAvg == null ? null : storedAvg * scale,
      scale: scale,
      reExpressed: reExpressed,
      kind: kind,
      resolution: resolution,
      gainApplied: applied,
    );
  }
}
