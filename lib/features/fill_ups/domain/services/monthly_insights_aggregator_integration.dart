// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'monthly_insights_aggregator.dart';

/// #3918 — the per-trip integration helpers of [aggregateMonthlyInsights]
/// (sample re-integration, the summary litres fallback, climb metres),
/// split out as a `part` so the aggregator stays under the #1680
/// file-length cap. Move-only apart from the `scale` factor the
/// pump-gain re-expression multiplies the litres by.

/// #2447 — fold a trip's canonical litres into the consumption average
/// from the summary, used when no per-tick fuel-rate series exists
/// (GPS-only / EV / no-fuel-PID / legacy). Adds the canonical litres
/// over [distanceKm] only when BOTH are meaningful — a trip with no
/// litres figure and no GPS estimate ([tripConsumedLitersOrNull] null)
/// or zero distance stays out of the average, so honest "no data" is
/// never zero-filled.
void _addSummaryFuelFallback(
  _MonthBucket bucket,
  TripSummary summary,
  double distanceKm,
  double scale,
) {
  if (distanceKm <= 0) return;
  final litres = tripConsumedLitersOrNull(summary);
  if (litres == null || litres <= 0) return;
  bucket.fuelLitres += litres * scale;
  bucket.consumptionDistanceKm += distanceKm;
}

/// Result of re-integrating a trip's per-tick samples. Carries the fuel
/// cadence bookkeeping (#2835) alongside distance + litres so the caller
/// can apply [isTripConsumptionReliable] — the same gate the live
/// recorder uses.
typedef _Integration = ({
  double distanceKm,
  double fuelLitres,
  bool hadFuelRate,
  int fuelIntervalCount,
  double fuelIntegratedSeconds,
});

/// Walk the per-tick samples and return the re-integrated distance +
/// fuel plus the cadence bookkeeping. Mirrors `TripRecorder.onSample` so
/// the per-trip figures the user already sees on the trip detail screen
/// line up with the monthly aggregate (no parallel-implementation drift).
_Integration _integrateSamples(List<TripSample> samples) {
  const empty = (
    distanceKm: 0.0,
    fuelLitres: 0.0,
    hadFuelRate: false,
    fuelIntervalCount: 0,
    fuelIntegratedSeconds: 0.0,
  );
  if (samples.length < 2) return empty;
  final sorted = [...samples]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  double distanceKm = 0;
  double fuelLitres = 0;
  bool hadFuelRate = false;
  int fuelIntervalCount = 0;
  double fuelIntegratedSeconds = 0;

  for (var i = 1; i < sorted.length; i++) {
    final prev = sorted[i - 1];
    final cur = sorted[i];
    final dt = cur.timestamp.difference(prev.timestamp).inMicroseconds /
        Duration.microsecondsPerSecond;
    if (dt <= 0) continue;

    final avgSpeedKmh = (prev.speedKmh + cur.speedKmh) / 2.0;
    distanceKm += avgSpeedKmh * dt / 3600.0;

    if (prev.fuelRateLPerHour != null && cur.fuelRateLPerHour != null) {
      final avgRate = (prev.fuelRateLPerHour! + cur.fuelRateLPerHour!) / 2.0;
      fuelLitres += avgRate * dt / 3600.0;
      hadFuelRate = true;
      fuelIntervalCount++;
      fuelIntegratedSeconds += dt;
    }
  }

  return (
    distanceKm: distanceKm,
    fuelLitres: fuelLitres,
    hadFuelRate: hadFuelRate,
    fuelIntervalCount: fuelIntervalCount,
    fuelIntegratedSeconds: fuelIntegratedSeconds,
  );
}

/// Sum of positive altitude deltas (metres climbed) across [samples]
/// (#2697 P3). Samples without altitude contribute nothing.
double _climbMeters(List<TripSample> samples) {
  if (samples.length < 2) return 0;
  final sorted = [...samples]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  double climb = 0;
  for (var i = 1; i < sorted.length; i++) {
    final pAlt = sorted[i - 1].altitudeM, cAlt = sorted[i].altitudeM;
    if (pAlt != null && cAlt != null && cAlt > pAlt) climb += cAlt - pAlt;
  }
  return climb;
}

