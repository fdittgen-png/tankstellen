// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/domain/fuel_type.dart';
import '../entities/fuel_consumption_figure.dart';
import '../entities/fuel_type_efficiency_stats.dart';
import '../fuel_energy_content.dart';

/// A consumption figure the estimate can be anchored on, with the fuel it
/// was burned as — the energy ratio needs both (#3945).
class ConsumptionBaseline {
  final double litersPer100km;
  final FuelType fuel;

  const ConsumptionBaseline({required this.litersPer100km, required this.fuel});
}

/// The per-fuel consumption model behind the all-prices table (#3945,
/// ADR 0015 amendment).
///
/// Pure Dart — no Riverpod, no Flutter. Given the ADR 0015 buckets for one
/// vehicle, it answers, for every fuel the vehicle can take: *what does this
/// car burn per 100 km on that grade?* — and, crucially, HOW it knows:
///
/// * **measured** — a PURE bucket of that very grade (dominant share
///   ≥ 85 %). Today's path, unchanged.
/// * **estimated** — the grade has no pure window (every tank of it was a
///   blend, or it was never bought). The figure is then the vehicle's
///   BASELINE consumption converted by the two fuels' energy content
///   ([FuelEnergyContent]): `L100_X = L100_base × (energy_base / energy_X)`.
///
/// The baseline is the best measured figure available for the vehicle, in
/// this order: the most-confident pure bucket of another grade (most
/// attributed intervals; ties → most litres → lowest `apiValue`), else the
/// caller-supplied [fallbackBaseline] (the vehicle's all-fuel
/// `ConsumptionStats` average, anchored on its declared primary grade).
/// No baseline at all ⇒ the fuel simply has no figure, exactly as before.
///
/// What this never does: credit the measured litres of a MIX bucket to a
/// grade. A blend is not a grade you can buy; folding it into one is the
/// ADR 0014 collapse ADR 0015 exists to reject. The mix buckets are
/// therefore ignored here on purpose.
class FuelConsumptionEstimator {
  FuelConsumptionEstimator._();

  /// One figure per fuel: every pure bucket in [stats] as `measured`, then
  /// an `estimated` figure for each fuel in [candidateFuels] that has none —
  /// when a baseline exists and both fuels have a volumetric energy content.
  static Map<FuelType, FuelConsumptionFigure> byFuel({
    required List<FuelTypeEfficiencyStats> stats,
    required Set<FuelType> candidateFuels,
    ConsumptionBaseline? fallbackBaseline,
  }) {
    final result = <FuelType, FuelConsumptionFigure>{};
    for (final s in stats) {
      if (s.isMix) continue;
      final l100 = s.avgL100km;
      if (l100 == null || l100 <= 0) continue;
      result[s.dominant] = FuelConsumptionFigure.measured(l100);
    }

    final baseline = _measuredBaseline(stats) ?? _usable(fallbackBaseline);
    if (baseline == null) return result;

    for (final fuel in candidateFuels) {
      if (result.containsKey(fuel)) continue;
      final ratio = FuelEnergyContent.litreRatio(
        base: baseline.fuel,
        target: fuel,
      );
      if (ratio == null) continue;
      result[fuel] = FuelConsumptionFigure.estimated(
        baseline.litersPer100km * ratio,
      );
    }
    return result;
  }

  /// The most-confident PURE bucket with a usable figure: most attributed
  /// intervals, then most litres, then lowest `apiValue` for determinism.
  static ConsumptionBaseline? _measuredBaseline(
    List<FuelTypeEfficiencyStats> stats,
  ) {
    FuelTypeEfficiencyStats? best;
    for (final s in stats) {
      if (s.isMix) continue;
      final l100 = s.avgL100km;
      if (l100 == null || l100 <= 0) continue;
      if (best == null || _moreConfident(s, best)) best = s;
    }
    if (best == null) return null;
    return ConsumptionBaseline(
      litersPer100km: best.avgL100km!,
      fuel: best.dominant,
    );
  }

  static bool _moreConfident(
    FuelTypeEfficiencyStats a,
    FuelTypeEfficiencyStats b,
  ) {
    if (a.attributedIntervalCount != b.attributedIntervalCount) {
      return a.attributedIntervalCount > b.attributedIntervalCount;
    }
    if (a.totalLitres != b.totalLitres) return a.totalLitres > b.totalLitres;
    return a.dominant.apiValue.compareTo(b.dominant.apiValue) < 0;
  }

  static ConsumptionBaseline? _usable(ConsumptionBaseline? b) =>
      (b == null || b.litersPer100km <= 0) ? null : b;
}
