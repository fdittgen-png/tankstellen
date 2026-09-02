// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/data/storage_repository.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/fill_ups_sync.dart';
import '../../vehicle/data/reference_vehicle_catalog_provider.dart';
import '../domain/services/pump_gain_learner.dart';
import '../../vehicle/data/vehicle_profile_catalog_matcher.dart';
import '../../../core/domain/gps_calibration_matrix.dart';
import '../../vehicle/domain/entities/reference_vehicle.dart';
import '../../vehicle/providers/service_reminder_providers.dart';
import '../../vehicle/providers/vehicle_providers.dart';
import '../../obd2/api.dart';
import '../data/repositories/fill_up_repository.dart';
import '../../trips/api.dart';
import '../domain/entities/consumption_stats.dart';
import '../domain/entities/eco_score.dart';
import '../domain/entities/fill_inventory.dart';
import '../domain/entities/fill_up.dart';
import '../domain/entities/pending_reconciliation.dart';
import '../domain/services/eco_score_calculator.dart';
import '../domain/services/fill_up_trip_linker.dart';
import '../domain/services/reconciler.dart';
import '../domain/services/tank_mix_estimator.dart';
import 'fill_inventory_provider.dart';
import 'pending_reconciliation_provider.dart';

part 'consumption_providers.g.dart';
part 'consumption_providers_belief_store.dart';
part 'consumption_providers_calibration.dart';
part 'consumption_providers_reconcile.dart';
part 'consumption_providers_windows.dart';

/// Repository for reading/writing [FillUp] entries.
@Riverpod(keepAlive: true)
FillUpRepository fillUpRepository(Ref ref) {
  final storage = ref.watch(settingsStorageProvider);
  return FillUpRepository(storage);
}

/// Learner for the per-vehicle pump-anchored fuel gain (#3887; replaced
/// the #815 η_v learner).
///
/// Returns null when the trip-history Hive box isn't open (widget
/// tests that don't bother initialising Hive) — callers guard by
/// skipping the reconciliation entirely when the instance is null,
/// which also lets the fill-up save path stay a single-line change.
@Riverpod(keepAlive: true)
PumpGainLearner? pumpGainLearner(Ref ref) {
  final history = ref.watch(tripHistoryRepositoryProvider);
  if (history == null) return null;
  return PumpGainLearner(
    profileRepository: ref.watch(vehicleProfileRepositoryProvider),
  );
}

/// Detector for the broken-MAP belief system (#1423 phase 3). Single
/// stateless instance shared across observations.
@Riverpod(keepAlive: true)
BrokenMapDetector brokenMapDetector(Ref ref) => const BrokenMapDetector();

/// Persistent per-adapter broken-MAP blocklist (#1423 phase 4). Reads
/// and writes the latest belief confidence by ELM ID through the
/// shared [SettingsStorage] (Hive `settings` box). The populator
/// recalls before each pair attempt so a known-broken adapter
/// surfaces a warning without re-probing.
@Riverpod(keepAlive: true)
ObdAdapterBlocklist obdAdapterBlocklist(Ref ref) =>
    ObdAdapterBlocklist(ref.watch(settingsStorageProvider));

