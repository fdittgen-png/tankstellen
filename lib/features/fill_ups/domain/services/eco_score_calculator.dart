// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'physical_tank_windows.dart';
import '../entities/eco_score.dart';
import '../entities/fill_up.dart';

/// Computes a per-fill-up [EcoScore] from the user's fill-up history.
///
/// Pure, free of I/O. The caller supplies the full fill-up list and
/// picks the "current" entry; the calculator finds the preceding
/// same-fuel-type fill-ups to build a rolling L/100 km baseline and
/// decides how the current tank compares.
///
/// This is the computational half of issue #676 — the UI badge that
/// answers "did I drive more economically than usual?" for every new
/// fill-up. It is the feature most directly aligned with the product
/// leitmotiv (see README): once the user sees their consumption
/// drifting up or down at a glance, they can actually act on it.
class EcoScoreCalculator {
  EcoScoreCalculator._();

  /// How many previous fill-ups of the same fuel type to average.
  /// Three is enough to smooth out a single bad tank (winter mix,
  /// short-trip week) but short enough to show a real trend rather
  /// than regress to a year-old baseline.
  static const int rollingWindow = 3;

  /// Compute the eco-score for [current], comparing it against the
  /// [rollingWindow] most recent preceding fill-ups of the same fuel
  /// type in [history].
  ///
  /// [history] must include [current]; the calculator finds it by id
  /// (not by reference equality) so callers can pass freshly-loaded
  /// lists without worrying about identity. Order within [history]
  /// is not assumed — entries are sorted by date internally.
  ///
  /// Returns `null` when the score cannot be meaningfully produced:
  ///
  /// - [current] is not found in [history]
  /// - [current] is the first-ever fill-up (no preceding same-fuel entry)
  /// - Any of the preceding fill-ups (or [current] itself) has a
  ///   non-positive odometer delta — indicates a data-entry error
  ///   (odometer reset, typo) and a negative-or-zero delta would
  ///   produce a meaningless or infinite L/100 km.
  /// - Fewer than 1 valid preceding same-fuel-type entry.
  ///
  /// Callers are expected to render nothing when the return is `null`.
  static EcoScore? compute({
    required FillUp current,
    required List<FillUp> history,
  }) {
    final windows = physicalTankWindows(history).closed;
    final index = windows.indexWhere((w) => w.closing.id == current.id);
    if (index < 0) return null;
    final window = windows[index];
    // Compare complete windows belonging to the same vehicle and opening
    // grade. A partial or synthetic entry never becomes a scored tank.
    final prior = windows
        .take(index)
        .where(
          (w) =>
              w.opening.vehicleId == window.opening.vehicleId &&
              w.opening.fuelType == window.opening.fuelType,
        )
        .toList();
    if (prior.isEmpty) return null;
    final recent = prior.skip(
      prior.length > rollingWindow ? prior.length - rollingWindow : 0,
    );
    final km = recent.fold(0.0, (sum, w) => sum + w.distanceKm);
    final baseline = recent.fold(0.0, (sum, w) => sum + w.liters) / km * 100;
    final currentLp100 = window.lPer100Km;

    final deltaPercent = (currentLp100 - baseline) / baseline * 100;
    final direction = _directionFor(deltaPercent);

    return EcoScore(
      litersPer100Km: currentLp100,
      rollingAverage: baseline,
      deltaPercent: deltaPercent,
      direction: direction,
    );
  }

  static EcoScoreDirection _directionFor(double deltaPercent) {
    if (deltaPercent <= -EcoScore.threshold) return EcoScoreDirection.improving;
    if (deltaPercent >= EcoScore.threshold) return EcoScoreDirection.worsening;
    return EcoScoreDirection.stable;
  }

  /// The physical reference on the qualified closing fill, without a trend.
  /// A full-to-full window needs no earlier comparison window; partial and
  /// synthetic records never have independent measured consumption (#4469).
  static double? computeLitersPer100Km({
    required FillUp current,
    required List<FillUp> history,
  }) {
    return physicalTankWindows(
      history,
    ).closed.where((w) => w.closing.id == current.id).firstOrNull?.lPer100Km;
  }
}
