// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Shared reliability gates for a trip's fuel-economy figure (#2835).
///
/// A real backup (2022 Skoda diesel, Italy, vLinker BM) surfaced two
/// data-quality failure modes in the per-trip L/100 km the recorder
/// integrates:
///
///   1. **Tiny-distance blow-up.** A 0.4 km trip integrated to 306
///      L/100 km, a 3.5 km trip to 60. The litres figure is dominated by
///      a single cold-start enrichment burst or one stop-and-go cycle,
///      and dividing it by a sub-kilometre denominator amplifies that
///      noise into an absurd headline. Worse, those outliers poisoned the
///      simple mean of per-trip averages (19.3 vs the true distance-
///      weighted aggregate of 6.7 L/100 km).
///
///   2. **Sparse-cadence under-count.** A 58.8 km trip carried only 126
///      samples (~1/min). Trapezoidal integration of `fuelRateLPerHour`
///      across a 60 s interval assumes the rate was constant for a whole
///      minute — wildly wrong across an accel/coast/brake cycle — so the
///      integral collapses toward zero and the trip reports ~0 L/100 km
///      despite real distance and real samples.
///
/// Both gates live here as pure predicates so the live recorder
/// ([TripRecorder.buildSummary]) and any re-integrating aggregate apply
/// the SAME thresholds — no parallel-implementation drift.
library;

/// Minimum trip distance (km) below which an integrated L/100 km figure
/// is treated as unreliable and suppressed to null. Below ~1 km a single
/// warm-up burst dominates the litres numerator while the denominator is
/// tiny, so the ratio blows up. 1 km is the smallest denominator at
/// which a normal drive's litres divide to a sane figure.
const double kMinReliableConsumptionDistanceKm = 1.0;

/// Maximum mean fuel-integration interval (seconds) below which the
/// trapezoidal `fuelRateLPerHour` integral is trusted. When samples
/// arrive on average farther apart than this, each interval assumes a
/// constant fuel rate over too long a window to integrate honestly, so
/// the resulting litres (and L/100 km) are marked unavailable rather
/// than reported as a near-zero artefact. 30 s comfortably admits the
/// usual 1–2 Hz OBD2 / GPS cadence and the occasional skipped poll — it
/// matches the loosest gap the live integrators are willing to bridge
/// (the GPS-only recorder's 30 s `maxIntegrationGapSeconds`) — but
/// rejects the ~60 s cadence that produced the 0-L/100 km field trip.
const double kMaxReliableFuelIntervalSeconds = 30.0;

/// Whether a trip's fuel was integrated densely enough to trust the
/// LITRES figure (#2835 failure mode 2 — sparse-cadence under-count).
///
/// `false` (→ caller should report `fuelLitersConsumed` AND
/// `avgLPer100Km` null, since the litres themselves are unreliable) when
/// no interval contributed litres ([fuelIntervalCount] == 0) or the mean
/// fuel-integration interval ([fuelIntegratedSeconds] /
/// [fuelIntervalCount]) exceeds [kMaxReliableFuelIntervalSeconds].
///
/// Pass the recorder's fuel-integration bookkeeping: [fuelIntervalCount]
/// is the number of intervals that actually contributed litres, and
/// [fuelIntegratedSeconds] is their summed Δt.
bool isFuelCadenceReliable({
  required int fuelIntervalCount,
  required double fuelIntegratedSeconds,
}) {
  if (fuelIntervalCount <= 0) return false;
  final meanIntervalSeconds = fuelIntegratedSeconds / fuelIntervalCount;
  return meanIntervalSeconds <= kMaxReliableFuelIntervalSeconds;
}

/// Whether the trip's distance is a trustworthy denominator for an
/// L/100 km ratio (#2835 failure mode 1 — tiny-distance blow-up).
///
/// `false` (→ caller should report `avgLPer100Km` null but may still
/// keep the measured `fuelLitersConsumed`, which is a real quantity)
/// when [distanceKm] is below [kMinReliableConsumptionDistanceKm].
bool isDistanceReliableForRatio(double distanceKm) =>
    distanceKm >= kMinReliableConsumptionDistanceKm;

/// Whether a trip's integrated L/100 km is reliable enough to surface as
/// the trip's headline figure and to feed an average — the AND of both
/// gates ([isFuelCadenceReliable] + [isDistanceReliableForRatio]).
bool isTripConsumptionReliable({
  required double distanceKm,
  required int fuelIntervalCount,
  required double fuelIntegratedSeconds,
}) =>
    isDistanceReliableForRatio(distanceKm) &&
    isFuelCadenceReliable(
      fuelIntervalCount: fuelIntervalCount,
      fuelIntegratedSeconds: fuelIntegratedSeconds,
    );
