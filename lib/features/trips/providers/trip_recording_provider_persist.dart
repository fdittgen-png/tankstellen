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
      state = const TripRecordingState();
      return const StoppedTripResult.empty();
    }
    // Resolve every Riverpod-backed dependency synchronously up
    // front. Reading `ref` after an `await` is unsafe — the provider
    // could be disposed by then (rare in production thanks to
    // `keepAlive: true`, frequent in tests where the container goes
    // out of scope before the unawaited future settles).
    TripHistoryRepository? historyRepo;
    TripHistoryList? historyList;
    Future<AutoRecordBadgeService>? badgeFuture;
    try {
      historyRepo = ref.read(tripHistoryRepositoryProvider);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording recovered finalise: history repo read failed'}));
    }
    try {
      historyList = ref.read(tripHistoryListProvider.notifier);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording recovered finalise: history list read failed'}));
    }
    if (snapshot.automatic) {
      try {
        badgeFuture = ref.read(autoRecordBadgeServiceProvider.future);
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording recovered finalise: badge service read failed'}));
      }
    }

    // #3597 — the snapshot's summary is a skeleton (distance + maxRpm
    // only); replay the persisted samples through the canonical recorder
    // so the salvaged trip keeps its consumption figure, idle/high-RPM
    // time and cold-start flag instead of surfacing avgLPer100Km null.
    final summary = rebuildRecoveredSummary(
      skeleton: snapshot.summary,
      samples: snapshot.samples,
    );

    final result = StoppedTripResult(
      summary: summary,
      odometerStartKm: snapshot.odometerStartKm,
      odometerLatestKm: snapshot.odometerLatestKm,
    );
    // Transition state synchronously so the recording screen flips to
    // the summary view immediately — even if the Hive writes below
    // race against provider disposal in a test harness.
    state = state.copyWith(phase: TripRecordingPhase.finished);

    if (historyRepo != null) {
      try {
        await historyRepo.save(TripHistoryEntry(
          id: snapshot.id,
          vehicleId: snapshot.vehicleId,
          summary: summary,
          automatic: snapshot.automatic,
          samples: snapshot.samples,
          // #3796 — the honest label. A WAL row whose writing process is
          // not this one was left behind by a process that died: an
          // orderly stop always clears it. Until now this trip was saved
          // indistinguishable from a normal one, after being surfaced to
          // the user as a Bluetooth drop.
          termination: ProcessDeathContext.diedWhileRecording(
                  snapshot.processInstanceId)
              ? TripTermination(
                  TripTerminationReason.recoveredAfterProcessDeath,
                  detail: ProcessDeathContext.terminationDetail(),
                )
              : const TripTermination(TripTerminationReason.userStopped,
                  detail: 'finalised from a recovered snapshot'),
        ));
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording recovered finalise: save failed'}));
      }
    }

    // Clear the snapshot BEFORE the best-effort observer-refresh and
    // badge bump below — the recovery service must not resurrect a
    // finalised trip on next launch even if those follow-up steps
    // throw or race against provider disposal in a test harness.
    await _clearActiveSnapshot();

    try {
      historyList?.refresh();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording recovered finalise: list refresh failed'}));
    }

    // Mirror the auto-record badge bookkeeping the regular
    // `_saveToHistory` path applies — a recovered auto-trip is still
    // an "unseen" trip the user should see in the launcher.
    if (badgeFuture != null) {
      try {
        final badge = await badgeFuture;
        await badge.increment();
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording recovered finalise: badge bump failed'}));
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
  /// stay silent on a save (#2509).
  Future<TripPersistOutcome> _saveToHistory(
    TripSummary summary, {
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
      // No silent discard (#2509): record WHY so a regression of the
      // silent-data-loss bug surfaces in the error log, and let the caller
      // surface a "no movement detected" notice to the user.
      //
      // #2787 — but only error-log when captured SIGNAL is actually being
      // dropped (the silent-data-loss regression this guard exists to catch).
      // A genuinely empty stop — no samples AND no GPS fixes, e.g. the user
      // stopped without moving, or the foreground GPS stream never started
      // (the #2766 FGS-permission case, error log #17) — has no data to lose,
      // so logging it as an error trace is pure noise. The user-facing "no
      // movement detected" notice (the returned outcome) is unchanged.
      final droppedCapturedSignal = samples.isNotEmpty || gpsFixCount > 0;
      if (droppedCapturedSignal) {
        unawaited(errorLogger.log(
          ErrorLayer.providers,
          StateError('trip discarded — no movement detected'),
          StackTrace.current,
          context: {
            'where': 'TripRecording._saveToHistory discard',
            'reason': 'no-movement',
            'distanceKm': summary.distanceKm.toStringAsFixed(4),
            'distanceSource': summary.distanceSource,
            'sampleCount': samples.length.toString(),
            'gpsFixCount': gpsFixCount.toString(),
            'hadStartedAt': (summary.startedAt != null).toString(),
          },
        ));
      }
      return TripPersistOutcome.discardedNoMovement;
    }
    try {
      final repo = ref.read(tripHistoryRepositoryProvider);
      if (repo == null) return TripPersistOutcome.saved;
      final id = summary.startedAt?.toIso8601String() ??
          DateTime.now().toIso8601String();
      // #2912 — per-trip OBD2 comm-health diagnostic (never-throws capture).
      // #3573 — only for trips that actually bound an OBD2 service
      // (adapter identity is stamped by the OBD2 pipeline alone): the
      // capture reads a PROCESS-WIDE singleton session, so a GPS-only
      // trip used to inherit whatever idle link the supervisor happened
      // to hold and render a misleading "0% complete · 0% utilization ·
      // no dropouts" card for a link the trip never touched.
      final obd2Diagnostic = adapterMac == null
          ? null
          : Obd2CommDiagnostics.instance.captureForTrip();
      await repo.save(TripHistoryEntry(
        id: id,
        vehicleId: vehicleId,
        summary: summary,
        automatic: automatic,
        samples: samples,
        // #1312 — adapter identity snapshotted at [start] time. Null
        // for legacy / fake-service code paths; the detail card hides
        // the row entirely in that case.
        adapterMac: adapterMac,
        adapterName: adapterName,
        adapterFirmware: adapterFirmware,
        // #1458 phase 2 — GPS cadence diagnostics captured during
        // recording. Empty when the GPS feature flag was off for this
        // trip; the entry's JSON serialiser elides the key in that case.
        gpsSampleDiagnostics: gpsSampleDiagnostics,
        // #3465 — background/resume marks windowed to this trip, so the
        // GPS coverage report can attribute track gaps post-hoc.
        lifecycleMarks: summary.startedAt == null
            ? const []
            : _lifecycleMarks.marksForWindow(
                summary.startedAt!, summary.endedAt ?? DateTime.now()),
        obd2Diagnostic: obd2Diagnostic, // #2912 — per-trip comm-health
        // #3795/#3797 — WHY the session ended + its lifecycle timeline.
        // Defaulted to userStopped only when the caller attributed
        // nothing: an unattributed manual save IS a user stop, whereas
        // guessing on the automatic path would mislabel a grace expiry.
        termination: termination ??
            (automatic
                ? null
                : const TripTermination(TripTerminationReason.userStopped)),
        sessionJournal: sessionJournal,
      ));
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
          unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording auto-record badge increment'}));
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
          final entry = repo.loadById(id) ??
              TripHistoryEntry(
                id: id,
                vehicleId: vehicleId,
                summary: summary,
                automatic: automatic,
              );
          // Fire-and-forget: an upload failure must not roll back the
          // local save. TripsSync swallows + debugPrints internally.
          unawaited(TripsSync.uploadSummary(entry));
        }
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording trip-sync hook'}));
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording._saveToHistory'}));
    }
    // #2509 — the trip reached the history write (or a best-effort
    // sub-step failed and was logged above); either way it was not a
    // stationary discard, so the stop UI shows no "no movement" notice.
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
      unawaited(errorLogger.log(ErrorLayer.providers, e, st,
          context: const {'where': 'TripRecording._calibratePhysicsScale'}));
    }
  }
}
