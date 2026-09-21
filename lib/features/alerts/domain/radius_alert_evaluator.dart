// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../../core/utils/geo_utils.dart';
import 'entities/radius_alert.dart';
import 'station_price_sample.dart';

// #4149 — [StationPriceSample] moved to its own file when the velocity
// detector's near-identical `VelocityStationObservation` was collapsed
// into it. Re-exported so every existing import of this file keeps
// resolving the type unchanged.
export 'station_price_sample.dart';

/// Pure-Dart threshold evaluator for [RadiusAlert] (#578 phase 1).
///
/// Zero Riverpod / Hive imports so this can be reused inside the
/// phase-2 background worker without hauling the whole app
/// dependency graph into a WorkManager isolate.
class RadiusAlertEvaluator {
  const RadiusAlertEvaluator();

  /// True iff at least one [StationPriceSample] satisfies all three
  /// of: (a) same fuel as [alert], (b) price at or below
  /// [RadiusAlert.threshold], and (c) located within
  /// [RadiusAlert.radiusKm] of the alert's centre.
  ///
  /// Disabled alerts ([RadiusAlert.enabled] false) never trigger —
  /// the caller can filter on `enabled` themselves, but short-
  /// circuiting here keeps the common "toggled off" path cheap.
  bool triggered(RadiusAlert alert, List<StationPriceSample> samples) {
    if (!alert.enabled) return false;
    for (final s in samples) {
      if (_matches(alert, s)) return true;
    }
    return false;
  }

  /// Iterable of every sample that would trigger [alert]. Used by
  /// the phase-2 notification payload so the user sees a list like
  /// "Shell, Aldi, Total" instead of a bare "someone is cheap
  /// somewhere".
  ///
  /// Returns an empty iterable when [alert] is disabled.
  Iterable<StationPriceSample> matches(
    RadiusAlert alert,
    List<StationPriceSample> samples,
  ) sync* {
    if (!alert.enabled) return;
    for (final s in samples) {
      if (_matches(alert, s)) yield s;
    }
  }

  bool _matches(RadiusAlert alert, StationPriceSample s) {
    if (s.fuelType != alert.fuelType) return false;
    if (s.pricePerLiter > alert.threshold) return false;
    final d = distanceKm(
      alert.centerLat,
      alert.centerLng,
      s.lat,
      s.lng,
    );
    return d <= alert.radiusKm;
  }
}
