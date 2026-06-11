// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/data/storage_repository.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/sync/fill_ups_sync.dart';
import '../../vehicle/data/reference_vehicle_catalog_provider.dart';
import '../../vehicle/data/ve_learner.dart';
import '../../vehicle/data/vehicle_profile_catalog_matcher.dart';
import '../../../core/domain/gps_calibration_matrix.dart';
import '../../vehicle/domain/entities/reference_vehicle.dart';
import '../../vehicle/providers/service_reminder_providers.dart';
import '../../vehicle/providers/vehicle_providers.dart';
import '../data/obd2/broken_map_belief.dart';
import '../data/obd2/broken_map_detector.dart';
import '../data/obd2/obd_adapter_blocklist.dart';
import '../data/repositories/fill_up_repository.dart';
import '../data/trip_history_repository.dart';
import '../domain/entities/consumption_stats.dart';
import '../domain/entities/eco_score.dart';
import '../domain/entities/fill_up.dart';
import '../domain/entities/pending_reconciliation.dart';
import '../domain/gps_driving_features.dart';
import '../domain/services/eco_score_calculator.dart';
import '../domain/services/gps_matrix_reconciler.dart';
import '../domain/services/reconciler.dart';
import '../domain/trip_recorder.dart';
import 'pending_reconciliation_provider.dart';
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

/// Settings-box key prefix used by [BrokenMapBeliefByVehicle] for
/// per-vehicle persistence (#1423 phase 4). Separate namespace from
/// [ObdAdapterBlocklist]'s adapter-keyed entries — the two are
/// orthogonal: vehicle-keyed survives an adapter change; adapter-keyed
/// survives a vehicle change.
@visibleForTesting
const String brokenMapBeliefSettingsKeyPrefix = 'brokenMapBelief:';

/// Threshold above which a belief is considered actionable enough to
/// persist into the [ObdAdapterBlocklist] (#1423 phase 4). Mirrors the
/// spec § C wording: "if matched and confidence > 0.7, surface the
/// warning". Below this we still update the per-vehicle belief in
/// settings, but don't pollute the adapter blocklist with weak signals.
@visibleForTesting
const double brokenMapBlocklistThreshold = 0.7;

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
class BrokenMapBeliefByVehicle extends _$BrokenMapBeliefByVehicle {
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

  /// Synchronously decode the persisted belief for [vehicleId]. Returns
  /// null when no entry exists or when the JSON payload can't be
  /// parsed (defensive against schema drift / hand-edited values).
  BrokenMapBelief? _loadFromStorage(String vehicleId) {
    try {
      final storage = ref.read(settingsStorageProvider);
      final raw = storage.getSetting(_keyFor(vehicleId));
      if (raw is! String || raw.isEmpty) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return BrokenMapBelief.fromJson(json);
    } catch (e, st) {
      // Synchronous debugPrint instead of errorLogger.log: when this
      // provider runs in an unbound zone (ProviderContainer without
      // bindContainer — every unit test for the notifier), errorLogger
      // falls through to IsolateErrorSpool.enqueue, which opens a Hive
      // box. That fire-and-forget Hive open races the test's tearDown
      // (which deletes the temp Hive dir) and surfaces as
      // PathNotFoundException + LateInitializationError "after test
      // completion". Returning null falls back to a fresh belief —
      // the worst case is one re-probed pair, not a crash.
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'brokenMapBeliefByVehicle.load failed'}));
      return null;
    }
  }

  /// Persist [belief] under [vehicleId]. Async-throws are caught and
  /// logged — the calling fill-up save must not be derailed by a
  /// storage hiccup.
  Future<void> _persist(String vehicleId, BrokenMapBelief belief) async {
    try {
      final SettingsStorage storage = ref.read(settingsStorageProvider);
      final encoded = jsonEncode(belief.toJson());
      await storage.putSetting(_keyFor(vehicleId), encoded);
    } catch (e, st) {
      await errorLogger.log(
        ErrorLayer.background,
        e,
        st,
        context: const {
          'op': 'brokenMapBeliefByVehicle.persist',
        },
      );
    }
  }

  String _keyFor(String vehicleId) =>
      '$brokenMapBeliefSettingsKeyPrefix$vehicleId';
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

