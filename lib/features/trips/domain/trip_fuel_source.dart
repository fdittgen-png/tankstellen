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

/// #4330 — the provenance an OBD2 trip's figure carries when the
/// adapter+ECU supported NO fuel PID and `Obd2GpsEstimateFallback`
/// back-filled it from GPS road-load physics (#2431).
///
/// It is not a `FuelRateSourceTag`: no per-sample stamp can carry it,
/// because the samples that produced it have no engine fuel signal at
/// all — that is the whole point. It is written onto the summary by the
/// fallback itself, so the figure's class survives into a summary-only
/// history row exactly like the engine branches do.
const String kGpsPhysicsFuelSourceTag = 'gpsPhysics';

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
    // #4330 — an OBD2 trip whose adapter supported no fuel PID: the
    // figure IS the GPS-physics estimate, so the class is `gps`, not the
    // `none` it fell through to before (which labelled a figure the
    // trip plainly shows as "no per-distance fuel figure exists").
    if (dominant == kGpsPhysicsFuelSourceTag) return TripFuelSourceKind.gps;
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

/// #4321 — the pump gain [summary]'s stored litres actually CARRY: its
/// [TripSummary.pumpGainApplied] (null ≡ 1.0) when the trip is
/// [TripFuelSourceKind.estimated], 1.0 for every other class. The recorder
/// stamps the resolved gain on every trip, but only the estimated branches
/// (MAF / speed-density) multiply by it; a measured or GPS trip divided by
/// its stamp would feed calibration a figure scaled by 1/gain. Readers that
/// strip the gain back to the raw estimator output divide by THIS, never by
/// the raw stamp.
double tripPumpGainCarried(TripSummary summary) =>
    tripFuelSourceKind(summary) == TripFuelSourceKind.estimated
        ? (summary.pumpGainApplied ?? 1.0)
        : 1.0;