/// Holds the most recent per-vehicle [BrokenMapBelief] (#1423 phase 3).
///
/// Hive-backed via [SettingsStorage] (#1423 phase 4) — beliefs survive
/// app restart. Lazy-loaded on first [beliefFor] call per vehicle;
/// [set] writes back to settings fire-and-forget. Errors are logged
/// via [errorLogger] but never propagate (a storage hiccup must not
/// break the fill-up save flow that triggered the update).
///
/// Keyed by `vehicleId`. Beliefs default to [BrokenMapBelief()] when
/// the vehicle hasn't been observed yet.
@Riverpod(keepAlive: true)
class BrokenMapBeliefByVehicle extends _$BrokenMapBeliefByVehicle
    with _BrokenMapBeliefStorePersistence {
  @override
  Map<String, BrokenMapBelief> build() => <String, BrokenMapBelief>{};

  /// Read the current belief for [vehicleId]; defaults to a fresh
  /// [BrokenMapBelief] when nothing has been recorded yet. Hydrates
  /// lazily from [SettingsStorage] on first access — subsequent calls
  /// hit the cached state.
  BrokenMapBelief beliefFor(String vehicleId) {
    final cached = state[vehicleId];
    if (cached != null) return cached;
    final stored = _loadFromStorage(vehicleId);
    if (stored != null) {
      // Cache without re-firing the setter's persistence path.
      state = {...state, vehicleId: stored};
      return stored;
    }
    return const BrokenMapBelief();
  }

  /// Replace the belief for [vehicleId] with [belief]. Persists to
  /// [SettingsStorage] in the background; persistence failures are
  /// logged but never thrown so the calling save flow stays atomic.
  void set(String vehicleId, BrokenMapBelief belief) {
    state = {...state, vehicleId: belief};
    // ignore: discarded_futures
    _persist(vehicleId, belief);
  }
}

/// Holds the most recent [PumpGainResult] (#3887) so the UI can show a
/// one-shot calibration snackbar after the fill-up save flow closes.
///
/// The fill-up screen reads-and-clears this on its way out; unread
/// results persist across widget rebuilds so the snackbar still fires
/// when the user lands on the consumption tab. Only the most recent
/// result is retained — if two tankfuls calibrate back-to-back (rare,
/// but possible during data imports) the second one wins.
@Riverpod(keepAlive: true)
class LastPumpGainResult extends _$LastPumpGainResult {
  @override
  PumpGainResult? build() => null;

  /// Stash [result]. Pass `null` from the consumer to clear after
  /// rendering the snackbar.
  void set(PumpGainResult? result) {
    state = result;
  }
}

/// Signature of the bidirectional fill-ups merge. Defaults to
/// [FillUpsSync.merge]; injectable so the #3077 pull-persist wiring is
/// unit-testable without a live Supabase session (the real merge returns
/// the input unchanged when unauthenticated, masking the wiring under test).
typedef FillUpsMergeFn = Future<List<FillUp>> Function(List<FillUp> local);

