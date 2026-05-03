/// In-memory ring buffer that captures every fuel-rate sample the
/// OBD2 stack produces during a recording trip — the raw inputs (PID
/// 5E read, MAF read, MAP/IAT/RPM samples), the resolved branch
/// ([Obd2BranchTag]) that fired, the AFR / density / displacement /
/// volumetric-efficiency actually used, and any sanity flag that
/// tripped (#1395). Sibling to the map breadcrumb collector shipped
/// in #1316 phase 2 / PR #1378.
///
/// Diagnostic motivation: PID 5E values that drift implausibly low at
/// cruise have been the #1 source of "trip summary says 1 L/100 km"
/// support reports. The MAF-vs-5E divergence guard catches the
/// classic symptom (dirty MAF reading high while 5E reports
/// post-trim 0.2 L/h) without requiring the user to ship a logcat.
///
/// The buffer is in-memory only — not persisted across launches —
/// because the only useful data is the trace from the current trip
/// (the previous trip's data is already in [TripHistoryEntry]). A
/// 200-entry cap is enough to capture three minutes at 1 Hz plus
/// some headroom for back-pressure spikes; older entries drop on
/// overflow.
library;

/// Branch tag stamped on each fuel-rate breadcrumb so the overlay can
/// colour-group rows by which fallback tier resolved the value.
enum Obd2BranchTag {
  /// PID 5E direct fuel rate (post-trim, no correction applied).
  pid5E,

  /// MAF-derived rate (`L/h = MAF × 3600 / (AFR × density)`).
  maf,

  /// Speed-density estimate from MAP + IAT + RPM (#800).
  speedDensity,

  /// No branch resolved — every input was unavailable. Captured for
  /// completeness so the overlay can show "[--] no rate" rows during
  /// the warm-up window before any PID has landed.
  none,
}

/// One fuel-rate breadcrumb. The fields mirror what a debugging user
/// (or developer) needs in order to reason about a suspicious
/// L/100 km figure on a trip summary:
///
///   - [branch] — which tier fired (5E / MAF / SD / none).
///   - [fuelRateLPerHour] — the value the trip recorder integrated.
///   - [pid5ELPerHour] — the raw PID 5E read (when present).
///   - [mafGramsPerSecond] — the raw MAF read (when present).
///   - [mapKpa] / [iatCelsius] / [rpm] — the speed-density inputs.
///   - [afr] / [fuelDensityGPerL] — the stoichiometric constants used.
///   - [engineDisplacementCc] / [volumetricEfficiency] — vehicle
///     parameters that fed the speed-density math.
///   - [flag] — any sanity flag the collector recorded for this
///     sample. Null when the sample looks normal.
///   - [flagDetail] — free-form payload describing the flag (e.g.
///     `directRate=0.18;rpm=2200`). Null when [flag] is null.
class Obd2Breadcrumb {
  /// When the breadcrumb was recorded.
  final DateTime at;

  /// Which fuel-rate fallback tier resolved the value.
  final Obd2BranchTag branch;

  /// L/h actually surfaced to the trip recorder. Null when the branch
  /// is [Obd2BranchTag.none] — the trip recorder skipped the sample.
  final double? fuelRateLPerHour;

  /// Raw PID 5E read in L/h, when the car returned a value this tick.
  /// Null when PID 5E is unsupported / NO DATA.
  final double? pid5ELPerHour;

  /// Raw MAF in g/s, when the car returned a value this tick. Null
  /// when MAF is unsupported / NO DATA.
  final double? mafGramsPerSecond;

  /// Manifold absolute pressure in kPa for the speed-density branch.
  final double? mapKpa;

  /// Intake air temperature in Celsius for the speed-density branch.
  final double? iatCelsius;

  /// Engine RPM. Captured on every sample so suspicious-low at cruise
  /// can be reasoned about ("0.2 L/h at 2300 RPM is impossible").
  final double? rpm;

  /// Stoichiometric AFR used for the MAF / SD path (14.7 petrol,
  /// 14.5 diesel).
  final double? afr;

