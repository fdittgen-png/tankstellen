import 'package:flutter/foundation.dart';

/// Gamification badges (#781 phase 1). Deliberately small and
/// hand-tuned — every badge has to pay off the leitmotiv (save at the
/// pump or save at the wheel). No participation trophies.
enum AchievementId {
  /// First OBD2 trip recorded. Onboarding nudge.
  firstTrip,

  /// First fill-up logged. Onboarding nudge.
  firstFillUp,

  /// Ten OBD2 trips recorded. Volume milestone that proves the
  /// user has integrated the trip recorder into their routine.
  tenTrips,

  /// One trip with zero harsh-brake + zero harsh-accel events and
  /// at least 10 km of distance. Rewards smooth driving, not just
  /// short drives that trivially have no events.
  zeroHarshTrip,

  /// Seven consecutive calendar days, each with at least one trip
  /// of ≥10 km and zero harsh events. Rewards sustained smooth
  /// driving — a single good day isn't enough. The streak window
  /// is rolling: any 7-day stretch in the log qualifies, not just
  /// the most recent one.
  ecoWeek,

  /// At least one logged fill-up beat the station's 30-day average
  /// price for that fuel type by ≥5 %. Rewards the "save at the
  /// pump" lens directly — the user timed their visit well.
  priceWin,

  /// Five consecutive trips, ordered by `summary.startedAt`, each
  /// with a driving-score (#1041 phase 5 derived metric) of ≥ 80
  /// and no gap of more than 14 days between adjacent trips. Trips
  /// without a `startedAt` are skipped (cannot be ordered).
  /// Rewards a sustained smooth-driving streak — one good trip is
  /// already covered by [zeroHarshTrip].
  smoothDriver,

  /// At least one calendar month where the total cold-start excess
  /// fuel sums to less than 2 % of that month's total fuel
  /// consumed. Months with fewer than 3 trips are skipped because
  /// the aggregate isn't representative. Rewards the "combine
  /// short trips" lens of the leitmotiv.
  coldStartAware,

  /// One single trip with distance ≥ 30 km, driving-score ≥ 90
  /// and tight speed std-dev (≤ 8 km/h across non-idle samples).
  /// Rewards a long, consistent highway run — the situation where
  /// driving smoothness has the biggest fuel-saving payoff.
  highwayMaster,
}

/// An achievement the user has earned. `earnedAt` is the moment the
/// rule first evaluated true — persisted so re-computing rules after
/// later trips doesn't re-surface the same badge with a new date.
@immutable
class EarnedAchievement {
  final AchievementId id;
  final DateTime earnedAt;

  const EarnedAchievement({required this.id, required this.earnedAt});

  Map<String, dynamic> toJson() => {
        'id': id.name,
        'earnedAt': earnedAt.toIso8601String(),
      };

  static EarnedAchievement? fromJson(Map<String, dynamic> json) {
    final idName = json['id'] as String?;
    final earnedIso = json['earnedAt'] as String?;
    if (idName == null || earnedIso == null) return null;
    final id = AchievementId.values
        .where((e) => e.name == idName)
        .firstOrNull;
    if (id == null) return null;
    try {
      return EarnedAchievement(
        id: id,
        earnedAt: DateTime.parse(earnedIso),
      );
    } catch (_) {
      return null;
    }
  }
}
