/// Predictive-maintenance trend analyzer for the Trips data layer (#1124).
///
/// Walks the last 30 days of finalised trips and surfaces a small
/// number of [MaintenanceSuggestion]s when one of the pilot heuristics
/// fires:
///
///   * **idle-RPM creep** — the median idle RPM in the second half
///     of the window has risen more than 8 % above the median in the
///     first half. Idle is detected per-trip from the persisted
///     `speedKmh` / `rpm` samples (speed < 5 km/h, rpm > 0).
///   * **MAF deviation (proxy)** — at steady cruise (speed 60–100
///     km/h, rpm 1500–2500), the median `fuelRateLPerHour` in the
///     second half of the window has fallen more than 10 % below the
///     median in the first half. We use fuel rate at a fixed cruise
///     envelope as a proxy for raw MAF mass-flow — restricted intake
///     manifests as a lower steady-cruise fuel rate at the same speed
///     / RPM, and lets us run the heuristic against the data already
///     on disk (raw MAF samples are not persisted today).
///
/// The analyzer is a pure function: feed it a `now` clock and a list
/// of `TripHistoryEntry` and it returns a `List<MaintenanceSuggestion>`
/// (empty when nothing fires, when there is too little data, or when
/// every trip carried zero usable samples for the heuristic). It does
/// not read Hive, Riverpod, or the system clock — the provider does
/// that, this stays trivially testable.
library;

import 'dart:math' as math;

import '../../data/trip_history_repository.dart';
import '../entities/maintenance_suggestion.dart';
import '../trip_recorder.dart';

/// Default thresholds for the two pilot heuristics. Exposed as
/// top-level constants so the provider, the tests, and any future UI
/// "explain why" affordance can read the same source of truth.
class MaintenanceAnalyzerThresholds {
  /// Inclusive cutoff on speed (km/h) for "this sample is at idle".
  /// Matches the recorder's `speedKmh <= 0.5` idle-time accounting,
  /// loosened to 5 km/h here because we need a credible idle median
  /// per trip and the recorder's strict cutoff sometimes leaves us
  /// with five usable samples in a 30-minute trip.
  static const double idleSpeedKmhCutoff = 5.0;

  /// Minimum RPM treated as "engine on". Filters out the spurious
  /// `rpm == 0` samples that the recorder emits during a Bluetooth
  /// reconnect — we only count idle samples while the engine is
  /// actually idling, not while the adapter is dropping data.
  static const double minIdleRpm = 200.0;

  /// Steady-cruise envelope used by the MAF-deviation heuristic. A
  /// generous 60–100 km/h band catches typical highway / boulevard
  /// commutes; the 1500–2500 RPM band keeps us out of low-gear-pull
  /// and out of high-gear-cruise.
  static const double cruiseSpeedMinKmh = 60.0;
  static const double cruiseSpeedMaxKmh = 100.0;
  static const double cruiseRpmMin = 1500.0;
  static const double cruiseRpmMax = 2500.0;

  /// Fractional rise (0.08 == 8 %) in the median idle RPM that triggers
  /// an [MaintenanceSignal.idleRpmCreep] suggestion.
  static const double idleRpmCreepFraction = 0.08;

  /// Fractional drop (0.10 == 10 %) in the median cruise fuel rate
  /// that triggers an [MaintenanceSignal.mafDeviation] suggestion.
  static const double mafDeviationDropFraction = 0.10;

  /// Trip-count gates. Both halves of the 30-day window need at least
  /// [minTripsPerHalf] trips with usable samples for the heuristic to
  /// fire, and the union must reach at least [minTripsTotal] — we
  /// don't fire on three trips on either side of the median because
  /// the half-vs-half compare gets too noisy.
  static const int minTripsPerHalf = 3;
  static const int minTripsTotal = 6;

  /// Trip-count ceiling for the saturating confidence ramp. With
  /// [confidenceCap] usable trips a fired signal hits 100 %
  /// confidence; 10 trips lands at 50 %, 5 trips at 25 %.
  static const int confidenceCap = 20;

  /// Default analysis window in days. Picked so the heuristic can
  /// fire on a typical commuter who logs 1–2 trips per workday — 30
  /// days yields 20–40 candidate trips, well above [minTripsTotal].
  static const int windowDays = 30;
}

/// Run the predictive-maintenance heuristics over [trips].
///
/// [now] anchors the rolling window — `now - windowDays` is the
/// inclusive lower bound on `trip.summary.startedAt`. Trips with a
/// null `startedAt` are skipped (legacy entries that pre-date the
/// timestamping we ship today).
///
/// Returns an empty list when no signal fires, when the trip count
/// falls below the gates, or when none of the trips carry usable
/// samples for the heuristic.
List<MaintenanceSuggestion> analyzeMaintenance({
  required List<TripHistoryEntry> trips,
  required DateTime now,
  int windowDays = MaintenanceAnalyzerThresholds.windowDays,
}) {
  final cutoff = now.subtract(Duration(days: windowDays));
  // Filter to "in-window with a real start timestamp" first — every
  // downstream split / median works against this single list, so
  // walking the trip list once at the entrance keeps the analyzer
  // fast even on a maxed-out 100-trip box.
  final inWindow = <TripHistoryEntry>[];
  for (final t in trips) {
    final startedAt = t.summary.startedAt;
    if (startedAt == null) continue;
    if (startedAt.isBefore(cutoff)) continue;
    if (startedAt.isAfter(now)) continue;
    inWindow.add(t);
  }
  if (inWindow.length < MaintenanceAnalyzerThresholds.minTripsTotal) {
    return const [];
  }

  // Sort oldest-first so the half-split lines up with chronology —
  // first half = older 50 % of the window, second half = newer 50 %.
  // Repository hands us newest-first; we re-sort defensively because
  // the analyzer must not depend on the upstream order.
  inWindow.sort((a, b) {
    final ax = a.summary.startedAt!;
    final bx = b.summary.startedAt!;
    return ax.compareTo(bx);
  });

  final results = <MaintenanceSuggestion>[];

  final idleSignal = _detectIdleRpmCreep(inWindow, now);
  if (idleSignal != null) results.add(idleSignal);

  final mafSignal = _detectMafDeviation(inWindow, now);
  if (mafSignal != null) results.add(mafSignal);

  return results;
}

