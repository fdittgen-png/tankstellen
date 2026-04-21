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

  /// Evaluate every rule and return the set of badge ids currently
  /// earned based on [trips] and [fillUps]. [hasPriceWin] is a
  /// pre-computed flag — the price-history lookup lives outside
  /// the engine so it stays a pure function, trivially testable.
  /// Order is deterministic (iteration order of
  /// [AchievementId.values]).
  Set<AchievementId> evaluate({
    required List<TripHistoryEntry> trips,
    required List<FillUp> fillUps,
    bool hasPriceWin = false,
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
}
