// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../entities/fill_up.dart';
import 'fill_anchored_consumption.dart';

/// Default L/100 km for the between-fill burn estimate when the fill
/// history has no valid tank-to-tank window yet — the same defensive
/// fleet midpoint the tank-level estimator uses (#3645/#3647).
const double _defaultAvgLPer100Km = 7.0;

/// One grade's share of the current tank content (#3652).
@immutable
class TankMixShare {
  final FuelType fuel;

  /// Fraction of the tank content, in `[0, 1]`. All shares of an
  /// estimate sum to 1.
  final double share;

  const TankMixShare({required this.fuel, required this.share});
}

/// The estimated composition of the CURRENT tank content (#3652).
///
/// Burning fuel between fills changes the volume, never the ratio — so
/// the composition after the most recent fill IS the current mix.
@immutable
class TankMixEstimate {
  /// Shares ordered by descending fraction (ties broken by ascending
  /// `apiValue` for determinism). Non-empty; fractions sum to 1.
  final List<TankMixShare> shares;

  /// Date of the most recent physical fill the mix is valid from.
  final DateTime asOf;

  const TankMixEstimate({required this.shares, required this.asOf});

  /// True when the tank actually holds a blend worth surfacing: at
  /// least two grades with ≥ [minShare] each. A pure tank (or one with
  /// only a trace of a second grade) reads as single-fuel.
  bool isBlend({double minShare = 0.01}) =>
      shares.where((s) => s.share >= minShare).length >= 2;

  /// #3701 — share-weighted ethanol volume fraction of the tank content
  /// (0..1), from the nominal ethanol content of each grade (E85 ≈ 85 %,
  /// E10 = 10 %, E5/E98 = 5 %). Drives the combustion-health lesson's
  /// fuel-explains-the-trims gate: an ECU running an E85-heavy tank
  /// legitimately holds LTFT around +20‥30 % (stoich 9.8:1 vs 14.7:1) —
  /// that is the fuel, not a P0171-style fault.
  double get ethanolVolumeFraction {
    var fraction = 0.0;
    for (final s in shares) {
      fraction += s.share * _nominalEthanolContent(s.fuel);
    }
    return fraction.clamp(0.0, 1.0);
  }

  static double _nominalEthanolContent(FuelType fuel) {
    if (fuel == FuelType.e85) return 0.85;
    if (fuel == FuelType.e10) return 0.10;
    if (fuel == FuelType.e5 || fuel == FuelType.e98) return 0.05;
    return 0.0;
  }
}

/// Estimate the fuel mix of the current tank content from the fill-up
/// history (#3652).
///
/// ## The model, per the maintainer directive (2026-08-01)
///
/// > If the user fills with different types, take the mix into
/// > consideration for the content of the current tank. So if adding
/// > E10 to E85, the content becomes a percentage of both. Determine
/// > that with the fill-up. If the user says that the tank is full,
/// > you know what the mix is. Otherwise determine it based on OBD2,
/// > or by what the user says is the current tank content, or what you
/// > think is best.
///
/// Walks the physical (non-correction, #1361) fills oldest → newest,
/// carrying a litres-per-grade composition. At each fill the **prior
/// content** — the litres already in the tank when the pump started —
/// weights the blend against the pumped litres. Best available truth,
/// in order:
///
///  1. **Full-tank flag + known capacity** → `capacity − pumped`
///     ("if the tank is full, you know what the mix is": residual and
///     pumped litres both pin exactly).
///  2. The OBD2 / user-entered pre-pump level (`fuelLevelBeforeL`,
///     #1401), else the post-pump level minus the pumped litres.
///  3. The previous post-fill level minus the odometer-delta burn at
///     the fill-anchored tank-to-tank average (#3645; fleet default
///     7.0 when no valid window exists).
///  4. Nothing known → half the previous post-fill level — the
///     midpoint of the honest `[0, previous level]` interval; over- or
///     under-weighting either side systematically would bias the mix
///     toward old or new fuel.
///
/// The very first fill has an unknown residual; any residual implied by
/// its full flag is attributed to that fill's own grade. The
/// approximation washes out within a tank or two — every later full
/// fill re-pins the composition exactly.
///
/// Returns null when the vehicle has no physical fills. Single-grade
/// histories return a 100 % share — callers use [TankMixEstimate.isBlend]
/// to decide whether the mix is worth surfacing.
TankMixEstimate? estimateTankMix({
  required VehicleProfile vehicle,
  required List<FillUp> fillUps,
}) =>
    estimateTankMixForCapacity(
      tankCapacityL: vehicle.tankCapacityL,
      fillUps: fillUps,
    );

