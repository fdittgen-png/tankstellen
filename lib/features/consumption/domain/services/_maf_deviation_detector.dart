/// MAF-deviation pilot heuristic for [MaintenanceAnalyzer] (#1124).
///
/// Split out of `maintenance_analyzer.dart` to keep that file under the
/// 300-LOC budget (Refs #563). The heuristic stays internal to the
/// analyzer library via `part of` — no public API surface changes.
part of 'maintenance_analyzer.dart';

/// Second pilot heuristic: median cruise fuel rate in the second half
/// of the window > 10 % lower than the median in the first half. Same
/// half-split machinery as the idle creep detector — only the per-trip
/// reduction differs.
MaintenanceSuggestion? _detectMafDeviation(
  List<TripHistoryEntry> tripsOldestFirst,
  DateTime now,
) {
  final perTripCruise = <_TimedValue>[];
  for (final trip in tripsOldestFirst) {
    final m = _medianCruiseFuelRate(trip.samples);
    if (m == null) continue;
    perTripCruise.add(_TimedValue(at: trip.summary.startedAt!, value: m));
  }
  return _emitHalfSplitSignal(
    perTripValues: perTripCruise,
    now: now,
    triggerWhen: (firstMedian, secondMedian) {
      if (firstMedian <= 0) return null;
      final delta = (firstMedian - secondMedian) / firstMedian;
      if (delta <= MaintenanceAnalyzerThresholds.mafDeviationDropFraction) {
        return null;
      }
      return delta * 100.0;
    },
    signal: MaintenanceSignal.mafDeviation,
    nowForStamp: now,
  );
}

/// Compute the median fuel rate during steady-cruise samples in
/// [samples]. Cruise = speed `[60, 100]` km/h AND rpm `[1500, 2500]`.
/// Returns null when fewer than four samples qualify or when the
/// trip's recording stack didn't carry the fuel-rate PID (older car
/// without PID 5E or MAF).
double? _medianCruiseFuelRate(List<TripSample> samples) {
  if (samples.isEmpty) return null;
  final rates = <double>[];
  for (final s in samples) {
    final fuel = s.fuelRateLPerHour;
    if (fuel == null) continue;
    if (s.speedKmh < MaintenanceAnalyzerThresholds.cruiseSpeedMinKmh) {
      continue;
    }
    if (s.speedKmh > MaintenanceAnalyzerThresholds.cruiseSpeedMaxKmh) {
      continue;
    }
    if (s.rpm < MaintenanceAnalyzerThresholds.cruiseRpmMin) continue;
    if (s.rpm > MaintenanceAnalyzerThresholds.cruiseRpmMax) continue;
    rates.add(fuel);
  }
  if (rates.length < 4) return null;
  return _median(rates);
}
