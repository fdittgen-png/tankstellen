import 'entities/charging_log.dart';

/// Pure-Dart pricing math for EV charging logs (#582 phase 1).
///
/// No Riverpod, no Hive, no `package:flutter` imports — intentionally
/// isolate-safe so the phase-2 background aggregator can reuse it
/// without pulling in a widget binding.
///
/// All three public entry points share the same rounding philosophy:
/// divide in `double` (IEEE 754), don't hand-roll precision
/// correction. The UI is expected to format with at most one decimal
/// place, which absorbs the usual floating-point drift.
class ChargingCostCalculator {
  const ChargingCostCalculator._();

  /// EUR cost per 100 km for a single session.
  ///
  /// Throws [ArgumentError] when [kmDriven] is non-positive — a zero
  /// or negative distance is nonsense for a per-100km metric and we
  /// refuse to paper over the bug with a sentinel.
  static double eurPer100km(
    ChargingLog log, {
    required int kmDriven,
  }) {
    if (kmDriven <= 0) {
      throw ArgumentError.value(
        kmDriven,
        'kmDriven',
        'must be a positive distance in kilometres',
      );
    }
    return log.costEur / kmDriven * 100;
  }

  /// Energy consumption per 100 km for a single session, in kWh.
  ///
  /// Throws [ArgumentError] when [kmDriven] is non-positive — see
  /// [eurPer100km] for the rationale.
  static double kWhPer100km(
    ChargingLog log, {
    required int kmDriven,
  }) {
    if (kmDriven <= 0) {
      throw ArgumentError.value(
        kmDriven,
        'kmDriven',
        'must be a positive distance in kilometres',
      );
    }
    return log.kWh / kmDriven * 100;
  }

  /// Cost-weighted mean EUR/100km across a mixed list of sessions.
  ///
  /// Each entry in [segments] describes the odometer window the
  /// matching log in [logs] paid for — `(fromKm, toKm)` — which the
  /// caller typically derives from the previous log's [ChargingLog.odometerKm]
  /// and the current log's [ChargingLog.odometerKm]. Two parallel
  /// lists (rather than a List of pairs) mirrors the way the issue
  /// spec phrased the contract so the phase-2 caller can keep the
  /// segment derivation close to the UI.
  ///
  /// The weighted mean is
  ///
  ///     total_cost_eur / total_km * 100
  ///
  /// which is what the user really wants — it avoids letting a single
  /// very-short trip dominate the average the way a naive arithmetic
  /// mean of per-segment ratios would.
  ///
  /// Returns `0.0` when [logs] is empty so the UI can render "—" or
  /// "no data" without special-casing NaN.
  ///
  /// Throws [ArgumentError] when the two lists differ in length, or
  /// when any segment is non-positive (`toKm <= fromKm`) — the caller
  /// should either drop that entry (no paired trip distance) or flag
  /// it for review. The zero-distance case catches back-to-back logs
  /// with no driving between them; the negative case catches bad
  /// odometer edits.
  static double avgEurPer100km(
    List<ChargingLog> logs,
    List<({int fromKm, int toKm})> segments,
  ) {
    if (logs.isEmpty) return 0.0;
    if (logs.length != segments.length) {
      throw ArgumentError(
        'logs and segments must have the same length '
        '(got ${logs.length} and ${segments.length})',
      );
    }
    double totalCost = 0;
    int totalKm = 0;
    for (var i = 0; i < logs.length; i++) {
      final seg = segments[i];
      final km = seg.toKm - seg.fromKm;
      if (km <= 0) {
        throw ArgumentError.value(
          seg,
          'segments[$i]',
          'every segment must span a positive distance (toKm > fromKm)',
        );
      }
      totalCost += logs[i].costEur;
      totalKm += km;
    }
    if (totalKm == 0) return 0.0;
    return totalCost / totalKm * 100;
  }
}