/// Capacity-parameterised core of [estimateTankMix] (#3764).
///
/// Identical model, but takes the tank capacity directly instead of a
/// [VehicleProfile] — the only profile fact the chain consumes. This lets
/// pure aggregation code (no profile in scope) replay the mix chain over a
/// PREFIX of the fill history to obtain "the mix as of fill N": passing the
/// fills up to and including a given fill returns the estimated tank
/// composition right after that fill (`asOf` = that fill's date). The
/// per-fuel efficiency aggregator uses exactly that to price an interval's
/// carried-over opening content (ADR 0015 v3).
TankMixEstimate? estimateTankMixForCapacity({
  required double? tankCapacityL,
  required List<FillUp> fillUps,
}) {
  final physical = fillUps.where((f) => !f.isCorrection).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  if (physical.isEmpty) return null;

  final capacity = tankCapacityL;
  final avgLPer100Km =
      fillAnchoredAvgLPer100Km(fillUps)?.avgLPer100Km ?? _defaultAvgLPer100Km;

  // Composition of the tank content, litres per fuel apiValue.
  var composition = <String, double>{};
  final fuelByApiValue = <String, FuelType>{};
  double? prevLevel; // post-fill level after the previous fill
  double prevOdometerKm = 0;

  for (final f in physical) {
    fuelByApiValue[f.fuelType.apiValue] = f.fuelType;

    // ── Prior content: litres in the tank when the pump started. ──
    double prior;
    if (f.isFullTank && capacity != null) {
      prior = (capacity - f.liters).clamp(0.0, capacity);
    } else if (f.fuelLevelBeforeL != null && f.fuelLevelBeforeL! >= 0) {
      prior = f.fuelLevelBeforeL!;
    } else if (f.fuelLevelAfterL != null && f.fuelLevelAfterL! >= 0) {
      prior = (f.fuelLevelAfterL! - f.liters).clamp(0.0, double.infinity);
    } else if (prevLevel != null &&
        prevOdometerKm > 0 &&
        f.odometerKm > prevOdometerKm) {
      final burned = (f.odometerKm - prevOdometerKm) * avgLPer100Km / 100.0;
      prior = (prevLevel - burned).clamp(0.0, double.infinity);
    } else if (prevLevel != null) {
      prior = prevLevel / 2;
    } else {
      prior = 0;
    }
    if (capacity != null) {
      // Content + pumped litres can't exceed the tank.
      prior = prior.clamp(0.0, (capacity - f.liters).clamp(0.0, capacity));
    }

    // ── Rescale the carried composition to the prior content. ──
    final prevTotal = composition.values.fold(0.0, (a, b) => a + b);
    if (prevTotal > 0 && prior > 0) {
      final factor = prior / prevTotal;
      composition = {
        for (final e in composition.entries) e.key: e.value * factor,
      };
    } else if (prior > 0) {
      // Unknown residual on the very first fill: attribute it to this
      // fill's own grade (see docstring — converges within a tank).
      composition = {f.fuelType.apiValue: prior};
    } else {
      composition = {};
    }

    // ── Blend in the pumped litres. ──
    composition.update(
      f.fuelType.apiValue,
      (v) => v + f.liters,
      ifAbsent: () => f.liters,
    );

    final total = composition.values.fold(0.0, (a, b) => a + b);
    prevLevel = (f.isFullTank && capacity != null) ? capacity : total;
    if (f.odometerKm > 0) prevOdometerKm = f.odometerKm;
  }

  final total = composition.values.fold(0.0, (a, b) => a + b);
  if (total <= 0) return null;

  final ordered = composition.entries.toList()
    ..sort((a, b) {
      final byShare = b.value.compareTo(a.value);
      if (byShare != 0) return byShare;
      return a.key.compareTo(b.key);
    });

  return TankMixEstimate(
    shares: [
      for (final e in ordered)
        TankMixShare(fuel: fuelByApiValue[e.key]!, share: e.value / total),
    ],
    asOf: physical.last.date,
  );
}
