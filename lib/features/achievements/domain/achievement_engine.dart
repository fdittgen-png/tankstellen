import '../../consumption/data/trip_history_repository.dart';
import '../../consumption/domain/entities/fill_up.dart';
import 'achievement.dart';

/// Pure-function rules that derive earned badges from the user's
/// activity (#781). Separated from the Hive/Riverpod plumbing so
/// every rule can be unit-tested against synthetic fixtures.
///
/// The engine is additive: it inspects current activity and returns
/// the set of badge ids that are *now* earned. The repository layer
/// merges that with persisted earned badges so the `earnedAt` of an
/// already-earned badge is preserved on later evaluations.
class AchievementEngine {
  static const double _zeroHarshMinDistanceKm = 10.0;

  /// `smoothDriver` requires this many consecutive trips with a
  /// driving-score above [_smoothDriverScoreThreshold].
  static const int _smoothDriverStreakLength = 5;
  static const int _smoothDriverScoreThreshold = 80;

  /// Maximum allowed gap between adjacent trips in the
  /// `smoothDriver` streak. Two-week gap absorbs ordinary holidays
  /// without breaking the streak.
  static const Duration _smoothDriverMaxGap = Duration(days: 14);

  /// `coldStartAware` requires the monthly cold-start excess to be
  /// below this fraction of the month's total fuel.
  static const double _coldStartAwareMaxRatio = 0.02;

  /// Months with fewer than this many trips are skipped — the
  /// aggregate is not representative.
  static const int _coldStartAwareMinTripsPerMonth = 3;

  /// `highwayMaster` thresholds.
  static const double _highwayMasterMinDistanceKm = 30.0;
  static const int _highwayMasterMinScore = 90;
  static const double _highwayMasterMaxSpeedStdDev = 8.0;

  /// Evaluate every rule and return the set of badge ids currently
  /// earned based on [trips] and [fillUps]. [hasPriceWin] is a
  /// pre-computed flag — the price-history lookup lives outside
  /// the engine so it stays a pure function, trivially testable.
  ///
  /// [scoresByTripId] (#1041 phase 5) is an optional pre-computed
  /// map of `tripId -> 0-100 driving-score`. The achievement
  /// provider derives this once per evaluation via `TripMetrics`;
  /// the engine treats a missing entry as "score unknown" and
  /// excludes the trip from score-based rules.
  ///
  /// [coldStartExcessLByTripId] (#1041 phase 5) is the matching
  /// `tripId -> cold-start excess litres` map. Same semantics —
  /// missing entries treated as zero excess (does not penalise the
  /// month's ratio).
  ///
  /// [speedStdDevByTripId] (#1041 phase 5) is the matching
  /// `tripId -> speed std-dev (km/h)` map across non-idle
  /// samples. Missing entries treated as `double.infinity` so the
  /// trip cannot satisfy `highwayMaster`.
  ///
  /// Order is deterministic (iteration order of
  /// [AchievementId.values]).
  Set<AchievementId> evaluate({
    required List<TripHistoryEntry> trips,
    required List<FillUp> fillUps,
    bool hasPriceWin = false,
    Map<String, int>? scoresByTripId,
    Map<String, double>? coldStartExcessLByTripId,
    Map<String, double>? speedStdDevByTripId,
  }) {
    final earned = <AchievementId>{};
    if (trips.isNotEmpty) {
      earned.add(AchievementId.firstTrip);
    }
    if (fillUps.isNotEmpty) {
      earned.add(AchievementId.firstFillUp);
    }
    if (trips.length >= 10) {
      earned.add(AchievementId.tenTrips);
    }
    if (_anyZeroHarshTrip(trips)) {
      earned.add(AchievementId.zeroHarshTrip);
    }
    if (_hasEcoWeekStreak(trips)) {
      earned.add(AchievementId.ecoWeek);
    }
    if (hasPriceWin) {
      earned.add(AchievementId.priceWin);
    }
    final scores = scoresByTripId ?? const <String, int>{};
    final coldStarts = coldStartExcessLByTripId ?? const <String, double>{};
    final stdDevs = speedStdDevByTripId ?? const <String, double>{};
    if (_hasSmoothDriverStreak(trips, scores)) {
      earned.add(AchievementId.smoothDriver);
    }
    if (_hasColdStartAwareMonth(trips, coldStarts)) {
      earned.add(AchievementId.coldStartAware);
    }
    if (_hasHighwayMasterTrip(trips, scores, stdDevs)) {
      earned.add(AchievementId.highwayMaster);
    }
    return earned;
  }

  bool _anyZeroHarshTrip(List<TripHistoryEntry> trips) {
    for (final t in trips) {
      final s = t.summary;
      if (s.distanceKm >= _zeroHarshMinDistanceKm &&
          s.harshBrakes == 0 &&
          s.harshAccelerations == 0) {
        return true;
      }
    }
    return false;
  }

