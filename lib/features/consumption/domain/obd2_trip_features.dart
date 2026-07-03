// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'trip_sample.dart';

/// Per-trip aggregate of the **OBD2** telemetry a trip actually captured —
/// the engine-side counterpart to [GpsDrivingFeatures] (#3402 child 1).
///
/// The driving-analysis export historically surfaced only GPS-derived KPIs,
/// so a trip whose adapter streamed RPM / engine-load / throttle / fuel rate
/// showed none of it, and a reader could not tell whether the trip's
/// `avgLPer100Km` was a *measured* fuel-PID figure or a GPS-physics estimate.
/// This aggregate makes the real engine signal — and how much of it the
/// adapter exposed — explicit per trip.
///
/// Pure transform, no I/O. [fromSamples] returns `null` when the trip carried
/// **no** engine signal at all (a GPS-only trip, or an OBD2 trip whose link
/// failed so every read fell back to GPS — see the classic-RFCOMM reconnect
/// hang). A `null` here is therefore the export's honest "0 % OBD2 coverage"
/// marker, not a missing field.
class Obd2TripFeatures {
  /// Total samples in the trip (GPS + OBD2).
  final int sampleCount;

  /// Samples carrying at least one engine signal (RPM / engine-load /
  /// throttle / measured fuel rate). [obd2Coverage] is this over
  /// [sampleCount].
  final int obd2SampleCount;

  /// Fraction of samples with an engine signal — 1.0 on a clean OBD2 trip,
  /// near 0 when the adapter kept dropping and reads fell back to GPS.
  final double obd2Coverage;

  /// Where the trip's fuel figure came from:
  /// - `measured` — at least one real fuel PID landed (PID 5E / MAF / MAP).
  /// - `estimated` — no fuel PID; the GPS-physics fallback supplied it.
  /// - `none` — neither; no per-distance fuel figure is meaningful.
  final Obd2FuelSource fuelSource;

  /// RPM distribution (null-RPM samples excluded). All null on a trip that
  /// never saw PID 0x0C.
  final Obd2SignalDistribution rpm;

  /// Calculated engine load %, PID 0x04 (the captured-but-previously-unused
  /// "uphill vs flat at the same speed" signal).
  final Obd2SignalDistribution engineLoadPercent;

  /// Throttle position %, PID 0x11.
  final Obd2SignalDistribution throttlePercent;

  /// Accelerator-pedal position %, PIDs 0x49/0x4A/0x4B — driver intent.
  final Obd2SignalDistribution pedalPercent;

  /// Absolute load %, PID 0x43 — boosted-engine high-load proxy (>100 % ok).
  final Obd2SignalDistribution absLoadPercent;

  /// Share of RPM samples above 3000 — the high-RPM band the score penalises.
  final double rpmShareAbove3000;

  /// Share of samples idling (engine on, RPM in (0, 1100], speed < 3 km/h).
  final double idleShare;

  /// Peak coolant temperature °C, PID 0x05 (null if never seen).
  final double? coolantMaxC;

  /// Whether coolant reached operating temperature (≥ 80 °C) — a cold trip
  /// burns proportionally more fuel for warm-up.
  final bool reachedOperatingTemp;

  /// Measured wideband equivalence ratio φ (PIDs 0x24–0x2B / 0x34–0x3B,
  /// #3427 / #3433). All-null on cars without a wideband sensor.
  final Obd2SignalDistribution measuredPhi;

  /// Measured ethanol fuel % (PID 0x52, #3429 / #3433). All-null when
  /// unsupported.
  final Obd2SignalDistribution ethanolPercent;

  /// Share of the FUEL-carrying samples per fuel-source branch
  /// (`FuelRateSourceTag` names: `pid9D` / `pidA2` / `pid5E` / `maf66` /
  /// `maf` / `speedDensity`), #3428 / #3433. Empty on legacy trips (no
  /// per-sample provenance was stamped) and on trips without any fuel
  /// signal.
  final Map<String, double> fuelSourceShares;

  /// The branch that produced the MOST fuel-carrying samples — "which
  /// branch dominated the trip" (#3433). Null when [fuelSourceShares] is
  /// empty.
  final String? dominantFuelSource;

  /// Per-signal capture fraction: for each OBD2 field, the share of samples
  /// that carried it. This is the at-a-glance "what did this adapter / ECU
  /// actually expose" map — a `0.0` means the PID is unsupported (or the link
  /// was down), a `1.0` a fully-streamed signal.
  final Map<String, double> signalCoverage;

