/// Aggregated metrics for a single driving trip (#718).
///
/// Extracted from `trip_recorder.dart` (#1927 — keeps that file under
/// the 400-line guard); re-exported from there so existing importers
/// are unaffected.
class TripSummary {
  final double distanceKm;
  final double maxRpm;
  final double highRpmSeconds;
  final double idleSeconds;
  final int harshBrakes;
  final int harshAccelerations;
  /// Average fuel consumption in L/100 km. Null when the trip carried
  /// no fuel-rate samples (cars without PID 5E / MAF).
  final double? avgLPer100Km;
  /// Estimated fuel burned during the trip, in litres. Null when the
  /// trip carried no fuel-rate samples. This is what the "save as
  /// fill-up" flow pre-fills into the liters field (#726).
  final double? fuelLitersConsumed;
  final DateTime? startedAt;
  final DateTime? endedAt;

  /// Provenance flag for [distanceKm] (#800). Either `'real'` — the
  /// value came from the car's odometer (`odometerLatest -
  /// odometerStart`) — or `'virtual'` — the value is the trapezoidal
  /// integration of speed samples from [VirtualOdometer]. UI /
  /// analytics use this to decide whether to trust the km figure as a
  /// ground truth (fuel-reconciliation denominator) or flag it as an
  /// estimate. Defaults to `'virtual'` because the recorder
  /// integrates speed even when an odometer is available — legacy
  /// trips before this flag landed keep that honest label.
  final String distanceSource;

  /// Whether this trip likely paid a cold-start fuel surcharge
  /// (#1262 phase 2). Flipped true when the coolant temperature
  /// telemetry suggests the engine was warming up for a meaningful
  /// portion of the trip — short trips that never reached operating
  /// temperature, trips where the coolant max stayed below 70 °C, or
  /// trips that only crossed 70 °C in the second half. Cars without
  /// PID 0x05 produce no coolant samples, so the flag stays false to
  /// avoid false positives on absent data. UI surfaces (Phase 3)
  /// render a chip on the trip card based on this bit.
  final bool coldStartSurcharge;

  /// Seconds during the trip the engine was in a lower gear than
  /// optimal — heuristic: in-gear-N when N+1 would let RPM drop below
  /// `optimalRpmCeiling` (≈ 2200 RPM). Computed from
  /// `gear_inference.dart` outputs at trip end. Null = no inference
  /// (no centroids, EV, insufficient samples).
  final double? secondsBelowOptimalGear;

  /// Whether the fuel-rate samples that produced [fuelLitersConsumed]
  /// / [avgLPer100Km] tripped the cross-check sanity bounds at a
  /// meaningful rate during the trip (#1395). Set true at trip end
  /// when the breadcrumb collector reports
  /// `suspiciousSampleCount / totalSampleCount > 0.3` — i.e. more
  /// than 30 % of samples were either implausibly low (RPM > 1500
  /// AND L/h < 0.3) or showed > 50 % divergence between PID 5E and
  /// the MAF-derived rate. Stays false when no samples or no flagged
  /// samples were recorded; UI surfaces (#1395 phase 4) render a chip
  /// on the trip summary card based on this bit.
  final bool fuelRateSuspect;

  /// Fuel-weighted mean volumetric efficiency (η_v) the trip's fuel was
  /// integrated with (#1858), or null when the trip is **not**
  /// η_v-recalculable.
  ///
  /// Speed-density fuel scales linearly with η_v, so a stored trip can
  /// be retroactively recomputed for a corrected η_v by
  /// `fuelLitersConsumed × (newVe / volumetricEfficiencyUsed)` — but
  /// only when *every* litre was speed-density-derived. This field is
  /// non-null exactly then: it carries the fuel-weighted mean of the
  /// per-tick η_v actually applied. It is null when any fuel came from
  /// PID 5E or the MAF branch (neither uses η_v — rescaling would
  /// corrupt that portion), when the trip burned no fuel, and for
  /// legacy trips recorded before #1858. A null value means "not
  /// recalculable" and such trips are left untouched by a recompute.
  final double? volumetricEfficiencyUsed;

  const TripSummary({
    required this.distanceKm,
    required this.maxRpm,
    required this.highRpmSeconds,
    required this.idleSeconds,
    required this.harshBrakes,
    required this.harshAccelerations,
    this.avgLPer100Km,
    this.fuelLitersConsumed,
    this.startedAt,
    this.endedAt,
    this.distanceSource = 'virtual',
    this.coldStartSurcharge = false,
    this.secondsBelowOptimalGear,
    this.fuelRateSuspect = false,
    this.volumetricEfficiencyUsed,
  });

  /// Returns a copy with the given fields replaced (#1858). Used by the
  /// retroactive η_v recompute to rescale `fuelLitersConsumed` /
  /// `avgLPer100Km` and re-stamp `volumetricEfficiencyUsed`. A passed
  /// null keeps the existing value — the recompute never needs to
  /// *clear* a field, so the simple form is sufficient.
  TripSummary copyWith({
    double? distanceKm,
    double? maxRpm,
    double? highRpmSeconds,
    double? idleSeconds,
    int? harshBrakes,
    int? harshAccelerations,
    double? avgLPer100Km,
    double? fuelLitersConsumed,
    DateTime? startedAt,
    DateTime? endedAt,
    String? distanceSource,
    bool? coldStartSurcharge,
    double? secondsBelowOptimalGear,
    bool? fuelRateSuspect,
    double? volumetricEfficiencyUsed,
  }) =>
      TripSummary(
        distanceKm: distanceKm ?? this.distanceKm,
        maxRpm: maxRpm ?? this.maxRpm,
        highRpmSeconds: highRpmSeconds ?? this.highRpmSeconds,
        idleSeconds: idleSeconds ?? this.idleSeconds,
        harshBrakes: harshBrakes ?? this.harshBrakes,
        harshAccelerations: harshAccelerations ?? this.harshAccelerations,
        avgLPer100Km: avgLPer100Km ?? this.avgLPer100Km,
        fuelLitersConsumed: fuelLitersConsumed ?? this.fuelLitersConsumed,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        distanceSource: distanceSource ?? this.distanceSource,
        coldStartSurcharge: coldStartSurcharge ?? this.coldStartSurcharge,
        secondsBelowOptimalGear:
            secondsBelowOptimalGear ?? this.secondsBelowOptimalGear,
        fuelRateSuspect: fuelRateSuspect ?? this.fuelRateSuspect,
        volumetricEfficiencyUsed:
            volumetricEfficiencyUsed ?? this.volumetricEfficiencyUsed,
      );
}
