// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_recording_provider.dart';

/// #3760 — the pause / resume / stop / reset lifecycle boundaries, the
/// #2274 connecting- and #2548 saving-phase transitions, and the
/// app-lifecycle hooks, split out of `trip_recording_provider.dart` as
/// a `part` mixin (move-only, behaviour preserved). Constrained `on`
/// the sibling mixins so the stop/resume salvage paths keep reaching
/// the recovered-snapshot finalisation and the WAL flush helpers.
mixin _TripRecordingLifecycle
    on
        _$TripRecording,
        _TripRecordingCore,
        _TripRecordingSnapshot,
        _TripRecordingPersist {
  /// #2274 concern 2 — enter the transient "connecting" phase so the
  /// recording screen can be pushed IMMEDIATELY (mirroring the GPS-only
  /// path) and resolve the connect+prime in-place, instead of the
  /// trajets tab blocking on connect before navigating. Records the
  /// vehicle id + start time up-front so the recording screen's
  /// auto-pin / unpinned-warning logic resolves the right vehicle while
  /// the link is still warming.
  ///
  /// No-op when a trip is already active or another start is in
  /// progress — the caller falls through to its already-active branch.
  void enterConnecting({String? vehicleId}) {
    if (state.isActive || _startInProgress || state.isConnecting) return;
    _lastTripVehicleId = vehicleId ?? _tryReadActiveVehicle()?.id;
    _lastTripStartedAt = DateTime.now();
    state = const TripRecordingState(
      phase: TripRecordingPhase.connecting,
      connectStage: TripStartStage.connectingAdapter,
    );
  }

  /// #2274 concern 2 — advance the inline connect progress shown on the
  /// recording screen while [TripRecordingPhase.connecting]. No-op once
  /// the trip has gone active (the live metrics have taken over).
  void setConnectStage(TripStartStage stage) {
    if (state.phase != TripRecordingPhase.connecting) return;
    state = state.copyWith(connectStage: stage);
  }

  /// #2548 — enter / advance the transient (non-active)
  /// [TripRecordingPhase.saving] phase shown while a stopped trip is
  /// wrapped up. The stop-side mirror of [setConnectStage]: each
  /// pipeline's `stop()` calls it before its major teardown beats. The
  /// final state write at the end of `stop()` is unchanged.
  void setSaveStage(TripSaveStage stage) {
    state = state.copyWith(phase: TripRecordingPhase.saving, saveStage: stage);
  }

  /// #2274 concern 2 — abandon a connecting session (connect failed, or
  /// the user backed out before the link came up). Returns to idle so
  /// the trajets tab CTA reverts to "Start recording". No-op once the
  /// trip has gone active.
  void cancelConnecting() {
    if (state.phase != TripRecordingPhase.connecting) return;
    state = const TripRecordingState();
  }

  void pause() {
    if (!state.isActive) return;
    // #2227 — delegate the live pause to the active pipeline. The
    // GPS-only pipeline is a no-op (its position stream keeps running);
    // the OBD2 pipeline pauses the controller. Only flip the phase when a
    // live recording was actually paused.
    if (_pipeline?.pause() ?? false) {
      state = state.copyWith(phase: TripRecordingPhase.paused);
    }
  }

  void resume() {
    // #2227 — a live pipeline owns the controller. Mirror the original
    // ordering exactly: the phase guard is checked BEFORE the controller
    // is resumed, so resume() is a no-op while recording.
    final obd2 = _obd2;
    if (obd2 != null && obd2.controller != null) {
      if (state.phase != TripRecordingPhase.paused &&
          state.phase != TripRecordingPhase.pausedDueToDrop) {
        return;
      }
      obd2.resume();
      state = state.copyWith(phase: TripRecordingPhase.recording);
      return;
    }
    // #1347 — cold-start recovery left us with a snapshot but no
    // controller / pipeline. The pause banner's Resume button reaches us
    // here; without this path the tap is a silent no-op and the captured
    // samples are stranded in Hive forever. True "continue recording"
    // requires re-pairing the OBD2 adapter (out of scope — see the #1347
    // follow-up issue); the minimum correct behaviour is to finalise the
    // snapshot into trip history so the partial drive is preserved.
    if (_activeSnapshot != null &&
        state.phase == TripRecordingPhase.pausedDueToDrop) {
      unawaited(_finalizeRecoveredSnapshot());
    }
  }

  /// Stop the polling loop, refresh the odometer one last time,
  /// release the service, and return the accumulated [TripSummary].
  /// Safe to call when no trip is active — returns a default empty
  /// summary so callers don't have to null-check.
  ///
  /// [automatic] flags the saved [TripHistoryEntry] as auto-recorded
  /// (#1004 phase 2a). Defaults to `false` so existing manual call
  /// sites keep their behaviour unchanged. The hands-free
  /// [AutoTripCoordinator] calls [stopAndSaveAutomatic] (the typed
  /// wrapper below) so the launcher-icon badge increments only when
  /// the coordinator was the one that decided to save.
  Future<StoppedTripResult> stop({bool automatic = false}) async {
    // #2190 / #2227 — both modes run a [RecordingPipeline] now (OBD2 and
    // GPS-only). Delegate the full teardown — the OBD2 pipeline owns the
    // controller / service / subscriptions and drives the WAL clear
    // through the host; the GPS-only pipeline owns its Geolocator stream.
    final pipeline = _pipeline;
    if (pipeline != null) {
      final result = await pipeline.stop(automatic: automatic);
      _pipeline = null;
      return result;
    }
    // #1347 — cold-start recovery left us with a snapshot on disk but no
    // pipeline. The pause banner's End button reaches us here; without
    // this path the tap silently throws away the captured samples
    // (`StoppedTripResult.empty()` and a zero-state reset). Salvage the
    // snapshot into trip history so the user keeps their partial drive.
    if (_activeSnapshot != null &&
        state.phase == TripRecordingPhase.pausedDueToDrop) {
      return _finalizeRecoveredSnapshot();
    }
    state = const TripRecordingState();
    return const StoppedTripResult.empty();
  }

  /// Typed entry point for the hands-free [AutoTripCoordinator]
  /// (#1004 phase 2a). Forwards to [stop] with `automatic: true` so
  /// the saved [TripHistoryEntry] is tagged as auto-recorded and the
  /// launcher-icon badge increments. Kept as a thin wrapper so the
  /// coordinator binds to a stable, no-arg `Future<void>` seam — the
  /// internal stop signature can grow more flags later without
  /// breaking the coordinator's call site.
  Future<void> stopAndSaveAutomatic() async {
    await stop(automatic: true);
  }

  /// Return to idle — used after the caller consumes the
  /// [StoppedTripResult] (saves as fill-up or discards).
  ///
  /// Keeps [lastTripVehicleId] / [lastTripStartedAt] intact so the
  /// subsequent fill-up save path can still resolve the link-window
  /// (#888) after the user lands back on the fill-up screen.
  void reset() {
    state = const TripRecordingState();
    // #1303 — also drop any stale snapshot. `reset` runs when the
    // user discards a stopped trip from the summary screen; without
    // this call the recovery service would re-surface the discarded
    // trip on next cold start.
    unawaited(_clearActiveSnapshot());
  }

  /// Lifecycle hook entry point — called by the wiring layer's
  /// [WidgetsBindingObserver] when the host app transitions into
  /// the background. We force-flush so the latest sample buffer
  /// is on disk before the OS has a chance to kill us.
  ///
  /// No-op when no trip is active (the snapshot is null) so the
  /// hook is safe to fire on every backgrounding regardless of
  /// recording state.
  Future<void> onAppBackgrounded() async {
    if (!state.isActive) return;
    // #3438 — a GPS-only recording force-flushes its WAL too (previously
    // only the OBD2 snapshot below flushed; a kill lost the debounce
    // window). Concrete-type dispatch mirrors [debugAppendObd2SampleToGpsOnly].
    final pipeline = _pipeline;
    if (pipeline is GpsOnlyRecordingPipeline) pipeline.onAppBackgrounded();
    if (_obd2?.controller == null) return;
    await _flushActiveSnapshot(force: true);
  }
}
