// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'obd2_breadcrumb_collector.dart';

/// Diagnostic collaborator extracted from
/// `Obd2Service.readFuelRateLPerHour` (#2191). Owns the breadcrumb /
/// cross-check side-channel so the read method itself reads as a clean
/// three-step fallback: compute the value, delegate the diagnostics.
///
/// The breadcrumb trace (which PID path resolved the rate, the
/// stoichiometric constants in play) and the two sanity bounds
/// (suspicious-low at cruise, PID 5E vs MAF divergence) were
/// previously interleaved into the hot read path (#1395). Pulling them
/// here keeps the read method behaviour-identical — same breadcrumbs
/// emitted, same value returned — while isolating the "why does the
/// trip say 1 L/100 km" diagnostics into one testable unit.
///
/// Construct one per `readFuelRateLPerHour` call: it captures the
/// per-call resolved constants (AFR, density, displacement, VE) plus
/// the live-read tear-offs the cross-checks need, so the read method
/// passes only the branch-specific values at each emit point.
///
/// All methods are no-ops when [collector] is null — the production
/// one-shot read paths (e.g. VIN decode) wire no collector, and the
/// `?.` short-circuit must stay free.
class FuelRateDiagnostics {
  /// The optional ring-buffer recorder. Null on paths that don't trace
  /// fuel-rate samples; every emit method short-circuits when absent.
  final Obd2BreadcrumbRecorder? collector;

  /// Stoichiometric AFR resolved for this read (14.7 petrol, 14.5
  /// diesel, or a manual override). Stamped on every breadcrumb and
  /// used to derive the MAF cross-check rate.
  final double afr;

  /// Fuel density in g/L resolved for this read. Stamped on every
  /// breadcrumb and used to derive the MAF cross-check rate.
  final double fuelDensityGPerL;

  /// Engine displacement in cc (pre-coerced to double for the
  /// recorder, which renders it as a plain number). Stamped on every
  /// breadcrumb.
  final double engineDisplacementCc;

  /// Volumetric efficiency resolved for this read. Stamped on every
  /// breadcrumb.
  final double volumetricEfficiency;

  /// Reads current engine RPM. Used by the suspicious-low sanity bound
  /// (a sub-0.3 L/h reading at > 1500 RPM is almost always noise).
  final Future<double?> Function() readRpm;

  /// Whether PID 0x10 (MAF) is implemented. Gates the 5E-vs-MAF
  /// cross-check — skipped entirely on cars without a MAF sensor.
  final bool Function() isMafSupported;

  /// Reads mass air flow in g/s. Used by the 5E-vs-MAF cross-check.
  final Future<double?> Function() readMaf;

  const FuelRateDiagnostics({
    required this.collector,
    required this.afr,
    required this.fuelDensityGPerL,
    required this.engineDisplacementCc,
    required this.volumetricEfficiency,
    required this.readRpm,
    required this.isMafSupported,
    required this.readMaf,
  });

  /// Records the PID 5E direct-read breadcrumb and runs both sanity
  /// bounds against it:
  ///
  ///   - **A (suspicious-low):** a `directRate < 0.3 L/h` while the
  ///     engine is spinning above 1500 RPM flags the sample but does
  ///     NOT drop it — the caller still surfaces the value; the
  ///     suspicion ratio rolls up at trip-end.
  ///   - **B (5E-vs-MAF divergence):** when MAF is also available, the
  ///     MAF-derived rate is compared; > 50 % divergence flags the
  ///     most-recent breadcrumb as `5e-vs-maf-divergent`.
  ///
  /// Issues at most one extra RPM read (only when [directRate] is
  /// already below the 0.3 L/h floor) and one extra MAF read (only
  /// when MAF is supported) — identical to the inlined behaviour.
  Future<void> recordPid5E(double directRate) async {
    final recorder = collector;
    if (recorder == null) return;

    // Sanity bound A: implausibly-low at non-idle RPM. PID 5E values
    // < 0.3 L/h while the engine is spinning above 1500 RPM are almost
    // always sensor noise / stuck PID — flag but DON'T drop.
    String? lowFlag;
    String? lowDetail;
    double? rpmAtSample;
    if (directRate < 0.3) {
      rpmAtSample = await readRpm();
      if (rpmAtSample != null && rpmAtSample > 1500) {
        lowFlag = Obd2BreadcrumbCollector.flagSuspiciousLow;
        lowDetail = 'directRate=${directRate.toStringAsFixed(2)};'
            'rpm=${rpmAtSample.toStringAsFixed(0)}';
      }
    }
    recorder.record(
      branch: Obd2BranchTag.pid5E,
      fuelRateLPerHour: directRate,
      pid5ELPerHour: directRate,
      rpm: rpmAtSample,
      afr: afr,
      fuelDensityGPerL: fuelDensityGPerL,
      engineDisplacementCc: engineDisplacementCc,
      volumetricEfficiency: volumetricEfficiency,
      flag: lowFlag,
      flagDetail: lowDetail,
    );

    // Sanity bound B: when MAF is also available, run the MAF-derived
    // rate and compare. > 50 % divergence flags the sample as
    // 5e-vs-maf-divergent. The diagnostic value is in having BOTH
    // numbers side-by-side — the caller still uses the direct reading.
    if (isMafSupported()) {
      final mafCross = await readMaf();
      if (mafCross != null) {
        final mafDerived = mafCross * 3600.0 / (afr * fuelDensityGPerL);
        if (mafDerived > 0 &&
            (directRate - mafDerived).abs() / mafDerived > 0.5) {
          recorder.recordFlag(
            Obd2BreadcrumbCollector.flag5eVsMafDivergent,
            'direct=${directRate.toStringAsFixed(2)};'
                'mafDerived=${mafDerived.toStringAsFixed(2)};'
                'maf=${mafCross.toStringAsFixed(2)}',
          );
        }
      }
    }
  }

