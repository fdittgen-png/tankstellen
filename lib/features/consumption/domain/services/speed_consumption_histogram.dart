/// Speed-vs-consumption histogram aggregator (#1192).
///
/// Folds a stream of per-second [TripSample]s into seven fixed
/// [SpeedBand] bins so the Carbon dashboard's Charts tab can show how
/// many L/100 km the user actually burns at each cruising speed. The
/// most actionable lever the driver has is motorway speed: aero drag
/// rises with v², so dropping 130 km/h to 110 km/h typically cuts
/// consumption by 15-25 % on the same car. Surfacing the user's own
/// data is what makes that abstract advice land.
///
/// ## Design notes
///
/// **Pure function** — no Riverpod, no I/O, no DateTime arithmetic
/// beyond what the input already carries. Mirrors the style of
/// `monthly_insights_aggregator.dart` and
/// `throttle_rpm_histogram_calculator.dart` in the same directory.
///
/// **Sample = 1 second.** The OBD2 polling loop runs at ~1 Hz, so we
/// treat each sample as a one-second tick for the time-share metric.
/// This is identical to how `throttle_rpm_histogram_calculator` weights
/// its bins — drift between cadences would matter for sub-second
/// analysis but not for the "how much of my driving is at 130 km/h"
/// question this card answers.
///
/// **Aggregate L/100 km, not mean of per-sample ratios.** The clean
/// formula for a bin's average consumption is
/// `(Σ fuelRateLPerHour) / (Σ speedKmh) * 100`, NOT the arithmetic mean
/// of `(fuelRate / speed * 100)` across samples. The latter would
/// double-count slow ticks (where the ratio explodes) and drift away
/// from the figure the user already sees on the trip-detail screen.
/// This is the harmonic-vs-arithmetic-mean trap most consumption
/// dashboards stumble into.
///
/// **Idle/jam band has no consumption average.** Below 10 km/h the
/// fuelRate / speed ratio is dominated by the speed denominator (a car
/// idling at 2 L/h with `speedKmh = 0.5` reports 400 L/100 km, which
/// is technically correct but useless on a dashboard). The bin still
/// counts samples + time-share so the user sees "12 % of driving was in
/// stop-and-go", but its `avgLPer100Km` is always null.
///
/// ## Bin edges
///
/// Inclusive lower, exclusive upper — a sample at exactly 10.0 km/h
/// goes to [SpeedBand.urban], at exactly 50.0 to [SpeedBand.suburban],
/// at 100.0 to [SpeedBand.motorwaySlow], at 130.0 to
/// [SpeedBand.motorwayFast]. The 130+ band has no upper bound.
///
/// ## Sample skip rules
///
/// * `fuelRateLPerHour == null` → sample dropped from EVERY bin (not
///   counted in time-share either — keeps the time-share comparable to
///   the consumption metric).
/// * `speedKmh < 0` → sensor glitch, sample dropped entirely.
/// * Otherwise the sample is credited to its band's count + time-share,
///   and (if not idle/jam) to the running fuel + speed sums used to
///   compute the bin's average.
library;

import '../trip_recorder.dart';

/// Speed bands the dashboard splits driving into. Order is the
/// declaration order — the aggregator returns one bin per value in
/// this order so consumers can render the bars top-to-bottom without
/// re-sorting.
enum SpeedBand {
  /// 0–10 km/h. Stop-and-go, traffic jams. Counted for time-share but
  /// excluded from the L/100 km average (denominator approaches zero).
  idleJam,

  /// 10–50 km/h. City driving.
  urban,

  /// 50–80 km/h. Mixed roads / boulevards.
  suburban,

  /// 80–100 km/h. Country roads, secondary highways.
  rural,

  /// 100–115 km/h. Eco-cruise — the sweet spot on most modern engines.
  motorwaySlow,

  /// 115–130 km/h. Standard motorway / French highway speed limit.
  motorway,

  /// 130 km/h and above. Above the French limit; German Autobahn fast
  /// lane. Aero drag is dominant here — surfacing this bin lets the
  /// driver see the cost of the last 20 km/h.
  motorwayFast,
}

/// Lower edge (inclusive) of each speed band, in km/h. The
/// declaration order matches [SpeedBand]; `idleJam` starts at 0 by
/// convention and the next band's lower edge is the previous band's
/// exclusive upper edge.
const Map<SpeedBand, double> _speedBandLowerKmh = <SpeedBand, double>{
  SpeedBand.idleJam: 0.0,
  SpeedBand.urban: 10.0,
  SpeedBand.suburban: 50.0,
  SpeedBand.rural: 80.0,
  SpeedBand.motorwaySlow: 100.0,
  SpeedBand.motorway: 115.0,
  SpeedBand.motorwayFast: 130.0,
};

/// One band's aggregate stats. Value type — the widget reads these
/// fields directly.
class SpeedConsumptionBin {
  /// Which band this bin represents.
  final SpeedBand band;

  /// Number of samples that landed in this band. Includes idle/jam
  /// samples (we count time-share even when avg is null).
  final int sampleCount;

  /// Seconds spent in this band, computed as `sampleCount` (each OBD2
  /// tick is treated as one second per the design notes). Stored as a
  /// `double` so future sub-second cadences can be plumbed without a
  /// type change.
  final double timeShareSeconds;

