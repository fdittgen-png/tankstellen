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
  /// earned based on [trips] and [fillUps]. Order is deterministic
  /// (iteration order of [AchievementId.values]).
  Set<AchievementId> evaluate({
    required List<TripHistoryEntry> trips,
    required List<FillUp> fillUps,
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
}
