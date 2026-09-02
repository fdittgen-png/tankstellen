// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'trip_sample.dart';
import 'trip_summary.dart';

/// Where a trip's fuel figure came from, at the granularity the badges
/// need (#3919, Epic #3914).
enum TripFuelSourceKind {
  /// The ECU reported the fuel rate itself (PID 5E / 9D / A2) — never
  /// rescaled by the pump gain.
  measured,

  /// An estimated branch (MAF / speed-density) — the pump gain applies.
  estimated,

  /// The GPS-physics estimate; no engine data at all.
  gps,

  /// No per-distance fuel figure exists.
  none,
}

/// `FuelRateSourceTag` names that mean "the ECU reported fuel".
const Set<String> kMeasuredFuelSourceTags = {'pid9D', 'pidA2', 'pid5E'};

/// `FuelRateSourceTag` names that mean "estimated from air mass".
const Set<String> kEstimatedFuelSourceTags = {'maf66', 'maf', 'speedDensity'};

/// The branch that produced the MOST fuel-carrying samples, by the
/// per-sample provenance stamp ([TripSample.fuelSource]); null when no
/// sample carries one (legacy / GPS-only trips). Stamped onto
/// [TripSummary.dominantFuelSource] at persist time so the summary-only
/// history list can badge a trip without materialising its samples.
String? dominantFuelSourceOf(Iterable<TripSample> samples) {
  final counts = <String, int>{};
  for (final s in samples) {
    final tag = s.fuelSource;
    if (tag == null || tag == 'none') continue;
    counts[tag] = (counts[tag] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  String? best;
  var bestCount = -1;
  for (final e in counts.entries) {
    if (e.value > bestCount) {
      best = e.key;
      bestCount = e.value;
    }
  }
  return best;
}

/// Classify [summary] (#3919). The dominant per-sample provenance wins;
/// a legacy trip without one is `estimated` when every litre was
/// speed-density-derived ([TripSummary.volumetricEfficiencyUsed] is
/// non-null exactly then) and otherwise honestly unknown → [none] for
/// the badge (a measured trip must never be rescaled by guesswork).
TripFuelSourceKind tripFuelSourceKind(TripSummary summary) {
  if (summary.isVirtual) return TripFuelSourceKind.none;
  if (summary.avgLPer100Km == null && summary.fuelLitersConsumed == null) {
    return summary.estimatedAvgLPer100Km != null
        ? TripFuelSourceKind.gps
        : TripFuelSourceKind.none;
  }
  // A GPS-only trip's `avgLPer100Km` IS the GPS-physics estimate
  // (#2080 / #2431) — no engine branch ever produced it.
  if (summary.kind == TripKind.gpsOnly) return TripFuelSourceKind.gps;
  final dominant = summary.dominantFuelSource;
  if (dominant != null) {
    if (kMeasuredFuelSourceTags.contains(dominant)) {
      return TripFuelSourceKind.measured;
    }
    if (kEstimatedFuelSourceTags.contains(dominant)) {
      return TripFuelSourceKind.estimated;
    }
  }
  if (summary.volumetricEfficiencyUsed != null) {
    return TripFuelSourceKind.estimated;
  }
  return TripFuelSourceKind.none;
}