  const Obd2TripFeatures({
    required this.sampleCount,
    required this.obd2SampleCount,
    required this.obd2Coverage,
    required this.fuelSource,
    required this.rpm,
    required this.engineLoadPercent,
    required this.throttlePercent,
    required this.pedalPercent,
    required this.absLoadPercent,
    required this.rpmShareAbove3000,
    required this.idleShare,
    required this.coolantMaxC,
    required this.reachedOperatingTemp,
    required this.measuredPhi,
    required this.ethanolPercent,
    required this.fuelSourceShares,
    required this.dominantFuelSource,
    required this.signalCoverage,
  });

  /// Build the aggregate from a trip's samples, or `null` when no sample
  /// carried any engine signal (pure-GPS / failed-link trip).
  static Obd2TripFeatures? fromSamples(List<TripSample> samples) {
    if (samples.isEmpty) return null;

    bool hasEngine(TripSample s) =>
        s.rpm != null ||
        s.engineLoadPercent != null ||
        s.throttlePercent != null ||
        s.fuelRateLPerHour != null;

    final obd2Count = samples.where(hasEngine).length;
    if (obd2Count == 0) return null;

    final n = samples.length;

    final rpms = <double>[];
    var rpmAbove3000 = 0;
    var idle = 0;
    for (final s in samples) {
      final r = s.rpm;
      if (r != null) {
        rpms.add(r);
        if (r > 3000) rpmAbove3000++;
        if (r > 0 && r <= 1100 && s.speedKmh < 3) idle++;
      }
    }

    final hasMeasuredFuel = samples.any((s) => s.fuelRateLPerHour != null);
    final hasEstimatedFuel =
        samples.any((s) => s.estimatedFuelRateLPerHour != null);
    final fuelSource = hasMeasuredFuel
        ? Obd2FuelSource.measured
        : hasEstimatedFuel
            ? Obd2FuelSource.estimated
            : Obd2FuelSource.none;

    final coolants = [for (final s in samples) s.coolantTempC]
        .whereType<double>()
        .toList();
    final coolantMax = coolants.isEmpty
        ? null
        : coolants.reduce((a, b) => a > b ? a : b);

    // #3428 / #3433 — per-branch shares of the fuel-carrying samples +
    // the dominant branch. Legacy trips carry no `fuelSource`, so both
    // stay empty/null and old exports are unchanged.
    final branchCounts = <String, int>{};
    var fuelSamples = 0;
    for (final s in samples) {
      final source = s.fuelSource;
      if (s.fuelRateLPerHour == null || source == null) continue;
      fuelSamples++;
      branchCounts[source] = (branchCounts[source] ?? 0) + 1;
    }
    final fuelSourceShares = <String, double>{
      for (final e in branchCounts.entries) e.key: e.value / fuelSamples,
    };
    String? dominant;
    var dominantCount = -1;
    for (final e in branchCounts.entries) {
      if (e.value > dominantCount) {
        dominantCount = e.value;
        dominant = e.key;
      }
    }

    return Obd2TripFeatures(
      sampleCount: n,
      obd2SampleCount: obd2Count,
      obd2Coverage: obd2Count / n,
      fuelSource: fuelSource,
      rpm: Obd2SignalDistribution.from(rpms),
      engineLoadPercent: _distOf(samples, (s) => s.engineLoadPercent),
      throttlePercent: _distOf(samples, (s) => s.throttlePercent),
      pedalPercent: _distOf(samples, (s) => s.pedalPercent),
      absLoadPercent: _distOf(samples, (s) => s.absLoadPercent),
      rpmShareAbove3000: rpms.isEmpty ? 0.0 : rpmAbove3000 / rpms.length,
      idleShare: idle / n,
      coolantMaxC: coolantMax,
      reachedOperatingTemp: coolantMax != null && coolantMax >= 80,
      measuredPhi: _distOf(samples, (s) => s.measuredPhi),
      ethanolPercent: _distOf(samples, (s) => s.ethanolPercent),
      fuelSourceShares: fuelSourceShares,
      dominantFuelSource: dominant,
      signalCoverage: {
        'rpm': _coverage(samples, (s) => s.rpm),
        'fuelRate': _coverage(samples, (s) => s.fuelRateLPerHour),
        'engineLoadPercent': _coverage(samples, (s) => s.engineLoadPercent),
        'absLoadPercent': _coverage(samples, (s) => s.absLoadPercent),
        'throttlePercent': _coverage(samples, (s) => s.throttlePercent),
        'pedalPercent': _coverage(samples, (s) => s.pedalPercent),
        'lambda': _coverage(samples, (s) => s.lambda),
        // #3427 / #3429 — measured wideband φ + ethanol % coverage.
        'measuredPhi': _coverage(samples, (s) => s.measuredPhi),
        'ethanolPercent': _coverage(samples, (s) => s.ethanolPercent),
        'baroKpa': _coverage(samples, (s) => s.baroKpa),
        'maf': _coverage(samples, (s) => s.mafGramsPerSecond),
        'map': _coverage(samples, (s) => s.mapKpa),
        'stft': _coverage(samples, (s) => s.stft),
        'ltft': _coverage(samples, (s) => s.ltft),
        'coolantTempC': _coverage(samples, (s) => s.coolantTempC),
        'oilTempC': _coverage(samples, (s) => s.oilTempC),
        'ambientTempC': _coverage(samples, (s) => s.ambientTempC),
      },
    );
  }

