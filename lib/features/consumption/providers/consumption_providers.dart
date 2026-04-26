import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../../vehicle/data/ve_learner.dart';
import '../../vehicle/providers/service_reminder_providers.dart';
import '../../vehicle/providers/vehicle_providers.dart';
import '../data/repositories/fill_up_repository.dart';
import '../data/trip_history_repository.dart';
import '../domain/entities/consumption_stats.dart';
import '../domain/entities/eco_score.dart';
import '../domain/entities/fill_up.dart';
import '../domain/services/eco_score_calculator.dart';
import 'trip_history_provider.dart';

part 'consumption_providers.g.dart';

/// Repository for reading/writing [FillUp] entries.
@Riverpod(keepAlive: true)
FillUpRepository fillUpRepository(Ref ref) {
  final storage = ref.watch(settingsStorageProvider);
  return FillUpRepository(storage);
}

/// Learner for per-vehicle volumetric efficiency (#815).
///
/// Returns null when the trip-history Hive box isn't open (widget
/// tests that don't bother initialising Hive) — callers guard by
/// skipping the reconciliation entirely when the instance is null,
/// which also lets the fill-up save path stay a single-line change.
@Riverpod(keepAlive: true)
VeLearner? veLearner(Ref ref) {
  final history = ref.watch(tripHistoryRepositoryProvider);
  if (history == null) return null;
  final profileRepo = ref.watch(vehicleProfileRepositoryProvider);
  return VeLearner.fromRepos(
    profileRepository: profileRepo,
    tripHistoryRepository: history,
  );
}

/// Holds the most recent [VeLearnResult] (#815) so the UI can show a
/// one-shot calibration snackbar after the fill-up save flow closes.
///
/// The fill-up screen reads-and-clears this on its way out; unread
/// results persist across widget rebuilds so the snackbar still fires
/// when the user lands on the consumption tab. Only the most recent
/// result is retained — if two tankfuls calibrate back-to-back (rare,
/// but possible during data imports) the second one wins.
@Riverpod(keepAlive: true)
class LastVeLearnResult extends _$LastVeLearnResult {
  @override
  VeLearnResult? build() => null;

  /// Stash [result]. Pass `null` from the consumer to clear after
  /// rendering the snackbar.
  void set(VeLearnResult? result) {
    state = result;
  }
}

/// Mutable list of all fill-ups, newest first.
@Riverpod(keepAlive: true)
class FillUpList extends _$FillUpList {
  @override
  List<FillUp> build() {
    final repo = ref.watch(fillUpRepositoryProvider);
    return repo.getAll();
  }

  /// Insert a new fill-up entry and refresh the list.
  ///
  /// After saving, runs the odometer-based service-reminder check
  /// (#584) for the fill-up's vehicle and — when the vehicle has an
  /// OBD2 trip history since the previous fill-up — kicks off the
  /// η_v reconciliation (#815). Failures in either side-effect path
  /// are swallowed: logging a fill-up must never fail because a
  /// downstream calibration did.
  ///
  /// #888 — auto-links OBD2 trajets recorded since the previous
  /// fill-up for the same vehicle. Populates [FillUp.linkedTripIds]
  /// before persisting so the derived relationship is durable and
  /// queryable (per-tank eco-score, trajets list filtering).
  Future<void> add(FillUp fillUp) async {
    final repo = ref.read(fillUpRepositoryProvider);
    final previous = _previousFillUpFor(fillUp, repo.getAll());
    final linkedIds = _linkedTripIdsFor(fillUp, previous);
    final linked = fillUp.linkedTripIds.isEmpty
        ? fillUp.copyWith(linkedTripIds: linkedIds)
        : fillUp;
    await repo.save(linked);
    state = repo.getAll();
    await _evaluateReminders(linked);
    await _reconcileVolumetricEfficiency(linked, previous);
  }

  /// Compute the trip-history ids recorded for [fillUp.vehicleId]
  /// between [previous] and [fillUp] (inclusive lower, inclusive
  /// upper). Returns an empty list when the fill-up has no vehicle
  /// bound, the history repository isn't available, or no trips fall
  /// in the window.
  List<String> _linkedTripIdsFor(FillUp fillUp, FillUp? previous) {
    final vehicleId = fillUp.vehicleId;
    if (vehicleId == null) return const <String>[];
    final repo = ref.read(tripHistoryRepositoryProvider);
    if (repo == null) return const <String>[];
    final history = repo.loadAll();
    final lowerBound = previous?.date;
    final upperBound = fillUp.date;
    final matches = <TripHistoryEntry>[];
    for (final entry in history) {
      if (entry.vehicleId != vehicleId) continue;
      final when = entry.summary.startedAt;
      if (when == null) continue;
      // Strictly after the previous fill-up (or everything older
      // than this one if there's no prior tank) and at-or-before
      // the new fill-up timestamp. Dates equal to the previous
      // fill-up are excluded so the trip that completed the prior
      // tank isn't double-counted.
      if (lowerBound != null && !when.isAfter(lowerBound)) continue;
      if (when.isAfter(upperBound)) continue;
      matches.add(entry);
    }
    return matches.map((e) => e.id).toList(growable: false);
  }