  /// Check every 7-consecutive-day window in the log. For each
  /// window, if each of the 7 calendar days has at least one trip
  /// that qualifies as "eco" (≥10 km, zero harsh events), the
  /// streak counts. The rolling window means once the user earns
  /// the badge it stays earned, even if next week they skip a day.
  bool _hasEcoWeekStreak(List<TripHistoryEntry> trips) {
    final ecoDays = <DateTime>{};
    for (final t in trips) {
      final s = t.summary;
      final startedAt = s.startedAt;
      if (startedAt == null) continue;
      if (s.distanceKm < _zeroHarshMinDistanceKm) continue;
      if (s.harshBrakes != 0 || s.harshAccelerations != 0) continue;
      ecoDays.add(DateTime(startedAt.year, startedAt.month, startedAt.day));
    }
    if (ecoDays.length < 7) return false;
    final sorted = ecoDays.toList()..sort();
    var streak = 1;
    for (var i = 1; i < sorted.length; i++) {
      final gap = sorted[i].difference(sorted[i - 1]).inDays;
      if (gap == 1) {
        streak++;
        if (streak >= 7) return true;
      } else if (gap > 1) {
        streak = 1;
      }
      // gap == 0 would mean duplicate same-day; impossible since the
      // set dedupes. Fall through.
    }
    return false;
  }

  /// `smoothDriver` — five consecutive trips (ordered by startedAt)
  /// each with score ≥ 80 and no >14-day gap between adjacent
  /// trips. Trips with no `startedAt` are skipped (cannot be
  /// ordered). Once earned, always earned — the rolling search
  /// across the trip log mirrors `_hasEcoWeekStreak`.
  bool _hasSmoothDriverStreak(
    List<TripHistoryEntry> trips,
    Map<String, int> scoresByTripId,
  ) {
    final ordered = [
      for (final t in trips)
        if (t.summary.startedAt != null) t,
    ]..sort(
        (a, b) => a.summary.startedAt!.compareTo(b.summary.startedAt!),
      );
    if (ordered.length < _smoothDriverStreakLength) return false;

    var streak = 0;
    DateTime? previousStart;
    for (final t in ordered) {
      final score = scoresByTripId[t.id];
      final start = t.summary.startedAt!;
      final gapTooLong = previousStart != null &&
          start.difference(previousStart).abs() > _smoothDriverMaxGap;
      if (score == null || score < _smoothDriverScoreThreshold || gapTooLong) {
        streak = 0;
        previousStart = start;
        continue;
      }
      streak++;
      previousStart = start;
      if (streak >= _smoothDriverStreakLength) return true;
    }
    return false;
  }

  /// `coldStartAware` — at least one calendar month where the sum of
  /// per-trip cold-start excess litres is below 2 % of the month's
  /// total fuel consumed. Months with fewer than 3 fuel-recording
  /// trips are skipped because the aggregate is not representative.
  ///
  /// "Fuel-recording" means the trip has both a non-null
  /// [TripSummary.fuelLitersConsumed] and an entry in
  /// [coldStartByTripId]. A user with no cold-start data at all
  /// (legacy trips, no fuel-rate sensor) cannot earn the badge —
  /// the rule needs real signal, not a vacuously-true "0 / 0".
  bool _hasColdStartAwareMonth(
    List<TripHistoryEntry> trips,
    Map<String, double> coldStartByTripId,
  ) {
    // Group by year-month from startedAt.
    final byMonth = <String, List<TripHistoryEntry>>{};
    for (final t in trips) {
      final start = t.summary.startedAt;
      if (start == null) continue;
      final key = '${start.year}-${start.month.toString().padLeft(2, '0')}';
      byMonth.putIfAbsent(key, () => []).add(t);
    }
    for (final entries in byMonth.values) {
      var totalFuel = 0.0;
      var totalCold = 0.0;
      var fuelRecordingTrips = 0;
      for (final t in entries) {
        final fuel = t.summary.fuelLitersConsumed;
        if (fuel == null || fuel <= 0) continue;
        if (!coldStartByTripId.containsKey(t.id)) continue;
        fuelRecordingTrips++;
        totalFuel += fuel;
        totalCold += coldStartByTripId[t.id]!;
      }
      if (fuelRecordingTrips < _coldStartAwareMinTripsPerMonth) continue;
      if (totalFuel <= 0) continue;
      if (totalCold / totalFuel < _coldStartAwareMaxRatio) return true;
    }
    return false;
  }

  /// `highwayMaster` — any single trip with distance ≥ 30 km, score
  /// ≥ 90, and speed std-dev across non-idle samples ≤ 8 km/h.
  bool _hasHighwayMasterTrip(
    List<TripHistoryEntry> trips,
    Map<String, int> scoresByTripId,
    Map<String, double> speedStdDevByTripId,
  ) {
    for (final t in trips) {
      if (t.summary.distanceKm < _highwayMasterMinDistanceKm) continue;
      final score = scoresByTripId[t.id];
      if (score == null || score < _highwayMasterMinScore) continue;
      final stdDev = speedStdDevByTripId[t.id] ?? double.infinity;
      if (stdDev <= _highwayMasterMaxSpeedStdDev) return true;
    }
    return false;
  }
}
