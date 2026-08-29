// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_recording_provider.dart';

/// #3760 — the #1303 write-through active-trip WAL snapshot concern
/// (debounced flush, cold-start restore, #3758 append-only sample WAL),
/// split out of `trip_recording_provider.dart` as a `part` mixin
/// (move-only, behaviour preserved). Constrained `on`
/// [_TripRecordingCore] so it reads the same private controller /
/// last-trip bookkeeping the notifier owns.
mixin _TripRecordingSnapshot on _$TripRecording, _TripRecordingCore {
  // ---------------------------------------------------------------------------
  // #1303 — write-through persistence of the in-progress trip
  // ---------------------------------------------------------------------------

  /// Optional override for tests: hand-built repository wrapping an
  /// in-memory Hive box. Production reads the box from
  /// [HiveBoxes.obd2ActiveTrip] when needed; this lets tests skip
  /// the box-open dance.
  ActiveTripRepository? _activeRepoOverride;

  /// Last persisted snapshot, kept in memory so the debounced
  /// flush can re-use the trip identity (id, startedAt, vehicleId)
  /// across writes without rebuilding it from scratch.
  ActiveTripSnapshot? _activeSnapshot;

  /// Wall-clock of the most recent flush. Used by the debounce
  /// gate so we don't pay a Hive write on every sample.
  DateTime? _lastSnapshotFlushAt;

  /// #3758 — samples already streamed to the append-only WAL.
  int _walWrittenCount = 0;

  /// Sample count since the last flush. Forces an out-of-band
  /// write when the user has been driving long enough to fill the
  /// buffer past the count threshold even if the time threshold
  /// hasn't elapsed (e.g. a 5 Hz fast tier on stop-and-go traffic).
  int _samplesSinceLastFlush = 0;

  /// Time-based debounce: at most one Hive write every 5 seconds
  /// while the trip is healthy. Aligned with the controller's
  /// 4 Hz emit cadence — 4 Hz × 5 s = 20 emits per write, which
  /// is a comfortable balance between recovery freshness and
  /// flash-write wear.
  static const Duration _snapshotFlushInterval = Duration(seconds: 5);

  /// Sample-count fallback: flush when this many emits have
  /// accumulated since the previous write, regardless of clock.
  /// 30 covers ~7.5 s at 4 Hz so the upper bound on a freshness
  /// gap is bounded by either rule.
  static const int _snapshotFlushSampleThreshold = 30;

  // ---------------------------------------------------------------------------
  // #1303 — write-through persistence helpers
  // ---------------------------------------------------------------------------

  /// Allow tests / wiring to inject a custom [ActiveTripRepository].
  /// Production never calls this — the box is resolved lazily from
  /// [HiveBoxes.obd2ActiveTrip].
  @visibleForTesting
  void debugSetActiveRepo(ActiveTripRepository repo) {
    _activeRepoOverride = repo;
  }

  /// Read the active-trip repo, returning null when the box isn't
  /// open (widget tests, fresh installs). The provider falls back to
  /// the in-memory snapshot only — recovery doesn't happen if
  /// there's no Hive to read from.
  ActiveTripRepository? _resolveActiveRepo() {
    final override = _activeRepoOverride;
    if (override != null) return override;
    if (!Hive.isBoxOpen(HiveBoxes.obd2ActiveTrip)) return null;
    try {
      return ActiveTripRepository(
        sampleWal: ActiveTripSampleWal.instance,
        box: Hive.box<String>(HiveBoxes.obd2ActiveTrip),
      );
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording active repo'}));
      return null;
    }
  }

  /// Initialise [_activeSnapshot] from controller state immediately
  /// after [start] succeeds. The snapshot is kept null until then so
  /// the lifecycle-paused hook on a never-started provider is a no-op.
  void _seedActiveSnapshot() {
    final ctl = _obd2?.controller;
    if (ctl == null) return;
    final id = ctl.sessionId ?? DateTime.now().toIso8601String();
    final startedAt = _lastTripStartedAt ?? DateTime.now();
    _activeSnapshot = ActiveTripSnapshot(
      id: id,
      vehicleId: _lastTripVehicleId ?? _baselines.vehicleId,
      vin: ctl.vin,
      automatic: _lastTripAutomatic, // #3251 — real auto-record provenance
      phase: 'recording',
      summary: const TripSummary(
        distanceKm: 0,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
      ),
      samples: const [],
      odometerStartKm: ctl.odometerStartKm,
      odometerLatestKm: ctl.odometerLatestKm,
      startedAt: startedAt,
      lastFlushedAt: DateTime.now(),
      // #3796 — whose process wrote this WAL row.

      processInstanceId: ProcessDeathContext.instanceId,
    );
    _lastSnapshotFlushAt = null;
    _samplesSinceLastFlush = 0;
    // #3758 — fresh trip, fresh sample WAL (truncates any stale file;
    // recovery for a crashed session already ran at launch).
    _walWrittenCount = 0;
    unawaited(_resolveActiveRepo()?.sampleWal?.openFresh());
    // First-write seed so the recovery service has something on
    // disk even if the OS kills us before the first live sample
    // lands. Best-effort, fire-and-forget.
    unawaited(_flushActiveSnapshot(force: true));
  }

  /// Build a fresh snapshot from the controller's current state.
  /// Returns null when there's no controller (defensive).
  ActiveTripSnapshot? _buildSnapshotFor(TripRecordingController ctl) {
    final base = _activeSnapshot;
    if (base == null) return null;
    final phaseStr = _phaseStringFor(ctl);
    // #3878 — the Hive row is meta-only whenever the WAL is writable (the
    // samples are on disk, the in-memory ring only holds the live window);
    // a broken WAL keeps the pre-#3758 fat row so no sample is lost.
    final walWritable = _resolveActiveRepo()?.sampleWal?.isWritable ?? false;
    final samples = walWritable ? const <TripSample>[] : ctl.capturedSamples;
    return base.copyWith(
      phase: phaseStr,
      summary: _summaryFromCtl(ctl),
      samples: samples,
      odometerStartKm: ctl.odometerStartKm,
      odometerLatestKm: ctl.odometerLatestKm,
      lastFlushedAt: DateTime.now(),
    );
  }

  /// Map the controller's enum to the string the snapshot
  /// serialises. Centralised so the recovery service doesn't have
  /// to translate enum names — both sides agree on the wire format.
  String _phaseStringFor(TripRecordingController ctl) {
    switch (ctl.currentState) {
      case TripRecordingControllerState.idle:
        return 'idle';
      case TripRecordingControllerState.recording:
        return 'recording';
      case TripRecordingControllerState.paused:
        return 'paused';
      case TripRecordingControllerState.pausedDueToDrop:
        return 'pausedDueToDrop';
      // #2565 — a GPS-only degraded trip is still actively recording, so
      // the WAL snapshot persists it as 'recording' (it rehydrates as a
      // live trip on relaunch, never as a pause that needs resuming).
      case TripRecordingControllerState.degradedGpsOnly:
        return 'recording';
      case TripRecordingControllerState.stopped:
        return 'stopped';
    }
  }

  /// Pull the recorder's running summary; lets the snapshot carry
  /// the latest distance / fuel / harsh counts without forcing the
  /// controller to expose more debug surface than [capturedSamples].
  /// [samples] is the buffer view the caller read for this flush (#3741).
  TripSummary _summaryFromCtl(TripRecordingController ctl) {
    // The controller has no public mid-trip summary accessor; rather
    // than reach into its recorder we use the captured buffer's O(1)
    // facts — the post-debounce 1 Hz feed, plenty for the staleness /
    // preview rendering recovery does. A perfect mid-trip summary
    // (idle/harsh counters) would need the controller to expose its own
    // recorder snapshot; deferred until recovery acquires a richer preview.
    final first = ctl.firstCapturedAt;
    final last = ctl.latestSample?.timestamp;
    if (first == null || last == null) {
      return const TripSummary(
        distanceKm: 0,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
      );
    }
    // #3741 — incremental running max; the old whole-buffer loop was
    // O(n) per 5 s flush (O(n²) over a drive) on the gauge isolate.
    final maxRpm = ctl.maxCapturedRpm;
    // #3251 — use the controller's OWN gap-capped distance + provenance, not a
    // re-integration of the raw buffer. Re-integrating bridged dropout gaps and
    // fabricated ~10 km across a 20-min hole (the #1927 bug on the recovery
    // path); `currentDistanceKm` already applies `maxIntegrationGapSeconds`, and
    // `distanceSource` keeps the real provenance instead of defaulting 'virtual'.
    return TripSummary(
      distanceKm: ctl.currentDistanceKm,
      maxRpm: maxRpm,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      startedAt: first,
      endedAt: last,
      distanceSource: ctl.distanceSource,
    );
  }

  /// Cheap gate called from the live-stream listener. Promotes to
  /// a real flush when either the time threshold or the sample
  /// threshold is crossed.
  void _maybeFlushActiveSnapshot() {
    _samplesSinceLastFlush++;
    final last = _lastSnapshotFlushAt;
    final now = DateTime.now();
    if (last != null) {
      final elapsed = now.difference(last);
      if (elapsed < _snapshotFlushInterval &&
          _samplesSinceLastFlush < _snapshotFlushSampleThreshold) {
        return;
      }
    }
    unawaited(_flushActiveSnapshot());
  }

  /// Persist the current snapshot. Always writes when called — the
  /// debounce gate lives upstream in [_maybeFlushActiveSnapshot]
  /// which decides whether to call this method. Forced callers
  /// (lifecycle backgrounded, phase transition, seed) skip the gate
  /// and invoke this directly so they can't lose the next interval.
  Future<void> _flushActiveSnapshot({bool force = false}) async {
    // `force` is kept on the signature for self-documenting call
    // sites (`_flushActiveSnapshot(force: true)` reads as "I do not
    // want this skipped"). The semantics are unconditional today;
    // earlier drafts had an internal gate here too which double-
    // counted with [_maybeFlushActiveSnapshot]. Keeping the param
    // makes the intent at the call site obvious without changing
    // behaviour.
    final ctl = _obd2?.controller;
    if (!force && ctl == null) return;
    if (ctl == null) return;
    final repo = _resolveActiveRepo();
    if (repo == null) return;
    final next = _buildSnapshotFor(ctl);
    if (next == null) return;
    _activeSnapshot = next;
    _lastSnapshotFlushAt = next.lastFlushedAt;
    _samplesSinceLastFlush = 0;
    try {
      // #3758 — stream only the NEW samples into the append-only WAL
      // (each written exactly once); saveSnapshot then persists meta
      // only. This replaces the old whole-list re-serialization that
      // crashed recordings at ~40 min.
      // #3878 — the unwritten tail comes from the controller's ring by
      // ABSOLUTE index, and once on disk the ring releases everything
      // older than its live window.
      final wal = repo.sampleWal;
      if (wal != null && wal.isWritable) {
        for (final s in ctl.capturedSince(_walWrittenCount)) {
          wal.append(s);
        }
        _walWrittenCount = ctl.capturedTotal;
        ctl.releaseWrittenSamples(_walWrittenCount);
      }
      await repo.saveSnapshot(next);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording flush snapshot failed'}));
    }
  }

  /// #3878 — every captured sample of the running trip, for the stop path
  /// and the grace-window finalise: flush the tail, then read the WAL back
  /// in one isolate hop. Without a writable WAL the controller's buffer
  /// still holds everything (nothing was released).
  Future<List<TripSample>> readAllCapturedSamples() async {
    final ctl = _obd2?.controller;
    if (ctl == null) return const [];
    await _flushActiveSnapshot(force: true);
    final wal = _resolveActiveRepo()?.sampleWal;
    if (wal == null || !wal.isWritable) {
      return List<TripSample>.unmodifiable(ctl.capturedSamples);
    }
    final fromDisk = await wal.readAll();
    // The WAL is the whole trip; the ring can only lag it (a torn final
    // line after a crash is the recovery path's problem, not ours).
    if (fromDisk.length >= ctl.capturedTotal) return fromDisk;
    return [...fromDisk, ...ctl.capturedSince(fromDisk.length)];
  }

  /// Drop the persisted snapshot + clear in-memory bookkeeping.
  /// Safe to call when nothing was ever written.
  Future<void> _clearActiveSnapshot() async {
    _activeSnapshot = null;
    _lastSnapshotFlushAt = null;
    _samplesSinceLastFlush = 0;
    final repo = _resolveActiveRepo();
    if (repo == null) return;
    try {
      await repo.clearSnapshot();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording clear snapshot failed'}));
    }
  }

  /// Surface the recovered snapshot from a previous cold-start
  /// recovery walk. Phase 2 of #1303: hands the user back into a
  /// `pausedDueToDrop`-shaped state with their captured samples
  /// preserved and exposed as `state.live.distanceKmSoFar` so the
  /// recording screen renders something meaningful.
  ///
  /// Does NOT auto-reconnect OBD2 — that's the existing reconnect
  /// scanner's job. The user manually resumes after they're back
  /// in the recording UI; that path picks up from a fresh BT
  /// connect through the regular adapter picker.
  ///
  /// Returns true when the snapshot was applied, false when the
  /// provider was already mid-trip (a fresh launch that started a
  /// trip before recovery ran — extremely unlikely but defensive).
  bool restoreFromSnapshot(ActiveTripSnapshot snapshot) {
    if (state.isActive) return false;
    _activeSnapshot = snapshot;
    _lastTripVehicleId = snapshot.vehicleId;
    _lastTripStartedAt = snapshot.startedAt;
    state = state.copyWith(
      phase: TripRecordingPhase.pausedDueToDrop,
    );
    return true;
  }
}
