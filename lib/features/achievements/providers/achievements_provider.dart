// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/hive_boxes.dart';
import '../../fill_ups/api.dart';
import '../../trips/api.dart';
import '../../price_history/providers/price_history_provider.dart';
import '../data/achievements_repository.dart';
import '../domain/achievement.dart';
import '../domain/achievement_engine.dart';
import '../domain/price_win_detector.dart';
import '../domain/trip_metrics.dart';

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
    // #781 — priceWin detection lives here (not inside the engine)
    // so the pure engine stays trivially testable. The repo read is
    // cheap: Hive-backed, already loaded per station.
    final priceRepo = ref.watch(priceHistoryRepositoryProvider);
    final hasPriceWin = anyPriceWin(fillUps, priceRepo);
    // #1041 phase 5 — driving-score, cold-start excess, and speed
    // std-dev are pre-computed here so the engine stays pure (no
    // sample-scanning in rule code). The maps are keyed by trip id;
    // missing entries fall back to safe defaults inside the engine.
    final scores = <String, int>{};
    final coldStarts = <String, double>{};
    final stdDevs = <String, double>{};
    // #3741 — the trip list is summaries-only now (`t.samples` is always
    // empty there); the sample-based metrics full-decode each stored
    // trip individually via `loadById`, skipping sample-less trips
    // (legacy / ghost entries) without paying any decode at all.
    final tripRepo = ref.watch(tripHistoryRepositoryProvider);
    for (final t in trips) {
      scores[t.id] = TripMetrics.drivingScore(t.summary);
      // Sample-based metrics only land for trips persisted with
      // their tick buffer (#1040+). Legacy trips with no stored
      // samples yield 0 / +inf which the engine treats as "skip this
      // trip for the rule". Widget-test overrides of the list provider
      // carry inline samples and no open box — honour those directly.
      final samples = t.samples.isNotEmpty
          ? t.samples
          : (t.sampleCount == 0
              ? t.samples
              : tripRepo?.loadById(t.id)?.samples ?? t.samples);
      coldStarts[t.id] = TripMetrics.coldStartExcessLiters(samples);
      stdDevs[t.id] = TripMetrics.speedStdDev(samples);
    }
    final earnedIds = engine.evaluate(
      trips: trips,
      fillUps: fillUps,
      hasPriceWin: hasPriceWin,
      scoresByTripId: scores,
      coldStartExcessLByTripId: coldStarts,
      speedStdDevByTripId: stdDevs,
    );
    // Fire-and-forget persistence so the build is synchronous.
    // The repository merges idempotently — re-runs are cheap.
    unawaited(repo.mergeEarned(earnedIds, now: DateTime.now()));
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