/// First pilot heuristic: median idle RPM in the second half of the
/// window > 8 % higher than the median in the first half. Returns null
/// when either half has fewer than [MaintenanceAnalyzerThresholds.minTripsPerHalf]
/// trips with usable idle samples.
MaintenanceSuggestion? _detectIdleRpmCreep(
  List<TripHistoryEntry> tripsOldestFirst,
  DateTime now,
) {
  // Per-trip median idle RPM, paired with the trip start so we can
  // split halves on chronology rather than list index — gives a
  // sane behaviour when trip cadence is irregular (vacation week
  // followed by a heavy commute spike etc.).
  final perTripIdle = <_TimedValue>[];
  for (final trip in tripsOldestFirst) {
    final m = _medianIdleRpm(trip.samples);
    if (m == null) continue;
    perTripIdle.add(_TimedValue(at: trip.summary.startedAt!, value: m));
  }
  return _emitHalfSplitSignal(
    perTripValues: perTripIdle,
    now: now,
    triggerWhen: (firstMedian, secondMedian) {
      if (firstMedian <= 0) return null;
      final delta = (secondMedian - firstMedian) / firstMedian;
      if (delta <= MaintenanceAnalyzerThresholds.idleRpmCreepFraction) {
        return null;
      }
      // Report observed delta as a percent (8.0 not 0.08) so the UI
      // copy can render `{percent}%` directly.
      return delta * 100.0;
    },
    signal: MaintenanceSignal.idleRpmCreep,
    nowForStamp: now,
  );
}

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

/// Compute the median RPM over the idle samples in [samples]. Idle =
/// `speedKmh <= idleSpeedKmhCutoff` AND `rpm >= minIdleRpm`. Returns
/// null when fewer than four samples qualify (per-trip medians need
/// some support; one or two ticks at a stoplight aren't enough to
/// claim a "trip-level idle RPM").
double? _medianIdleRpm(List<TripSample> samples) {
  if (samples.isEmpty) return null;
  final idle = <double>[];
  for (final s in samples) {
    if (s.speedKmh > MaintenanceAnalyzerThresholds.idleSpeedKmhCutoff) {
      continue;
    }
    if (s.rpm < MaintenanceAnalyzerThresholds.minIdleRpm) continue;
    idle.add(s.rpm);
  }
  if (idle.length < 4) return null;
  return _median(idle);
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

/// Shared half-split + emit shape used by both heuristics. [triggerWhen]
/// returns the observed delta in percent when the heuristic fires, or
/// null when it doesn't — keeping the half-split / median / confidence
/// math in one place.
MaintenanceSuggestion? _emitHalfSplitSignal({
  required List<_TimedValue> perTripValues,
  required DateTime now,
  required double? Function(double firstMedian, double secondMedian)
      triggerWhen,
  required MaintenanceSignal signal,
  required DateTime nowForStamp,
}) {
  if (perTripValues.length <
      MaintenanceAnalyzerThresholds.minTripsTotal) {
    return null;
  }

  // Split halves on the median timestamp so an even / odd trip count
  // both behave sensibly. `firstHalf` = older trips, `secondHalf` =
  // newer trips.
  final sorted = List<_TimedValue>.from(perTripValues)
    ..sort((a, b) => a.at.compareTo(b.at));
  final mid = sorted.length ~/ 2;
  final firstHalf = sorted.sublist(0, mid);
  final secondHalf = sorted.sublist(mid);

  if (firstHalf.length <
      MaintenanceAnalyzerThresholds.minTripsPerHalf) {
    return null;
  }
  if (secondHalf.length <
      MaintenanceAnalyzerThresholds.minTripsPerHalf) {
    return null;
  }

  final firstMedian =
      _median(firstHalf.map((e) => e.value).toList(growable: false));
  final secondMedian =
      _median(secondHalf.map((e) => e.value).toList(growable: false));

  final observedDelta = triggerWhen(firstMedian, secondMedian);
  if (observedDelta == null) return null;

  final tripCount = perTripValues.length;
  final confidence = math.min(
    1.0,
    tripCount / MaintenanceAnalyzerThresholds.confidenceCap,
  );

  return MaintenanceSuggestion(
    signal: signal,
    confidence: confidence,
    observedDelta: observedDelta,
    sampleTripCount: tripCount,
    computedAt: nowForStamp,
  );
}

/// Median of a non-empty list of doubles. Mutates a local copy via
/// `sort` so the caller's list stays untouched.
double _median(List<double> values) {
  assert(values.isNotEmpty, 'median requires non-empty input');
  final sorted = List<double>.from(values)..sort();
  final n = sorted.length;
  if (n.isOdd) return sorted[n ~/ 2];
  return (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2.0;
}

class _TimedValue {
  final DateTime at;
  final double value;
  const _TimedValue({required this.at, required this.value});
}