  /// Pick the fill-up with the largest `date` that is strictly older
  /// than [current] for the same vehicle. Ignores fill-ups without a
  /// vehicle id — reconciliation only applies to vehicle-bound fills.
  FillUp? _previousFillUpFor(FillUp current, List<FillUp> all) {
    if (current.vehicleId == null) return null;
    FillUp? best;
    for (final f in all) {
      if (f.id == current.id) continue;
      if (f.vehicleId != current.vehicleId) continue;
      if (!f.date.isBefore(current.date)) continue;
      if (best == null || f.date.isAfter(best.date)) best = f;
    }
    return best;
  }

  Future<void> _evaluateReminders(FillUp fillUp) async {
    final vehicleId = fillUp.vehicleId;
    if (vehicleId == null || fillUp.odometerKm <= 0) return;
    try {
      final evaluator = ref.read(serviceReminderEvaluatorProvider);
      await evaluator.evaluate(
        vehicleId: vehicleId,
        currentOdometerKm: fillUp.odometerKm,
      );
      // Invalidate the reminder list so the vehicle edit screen
      // picks up the new `pendingAcknowledgment` flag immediately.
      ref.invalidate(serviceReminderListProvider);
    } catch (e, st) {
      debugPrint('FillUpList: reminder evaluation failed: $e\n$st');
    }
  }

  Future<void> _reconcileVolumetricEfficiency(
    FillUp fillUp,
    FillUp? previous,
  ) async {
    final vehicleId = fillUp.vehicleId;
    if (vehicleId == null) return;
    if (fillUp.liters <= 0) return;
    try {
      final learner = ref.read(veLearnerProvider);
      if (learner == null) return;
      final result = await learner.reconcileAfterFillUp(
        vehicleId: vehicleId,
        pumpedLiters: fillUp.liters,
        fillUpTimestamp: fillUp.date,
        previousFillUpTimestamp: previous?.date,
      );
      if (result != null) {
        ref
            .read(lastVeLearnResultProvider.notifier)
            .set(result);
        // Refresh the vehicle list so the edit screen reflects the
        // bumped η_v sample count immediately.
        ref.invalidate(vehicleProfileListProvider);
      }
    } catch (e, st) {
      debugPrint('FillUpList: VE reconciliation failed: $e\n$st');
    }
  }

  /// Persist edits to an existing fill-up (matched by id) and refresh.
  Future<void> update(FillUp fillUp) async {
    final repo = ref.read(fillUpRepositoryProvider);
    await repo.save(fillUp);
    state = repo.getAll();
  }

  /// Delete the fill-up with the given [id] and refresh the list.
  Future<void> remove(String id) async {
    final repo = ref.read(fillUpRepositoryProvider);
    await repo.delete(id);
    state = repo.getAll();
  }

  /// Wipe the entire fill-up history. Used by the privacy dashboard.
  Future<void> clearAll() async {
    final repo = ref.read(fillUpRepositoryProvider);
    await repo.clear();
    state = repo.getAll();
  }

  /// Merge [incoming] fill-ups into local storage. Existing ids are
  /// overwritten; new ids are added. Returns the number of new entries
  /// actually inserted. Used by the device-linking flow (#713).
  Future<int> mergeFrom(Iterable<FillUp> incoming) async {
    final repo = ref.read(fillUpRepositoryProvider);
    final localIds = repo.getAll().map((f) => f.id).toSet();
    var added = 0;
    for (final f in incoming) {
      if (!localIds.contains(f.id)) added++;
      await repo.save(f);
    }
    state = repo.getAll();
    return added;
  }
}

/// Aggregated stats derived from the current fill-up list.
@riverpod
ConsumptionStats consumptionStats(Ref ref) {
  final fillUps = ref.watch(fillUpListProvider);
  return ConsumptionStats.fromFillUps(fillUps);
}

/// Per-fill-up eco-score — compares this tank's L/100 km to the
/// rolling average over the last 3 same-fuel-type fill-ups.
///
/// Returns `null` for fill-ups where the score is not meaningful
/// (first-ever fill-up, odometer rollback, no same-fuel history).
/// Callers render nothing when the return is null.
///
/// Keyed by fill-up id so the Riverpod graph invalidates just the
/// affected card when a single fill-up is edited, not the whole list.
/// See #676 ("Smarter pump. Smarter drive. Save twice.").
@riverpod
EcoScore? ecoScoreForFillUp(Ref ref, String fillUpId) {
  final fillUps = ref.watch(fillUpListProvider);
  final current = fillUps.where((f) => f.id == fillUpId).firstOrNull;
  if (current == null) return null;
  return EcoScoreCalculator.compute(
    current: current,
    history: fillUps,
  );
}
