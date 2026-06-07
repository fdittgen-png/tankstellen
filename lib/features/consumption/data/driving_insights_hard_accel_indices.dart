// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Hard-acceleration episode → sample-index helper for the trip-detail map
/// (#1458 phase 1), extracted from `driving_insights_analyzer.dart` so that
/// file stays under the 400-line guard (Epic #3015). It is a map-marker
/// helper, not a cost-line producer, so it lives on its own.
library;

import '../domain/accel_event_gate.dart';
import '../presentation/widgets/trip_detail_charts.dart';

/// Returns one index per hard-acceleration EPISODE (in the
/// sorted-by-timestamp ordering): the end index of the interval at which
/// the episode first crossed the canonical [kHardAccelThresholdMps2]
/// sustained ≥ 1 s, via the ONE shared [countAccelEvents] gate (#2667).
/// The trip-detail map drops a bolt marker at each (#1458 phase 1).
///
/// Reconciled (#2667): markers now come from the same gate the analyzer's
/// hard-accel count uses, so a single physical hard accel yields ONE
/// marker — not one per qualifying sample interval as the old raw
/// per-interval logic produced on a multi-second pull.
///
/// Sorting + dt-guard contract (delegated to the gate):
///   * input is copied + sorted by timestamp before iteration so an
///     out-of-order list never spuriously reports an event;
///   * intervals with `dt <= 0` are skipped (duplicate timestamps);
///   * the first sample (index 0) is never an event because there's
///     no previous sample to derive an acceleration from.
///
/// IMPORTANT: the returned indices reference positions in the
/// INTERNALLY-SORTED list, NOT the caller's input order. The trip-detail
/// map already passes timestamp-sorted samples, so it can use them
/// directly.
List<int> hardAccelSampleIndices(List<TripDetailSample> samples) {
  if (samples.length < 2) return const <int>[];
  return countAccelEvents([
    for (final s in samples)
      // TripDetailSample carries no horizontal accuracy — pass null
      // ("unknown, accept") so the gate behaves exactly as before for the
      // accuracy dimension while still applying the shared sustained-window
      // + min-speed + canonical-threshold gate.
      AccelSamplePoint(timestamp: s.timestamp, speedKmh: s.speedKmh),
  ]).accelStartIndices;
}