/// Mutable list of all fill-ups, newest first.
@Riverpod(keepAlive: true)
class FillUpList extends _$FillUpList
    with _FillUpListWindows, _FillUpListCalibration, _FillUpListReconcile {
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
    final linkedIds = _linkedTripIdsForWholeWindow(fillUp);
    // #3122 — stamp the local edit time (UTC) so the LWW sync merge can
    // propagate this record to other devices.
    final linked = (fillUp.linkedTripIds.isEmpty
            ? fillUp.copyWith(linkedTripIds: linkedIds)
            : fillUp)
        .copyWith(updatedAt: DateTime.now().toUtc());
    await repo.save(linked);
    // Re-link any partials in the open window so they share the
    // closing plein's trip set. No-op when [linked] is itself a
    // partial (the next plein will cover this), or when the vehicle
    // has no trips/partials in the window.
    await _relinkOpenWindow(linked);
    state = repo.getAll();
    await _evaluateReminders(linked);
    final gainOutcome = await _reconcilePumpGain(linked); // #3887 / #3917
    // #2081 — GPS matrix reconciliation. Independent of η_v: the η_v
    // path applies to the OBD2 fuel-rate trim; this path applies to
    // the GPS-only L/100 km matrix. Both happily run for hybrid
    // vehicles — the GPS matrix only consumes GPS-only / hybrid
    // trajets in the window, the OBD2 path consumes the rest.
    await _reconcileGpsCalibrationMatrix(linked);
    // #1361 — trip-vs-pump reconciliation. Only runs on plein fills;
    // partials extend the open window and don't trigger a closing.
    final reconciliation = await _reconcileTripVsPump(linked);
    // #1423 phase 3 — feed the plein-complet observation into the
    // broken-MAP belief. Only when the trip-vs-pump reconciler
    // actually evaluated the window (created OR skippedBelowThreshold —
    // both produce a meaningful pumped/consumed pair). The
    // skippedNoTrips and clampedNegative buckets carry no L/100km
    // signal so we don't fold them in.
    await _recordBrokenMapObservation(
      fillUp: linked,
      reconciliation: reconciliation,
      proposedEta: gainOutcome?.result?.proposedEta,
    );
  }

  /// Path A of the guided reconciliation workflow (#2443) — persist a
  /// CONSENTED correction fill-up. Called by the workflow ONLY after
  /// the user confirmed a fill-up was missing/mistyped and (optionally)
  /// edited the proposed litres. Never invoked silently — the detector
  /// merely publishes a [PendingReconciliation]; this is the explicit
  /// "the user chose to correct the fill-ups" apply.
  ///
  /// [correction] is the (possibly user-edited) synthetic correction
  /// FillUp — it keeps `isCorrection: true` so it renders distinctly
  /// and is excluded from the honest Total L (#2446). After saving we
  /// clear the pending gap: the window now reconciles
  /// ([reconciliationBasis] residual == 0).
  Future<void> applyReconciliation(FillUp correction) async {
    final repo = ref.read(fillUpRepositoryProvider);
    // #3122 — a consented correction is a local edit: stamp it for LWW.
    await repo.save(correction.copyWith(updatedAt: DateTime.now().toUtc()));
    state = repo.getAll();
    ref.read(pendingReconciliationsProvider.notifier).set(null);
  }

  /// Persist edits to an existing fill-up (matched by id) and refresh.
  ///
  /// #3122 — stamps `updatedAt` (UTC) so the LWW sync merge propagates
  /// the edit to other devices instead of letting it diverge forever.
  Future<void> update(FillUp fillUp) async {
    final repo = ref.read(fillUpRepositoryProvider);
    await repo.save(fillUp.copyWith(updatedAt: DateTime.now().toUtc()));
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

  /// Pull the user's server fill-ups and **persist the server-side
  /// changes into local storage** (#3077, #3122).
  ///
  /// [FillUpsSync.merge] uploads local-only rows AND returns the union
  /// (`[...local, ...downloaded]`) with last-write-wins applied to ids
  /// present on both sides (#3122). We persist every returned entry that
  /// differs from the local copy: server-only rows (the #3077 pull) and
  /// server-newer overwrites (the #3122 LWW download); equal entries are
  /// skipped via [mergeFrom]'s overwrite-by-id. Returns the count of
  /// newly-added (previously unknown) fill-ups.
  ///
  /// The caller owns the consent gate — this is invoked behind the
  /// trip-data sync gate (fill-ups are trip-data adjacent). [mergeFn]
  /// defaults to the real sync and is injectable for unit tests.
  Future<int> pullFromServer({FillUpsMergeFn mergeFn = FillUpsSync.merge}) async {
    final repo = ref.read(fillUpRepositoryProvider);
    final localById = {for (final f in repo.getAll()) f.id: f};
    final merged = await mergeFn(repo.getAll());
    // #3077 server-only pulls + #3122 server-newer LWW overwrites both
    // differ from the local copy; untouched (and local-newer, already
    // re-uploaded) entries compare equal and are skipped, so an in-flight
    // local edit is never clobbered.
    final changed = merged.where((f) => localById[f.id] != f).toList();
    if (changed.isEmpty) return 0;
    return mergeFrom(changed);
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

/// Raw per-fill-up L/100 km, with no baseline / no comparison (#2060).
///
/// Returns the per-entry consumption number even when
/// [ecoScoreForFillUp] is null because there isn't enough history
/// to build a rolling-average baseline. The card consumes this to
/// render a plain "X.X L/100 km" line on entries that would otherwise
/// be blank — the 2026-05-20 entry in the user's screenshot has the
/// distance + litres to compute a number, just not enough preceding
/// same-fuel entries for a trend.
@riverpod
double? litersPer100KmForFillUp(Ref ref, String fillUpId) {
  final fillUps = ref.watch(fillUpListProvider);
  final current = fillUps.where((f) => f.id == fillUpId).firstOrNull;
  if (current == null) return null;
  return EcoScoreCalculator.computeLitersPer100Km(
    current: current,
    history: fillUps,
  );
}
