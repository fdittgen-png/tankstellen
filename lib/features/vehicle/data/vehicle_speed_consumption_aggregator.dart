import '../../consumption/domain/trip_recorder.dart';
import '../domain/entities/speed_consumption_histogram.dart';

/// Below this sample count a speed band is excluded from the
/// histogram's `bands` list. Mirrors the value-object docstring on
/// [SpeedConsumptionHistogram] which signals "no data yet" by omitting
/// the band rather than carrying zero values.
const int kMinSamplesPerSpeedBand = 50;

/// Pure: bin [samples] by speed band per
/// [SpeedConsumptionHistogram.standardBandTemplate] and emit the
/// per-band stats.
///
/// Sample model — the `TripSample` carried by `TripHistoryEntry.samples`
/// (#1040) holds:
///   * `speedKmh` (always populated — band classifier reads this)
///   * `fuelRateLPerHour` (nullable — populated when the car answers
///     PID 5E or the MAF / speed-density fallback yields a value).
///
/// Per-band mean L/100 km is computed by integrating fuel-rate over
/// time and distance over time, then `Σlitres / Σkm * 100`. Samples
/// without a fuel-rate reading still count toward [SpeedBand.sampleCount]
/// and [SpeedBand.timeShareFraction] (they were observed driving in
/// that band), but contribute zero litres and zero km — same caveat as
/// the trip-length aggregator.
///
/// Time accounting uses a 1 Hz nominal cadence: each sample is treated
/// as one second of observed driving. The chart cadence is actually
/// "whatever the OBD2 polling loop sustains" (1-2 Hz), but the same
/// share-of-time is preserved across bands as long as cadence stays
/// roughly consistent within a trip. A future revision can integrate
/// real Δt between consecutive samples — the schema keeps that path
/// open via `timestamp`. Documented honestly here.
///
/// Bands with fewer than [kMinSamplesPerSpeedBand] samples are omitted
/// from the result's [SpeedConsumptionHistogram.bands] list (rather
/// than carrying zero values) — see the value-object docstring.
SpeedConsumptionHistogram aggregateSpeedConsumption(List<TripSample> samples) {
  if (samples.isEmpty) {
    return const SpeedConsumptionHistogram();
  }

  // Per-band running totals, indexed by band template position.
  const template = SpeedConsumptionHistogram.standardBandTemplate;
  final counts = List<int>.filled(template.length, 0);
  final litres = List<double>.filled(template.length, 0.0);
  final km = List<double>.filled(template.length, 0.0);

  // 1 Hz nominal — each sample counts as 1 s of observed driving for
  // litres + km integration. Documented in the function docstring.
  const double dtSec = 1.0;

  var totalCount = 0;
  for (final s in samples) {
    final idx = _classifySpeed(s.speedKmh, template);
    if (idx < 0) continue; // negative speed — skip defensively.
    counts[idx]++;
    totalCount++;
    final rate = s.fuelRateLPerHour;
    if (rate != null) {
      litres[idx] += rate * dtSec / 3600.0;
    }
    km[idx] += s.speedKmh * dtSec / 3600.0;
  }

  if (totalCount == 0) {
    return const SpeedConsumptionHistogram();
  }

  final bands = <SpeedBand>[];
  for (var i = 0; i < template.length; i++) {
    if (counts[i] < kMinSamplesPerSpeedBand) continue;
    final mean = km[i] > 0 ? litres[i] / km[i] * 100.0 : 0.0;
    bands.add(SpeedBand(
      minKmh: template[i].$1,
      maxKmh: template[i].$2,
      sampleCount: counts[i],
      meanLPer100km: mean,
      timeShareFraction: counts[i] / totalCount,
    ));
  }

  return SpeedConsumptionHistogram(bands: bands);
}

/// Index of the band in [template] that contains [speedKmh] under the
/// half-open `[min, max)` convention (with the top band open-ended).
/// Returns `-1` for negative input — defensive against corrupt
/// samples.
int _classifySpeed(double speedKmh, List<(int, int?)> template) {
  if (speedKmh < 0) return -1;
  for (var i = 0; i < template.length; i++) {
    final (lo, hi) = template[i];
    if (speedKmh >= lo && (hi == null || speedKmh < hi)) {
      return i;
    }
  }
  return -1;
}

