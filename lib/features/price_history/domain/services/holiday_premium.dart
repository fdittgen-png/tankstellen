// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/utils/num_extensions.dart';

/// Single source of truth for the public-holiday price-premium maths
/// shared by the price-prediction provider and the fill-up-guidance
/// heuristic (#1117 phase 1, #2570).
///
/// Both call sites used to (or would have to) re-derive the same
/// "average EUR/L gap between holiday and non-holiday readings". This
/// helper extracts that proven calculation once so the two heuristics
/// can never drift apart. It is pure, side-effect-free, and takes the
/// two price populations directly so it stays decoupled from whatever
/// observation type the caller carries (`FeatureVector`, the
/// predictor's internal sample, …).
class HolidayPremium {
  const HolidayPremium._();

  /// Minimum holiday observations required before a premium is trusted.
  /// Below this the signal is too noisy to be useful (#1117 phase 1).
  static const int minHolidaySamples = 3;

  /// EUR/L magnitude above which a holiday premium is considered
  /// actionable — both for the provider's text hint and the predictor's
  /// verdict nudge. Below 2 cents the difference is not worth acting on.
  static const double noticeThresholdEur = 0.02;

  /// Average EUR/L delta between [holidayPrices] and [nonHolidayPrices]
  /// (positive = holidays run dearer, negative = cheaper).
  ///
  /// Returns `null` — i.e. "no trustworthy signal" — when there are
  /// fewer than [minHolidaySamples] holiday observations or no
  /// non-holiday baseline to compare against. The result is rounded to
  /// 3 decimals (0.1 ct/L) to match the legacy provider behaviour.
  static double? compute({
    required List<double> holidayPrices,
    required List<double> nonHolidayPrices,
  }) {
    if (holidayPrices.length < minHolidaySamples) return null;
    if (nonHolidayPrices.isEmpty) return null;

    final delta = holidayPrices.average - nonHolidayPrices.average;
    return double.parse(delta.toStringAsFixed(3));
  }

  /// Whether [premium] is large enough (in either direction) to act on.
  /// `null` and sub-threshold premiums are not actionable.
  static bool isActionable(double? premium) =>
      premium != null && premium.abs() > noticeThresholdEur;
}
