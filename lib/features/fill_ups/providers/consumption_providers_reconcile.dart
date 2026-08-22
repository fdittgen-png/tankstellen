// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'consumption_providers.dart';

/// #3762 — the trip-vs-pump reconciliation + broken-MAP observation
/// half of [FillUpList], split out of `consumption_providers.dart` as a
/// `part` mixin to satisfy the #1680 file-length ratchet. Move-only:
/// behaviour preserved verbatim. Constrained `on _FillUpListWindows`
/// because [_reconcileTripVsPump] reuses its window-distance math.
mixin _FillUpListReconcile on _FillUpListWindows {
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
      final history = tripRepo.loadSummaries(); // #3613 — summary reconcile
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
    final history = repo.loadSummaries(); // #3613 — firmware+times only
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
