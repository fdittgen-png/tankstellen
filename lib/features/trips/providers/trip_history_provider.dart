// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/hive_boxes.dart';
import '../../../core/sync/sync_events.dart';
import '../data/trip_history_repository.dart';
import '../domain/trip_sample.dart';
import '../domain/trip_verdict.dart';
import '../domain/gps_driving_features.dart';
import 'verdict_calibration_provider.dart';
import '../../../core/logging/error_logger.dart';

part 'trip_history_provider.g.dart';

/// App-wide access to the [TripHistoryRepository] (#726).
///
/// Returns null when the underlying Hive box isn't open — widget
/// tests that don't bother initialising Hive get a silent no-op
/// instead of a thrown error from the UI.
@Riverpod(keepAlive: true)
TripHistoryRepository? tripHistoryRepository(Ref ref) {
  if (!Hive.isBoxOpen(HiveBoxes.obd2TripHistory)) return null;
  final repo = TripHistoryRepository(
    box: Hive.box<String>(HiveBoxes.obd2TripHistory),
  );
  // #3882 — rewrite any legacy single-row trips into the v2 meta +
  // chunk layout, one row at a time off the critical path (a no-op —
  // no timers, no writes — once every row is v2).
  unawaited(repo.migrateLegacyRowsInBackground());
  return repo;
}

/// List of finalised trips, newest-first. Empty when the box is
/// closed or carries no entries. Refreshed by callers after they
/// save a new trip via [TripHistoryListNotifier.refresh].
///
/// #3741 — SUMMARIES-ONLY: entries come from
/// [TripHistoryRepository.loadSummaries], so the heavy per-tick
/// payloads are never materialised on the UI isolate (the flagship
/// list decoded every trip's full 1 Hz sample array on first watch and
/// after every save/delete/verdict/sync — the consumption-tab jank).
/// `entry.samples` is always empty here and `entry.sampleCount` carries
/// the stored count; consumers that render or recompute samples fetch
/// the single trips they need through [tripHistoryDetailProvider].
@Riverpod(keepAlive: true)
class TripHistoryList extends _$TripHistoryList {
  @override
  List<TripHistoryEntry> build() {
    final repo = ref.watch(tripHistoryRepositoryProvider);
    // #3446 — re-read the Hive box whenever the launch trips merge
    // persists server-only summaries; without this the pulled trips
    // appeared one restart late. When this provider first built BEFORE
    // the deferred box opened, the keep-alive repository provider cached
    // `null` — invalidate it so the rebuild picks up the now-open box.
    final sub =
        SyncEvents.instance.forTable(SyncTables.tripSummaries).listen((_) {
      if (ref.read(tripHistoryRepositoryProvider) == null) {
        ref.invalidate(tripHistoryRepositoryProvider);
      } else {
        refresh();
      }
    });
    ref.onDispose(sub.cancel);
    if (repo == null) return const [];
    return repo.loadSummaries();
  }

  /// Re-read the Hive box. Called by [TripRecording.stop] after a
  /// save so the UI picks up the new entry without waiting for a
  /// rebuild trigger.
  void refresh() {
    final repo = ref.read(tripHistoryRepositoryProvider);
    if (repo == null) return;
    state = repo.loadSummaries();
  }

  /// #3501 — persist the driver's post-trip verdict and refresh so the
  /// prompt card (which keys off `entry.verdict == null`) hides itself.
  Future<void> setVerdict(String id, TripVerdict verdict) async {
    final repo = ref.read(tripHistoryRepositoryProvider);
    if (repo == null) return;
    await repo.saveVerdict(id, verdict);
    state = repo.loadSummaries();
    // #3503 — feed the calibration store: join the label with the trip's
    // energy KPIs and re-derive the personal bands. Best-effort — the
    // store swallows its own failures, and a missing entry just skips.
    // #3741 — the state list is summaries-only now (no samples); the
    // KPI join needs the per-tick data, so full-decode THIS trip only.
    try {
      final entry = repo.loadById(id);
      final features =
          entry == null ? null : GpsDrivingFeatures.from(entry.samples);
      await ref
          .read(verdictCalibrationStoreProvider)
          .record(verdict, features);
      ref.invalidate(gpsKpiBandsProvider);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'TripHistoryList.setVerdict calibration record'
      }));
    }
  }

  /// Delete one trip and refresh the list. Exposed so the history
  /// card can support a swipe-to-delete the way the fill-up list
  /// already does.
  Future<void> delete(String id) async {
    final repo = ref.read(tripHistoryRepositoryProvider);
    if (repo == null) return;
    await repo.delete(id);
    state = repo.loadSummaries();
  }

  /// Persist [entry] (insert or update) and refresh the list. Used by
  /// the trip-detail lazy-fetch (#1541 phase 4) when the screen
  /// downloads a server-only `trip_details` row, and by the app-launch
  /// merge hook for newly-discovered server summaries.
  Future<void> save(TripHistoryEntry entry) async {
    final repo = ref.read(tripHistoryRepositoryProvider);
    if (repo == null) return;
    await repo.save(entry);
    state = repo.loadSummaries();
  }
}

