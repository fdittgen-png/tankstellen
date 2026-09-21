// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'fleet_kpis.dart';

/// The exception list the manager dashboard opens with (#4216).
///
/// Split out of `fleet_kpis.dart` so the aggregation and the JUDGEMENT
/// stay separable: the roll-up says what the period was, this file
/// says what is worth a second look, and the thresholds below are the
/// only opinionated numbers in the slice.

/// Why a fleet or a vehicle is on the "Needs attention" list (#4216).
///
/// Exceptions about VEHICLES and DATA, never a ranking of people:
/// #4214 rules out manager-facing driver scores, so nothing here names
/// an employee and nothing here orders anyone.
enum FleetAttentionKind {
  /// Cost per km well above the fleet's own median, after the period's
  /// figures — a vehicle to look at, not a driver to blame.
  costPerKmOutlier,

  /// Less than half the vehicle's fuel sits inside measured distance,
  /// so its efficiency figure rests on very little.
  lowMeasuredCoverage,

  /// No odometer evidence at all: cost/km and L/100 km cannot be
  /// stated for this vehicle.
  noDistanceEvidence,

  /// A grade in the period has no published emission factor, so the
  /// report says "not calculated" (#4219).
  co2NotCalculated,

  /// The period mixes currencies, so there is no fleet total.
  mixedCurrency,

  /// Vehicles exist that the aggregation threshold hides (D5.3).
  rowsSuppressed,
}

/// One entry of the "Needs attention" list: what, and about which
/// vehicle when it is about one.
typedef FleetAttentionItem = ({
  FleetAttentionKind kind,
  String? fleetVehicleId,
});

/// The exceptions worth a manager's attention, fleet-level first.
///
/// Deterministic order — fleet-wide findings, then per-vehicle ones in
/// the order the rows arrived — so the same period always reads the
/// same way.
List<FleetAttentionItem> fleetAttention(
  FleetKpis kpis, {
  double outlierFactor = 1.25,
  double minMeasuredShare = 0.5,
}) {
  final out = <FleetAttentionItem>[];
  if (!kpis.isSingleCurrency) {
    out.add((kind: FleetAttentionKind.mixedCurrency, fleetVehicleId: null));
  }
  if (kpis.suppressedCount > 0) {
    out.add((kind: FleetAttentionKind.rowsSuppressed, fleetVehicleId: null));
  }
  final costs = <String, double>{
    for (final r in kpis.reported)
      if (r.costPerKm.valueOrNull case final double c) r.fleetVehicleId: c,
  };
  final median = _median(costs.values.toList()..sort());
  for (final r in kpis.reported) {
    final id = r.fleetVehicleId;
    final cost = costs[id];
    if (median != null && cost != null && cost > median * outlierFactor) {
      out.add((kind: FleetAttentionKind.costPerKmOutlier, fleetVehicleId: id));
    }
    if (!r.km.value.isKnown) {
      out.add((kind: FleetAttentionKind.noDistanceEvidence, fleetVehicleId: id));
    } else if (r.measuredShare.valueOrNull case final double s
        when s < minMeasuredShare) {
      out.add(
          (kind: FleetAttentionKind.lowMeasuredCoverage, fleetVehicleId: id));
    }
    if (!r.co2eKg.value.isKnown) {
      out.add((kind: FleetAttentionKind.co2NotCalculated, fleetVehicleId: id));
    }
  }
  return List.unmodifiable(out);
}

/// The middle value of a SORTED list, or null when it is empty.
double? _median(List<double> sorted) {
  if (sorted.isEmpty) return null;
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}
