// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_recording_provider.dart';

/// #3760 — the trip-history persistence concern (`_saveToHistory`, the
/// #1347 recovered-snapshot finalisation, the #2392 physics-scale
/// calibration), split out of `trip_recording_provider.dart` as a
/// `part` mixin (move-only, behaviour preserved). Constrained `on`
/// [_TripRecordingCore] + [_TripRecordingSnapshot] so it reaches the
/// lifecycle-marks recorder and the recovered snapshot state.
mixin _TripRecordingPersist
    on _$TripRecording, _TripRecordingCore, _TripRecordingSnapshot {
  /// Exposed for tests (#3573): drive the private `_saveToHistory` write
  /// directly so the comm-diagnostic gating (adapter-identity present vs
  /// GPS-only) is assertable without a full recording pipeline.
  @visibleForTesting
  Future<TripPersistOutcome> debugSaveToHistory(
    TripSummary summary, {
    List<TripSample> samples = const [],
    String? adapterMac,
    String? adapterName,
    int gpsFixCount = 0,
  }) =>
      _saveToHistory(
        summary,
        samples: samples,
        adapterMac: adapterMac,
        adapterName: adapterName,
        gpsFixCount: gpsFixCount,
      );

  /// #1347 — finalise the recovered active-trip snapshot into trip
  /// history when the user taps Resume / End on the pause banner
  /// after a cold-start recovery. The controller is null in this
  /// state (`restoreFromSnapshot` deliberately leaves it that way),
  /// so [stop] cannot run its normal teardown; this helper writes
  /// the snapshot's captured samples + summary into the rolling
  /// trip-history log instead, clears the snapshot from Hive, and
  /// transitions state to `finished` so the recording screen renders
  /// the summary view.
  ///
  /// True "continue recording" — re-pair the adapter, reattach a
  /// controller carrying the snapshot's session id + prior samples,
  /// and resume polling — is intentionally out of scope here. See the
  /// #1347 follow-up issue. The salvage path's only job is to make
  /// sure the partial drive isn't silently lost.
  Future<StoppedTripResult> _finalizeRecoveredSnapshot() async {
    final snapshot = _activeSnapshot;
    if (snapshot == null) {
      _publish(const TripRecordingState(), 'finalise recovered: none');
      return const StoppedTripResult.empty();
    }
    // Every Riverpod-backed dependency, read synchronously up front.
    final deps = recoveredFinaliseDeps(ref, automatic: snapshot.automatic);

    // #3597 — the skeleton replayed into a full summary; #4329 — of the
    // kind the row's evidence names (see recoveredTripKind).
    final summary = recoveredTripSummary(snapshot);

    // Transition state synchronously so the recording screen flips to
    // the summary view immediately — even if the Hive writes below
    // race against provider disposal in a test harness.
    _publish(state.copyWith(phase: TripRecordingPhase.finished),
        'finalise recovered');

    var saved = false;
    try {
      saved = await deps.historyRepo
              ?.save(recoveredTripEntry(snapshot, summary)) ??
          false;
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.providers, context: const {'where': 'TripRecording recovered finalise: save failed'});
    }
    final result = StoppedTripResult(
      summary: summary,
      odometerStartKm: snapshot.odometerStartKm,
      odometerLatestKm: snapshot.odometerLatestKm,
      entryId: saved ? snapshot.id : null,
    );

    // Clear the snapshot BEFORE the best-effort observer-refresh and
    // badge bump below — the recovery service must not resurrect a
    // finalised trip on next launch even if those follow-up steps
    // throw or race against provider disposal in a test harness.
    // #4328 — and ONLY once the trip is in history: after a failed
    // write the WAL row is the trip, for the next launch to hand back.
    if (saved) await _clearActiveSnapshot();

    try {
      deps.historyList?.refresh();
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.providers, context: const {'where': 'TripRecording recovered finalise: list refresh failed'});
    }

    // Mirror the auto-record badge bookkeeping the regular
    // `_saveToHistory` path applies — a recovered auto-trip is still
    // an "unseen" trip the user should see in the launcher.
    if (deps.badge != null) {
      try {
        final badge = await deps.badge!;
        await badge.increment();
      } catch (e, st) {
        log.error(e, st, layer: ErrorLayer.providers, context: const {'where': 'TripRecording recovered finalise: badge bump failed'});
      }
    }

    return result;
  }

  /// Persist a finished trip into the rolling trip-history log (#726).
  /// Shared by both pipelines through the [RecordingPipelineHost]: the
  /// OBD2 pipeline passes the baseline vehicle id + the adapter identity
  /// it snapshotted at start (#1312); the GPS-only path leaves them null.
  ///
  /// Returns the [TripPersistOutcome] so the caller can surface a
  /// "no movement detected" notice on a genuine stationary discard and
  /// stay silent on a save (#2509) — and, #4328, retire the trip's
  /// recovery rows only when it is not [TripPersistOutcome.failed].
  Future<TripPersistOutcome> _saveToHistory(
    TripSummary summary, {
    String? tripId, // #4328 — the id the trip's WAL row carries
    bool automatic = false,
    List<TripSample> samples = const [],
    List<GpsSampleDiagnostic> gpsSampleDiagnostics = const [],
    String? vehicleId,
    String? adapterMac,
    String? adapterName,
    String? adapterFirmware,
    int gpsFixCount = 0,
    // #3794 — session transparency payloads (null on the GPS-only and
    // legacy paths, which simply persist less).
    TripTermination? termination,
    RecordingSessionJournal? sessionJournal,
  }) async {
    // Skip stub / ghost trips so they never clutter history (#1923 / #2509
    // no-movement guard + #2692 C4-H virtual-ghost guard). The full decision
    // lives in the pure [shouldDiscardAsNoMovement] helper.
    if (shouldDiscardAsNoMovement(
      summary: summary,
      sampleCount: samples.length,
      gpsFixCount: gpsFixCount,
    )) {
      // No silent discard (#2509) — the log decision lives with the guard.
      noteNoMovementDiscard(summary, samples.length, gpsFixCount);
      return TripPersistOutcome.discardedNoMovement;
    }
    // #3878 — ONE entry: saved, then reused for the upload (no re-decode
    // of the row just written).
    TripHistoryEntry? entry;
    try {
      // #4328 — a write that did not land is not a save. Say so, and the
      // caller keeps the WAL row the next launch recovers the trip from.
      final repo = ref.read(tripHistoryRepositoryProvider);
      if (repo == null) throw StateError('trip history box is not open');
      entry = finishedTripEntry(
        summary,
        tripId: tripId,
        now: ref.read(appClockProvider).now(),
        lifecycleMarks: _lifecycleMarks,
        automatic: automatic,
        samples: samples,
        gpsSampleDiagnostics: gpsSampleDiagnostics,
        vehicleId: vehicleId,
        adapterMac: adapterMac,
        adapterName: adapterName,
        adapterFirmware: adapterFirmware,
        termination: termination,
        sessionJournal: sessionJournal,
      );
      if (!await repo.save(entry)) throw StateError('the write did not land');
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.providers, context: const {'where': 'TripRecording._saveToHistory'});
      // #4378 — keep the trip under its own id: the active-trip WAL holds
      // ONE row, and the next recording seeds over it.
      if (entry != null) await PendingTripSaves.resolve()?.keep(entry);
      return TripPersistOutcome.failed;
    }
    try {
      ref.read(tripHistoryListProvider.notifier).refresh();
      // #2392 — calibrate the vehicle's physicsScale from this trip's
      // OBD2 ground truth (no-op for GPS-only / suspect / too-short
      // trips). Fire-and-forget: a calibration failure must never derail
      // the trip-save flow.
      unawaited(_calibratePhysicsScale(summary, samples, vehicleId));
      // Phase 5 (#1004): bump the launcher-icon badge so the user sees
      // "something happened while I was driving" without opening the
      // app. The decrement fires when the user lands on the trip
      // detail screen for this auto-recorded trip.
      if (automatic) {
        try {
          final badge = await ref.read(autoRecordBadgeServiceProvider.future);
          await badge.increment();
        } catch (e, st) {
          log.error(e, st, layer: ErrorLayer.providers, context: const {'where': 'TripRecording auto-record badge increment'});
        }
      }
      // #1479 phase 2 / #1665 — opportunistic upload of the freshly
      // saved summary to TankSync. Gated by `tripsSyncEnabledProvider`
      // — the single source of truth (non-anonymous account ∧ cloud
      // sync consent ∧ trips toggle). Read here rather than hoisted
      // into the orchestrator so a manual stop path also benefits.
      try {
        if (ref.read(tripsSyncEnabledProvider)) {
          // #2304 — O(1) box lookup for the richer serialised object to
          // upload, instead of deserialising + sorting every entry just
          // to discard all but the just-saved id. Falls back to a
          // freshly-built entry if the read missed (corrupt payload).
          // #3878 — the entry in hand IS the row (same fields, same
          // samples); the old O(1) box lookup re-decoded every sample.
          // Fire-and-forget: an upload failure must not roll back the
          // local save. TripsSync swallows + debugPrints internally.
          unawaited(TripsSync.uploadSummary(entry));
        }
      } catch (e, st) {
        log.error(e, st, layer: ErrorLayer.providers, context: const {'where': 'TripRecording trip-sync hook'});
      }
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.providers, context: const {'where': 'TripRecording._saveToHistory: after the write'});
    }
    // #2509 — the trip is in history (a best-effort follow-up that failed
    // was logged above), so the stop UI shows no "no movement" notice.
    return TripPersistOutcome.saved;
  }

  /// Refine the trip's vehicle physicsScale from OBD2 ground truth
  /// (#2392). Delegates the gating + EWMA math to the pure
  /// [PhysicsScaleCalibrator]; here we just resolve the vehicle, persist
  /// the result, and refresh the list. No-op when nothing was learned
  /// (the calibrator returns the matrix unchanged), so we only write +
  /// invalidate when the scale actually moved.
  Future<void> _calibratePhysicsScale(
    TripSummary summary,
    List<TripSample> samples,
    String? vehicleId,
  ) async {
    if (vehicleId == null || samples.isEmpty) return;
    try {
      final repo = ref.read(vehicleProfileRepositoryProvider);
      final vehicle = repo.getById(vehicleId);
      if (vehicle == null) return;
      final updated = PhysicsScaleCalibrator.calibrate(
        vehicle: vehicle,
        matrix: vehicle.gpsCalibration,
        summary: summary,
        samples: samples,
      );
      if (updated == vehicle.gpsCalibration) return;
      await repo.save(vehicle.copyWith(gpsCalibration: updated));
      ref.invalidate(vehicleProfileListProvider);
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.providers, context: const {'where': 'TripRecording._calibratePhysicsScale'});
    }
  }
}