  Map<String, dynamic> toJson() => {
        'sampleCount': sampleCount,
        'obd2SampleCount': obd2SampleCount,
        'obd2Coverage': _r(obd2Coverage, 3),
        'fuelSource': fuelSource.name,
        'rpm': rpm.toJson(),
        'rpmShareAbove3000': _r(rpmShareAbove3000, 3),
        'idleShare': _r(idleShare, 3),
        'engineLoadPercent': engineLoadPercent.toJson(),
        'throttlePercent': throttlePercent.toJson(),
        'pedalPercent': pedalPercent.toJson(),
        'absLoadPercent': absLoadPercent.toJson(),
        'coolantMaxC': coolantMaxC == null ? null : _r(coolantMaxC!, 1),
        'reachedOperatingTemp': reachedOperatingTemp,
        // #3433 — Epic #3416 precision signals: measured wideband φ,
        // ethanol %, and which fuel branch dominated the trip. Additive
        // keys (schema bumped in DrivingAnalysisTrace).
        'measuredPhi': measuredPhi.toJson(),
        'ethanolPercent': ethanolPercent.toJson(),
        'fuelSourceShares': {
          for (final e in fuelSourceShares.entries) e.key: _r(e.value, 3),
        },
        'dominantFuelSource': dominantFuelSource,
        'signalCoverage': {
          for (final e in signalCoverage.entries) e.key: _r(e.value, 3),
        },
      };

  static Obd2SignalDistribution _distOf(
    List<TripSample> samples,
    double? Function(TripSample) pick,
  ) =>
      Obd2SignalDistribution.from(
        [for (final s in samples) pick(s)].whereType<double>().toList(),
      );

  static double _coverage(
    List<TripSample> samples,
    double? Function(TripSample) pick,
  ) {
    if (samples.isEmpty) return 0.0;
    final present = samples.where((s) => pick(s) != null).length;
    return present / samples.length;
  }
}

/// Provenance of a trip's fuel figure (see [Obd2TripFeatures.fuelSource]).
enum Obd2FuelSource { measured, estimated, none }

/// A minimal mean / p95 / coverage summary of one optional signal.
/// `null` fields when the signal was never present so the export omits a
/// fabricated zero.
class Obd2SignalDistribution {
  final double? mean;
  final double? p95;

  /// Fraction of the supplied (already non-null) values — 0.0 when the signal
  /// was absent across the whole trip.
  final double coverage;

  const Obd2SignalDistribution({this.mean, this.p95, required this.coverage});

  /// Build from the non-null values of one signal. [coverage] here is whether
  /// any value was present (1.0) or none (0.0); the per-trip fraction lives in
  /// [Obd2TripFeatures.signalCoverage].
  factory Obd2SignalDistribution.from(List<double> values) {
    if (values.isEmpty) {
      return const Obd2SignalDistribution(coverage: 0.0);
    }
    final sum = values.fold<double>(0, (a, b) => a + b);
    final sorted = [...values]..sort();
    final p95Index = ((sorted.length - 1) * 0.95).ceil();
    return Obd2SignalDistribution(
      mean: sum / values.length,
      p95: sorted[p95Index],
      coverage: 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'mean': mean == null ? null : _r(mean!, 1),
        'p95': p95 == null ? null : _r(p95!, 1),
        'coverage': _r(coverage, 3),
      };
}

double _r(double v, int places) {
  var f = 1.0;
  for (var i = 0; i < places; i++) {
    f *= 10;
  }
  return (v * f).round() / f;
}
