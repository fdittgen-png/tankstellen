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
