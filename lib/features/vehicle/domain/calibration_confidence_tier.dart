/// User-facing trustworthiness label for a vehicle's consumption
/// calibration (#2027). Surfaced as a small chip on the vehicle
/// calibration screen + the per-trip summary header so the user
/// understands how much to trust the L/100 km figure.
enum CalibrationConfidenceTier {
  /// **GPS-only, no fill-ups.** The consumption estimate is driven
  /// entirely by the vehicle preset (drag area, mass) + GPS speed —
  /// no real measurement has anchored the model. Expected error band:
  /// **±40-60% absolute**.
  a,

  /// **GPS + fill-ups.** At least one full→full fill-up interval
  /// fed the EWMA calibration via [VeLearner], so the consumption
  /// coefficient is anchored to real litres pumped. Expected error
  /// band: **±10-20% per trip, ±5% across a rolling average**.
  b,

  /// **GPS + OBD2 + fill-ups.** Per-tick fuel rate comes from the
  /// engine (PID 0x5E or MAF-derived), the calibration is anchored
  /// against fill-ups, and recent trips are gpsPlusObd2. Expected
  /// error band: **±3-7% per trip, ±1-2% averaged**.
  c;

  /// Stable wire / display label.
  String get label => switch (this) {
        CalibrationConfidenceTier.a => 'A',
        CalibrationConfidenceTier.b => 'B',
        CalibrationConfidenceTier.c => 'C',
      };
}

/// Computes the [CalibrationConfidenceTier] for a vehicle given the
/// signals each tier requires (#2027). Pure function — no Riverpod,
/// no I/O. Caller supplies the two booleans + count derived from
/// the vehicle profile and trip-history snapshots.
///
/// Rules (precedence — most signals → highest tier):
/// 1. OBD2 trip recorded **and** ≥1 full→full fill-up calibrated → **C**
/// 2. ≥1 full→full fill-up calibrated **but no OBD2 trip yet** → **B**
/// 3. Otherwise (no fill-up calibration regardless of OBD2 status) → **A**
///
/// Note: the OBD2-trip signal alone is **not** enough for tier B/C —
/// without a fill-up anchor the engine-derived L/100 km can still
/// drift by a vehicle's `volumetricEfficiency` preset error. That's
/// the entire point of the EWMA loop in [VeLearner].
CalibrationConfidenceTier calibrationConfidenceTier({
  required int volumetricEfficiencySamples,
  required bool hasGpsPlusObd2Trip,
}) {
  final hasFillUpAnchor = volumetricEfficiencySamples > 0;
  if (hasGpsPlusObd2Trip && hasFillUpAnchor) {
    return CalibrationConfidenceTier.c;
  }
  if (hasFillUpAnchor) return CalibrationConfidenceTier.b;
  return CalibrationConfidenceTier.a;
}