  /// Fuel density in g/L used for the MAF / SD path (745 petrol,
  /// 832 diesel).
  final double? fuelDensityGPerL;

  /// Engine displacement in cc fed to the speed-density estimator.
  final double? engineDisplacementCc;

  /// Volumetric efficiency fed to the speed-density estimator.
  final double? volumetricEfficiency;

  /// Sanity-flag tag, when this sample tripped a guard. See
  /// [Obd2BreadcrumbCollector.recordFlag] for the canonical strings.
  final String? flag;

  /// Free-form payload describing the flag (e.g.
  /// `directRate=0.18;rpm=2200`). Null when [flag] is null.
  final String? flagDetail;

  const Obd2Breadcrumb({
    required this.at,
    required this.branch,
    this.fuelRateLPerHour,
    this.pid5ELPerHour,
    this.mafGramsPerSecond,
    this.mapKpa,
    this.iatCelsius,
    this.rpm,
    this.afr,
    this.fuelDensityGPerL,
    this.engineDisplacementCc,
    this.volumetricEfficiency,
    this.flag,
    this.flagDetail,
  });
}

/// Common write-side interface implemented by both
/// [Obd2BreadcrumbCollector] (raw, unit-test friendly) and the
/// Riverpod-backed `Obd2BreadcrumbsNotifier` (so production writes
/// republish the state list to the in-app overlay).
abstract class Obd2BreadcrumbRecorder {
  void record({
    required Obd2BranchTag branch,
    double? fuelRateLPerHour,
    double? pid5ELPerHour,
    double? mafGramsPerSecond,
    double? mapKpa,
    double? iatCelsius,
    double? rpm,
    double? afr,
    double? fuelDensityGPerL,
    double? engineDisplacementCc,
    double? volumetricEfficiency,
    String? flag,
    String? flagDetail,
  });

  void recordFlag(String flag, String detail);

  /// Snapshot of the current sample / flag counts for the trip-end
  /// suspicion-rate calculation, AND reset of the running counters so
  /// a subsequent recording starts clean. Implementations preserve
  /// the entry list — the overlay still renders the trace post-trip
  /// until the user explicitly clears it.
  ({int total, int suspicious}) snapshotAndResetCounters();
}

/// Ring buffer of recent OBD2 fuel-rate breadcrumbs, plus a running
/// flag tally for the trip-summary `fuelRateSuspect` heuristic.
/// Capped at [maxEntries]; oldest drop on overflow. Pure in-memory —
/// not persisted across launches (#1395).
class Obd2BreadcrumbCollector implements Obd2BreadcrumbRecorder {
  /// Maximum number of breadcrumbs retained. At 1 Hz that's 200 s
  /// (~3 min) of recent history — enough to scroll the overlay back
  /// far enough to see the start of a suspicious-low cluster without
  /// growing the in-memory footprint unboundedly on long trips.
  static const int maxEntries = 200;

  /// Canonical flag tag — fuel rate is implausibly low for the RPM.
  /// Recorded on PID 5E samples where `rpm > 1500` AND `directRate <
  /// 0.3 L/h`. Doesn't drop the sample — the trip integrator still
  /// uses the value, but the suspicion-rate is rolled up to the
  /// trip summary at end-of-trip.
  static const String flagSuspiciousLow = 'suspicious-low';

  /// Canonical flag tag — PID 5E and MAF disagree by more than 50%.
  /// Recorded when both are present this tick. Indicator of either a
  /// dirty MAF (reading high) or a stuck PID 5E (reading low / 0).
  static const String flag5eVsMafDivergent = '5e-vs-maf-divergent';

  final List<Obd2Breadcrumb> _entries = [];

  /// How many samples have ever been recorded this trip — i.e. how
  /// many times [record] was called, regardless of whether the sample
  /// also tripped a flag. Used as the denominator in the trip-end
  /// suspicion ratio.
  int _totalSampleCount = 0;

