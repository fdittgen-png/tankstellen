// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/domain/fuel_type.dart';
import '../entities/fill_up.dart';

/// What this driver normally pays, and normally buys (#4150).
///
/// "€1.67/L" answers nothing. "€0.09/L below what you normally pay, about
/// €5.20 on your usual fill" answers the only question the user has: why
/// should I care?
///
/// Every fill-up is already recorded — litres, price, date, vehicle,
/// fuel — and none of it was used as a reference for anything.
class PriceBaseline {
  const PriceBaseline({
    required this.typicalPricePerLitre,
    required this.typicalLitres,
    required this.sampleCount,
  });

  /// Median €/L over the window. The MEDIAN, not the mean: one motorway
  /// fill at €2.05 should not move the figure the driver is judged
  /// against.
  final double typicalPricePerLitre;

  /// Median litres per fill. This is what turns a price delta into
  /// money — 4 ct is €0.80 on 20 L and €2.40 on 60 L, and the app knows
  /// which this driver buys.
  final double typicalLitres;

  final int sampleCount;
}

/// Below this many fills in the window there is no baseline.
///
/// A baseline built on two fills is noise wearing a number's clothes,
/// and every saving measured against it would inherit that.
const int kMinBaselineSamples = 4;

/// How far back a baseline looks.
///
/// Long enough to survive a single unusual month, short enough to follow
/// the market rather than averaging over a year of price history.
const Duration kBaselineWindow = Duration(days: 90);

/// The driver's own baseline for [fuelType], or null when there is not
/// enough history.
///
/// Null is a real answer, not a failure: the caller falls back to a local
/// reference or says nothing at all. Trust rule 1 — a missing input is
/// stated, never defaulted.
PriceBaseline? priceBaselineFor(
  Iterable<FillUp> fillUps, {
  required FuelType fuelType,
  required DateTime now,
}) {
  final cutoff = now.subtract(kBaselineWindow);
  final relevant = [
    for (final f in fillUps)
      // Corrections are bookkeeping, not purchases — `ConsumptionStats`
      // excludes them from its arithmetic for the same reason.
      if (!f.isCorrection &&
          f.fuelType == fuelType &&
          f.liters > 0 &&
          f.totalCost > 0 &&
          f.date.isAfter(cutoff))
        f,
  ];
  if (relevant.length < kMinBaselineSamples) return null;

  return PriceBaseline(
    typicalPricePerLitre:
        _median([for (final f in relevant) f.totalCost / f.liters]),
    typicalLitres: _median([for (final f in relevant) f.liters]),
    sampleCount: relevant.length,
  );
}

double _median(List<double> values) {
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}