/// Signature of the bidirectional fill-ups merge. Defaults to
/// [FillUpsSync.merge]; injectable so the #3077 pull-persist wiring is
/// unit-testable without a live Supabase session (the real merge returns
/// the input unchanged when unauthenticated, masking the wiring under test).
typedef FillUpsMergeFn = Future<List<FillUp>> Function(List<FillUp> local);

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
    final veResult = await _reconcileVolumetricEfficiency(linked, previous);
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
      veResult: veResult,
    );
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
      // #3122 — the trip-link set changed: stamp so LWW propagates it.
      await repo.save(f.copyWith(
        linkedTripIds: merged,
        updatedAt: DateTime.now().toUtc(),
      ));
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
  ///
  /// Returns the [_TripVsPumpReconciliation] outcome so downstream
  /// hooks (#1423 phase 3 broken-MAP belief) can score the same
  /// reconciliation without redoing the window math. Returns `null`
  /// when reconciliation was skipped (partial fill, no vehicle,
  /// missing trip-history repo, throw).
  Future<_TripVsPumpReconciliation?> _reconcileTripVsPump(
    FillUp fillUp,
  ) async {
    if (fillUp.isCorrection) return null;
    if (!fillUp.isFullTank) return null;
    final vehicleId = fillUp.vehicleId;
    if (vehicleId == null) return null;
    try {
      final tripRepo = ref.read(tripHistoryRepositoryProvider);
      if (tripRepo == null) return null;
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
      if (result == null) return null;
      final correction = result.correction;
      if (correction != null && result.action == ReconciliationAction.created) {
        // Detect → publish seam (Epic #2439 / #2442 — NEVER silent):
        // surface the gap as a PendingReconciliation for the guided
        // workflow to pick up. We DO NOT apply anything here anymore —
        // no correction or virtual trajet is ever created without the
        // user completing the workflow. The UI (add_fill_up_screen)
        // reads this pending gap after the plein save and raises the
        // workflow, which then calls [applyReconciliation] (Path A) or
        // [applyVirtualTrajet] (Path B), or leaves the gap intact on
        // "Decide later".
        final pending = PendingReconciliation.fromCorrection(
          correction: correction,
          pumped: result.pumped,
          consumed: result.consumed,
          gap: result.gap,
        );
        ref.read(pendingReconciliationsProvider.notifier).set(pending);
      } else {
        // No correction this window. Clear any stale gap so the workflow
        // seam never reads one from a prior window — BUT never silently
        // drop a still-unresolved gap the user deferred (#2445). Such a
        // gap belongs to an EARLIER window for the same vehicle; this
        // clean window doesn't touch it, so the "Decide later" decision
        // (and the 'Resolve gap' affordance that re-opens it) survives a
        // subsequent plein. A gap for a DIFFERENT vehicle is stale here
        // and is cleared as before.
        final prior = ref.read(pendingReconciliationsProvider);
        final keepPriorGap =
            prior != null && prior.vehicleId == fillUp.vehicleId;
        if (!keepPriorGap) {
          ref.read(pendingReconciliationsProvider.notifier).set(null);
        }
      }
      // Sum the window-trip distances — used by the broken-MAP hook
      // to convert pumped/consumed litres into L/100 km. Mirrors the
      // window logic inside [Reconciler.reconcile]; we don't reach
      // into the result for it because the reconciler stays pure (no
      // distance field on [ReconciliationResult]).
      final windowDistanceKm = _windowDistanceKm(
        closingPlein: fillUp,
        allFillUpsForVehicle: allFills,
        tripsForVehicle: trips,
      );
      return _TripVsPumpReconciliation(
        result: result,
        windowDistanceKm: windowDistanceKm,
      );
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'FillUpList: trip-vs-pump reconciliation failed'}));
      return null;
    }
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

  /// Path B of the guided reconciliation workflow (#2444) — inject a
  /// CONSENTED virtual trajet. Called by the workflow ONLY after the
  /// user confirmed their fill-ups are correct and a drive went
  /// unrecorded (including the "both sides individually correct →
  /// gap is unrecorded driving" elimination case).
  ///
  /// Builds a synthetic [TripHistoryEntry] (`isVirtual: true`,
  /// `fuelLitersConsumed` = the gap, user-supplied [distanceKm],
  /// `startedAt` = the window midpoint) and persists it via
  /// [TripHistoryRepository]. No fill-up is created, so the headline
  /// Total L stays real pump litres (#2446). The virtual trip counts
  /// on the TRAJETS side of [reconciliationBasis] (via the
  /// `isVirtualTrip` predicate), driving the window residual to 0, but
  /// is excluded from the η_v learner and from the next window's
  /// recorded `consumed` so a re-run never double-counts the gap.
  Future<void> applyVirtualTrajet({
    required PendingReconciliation pending,
    required double gapLiters,
    required double distanceKm,
  }) async {
    final startedAt = pending.windowMidpointDate;
    final entry = TripHistoryEntry(
      id: 'virtual_${pending.correction.id}',
      vehicleId: pending.vehicleId,
      summary: TripSummary(
        distanceKm: distanceKm,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        fuelLitersConsumed: gapLiters,
        avgLPer100Km:
            distanceKm > 0 ? gapLiters / distanceKm * 100 : null,
        startedAt: startedAt,
        endedAt: startedAt,
        isVirtual: true,
      ),
    );
    // Persist + refresh via the list notifier so the Trajets list picks
    // up the synthetic trip immediately. No-op when the trip-history
    // box isn't open (widget tests without Hive).
    await ref.read(tripHistoryListProvider.notifier).save(entry);
    ref.read(pendingReconciliationsProvider.notifier).set(null);
  }

  /// Sum the [TripSummary.distanceKm] across every trip in the same
  /// plein-to-plein window the [Reconciler] uses. Inlined here so the
  /// reconciler can stay pure and free of the L/100 km derivation.
  double _windowDistanceKm({
    required FillUp closingPlein,
    required List<FillUp> allFillUpsForVehicle,
    required List<TripSummary> tripsForVehicle,
  }) {
    final vehicleId = closingPlein.vehicleId;
    final sameVehicleFills = allFillUpsForVehicle
        .where(
          (f) =>
              f.vehicleId == vehicleId &&
              !f.isCorrection &&
              f.id != closingPlein.id,
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    FillUp? previousPlein;
    for (final f in sameVehicleFills) {
      if (!f.date.isBefore(closingPlein.date)) continue;
      if (!f.isFullTank) continue;
      if (previousPlein == null || f.date.isAfter(previousPlein.date)) {
        previousPlein = f;
      }
    }
    DateTime windowStart;
    bool inclusiveLower;
    if (previousPlein != null) {
      windowStart = previousPlein.date;
      inclusiveLower = false;
    } else {
      windowStart = sameVehicleFills.isEmpty
          ? closingPlein.date
          : sameVehicleFills.first.date;
      inclusiveLower = true;
    }
    double sum = 0;
    for (final t in tripsForVehicle) {
      final when = t.startedAt;
      if (when == null) continue;
      final afterStart = inclusiveLower
          ? !when.isBefore(windowStart)
          : when.isAfter(windowStart);
      if (!afterStart) continue;
      if (when.isAfter(closingPlein.date)) continue;
      sum += t.distanceKm;
    }
    return sum;
  }

  /// #1423 phase 3 — fold the plein-complet observation into the
  /// broken-MAP belief. No-op when the trip-vs-pump reconciler didn't
  /// produce a usable pumped/consumed pair, when the closing fill
  /// isn't a plein, or when the window distance is too small to form
  /// a meaningful L/100 km. Errors are swallowed — a broken-MAP
  /// scoring failure must not break the save flow.
  Future<void> _recordBrokenMapObservation({
    required FillUp fillUp,
    required _TripVsPumpReconciliation? reconciliation,
    required VeLearnResult? veResult,
  }) async {
    if (reconciliation == null) return;
    final vehicleId = fillUp.vehicleId;
    if (vehicleId == null) return;
    if (!fillUp.isFullTank || fillUp.isCorrection) return;
    final result = reconciliation.result;
    // Only fold in observations where both sides of the ratio are
    // populated. skippedNoTrips means consumed = 0 (degenerate), and
    // clampedNegative means the integrator over-reported (the
    // discrepancy score isn't meaningful in that direction).
    if (result.action != ReconciliationAction.created &&
        result.action != ReconciliationAction.skippedBelowThreshold) {
      return;
    }
    if (result.consumed <= 0) return;
    final distance = reconciliation.windowDistanceKm;
    if (distance <= 0) return;
    try {
      final detector = ref.read(brokenMapDetectorProvider);
      final beliefs = ref.read(brokenMapBeliefByVehicleProvider.notifier);
      final prior = beliefs.beliefFor(vehicleId);
      final reconciledLPer100km = result.pumped * 100.0 / distance;
      final estimatedLPer100km = result.consumed * 100.0 / distance;
      // #1424 deliverable F — resolve the active vehicle's catalog
      // entry so the updater can apply the induction-class Bayes-factor
      // adjustment. `null` is acceptable (legacy profiles, or rows
      // whose reference catalog hasn't loaded yet) — the updater
      // treats it as a neutral 1.0 multiplier.
      final vehicle = _resolveReferenceVehicle(vehicleId);
      final updated = detector.recordPleinCompletObservation(
        prior: prior,
        reconciledLPer100km: reconciledLPer100km,
        estimatedLPer100km: estimatedLPer100km,
        proposedEta: veResult?.proposedEta,
        now: DateTime.now(),
        vehicle: vehicle,
      );
      beliefs.set(vehicleId, updated);
      // #1423 phase 4 — when the belief crosses the actionable
      // threshold, also persist into the per-adapter blocklist so a
      // future pair attempt with the SAME adapter (possibly on a
      // different vehicle) recalls without re-probing. The adapter
      // identifier comes from the most recent trip for this vehicle
      // — null when no trip has captured firmware yet, in which case
      // we skip the adapter-keyed write but still kept the per-
      // vehicle persistence above.
      if (updated.pointEstimate > brokenMapBlocklistThreshold) {
        final adapterId = _latestAdapterFirmwareFor(vehicleId);
        if (adapterId != null && adapterId.isNotEmpty) {
          await ref
              .read(obdAdapterBlocklistProvider)
              .recordBelief(adapterId, updated.pointEstimate);
        }
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'FillUpList: broken-MAP observation failed'}));
    }
  }

  /// Resolve the [ReferenceVehicle] for [vehicleId] using the loaded
  /// catalog (#1424 deliverable F). Returns `null` when:
  ///   - the vehicle profile isn't in the list,
  ///   - the catalog hasn't finished loading (AsyncValue still
  ///     resolving),
  ///   - no catalog row matches the profile's make/model/year.
  /// In all three cases, the updater falls back to a neutral 1.0
  /// Bayes-factor adjustment — observations still fold cleanly.
  ReferenceVehicle? _resolveReferenceVehicle(String vehicleId) {
    final profiles = ref.read(vehicleProfileListProvider);
    final profile = profiles.where((p) => p.id == vehicleId).firstOrNull;
    if (profile == null) return null;
    final catalog =
        ref.read(referenceVehicleCatalogProvider).value ?? const [];
    if (catalog.isEmpty) return null;
    return VehicleProfileCatalogMatcher.bestMatch(
      profile: profile,
      catalog: catalog,
    );
  }

  /// Look up the most-recently captured `adapterFirmware` across the
  /// trip history for [vehicleId] (#1423 phase 4). Returns null when
  /// the vehicle has no trips, or every trip pre-dates the
  /// `adapterFirmware` capture path landing — both cases result in
  /// the blocklist staying out of the loop, which is harmless (the
  /// per-vehicle belief still persisted in
  /// [_recordBrokenMapObservation] above).
  String? _latestAdapterFirmwareFor(String vehicleId) {
    final repo = ref.read(tripHistoryRepositoryProvider);
    if (repo == null) return null;
    final history = repo.loadAll();
    DateTime? bestWhen;
    String? best;
    for (final entry in history) {
      if (entry.vehicleId != vehicleId) continue;
      final firmware = entry.adapterFirmware;
      if (firmware == null || firmware.isEmpty) continue;
      final when = entry.summary.endedAt ?? entry.summary.startedAt;
      if (when == null) continue;
      if (bestWhen == null || when.isAfter(bestWhen)) {
        bestWhen = when;
        best = firmware;
      }
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
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'FillUpList: reminder evaluation failed'}));
    }
  }

  /// Run the η_v learner against the new fill-up. Returns the resulting
  /// [VeLearnResult] (or `null` when guards rejected) so downstream
  /// hooks (#1423 phase 3 broken-MAP belief) can read
  /// [VeLearnResult.proposedEta] without re-running the learner.
  Future<VeLearnResult?> _reconcileVolumetricEfficiency(
    FillUp fillUp,
    FillUp? previous,
  ) async {
    final vehicleId = fillUp.vehicleId;
    if (vehicleId == null) return null;
    if (fillUp.liters <= 0) return null;
    try {
      final learner = ref.read(veLearnerProvider);
      if (learner == null) return null;
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
      return result;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'FillUpList: VE reconciliation failed'}));
      return null;
    }
  }

  /// Refine the active vehicle's [GpsCalibrationMatrix] against the
  /// observed fuel burn at this fill-up (#2081 / Epic #2055).
  ///
  /// Looks up GPS-only / hybrid trajets in the fill-up's linked
  /// window, builds the feature aggregate per trajet, and passes
  /// them through [GpsMatrixReconciler.reconcile] to update the
  /// matrix's `baseline` coefficient + the bookkeeping fields
  /// (count, variance, last-reconciled-at). Skips silently when:
  ///
  /// - No vehicle is linked to the fill-up.
  /// - No GPS-only / hybrid trajets exist in the window.
  /// - The reconciler returns null (degenerate inputs).
  ///
  /// Cold-starts the matrix from the vehicle's defaults when the
  /// field is null — first GPS-only fill-up reconciliation will
  /// seed the matrix and step it once toward the observed truth.
  Future<void> _reconcileGpsCalibrationMatrix(FillUp fillUp) async {
    final vehicleId = fillUp.vehicleId;
    if (vehicleId == null) return;
    if (fillUp.liters <= 0) return;
    try {
      final vehicleRepo = ref.read(vehicleProfileRepositoryProvider);
      final vehicle = vehicleRepo.getById(vehicleId);
      if (vehicle == null) return;

      // Trajets linked to this fill-up's window. We restrict to
      // GPS-only + hybrid kinds — gpsPlusObd2 trips already had
      // their OBD2 fuel-rate ground truth and aren't useful signal
      // for the GPS matrix (they'd over-fit it to OBD2-instrumented
      // driving patterns).
      final tripHistory = ref.read(tripHistoryRepositoryProvider);
      if (tripHistory == null) return;
      final allTrips = tripHistory.loadAll();
      final inWindow = allTrips
          .where((t) => fillUp.linkedTripIds.contains(t.id))
          .where((t) => t.summary.kind != TripKind.gpsPlusObd2)
          .toList();
      if (inWindow.isEmpty) return;

      final trajetFeatures = <GpsDrivingFeatures>[];
      var totalKm = 0.0;
      for (final t in inWindow) {
        final f = GpsDrivingFeatures.from(t.samples);
        if (f != null) {
          trajetFeatures.add(f);
          totalKm += f.distanceKm;
        }
      }
      if (trajetFeatures.isEmpty || totalKm <= 0) return;

      final matrix =
          vehicle.gpsCalibration ?? GpsCalibrationMatrix.coldStart();
      // The reconciler manages its own residual window; we'd
      // need a per-vehicle residual log to persist across runs.
      // For the MVP we pass an empty list — the variance figure
      // reflects only this fill-up's residual and grows accurate
      // as the matrix iterates. A follow-up wires per-vehicle
      // residual history into Hive.
      final updated = GpsMatrixReconciler.reconcile(
        matrix: matrix,
        trajets: trajetFeatures,
        actualLitersBurned: fillUp.liters,
        totalDistanceKm: totalKm,
        recentResiduals: const <double>[],
      );
      if (updated == null) return;

      // #3122 — the calibration refinement is a real local modification:
      // stamp it so the LWW sync merge propagates (and protects) it.
      await vehicleRepo.save(
        vehicle.copyWith(
          gpsCalibration: updated,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      ref.invalidate(vehicleProfileListProvider);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'GPS matrix reconciliation failed'}));
    }
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

/// Bundle the [Reconciler] outcome with the per-window distance the
/// broken-MAP hook (#1423 phase 3) needs to convert pumped/consumed
/// litres into L/100 km. Private to this file — the public reconciler
/// stays distance-agnostic.
class _TripVsPumpReconciliation {
  final ReconciliationResult result;
  final double windowDistanceKm;

  const _TripVsPumpReconciliation({
    required this.result,
    required this.windowDistanceKm,
  });
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