  /// Records the mass-based-branch breadcrumb (PID 0x9D / 0xA2, #3428)
  /// and, when the 0x5E tear-offs are supplied, runs the 9D-vs-5E
  /// divergence cross-check: both are ECU-reported fuel figures, so a
  /// > 50 % gap flags a mis-scaled 0x9D implementation or a stuck 0x5E
  /// (`9d-vs-5e-divergent`). The caller still surfaces [rateLPerHour].
  ///
  /// The breadcrumb row is tagged [Obd2BranchTag.pid5E] — the overlay's
  /// tag enum is frozen (its exhaustive switch lives in presentation code
  /// owned by the #3431/#3432 pass); the trip-level provenance is carried
  /// by `FuelRateSourceTag` instead.
  Future<void> recordMassRate(
    double rateLPerHour, {
    bool Function()? isPid5ESupported,
    Future<double?> Function()? readPid5E,
  }) async {
    final recorder = collector;
    if (recorder == null) return;
    recorder.record(
      branch: Obd2BranchTag.pid5E,
      fuelRateLPerHour: rateLPerHour,
      afr: afr,
      fuelDensityGPerL: fuelDensityGPerL,
      engineDisplacementCc: engineDisplacementCc,
      volumetricEfficiency: volumetricEfficiency,
    );
    if (isPid5ESupported != null &&
        readPid5E != null &&
        isPid5ESupported()) {
      final direct5e = await readPid5E();
      if (direct5e != null &&
          direct5e > 0 &&
          (rateLPerHour - direct5e).abs() / direct5e > 0.5) {
        recorder.recordFlag(
          Obd2BreadcrumbCollector.flag9dVs5eDivergent,
          'rate9d=${rateLPerHour.toStringAsFixed(2)};'
              'pid5e=${direct5e.toStringAsFixed(2)}',
        );
      }
    }
  }

  /// Records the MAF-branch breadcrumb. [corrected] is the trim-applied
  /// rate the caller surfaces; [maf] is the raw g/s read.
  void recordMaf({required double corrected, required double maf}) {
    collector?.record(
      branch: Obd2BranchTag.maf,
      fuelRateLPerHour: corrected,
      mafGramsPerSecond: maf,
      afr: afr,
      fuelDensityGPerL: fuelDensityGPerL,
      engineDisplacementCc: engineDisplacementCc,
      volumetricEfficiency: volumetricEfficiency,
    );
  }

  /// Records the speed-density-branch breadcrumb. [corrected] is the
  /// trim-applied rate; the MAP / IAT / RPM inputs are stamped for the
  /// overlay.
  void recordSpeedDensity({
    required double corrected,
    required double mapKpa,
    required double iatCelsius,
    required double rpm,
  }) {
    collector?.record(
      branch: Obd2BranchTag.speedDensity,
      fuelRateLPerHour: corrected,
      mapKpa: mapKpa,
      iatCelsius: iatCelsius,
      rpm: rpm,
      afr: afr,
      fuelDensityGPerL: fuelDensityGPerL,
      engineDisplacementCc: engineDisplacementCc,
      volumetricEfficiency: volumetricEfficiency,
    );
  }

  /// Records a `none`-branch breadcrumb — no fuel-rate value resolved
  /// this tick. Captured for completeness so the overlay can show
  /// "[--] no rate" rows. [mapKpa] / [iatCelsius] / [rpm] are the
  /// partial speed-density inputs gathered so far (any may be null).
  void recordNoBranch({
    double? mapKpa,
    double? iatCelsius,
    double? rpm,
  }) {
    collector?.record(
      branch: Obd2BranchTag.none,
      mapKpa: mapKpa,
      iatCelsius: iatCelsius,
      rpm: rpm,
      afr: afr,
      fuelDensityGPerL: fuelDensityGPerL,
      engineDisplacementCc: engineDisplacementCc,
      volumetricEfficiency: volumetricEfficiency,
    );
  }
}