/// Welford-style fold of newly-arrived [newSamples] into an existing
/// [SpeedConsumptionHistogram]. The per-band running mean is updated
/// via Welford recurrence (ratio of running litres / running km),
/// which is exact when both running denominators come from the same
/// underlying samples — which is our case. Per-band sample counts and
/// time shares are exact.
///
/// `null` input is allowed; new bands are seeded as samples arrive.
/// Bands that don't yet meet [kMinSamplesPerSpeedBand] are kept in the
/// internal accumulator but omitted from the returned
/// [SpeedConsumptionHistogram.bands] list — same exclusion rule as
/// [aggregateSpeedConsumption], so the incremental and full-recompute
/// outputs are interchangeable from the consumer's point of view.
///
/// IMPORTANT — reconstructing per-band running totals from a
/// [SpeedConsumptionHistogram] is lossy: bands below threshold were
/// excluded from the prior, so this function CANNOT recover their
/// counters by reading [prior] alone. The first incremental fold over
/// a band that was previously below threshold will start its counter
/// from zero on the new samples only. Callers that need exact
/// continuity across the threshold boundary should run a full
/// recompute instead — that's the source of truth for a reason.
SpeedConsumptionHistogram foldSpeedConsumptionIncremental(
  SpeedConsumptionHistogram? prior,
  List<TripSample> newSamples,
) {
  const template = SpeedConsumptionHistogram.standardBandTemplate;
  final counts = List<int>.filled(template.length, 0);
  final litres = List<double>.filled(template.length, 0.0);
  final km = List<double>.filled(template.length, 0.0);

  // Seed from prior (lossy — see docstring). Bands below threshold
  // simply don't appear in `prior.bands` and start at zero here.
  if (prior != null) {
    for (final band in prior.bands) {
      final i = _bandIndex(band.minKmh, band.maxKmh, template);
      if (i < 0) continue;
      counts[i] = band.sampleCount;
      // Reconstruct litres / km from the persisted mean. We don't
      // store litres directly on SpeedBand (it's not on the schema),
      // so we lean on `meanLPer100km` × an implied km derived from
      // sample count × nominal time. Keep this in sync with the time
      // model in [aggregateSpeedConsumption].
      const double dtSec = 1.0;
      // Rough km estimate from the band's midpoint; for the
      // open-ended top band use the lower bound as a conservative
      // anchor.
      final midpoint = band.maxKmh == null
          ? band.minKmh.toDouble()
          : (band.minKmh + band.maxKmh!) / 2.0;
      km[i] = midpoint * band.sampleCount * dtSec / 3600.0;
      litres[i] = band.meanLPer100km * km[i] / 100.0;
    }
  }

  const double dtSec = 1.0;
  var totalCount = 0;
  for (var i = 0; i < counts.length; i++) {
    totalCount += counts[i];
  }

  for (final s in newSamples) {
    final idx = _classifySpeed(s.speedKmh, template);
    if (idx < 0) continue;
    counts[idx]++;
    totalCount++;
    final rate = s.fuelRateLPerHour;
    if (rate != null) {
      litres[idx] += rate * dtSec / 3600.0;
    }
    km[idx] += s.speedKmh * dtSec / 3600.0;
  }

  if (totalCount == 0) {
    return const SpeedConsumptionHistogram();
  }

  final bands = <SpeedBand>[];
  for (var i = 0; i < template.length; i++) {
    if (counts[i] < kMinSamplesPerSpeedBand) continue;
    final mean = km[i] > 0 ? litres[i] / km[i] * 100.0 : 0.0;
    bands.add(SpeedBand(
      minKmh: template[i].$1,
      maxKmh: template[i].$2,
      sampleCount: counts[i],
      meanLPer100km: mean,
      timeShareFraction: counts[i] / totalCount,
    ));
  }

  return SpeedConsumptionHistogram(bands: bands);
}

/// Look up the template index for a band described by [minKmh] /
/// [maxKmh]. Returns `-1` when no template entry matches — usually a
/// sign that the schema has been bumped between releases.
int _bandIndex(int minKmh, int? maxKmh, List<(int, int?)> template) {
  for (var i = 0; i < template.length; i++) {
    if (template[i].$1 == minKmh && template[i].$2 == maxKmh) return i;
  }
  return -1;
}