  /// How many of the recorded samples tripped any sanity flag. Used
  /// as the numerator in the trip-end suspicion ratio.
  int _suspiciousSampleCount = 0;

  /// Read-only view of the current buffer, oldest-first.
  List<Obd2Breadcrumb> get entries => List.unmodifiable(_entries);

  /// Total samples seen this trip. See [_totalSampleCount].
  int get totalSampleCount => _totalSampleCount;

  /// Samples that tripped any sanity flag this trip. See
  /// [_suspiciousSampleCount].
  int get suspiciousSampleCount => _suspiciousSampleCount;

  /// Records one fuel-rate breadcrumb. When the buffer is full
  /// (length == [maxEntries]) the oldest entry is dropped before
  /// appending the new one. Increments [totalSampleCount] regardless;
  /// also increments [suspiciousSampleCount] when [flag] is non-null.
  @override
  void record({
    required Obd2BranchTag branch,
    double? fuelRateLPerHour,
    double? pid5ELPerHour,
    double? mafGramsPerSecond,
    double? mapKpa,
    double? iatCelsius,
    double? rpm,
    double? afr,
    double? fuelDensityGPerL,
    double? engineDisplacementCc,
    double? volumetricEfficiency,
    String? flag,
    String? flagDetail,
  }) {
    if (_entries.length >= maxEntries) {
      _entries.removeAt(0);
    }
    _entries.add(Obd2Breadcrumb(
      at: DateTime.now(),
      branch: branch,
      fuelRateLPerHour: fuelRateLPerHour,
      pid5ELPerHour: pid5ELPerHour,
      mafGramsPerSecond: mafGramsPerSecond,
      mapKpa: mapKpa,
      iatCelsius: iatCelsius,
      rpm: rpm,
      afr: afr,
      fuelDensityGPerL: fuelDensityGPerL,
      engineDisplacementCc: engineDisplacementCc,
      volumetricEfficiency: volumetricEfficiency,
      flag: flag,
      flagDetail: flagDetail,
    ));
    _totalSampleCount++;
    if (flag != null) _suspiciousSampleCount++;
  }

  /// Records a sanity flag against the most-recent breadcrumb without
  /// adding a new entry — useful when the flag is detected by a
  /// downstream check after the breadcrumb was already pushed (e.g.
  /// the 5E-vs-MAF divergence cross-check). Increments
  /// [suspiciousSampleCount]. No-op when the buffer is empty (the
  /// caller hasn't recorded a baseline sample yet).
  @override
  void recordFlag(String flag, String detail) {
    if (_entries.isEmpty) return;
    final last = _entries.removeLast();
    _entries.add(Obd2Breadcrumb(
      at: last.at,
      branch: last.branch,
      fuelRateLPerHour: last.fuelRateLPerHour,
      pid5ELPerHour: last.pid5ELPerHour,
      mafGramsPerSecond: last.mafGramsPerSecond,
      mapKpa: last.mapKpa,
      iatCelsius: last.iatCelsius,
      rpm: last.rpm,
      afr: last.afr,
      fuelDensityGPerL: last.fuelDensityGPerL,
      engineDisplacementCc: last.engineDisplacementCc,
      volumetricEfficiency: last.volumetricEfficiency,
      flag: flag,
      flagDetail: detail,
    ));
    _suspiciousSampleCount++;
  }

  /// Snapshot of the current sample / flag counts for the trip-end
  /// suspicion-rate calculation, then resets the running counters
  /// (but not the entry list — the overlay can keep showing the trace
  /// after the trip ends until the user explicitly clears it).
  @override
  ({int total, int suspicious}) snapshotAndResetCounters() {
    final snapshot = (
      total: _totalSampleCount,
      suspicious: _suspiciousSampleCount,
    );
    _totalSampleCount = 0;
    _suspiciousSampleCount = 0;
    return snapshot;
  }

  /// Empties the buffer AND resets the running counters.
  void clear() {
    _entries.clear();
    _totalSampleCount = 0;
    _suspiciousSampleCount = 0;
  }
}