  /// Average L/100 km for this band, or null when:
  ///   * the band is [SpeedBand.idleJam] (denominator-zero);
  ///   * `sampleCount < minSamplesPerBin` (statistical floor — a 30 s
  ///     window on a single PID 5E reading isn't meaningful).
  final double? avgLPer100Km;

  const SpeedConsumptionBin({
    required this.band,
    required this.sampleCount,
    required this.timeShareSeconds,
    required this.avgLPer100Km,
  });
}

/// Default minimum samples per bin before [SpeedConsumptionBin.avgLPer100Km]
/// is exposed. ~30 s of consistent driving in a band is the smallest
/// window where the aggregate L/100 km stops swinging on engine-load
/// noise. Exposed as a parameter so tests can pin the threshold.
const int defaultMinSamplesPerBin = 30;

/// Pick the band an absolute [speedKmh] belongs to. Inclusive lower,
/// exclusive upper — a sample at exactly 10.0 km/h goes to
/// [SpeedBand.urban], at 130.0 to [SpeedBand.motorwayFast].
SpeedBand _bandFor(double speedKmh) {
  if (speedKmh < 10.0) return SpeedBand.idleJam;
  if (speedKmh < 50.0) return SpeedBand.urban;
  if (speedKmh < 80.0) return SpeedBand.suburban;
  if (speedKmh < 100.0) return SpeedBand.rural;
  if (speedKmh < 115.0) return SpeedBand.motorwaySlow;
  if (speedKmh < 130.0) return SpeedBand.motorway;
  return SpeedBand.motorwayFast;
}

/// Fold the [samples] iterable into one [SpeedConsumptionBin] per
/// [SpeedBand], in declaration order. Returns 7 bins always, including
/// empty ones (so the chart can render an empty bar with the band
/// label even when no sample fell in that band).
///
/// `minSamplesPerBin` controls the statistical floor below which a
/// bin's `avgLPer100Km` is reported as null. Defaults to
/// [defaultMinSamplesPerBin].
List<SpeedConsumptionBin> aggregateSpeedConsumption(
  Iterable<TripSample> samples, {
  int minSamplesPerBin = defaultMinSamplesPerBin,
}) {
  return _aggregate(samples, minSamplesPerBin);
}

/// Multi-trip variant: pass an iterable of per-trip sample lists; the
/// function flattens internally and returns the same shape. Behaviour
/// is identical to passing `trips.expand((t) => t)` to
/// [aggregateSpeedConsumption] — the convenience overload exists so the
/// dashboard caller doesn't have to do the flatten dance inline.
List<SpeedConsumptionBin> aggregateSpeedConsumptionMultiTrip(
  Iterable<List<TripSample>> trips, {
  int minSamplesPerBin = defaultMinSamplesPerBin,
}) {
  return _aggregate(trips.expand((t) => t), minSamplesPerBin);
}

/// Shared bin-walk used by both single- and multi-trip variants.
List<SpeedConsumptionBin> _aggregate(
  Iterable<TripSample> samples,
  int minSamplesPerBin,
) {
  // Per-band running counters. Indexed by SpeedBand.index so the loop
  // body stays branchless beyond the band lookup.
  final counts = List<int>.filled(SpeedBand.values.length, 0);
  final fuelSums = List<double>.filled(SpeedBand.values.length, 0.0);
  final speedSums = List<double>.filled(SpeedBand.values.length, 0.0);

  for (final sample in samples) {
    final speed = sample.speedKmh;
    final fuelRate = sample.fuelRateLPerHour;
    if (fuelRate == null) continue; // No consumption data → skip entirely.
    if (speed < 0) continue; // Sensor glitch.

    final band = _bandFor(speed);
    final idx = band.index;
    counts[idx]++;
    if (band != SpeedBand.idleJam) {
      // Idle/jam samples are counted for time-share only — including
      // them in the fuel/speed sums would skew the average for any
      // bin's neighbour at low speed.
      fuelSums[idx] += fuelRate;
      speedSums[idx] += speed;
    }
  }

  return <SpeedConsumptionBin>[
    for (final band in SpeedBand.values)
      _buildBin(
        band: band,
        sampleCount: counts[band.index],
        fuelSum: fuelSums[band.index],
        speedSum: speedSums[band.index],
        minSamplesPerBin: minSamplesPerBin,
      ),
  ];
}

/// Construct one [SpeedConsumptionBin] from its accumulated counters.
/// Encapsulates the avg-null rules so [_aggregate] stays focused on the
/// per-sample loop.
SpeedConsumptionBin _buildBin({
  required SpeedBand band,
  required int sampleCount,
  required double fuelSum,
  required double speedSum,
  required int minSamplesPerBin,
}) {
  double? avg;
  // Two reasons avg stays null:
  //   1. The band is idleJam (per spec — division by ~zero is meaningless).
  //   2. Sample count is below the statistical floor — a thin sliver
  //      of seconds isn't enough to trust the figure.
  if (band != SpeedBand.idleJam &&
      sampleCount >= minSamplesPerBin &&
      speedSum > 0) {
    avg = (fuelSum / speedSum) * 100.0;
  }
  return SpeedConsumptionBin(
    band: band,
    sampleCount: sampleCount,
    timeShareSeconds: sampleCount.toDouble(),
    avgLPer100Km: avg,
  );
}

/// Lower edge (inclusive) of [band], in km/h. Exposed for the widget's
/// label-formatting helpers — keeps the band-edge constants in one
/// place even if the UI changes how they're rendered.
double speedBandLowerKmh(SpeedBand band) => _speedBandLowerKmh[band]!;
