// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:hive/hive.dart';

import '../../../core/storage/json_box_repository.dart';
import '../domain/achievement.dart';

/// Hive-backed persistence of earned achievements (#781). One JSON
/// payload per earned badge, keyed by the enum name so version
/// migrations don't need to chase enum index ordering.
///
/// Stored as plain strings — the badges aren't PII; they're a
/// summary of activity the user already logged. Box is opened
/// alongside the other low-sensitivity Hive boxes at startup.
/// Storage mechanics live in [JsonBoxRepository] (#3614).
class AchievementsRepository extends JsonBoxRepository<EarnedAchievement> {
  AchievementsRepository({required Box<String> box})
      : super(
          box: box,
          fromJson: EarnedAchievement.fromJson,
          toJson: (earned) => earned.toJson(),
          keyOf: (earned) => earned.id.name,
          debugName: 'AchievementsRepository',
        );

  static const String boxName = 'achievements';

  /// Return every persisted earned achievement, sorted newest-first.
  /// Corrupt payloads are skipped so one bad write doesn't hide the
  /// whole list.
  List<EarnedAchievement> loadAll() {
    final result = getAll();
    result.sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
    return result;
  }

  /// Merge [newlyEarnedIds] into the persisted set at [now], preserving
  /// the original `earnedAt` of any id that was already earned.
  /// Returns the badges earned *for the first time* in this call —
  /// the UI can celebrate those and stay silent for the rest.
  Future<List<EarnedAchievement>> mergeEarned(
    Set<AchievementId> newlyEarnedIds, {
    required DateTime now,
  }) async {
    final existing = {
      for (final e in loadAll()) e.id: e,
    };
    final freshlyEarned = <EarnedAchievement>[];
    for (final id in newlyEarnedIds) {
      if (existing.containsKey(id)) continue;
      final earned = EarnedAchievement(id: id, earnedAt: now);
      await put(earned);
      freshlyEarned.add(earned);
    }
    return freshlyEarned;
  }

  Future<void> clear() async {
    await box.clear();
  }
}
