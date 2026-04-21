import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/hive_boxes.dart';
import '../../consumption/providers/consumption_providers.dart';
import '../../consumption/providers/trip_history_provider.dart';
import '../data/achievements_repository.dart';
import '../domain/achievement.dart';
import '../domain/achievement_engine.dart';

part 'achievements_provider.g.dart';

/// Hive-backed achievements store (#781). Returns null when the Hive
/// box isn't open — widget tests that skip Hive init get a silent
/// no-op instead of a thrown error.
@Riverpod(keepAlive: true)
AchievementsRepository? achievementsRepository(Ref ref) {
  if (!Hive.isBoxOpen(HiveBoxes.achievements)) return null;
  return AchievementsRepository(
    box: Hive.box<String>(HiveBoxes.achievements),
  );
}

/// Singleton engine — pure function, no state, cheap to share.
@Riverpod(keepAlive: true)
AchievementEngine achievementEngine(Ref ref) => AchievementEngine();

/// Earned badges, newest-first. Watches the trip-history and
/// fill-up providers so that adding a trip or fill-up naturally
/// re-evaluates the rules without an explicit `refresh()` call.
///
/// Because `mergeEarned` is idempotent (only persists ids that
/// aren't already stored), re-running the evaluation on every
/// upstream change is cheap and safe.
@Riverpod(keepAlive: true)
class Achievements extends _$Achievements {
  @override
  List<EarnedAchievement> build() {
    final repo = ref.watch(achievementsRepositoryProvider);
    if (repo == null) return const [];
    final trips = ref.watch(tripHistoryListProvider);
    final fillUps = ref.watch(fillUpListProvider);
    final engine = ref.watch(achievementEngineProvider);
    final earnedIds = engine.evaluate(trips: trips, fillUps: fillUps);
    // Fire-and-forget persistence so the build is synchronous.
    // The repository merges idempotently — re-runs are cheap.
    repo.mergeEarned(earnedIds, now: DateTime.now());
    return repo.loadAll();
  }

  /// Wipe every earned badge. Intended for a debug "reset progress"
  /// action; the next upstream change will re-earn anything still
  /// applicable from the current trip/fill-up state.
  Future<void> clearAll() async {
    final repo = ref.read(achievementsRepositoryProvider);
    if (repo == null) return;
    await repo.clear();
    state = const [];
  }
}
