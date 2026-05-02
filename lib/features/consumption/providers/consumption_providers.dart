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
import '../domain/services/reconciler.dart';
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
  /// η_v reconciliation (#815) and the trip-vs-pump correction
  /// reconciliation (#1361). Failures in any side-effect path are
  /// swallowed: logging a fill-up must never fail because a
  /// downstream calibration did.
  ///
  /// #888 / #1361 — auto-links OBD2 trajets to every fill-up in the
  /// open plein-to-plein window. Trips recorded inside a window land
  /// in `linkedTripIds` of every fill in that window (the closing
  /// plein and any partial top-ups between the previous plein and
  /// the closing one). When the new fill is itself a plein the
  /// window closes and we re-link backwards across the closed window
  /// so the partials see the full trip set.
  Future<void> add(FillUp fillUp) async {
    final repo = ref.read(fillUpRepositoryProvider);
    final previous = _previousFillUpFor(fillUp, repo.getAll());
    final linkedIds = _linkedTripIdsForWholeWindow(fillUp);
    final linked = fillUp.linkedTripIds.isEmpty
        ? fillUp.copyWith(linkedTripIds: linkedIds)
        : fillUp;
    await repo.save(linked);
    // Re-link any partials in the open window so they share the
    // closing plein's trip set. No-op when [linked] is itself a
    // partial (the next plein will cover this), or when the vehicle
    // has no trips/partials in the window.
    await _relinkOpenWindow(linked);
    state = repo.getAll();
    await _evaluateReminders(linked);
    await _reconcileVolumetricEfficiency(linked, previous);
    // #1361 — trip-vs-pump reconciliation. Only runs on plein fills;
    // partials extend the open window and don't trigger a closing.
    await _reconcileTripVsPump(linked);
  }

  /// Compute the trip-history ids recorded for [fillUp.vehicleId]
  /// in the OPEN plein-to-plein window that ends at [fillUp].
  ///
  /// Window semantics (#1361):
  ///   - upper bound: `fillUp.date` (inclusive).
  ///   - lower bound: most-recent prior plein (exclusive) for the
  ///     same vehicle, or — when no prior plein exists — the first
  ///     same-vehicle fill-up's date (inclusive).
  ///
  /// Returns an empty list when the fill-up has no vehicle bound,
  /// the trip-history repository isn't available, or no trips fall
  /// in the window.
  List<String> _linkedTripIdsForWholeWindow(FillUp fillUp) {
    final vehicleId = fillUp.vehicleId;
    if (vehicleId == null) return const <String>[];
    final repo = ref.read(tripHistoryRepositoryProvider);
    if (repo == null) return const <String>[];
    final history = repo.loadAll();
    final fillRepo = ref.read(fillUpRepositoryProvider);
    final allFills = fillRepo
        .getAll()
        .where(
          (f) =>
              f.vehicleId == vehicleId &&
              f.id != fillUp.id &&
              !f.isCorrection,
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    FillUp? previousPlein;
    for (final f in allFills) {
      if (!f.date.isBefore(fillUp.date)) continue;
      if (!f.isFullTank) continue;
      if (previousPlein == null || f.date.isAfter(previousPlein.date)) {
        previousPlein = f;
      }
    }

    // Window lower bound:
    //   - prior plein → strictly after that plein's date
    //   - no prior plein but earlier same-vehicle fills exist → at-or-
    //     after the earliest such fill (inclusive)
    //   - no prior fills at all → no lower bound (everything before
    //     this fill qualifies, matching the legacy #888 semantics)
    DateTime? windowStart;
    bool inclusiveLower = true;
    if (previousPlein != null) {
      windowStart = previousPlein.date;
      inclusiveLower = false;
    } else if (allFills.isNotEmpty) {
      windowStart = allFills.first.date;
      inclusiveLower = true;
    }
    final upperBound = fillUp.date;

    final matches = <TripHistoryEntry>[];
    for (final entry in history) {
      if (entry.vehicleId != vehicleId) continue;
      final when = entry.summary.startedAt;
      if (when == null) continue;
      if (windowStart != null) {
        final afterStart = inclusiveLower
            ? !when.isBefore(windowStart)
            : when.isAfter(windowStart);
        if (!afterStart) continue;
      }
      if (when.isAfter(upperBound)) continue;
      matches.add(entry);
    }
    return matches.map((e) => e.id).toList(growable: false);
  }

  /// After saving [closing], propagate its `linkedTripIds` to every
  /// other fill in the same open plein-to-plein window so the
  /// derived relationship is the same on each fill (#1361). This is
  /// the whole-window semantic the user requested: "the trajets
  /// since then are related to all fill-ups since then".
  ///
  /// The window is the same one [_linkedTripIdsForWholeWindow]
  /// computed for [closing]; when [closing] is a plein, we cover the
  /// fills between the previous plein and the closing one (the
  /// partials), and when [closing] is itself a partial, we still
  /// cover the open window so the prior partial picks up the new
  /// trips.
  Future<void> _relinkOpenWindow(FillUp closing) async {
    final vehicleId = closing.vehicleId;
    if (vehicleId == null) return;
    final repo = ref.read(fillUpRepositoryProvider);
    final allFills = repo
        .getAll()
        .where(
          (f) =>
              f.vehicleId == vehicleId &&
              f.id != closing.id &&
              !f.isCorrection,
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    FillUp? previousPlein;
    for (final f in allFills) {
      if (!f.date.isBefore(closing.date)) continue;
      if (!f.isFullTank) continue;
      if (previousPlein == null || f.date.isAfter(previousPlein.date)) {
        previousPlein = f;
      }
    }

    DateTime? windowStart;
    bool inclusiveLower = true;
    if (previousPlein != null) {
      windowStart = previousPlein.date;
      inclusiveLower = false;
    } else if (allFills.isNotEmpty) {
      windowStart = allFills.first.date;
      inclusiveLower = true;
    }
    final upperBound = closing.date;

    bool inWindow(DateTime when) {
      if (windowStart != null) {
        final afterStart = inclusiveLower
            ? !when.isBefore(windowStart)
            : when.isAfter(windowStart);
        if (!afterStart) return false;
      }
      return !when.isAfter(upperBound);
    }

    final newIds = closing.linkedTripIds;
    for (final f in allFills) {
      if (!inWindow(f.date)) continue;
      // Merge — preserve any pre-existing ids, add the new set.
      final merged = <String>{...f.linkedTripIds, ...newIds}.toList();
      if (merged.length == f.linkedTripIds.length &&
          merged.toSet().difference(f.linkedTripIds.toSet()).isEmpty) {
        continue;
      }
      await repo.save(f.copyWith(linkedTripIds: merged));
    }
  }

  /// Pick the fill-up with the largest `date` that is strictly older
  /// than [current] for the same vehicle. Ignores fill-ups without a
  /// vehicle id — reconciliation only applies to vehicle-bound fills.
  /// Skips correction entries — they're synthesised and shouldn't
  /// anchor the η_v window.
  FillUp? _previousFillUpFor(FillUp current, List<FillUp> all) {
    if (current.vehicleId == null) return null;
    FillUp? best;
    for (final f in all) {
      if (f.id == current.id) continue;
      if (f.vehicleId != current.vehicleId) continue;
      if (f.isCorrection) continue;
      if (!f.date.isBefore(current.date)) continue;
      if (best == null || f.date.isAfter(best.date)) best = f;
    }
    return best;
  }

  /// #1361 — synthesise a correction fill-up when the closing plein's
  /// pumped volume exceeds the OBD-integrated trip fuel by more than
  /// [Reconciler.absoluteThresholdLiters] and
  /// [Reconciler.relativeThreshold]. No-op for partial fills, fills
  /// without a bound vehicle, the synthesised correction itself, or
  /// when the trip-history repository isn't available. Errors are
  /// swallowed — a failed reconciliation must not break the save flow.
  Future<void> _reconcileTripVsPump(FillUp fillUp) async {
    if (fillUp.isCorrection) return;
    if (!fillUp.isFullTank) return;
    final vehicleId = fillUp.vehicleId;
    if (vehicleId == null) return;
    try {
      final tripRepo = ref.read(tripHistoryRepositoryProvider);
      if (tripRepo == null) return;
      final fillRepo = ref.read(fillUpRepositoryProvider);
      final allFills = fillRepo.getAll();
      final history = tripRepo.loadAll();
      final trips = tripSummariesForVehicle(
        vehicleId: vehicleId,
        history: history,
      );
      const reconciler = Reconciler();
      final result = reconciler.reconcile(
        closingPlein: fillUp,
        allFillUpsForVehicle: allFills,
        tripsForVehicle: trips,
      );
      final correction = result?.correction;
      if (correction != null) {
        await fillRepo.save(correction);
        state = fillRepo.getAll();
      }
    } catch (e, st) {
      debugPrint('FillUpList: trip-vs-pump reconciliation failed: $e\n$st');
    }
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