/// Full decode of ONE persisted trip — samples materialised (#3741).
///
/// [tripHistoryListProvider] is summaries-only; consumers that render or
/// recompute per-tick samples (the trip-detail charts, the trajets map
/// polylines, the speed-consumption histogram, the achievements sample
/// metrics) fetch exactly the trips they need through this family
/// instead of paying a full-history decode.
///
/// Watching the list makes every save/delete/verdict/sync refresh
/// re-read the row (the notifier pushes a new list instance on each).
/// Falls back to the list's own entry when the repository is
/// unavailable (closed box in widget tests, where the list provider is
/// overridden with fully-populated fixtures) or when the row vanished
/// between refreshes.
@riverpod
TripHistoryEntry? tripHistoryDetail(Ref ref, String id) {
  final listed = ref.watch(_listedTripProvider(id));
  final repo = ref.watch(tripHistoryRepositoryProvider);
  if (repo == null) return listed;
  return repo.loadById(id) ?? listed;
}

/// The list's own (summary-only) entry for [id], rebuilt only when THIS
/// trip's identity changes — the sample count moves on hydration, the
/// verdict on the post-trip prompt — not on every list refresh (#3882).
@riverpod
TripHistoryEntry? _listedTrip(Ref ref, String id) =>
    ref.watch(tripHistoryListProvider).where((t) => t.id == id).firstOrNull;

/// The identity of the listed trip's CONTENT — a record, so dependents
/// rebuild on a value change only (Riverpod filters on `==`), not on
/// every list refresh that hands out a fresh instance (#3882).
@riverpod
(int?, String?, int?) _listedTripKey(Ref ref, String id) {
  final t = ref.watch(_listedTripProvider(id));
  return (t?.sampleCount, t?.verdict, t?.gpsSampleDiagnostics.length);
}

/// #3882 — the trip-detail screen's loader: the FULL entry decoded on a
/// background isolate ([TripHistoryRepository.loadByIdAsync]), exposed as
/// an [AsyncValue] so the screen paints a skeleton instead of blocking
/// the UI isolate on a 40-minute trip's 34-column decode.
///
/// Re-decodes only when the trip's own `(sampleCount, verdict)` moves
/// (hydration, verdict) — a list refresh for an unrelated save/delete no
/// longer re-reads the row. With no repository (closed box in widget
/// tests) the list's fixture entry is served synchronously, so
/// fixture-driven screens render on the first pump exactly as before.
@riverpod
class TripDetailLoader extends _$TripDetailLoader {
  @override
  AsyncValue<TripHistoryEntry?> build(String id) {
    // Keyed on the identity that changes the row's content, not on the
    // list instance.
    ref.watch(_listedTripKeyProvider(id));
    final listed = ref.read(_listedTripProvider(id));
    final repo = ref.read(tripHistoryRepositoryProvider);
    if (repo == null) return AsyncData(listed);
    unawaited(_load(repo, listed));
    return const AsyncLoading();
  }

  Future<void> _load(
      TripHistoryRepository repo, TripHistoryEntry? listed) async {
    final entry = await repo.loadByIdAsync(id);
    if (!ref.mounted) return;
    state = AsyncData(entry ?? listed);
  }
}

/// #3882 — only the speed + fuel-rate columns of one trip, as light
/// samples, for the speed-consumption histogram (the carbon charts tab):
/// a 2-column read instead of the 34-column full decode. Refreshes with
/// the list like [tripHistoryDetailProvider].
@riverpod
List<TripSample> tripSpeedFuelSamples(Ref ref, String id) {
  ref.watch(_listedTripProvider(id));
  final repo = ref.watch(tripHistoryRepositoryProvider);
  if (repo == null) {
    return ref.watch(tripHistoryDetailProvider(id))?.samples ?? const [];
  }
  return repo.loadSamplesWith(id, const {'s', 'f'});
}
