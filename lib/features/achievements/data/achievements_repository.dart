import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../domain/achievement.dart';

/// Hive-backed persistence of earned achievements (#781). One JSON
/// payload per earned badge, keyed by the enum name so version
/// migrations don't need to chase enum index ordering.
///
/// Stored as plain strings — the badges aren't PII; they're a
/// summary of activity the user already logged. Box is opened
/// alongside the other low-sensitivity Hive boxes at startup.
class AchievementsRepository {
  final Box<String> _box;

  AchievementsRepository({required Box<String> box}) : _box = box;

  static const String boxName = 'achievements';

  /// Return every persisted earned achievement, sorted newest-first.
  /// Corrupt payloads are skipped so one bad write doesn't hide the
  /// whole list.
  List<EarnedAchievement> loadAll() {
    final result = <EarnedAchievement>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null || raw.isEmpty) continue;
      try {
        final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
        final earned = EarnedAchievement.fromJson(json);
        if (earned != null) result.add(earned);
      } catch (e, st) {
        debugPrint('AchievementsRepository.loadAll: skipping $key: $e\n$st');
      }
    }
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
      await _box.put(id.name, jsonEncode(earned.toJson()));
      freshlyEarned.add(earned);
    }
    return freshlyEarned;
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
