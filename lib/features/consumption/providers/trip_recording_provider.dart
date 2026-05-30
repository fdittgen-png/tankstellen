// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/feedback/auto_record_badge_provider.dart';
import '../../../core/feedback/auto_record_badge_service.dart';
import '../../../core/storage/hive_boxes.dart';
import '../../../core/sync/trips_sync.dart';
import '../../../core/sync/trips_sync_enabled_provider.dart';
import '../../feature_management/application/feature_flags_provider.dart';
import '../../feature_management/domain/feature.dart';
import '../../vehicle/domain/entities/vehicle_profile.dart';
import '../../vehicle/providers/vehicle_providers.dart';
import '../data/obd2/active_trip_repository.dart';
import '../data/obd2/obd2_service.dart';
import '../data/obd2/trip_recording_controller.dart';
import '../data/trip_history_repository.dart';
import '../domain/entities/gps_sample_diagnostic.dart';
import '../domain/entities/trip_start_stage.dart';
import '../domain/services/physics_scale_calibrator.dart';
import '../domain/trip_recorder.dart';
import 'gps_only_recording_pipeline.dart';
import 'obd2_recording_pipeline.dart';
import 'recording_pipeline.dart';
import 'trip_baseline_recorder.dart';
import 'trip_gps_stream_controller.dart';
import 'trip_haptic_controller.dart';
import 'trip_oem_fuel_level_controller.dart';
import 'trip_history_provider.dart';
import 'trip_recording_phase.dart';
import 'trip_recording_state.dart';
import '../../../core/logging/error_logger.dart';

// Re-export the phase, state, and haptic-policy types so existing
// callers (widgets, screens, tests) that import this file keep
// resolving without touching every import site after the #563
// provider-split refactor. New callers should import the individual
// files directly.
export 'haptic_feedback_policy.dart'
    show HapticIntensity, hapticForBandTransition;
export 'trip_recording_phase.dart' show TripRecordingPhase;
export 'trip_recording_state.dart' show TripRecordingState;
// #1330 phase 3 — re-export TripDropReason so widgets watching
// `tripRecordingProvider.select((s) => s.dropReason)` resolve the
// type without a second import.
export '../data/obd2/trip_recording_controller.dart' show TripDropReason;
// #2190 — StoppedTripResult moved next to the RecordingPipeline strategy
// seam to avoid a circular import. Re-export it so the ~10 callers that
// import this provider keep resolving the type without a new import.
export 'recording_pipeline.dart' show StoppedTripResult;
// #2274 concern 2 — the connecting phase carries a TripStartStage on the
// state; re-export it so callers that drive the start flow through this
// provider resolve the stage type without a second import.
export '../domain/entities/trip_start_stage.dart' show TripStartStage;

part 'trip_recording_provider.g.dart';

/// App-wide owner of the trip recording (#726).
///
/// Hoisted out of [TripRecordingScreen]'s state so a trip survives
/// navigation — the user can start recording, switch to the Search
/// tab, tap a station, come back, and find the trip still running.
/// Lives for the app's lifetime (`keepAlive: true`) because dropping
/// it mid-drive would silently throw away the trip.
///
/// Owns the [Obd2Service] while a trip is active; the
/// [Obd2ConnectionService] hands ownership here on [start] and gets
/// it back on [stop].
@Riverpod(keepAlive: true)
class TripRecording extends _$TripRecording {
  // #1932 — re-entrancy guard for [start]. `state` is only marked
  // active by the last line of `start()`, but `start()` has `await`s
  // before that, so a second start racing in the window between would
  // pass the `state.isActive` guard and orphan a controller. This flag
  // is set synchronously at the top of `start()` — before any await —
  // so the second call is rejected.
  bool _startInProgress = false;

  // #2190 / #2227 — the selected recording strategy. Both modes now run
  // a [RecordingPipeline]: `start(service)` installs an
  // [Obd2RecordingPipeline], the dongle-less #2025 flow installs a
  // [GpsOnlyRecordingPipeline]. The historical `_pipeline == null`
  // inline-OBD2 branch is gone — every lifecycle boundary dispatches
  // through `_pipeline`. A future third source (CarPlay / Android Auto
  // telemetry) becomes another implementation rather than another
  // `_xMode` bool (open/closed — the #2190 motivation). Null only
  // between trips and in the cold-start-recovered state (#1347), where
  // the WAL snapshot — not a live pipeline — is the source of truth.
  RecordingPipeline? _pipeline;

  /// The active OBD2 pipeline, or null when no trip is running, a
  /// GPS-only trip is running, or we're in the recovered-no-controller
  /// state. The notifier's WAL snapshot helpers, `pause` / `resume`, and
  /// `debugController` reach the live [TripRecordingController] through
  /// it (#2227).
  Obd2RecordingPipeline? get _obd2 {
    final p = _pipeline;
    return p is Obd2RecordingPipeline ? p : null;
  }

  // #1458 phase 2 — most recent app lifecycle state observed by the
  // wiring layer's [WidgetsBindingObserver]. Read by the GPS stream
  // listener every time a position fix arrives so the resulting
  // [GpsSampleDiagnostic] carries an accurate "was the phone awake?"
  // tag. Defaults to `resumed` so the very first sample on a freshly
  // started recording (where no lifecycle event has fired yet) is
  // tagged optimistically — the user just tapped Start, the app is
  // certainly foreground.
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  /// #767 band-transition haptics, extracted into a focused
  /// collaborator (#1679). Constructed once and reused across
  /// recordings so the test counters accumulate exactly as the
  /// inlined fields did.
  final TripHapticController _haptics = TripHapticController();

  /// #1374 / #1125 / #1458 GPS concern — the opt-in Geolocator
  /// position stream, the per-fix cadence diagnostics, and the
  /// glide-coach evaluation hook — extracted into a focused
  /// collaborator (#1679). `late` so it can capture [ref] and the
  /// [_lifecycleState] getter.
  late final TripGpsStreamController _gps = TripGpsStreamController(
    ref: ref,
    lifecycleState: () => _lifecycleState,
  );

  /// #769 / #780 / #894 baseline-learning concern — the per-trip
  /// situation classifier, the learned-baseline store, and the
  /// classify → record → band → delta pipeline — extracted into a
  /// focused collaborator (#1679). `late` so it can capture [ref].
  late final TripBaselineRecorder _baselines = TripBaselineRecorder(ref);

  /// #1615 experimental OEM-PID exact-fuel-level concern — the slow
  /// poll that reads exact litres-in-tank via the OEM-PID registry and
  /// pushes them into the controller's fuel sampler. Inert unless the
  /// `experimentalOemPids` flag is on (the provider reads the flag and
  /// passes it to [TripOemFuelLevelController.start]) AND the connected
  /// adapter is OEM-PID-capable.
  final TripOemFuelLevelController _oemFuel = TripOemFuelLevelController();

  /// Tests count haptic fires via these instead of hooking the
  /// platform channel. The production path also still calls
  /// [HapticFeedback], so counting here doesn't short-circuit the
  /// real vibration on a device.
  @visibleForTesting
  int get hapticLightCount => _haptics.lightCount;
  @visibleForTesting
  int get hapticMediumCount => _haptics.mediumCount;

  /// Exposed for tests: the underlying [TripRecordingController] while
  /// a trip is active. Lets the #1040 sample-persistence test inject a
  /// deterministic buffer through [TripRecordingController.debugCaptureSample]
  /// without spinning up a real polling clock. Null between trips.
  @visibleForTesting
  TripRecordingController? get debugController => _obd2?.controller;

  /// Exposed for tests (#2190): true when an alternate GPS-only
  /// [RecordingPipeline] is the selected strategy (i.e. the trip was
  /// started via [startGpsOnly]), false for the inline OBD2 path or when
  /// no trip is running. Lets the strategy-selection test assert which
  /// pipeline the notifier picked without depending on the concrete type.
  @visibleForTesting
  bool get debugIsGpsOnlyActive => _pipeline?.isGpsOnly ?? false;

  /// Snapshot of the vehicle the last [startTrip] call was scoped to.
  /// Exposed so the save-as-fill-up path can figure out which
  /// trajets to auto-link (#888). Null before the first call, or
  /// after a [reset] / fresh [build].
  String? _lastTripVehicleId;
  DateTime? _lastTripStartedAt;

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

  /// Most recent vehicle id this provider kicked a trip for.
  ///
  /// Readable by the consumption providers so the fill-up auto-link
  /// can filter trajets to the vehicle that was actually driven —
  /// decoupling the trajets flow from the fill-up flow (#888).
  String? get lastTripVehicleId => _lastTripVehicleId;

  /// Timestamp captured on the most recent [startTrip] call. Used by
  /// the auto-link window in the fill-up flow as a "latest-known
  /// driving activity" lower bound when no prior fill-up exists.
  DateTime? get lastTripStartedAt => _lastTripStartedAt;

  @override
  TripRecordingState build() {
    return const TripRecordingState();
  }

  /// #2190 — read / publish the recording state on behalf of an alternate
  /// [RecordingPipeline]. The Riverpod `state` getter + setter are
  /// protected to the notifier instance, so the [RecordingPipelineHost]
  /// adapter routes its access through these methods rather than touching
  /// `state` from outside the class — mirroring the `_emitState()` seam the
  /// controller exposes to its [DroppedSessionHost] (#2188).
  TripRecordingState _stateForPipeline() => state;
  void _setStateFromPipeline(TripRecordingState value) {
    state = value;
  }

  /// Standalone entry point for starting a trajet (#888).
  ///
  /// Unlike [start] (which already expects a connected [Obd2Service]),
  /// this call resolves the vehicle + adapter from the active profile
  /// by default. Callers can override either by passing [vehicleId]
  /// or [adapterMac] explicitly.
  ///
  /// Returns:
  ///  - [StartTripOutcome.started] when [service] was supplied by
  ///    the caller — the provider takes ownership and kicks off the
  ///    recording immediately.
  ///  - [StartTripOutcome.needsPicker] when no [service] is supplied
  ///    and the resolved vehicle has no pinned adapter MAC. The UI
  ///    layer is expected to fire `showObd2AdapterPicker`, then call
  ///    back into [start] with the returned service.
  ///  - [StartTripOutcome.alreadyActive] when a trip is already
  ///    running — no double-start.
  ///
  /// Trajets are first-class: this method does NOT require a pending
  /// fill-up, does NOT block on one, and does NOT read any fill-up
  /// state. The fill-up save path (#888) derives the trip→tank link
  /// from the rolling trip-history log independently.
  ///
  /// [automatic] flags the controller so any [PausedTripEntry]
  /// written on a mid-trip BLE drop (#1004 phase 4-WAL) carries the
  /// auto-record provenance. Defaults to `false` so manual UI
  /// callers are unchanged; the orchestrator no-picker path
  /// (`AutoTripCoordinator`) passes `true`.
  Future<StartTripOutcome> startTrip({
    String? vehicleId,
    String? adapterMac,
    Obd2Service? service,
    bool automatic = false,
  }) async {
    if (state.isActive || _startInProgress) {
      return StartTripOutcome.alreadyActive;
    }
    final activeVehicle = _tryReadActiveVehicle();
    final resolvedVehicleId = vehicleId ?? activeVehicle?.id;
    final resolvedMac = adapterMac ?? activeVehicle?.obd2AdapterMac;
    _lastTripVehicleId = resolvedVehicleId;
    _lastTripStartedAt = DateTime.now();
    if (service != null) {
      // #1004 phase 2b-3 — orchestrator-driven no-picker start path.
      // The caller supplies the connected `Obd2Service` directly so
      // `automatic: true` flows through to the controller and the
      // resulting [PausedTripEntry] (if BLE drops mid-trip) carries
      // the auto-record provenance at WAL recovery time.
      await start(service, automatic: automatic);
      return StartTripOutcome.started;
    }
    if (resolvedMac == null || resolvedMac.isEmpty) {
      return StartTripOutcome.needsPicker;
    }
    // Pinned adapter but no service handed in — the UI picker is
    // still the right place to fire a connect: it reuses the exact
    // same scan + connect flow (with retry/error surfacing) and
    // short-circuits on the pinned MAC. Keeping the connect logic
    // at the UI layer avoids pulling a Bluetooth stack into provider
    // code and keeps #888's scope to the decoupling concern.
    return StartTripOutcome.needsPicker;
  }

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

  /// #2274 concern 2 — abandon a connecting session (connect failed, or
  /// the user backed out before the link came up). Returns to idle so
  /// the trajets tab CTA reverts to "Start recording". No-op once the
  /// trip has gone active.
  void cancelConnecting() {
    if (state.phase != TripRecordingPhase.connecting) return;
    state = const TripRecordingState();
  }

  /// Begin a recording session backed by [service]. The provider
  /// takes ownership of the service — don't disconnect it from the
  /// caller; [stop] handles the full teardown.
  ///
  /// [automatic] flags the controller so any [PausedTripEntry] it
  /// writes on a mid-trip BLE drop (#1004 phase 4-WAL) carries the
  /// auto-record provenance. Defaults to false so existing manual
  /// call sites are unchanged. The hands-free [AutoTripCoordinator]
  /// path passes `automatic: true`.
  Future<void> start(Obd2Service service, {bool automatic = false}) async {
    // #1932 — synchronous re-entrancy guard. Both the check and the
    // flag set run before `start()`'s first `await`, so a second start
    // racing into the window (e.g. the AutoTripCoordinator and a manual
    // UI start firing together) is rejected instead of orphaning a
    // second controller. Cleared in a `finally` so a throwing start
    // never locks recording out permanently.
    if (state.isActive || _startInProgress) return;
    _startInProgress = true;
    try {
      await _startInternal(service, automatic: automatic);
    } finally {
      _startInProgress = false;
    }
  }

  Future<void> _startInternal(
    Obd2Service service, {
    bool automatic = false,
  }) async {
    _lastTripStartedAt ??= DateTime.now();
    // #769 — record the vehicle id the trip is scoped to up-front so the
    // fill-up auto-link window resolves it even if the baseline load
    // races. Cheap Riverpod cache hit.
    _lastTripVehicleId ??= _tryReadActiveVehicle()?.id;
    // #2227 — the OBD2 recording loop lives in [Obd2RecordingPipeline].
    // The notifier selects it (mirroring the GPS-only selection in
    // [startGpsOnly]) and delegates the live loop + teardown; the WAL
    // snapshot (#1303) + cold-start recovery (#1347) stay here, driven
    // through the [RecordingPipelineHost]. The collaborators are passed
    // in (not reconstructed) so test counters accumulate as before.
    final pipeline = Obd2RecordingPipeline(
      ref: ref,
      host: _RecordingPipelineHostAdapter(this),
      haptics: _haptics,
      gps: _gps,
      baselines: _baselines,
      oemFuel: _oemFuel,
      readActiveVehicle: _tryReadActiveVehicle,
      readOemPidsFlag: _readOemPidsFlag,
    );
    _pipeline = pipeline;
    await pipeline.start(service, automatic: automatic);
  }

  /// Read the active vehicle profile, swallowing any provider-wiring
  /// errors that show up in widget tests (where the Riverpod graph
  /// for the vehicle-active-profile chain isn't always overridden).
  /// Returns null — both a cold-start no-vehicle and an
  /// unavailable-provider state — which the [Obd2RecordingPipeline]
  /// handles by letting `readFuelRateLPerHour` fall back to its
  /// generic defaults.
  VehicleProfile? _tryReadActiveVehicle() {
    try {
      return ref.read(activeVehicleProfileProvider);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording: active vehicle unavailable'}));
      return null;
    }
  }

  /// #1615 — read the `experimentalOemPids` feature flag, swallowing
  /// any provider-wiring error the same way [_tryReadActiveVehicle]
  /// does. Widget tests that start a recording without overriding the
  /// feature-flags Riverpod graph then simply see the flag as off,
  /// which is the safe default (the OEM poll never arms).
  bool _readOemPidsFlag() {
    try {
      return ref
          .read(featureFlagsProvider.notifier)
          .isEnabled(Feature.experimentalOemPids);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording: feature flags unavailable'}));
      return false;
    }
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
      automatic: false, // refined on every flush via _buildSnapshotFor
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
    );
    _lastSnapshotFlushAt = null;
    _samplesSinceLastFlush = 0;
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
    return base.copyWith(
      phase: phaseStr,
      summary: _summaryFromCtl(ctl),
      samples: ctl.capturedSamples,
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
      case TripRecordingControllerState.stopped:
        return 'stopped';
    }
  }

  /// Pull the recorder's running summary; lets the snapshot carry
  /// the latest distance / fuel / harsh counts without forcing the
  /// controller to expose more debug surface than [capturedSamples].
  TripSummary _summaryFromCtl(TripRecordingController ctl) {
    // capturedSamples is a List<TripSample>; the controller exposes
    // the running summary indirectly via stop()/buildSummary, but
    // there's no public mid-trip accessor. Rather than reach into
    // the controller's recorder we recompute distance + max RPM
    // from the captured buffer — it's already the post-debounce
    // 1 Hz feed and is plenty for the staleness / preview rendering
    // that recovery does. A perfect mid-trip summary (idle/harsh
    // counters) would require the controller to expose its own
    // recorder snapshot; we leave that for a future iteration if
    // recovery acquires a richer preview.
    final samples = ctl.capturedSamples;
    if (samples.isEmpty) {
      return const TripSummary(
        distanceKm: 0,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
      );
    }
    var distanceKm = 0.0;
    var maxRpm = 0.0;
    for (var i = 0; i < samples.length; i++) {
      final s = samples[i];
      if (s.rpm > maxRpm) maxRpm = s.rpm;
      if (i == 0) continue;
      final prev = samples[i - 1];
      final dtSec = s.timestamp
              .difference(prev.timestamp)
              .inMicroseconds /
          Duration.microsecondsPerSecond;
      if (dtSec <= 0) continue;
      final avgSpeed = (prev.speedKmh + s.speedKmh) / 2.0;
      distanceKm += avgSpeed * dtSec / 3600.0;
    }
    final startedAt = samples.first.timestamp;
    final endedAt = samples.last.timestamp;
    return TripSummary(
      distanceKm: distanceKm,
      maxRpm: maxRpm,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      startedAt: startedAt,
      endedAt: endedAt,
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
      await repo.saveSnapshot(next);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording flush snapshot failed'}));
    }
  }

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

    final result = StoppedTripResult(
      summary: snapshot.summary,
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
          summary: snapshot.summary,
          automatic: snapshot.automatic,
          samples: snapshot.samples,
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

  /// Lifecycle hook entry point — called by the wiring layer's
  /// [WidgetsBindingObserver] when the host app transitions into
  /// the background. We force-flush so the latest sample buffer
  /// is on disk before the OS has a chance to kill us.
  ///
  /// No-op when no trip is active (the snapshot is null) so the
  /// hook is safe to fire on every backgrounding regardless of
  /// recording state.
  Future<void> onAppBackgrounded() async {
    if (_obd2?.controller == null) return;
    if (!state.isActive) return;
    await _flushActiveSnapshot(force: true);
  }

  /// #1458 phase 2 — track every app-lifecycle transition so the GPS
  /// diagnostic recorder knows whether each fix arrived while the
  /// phone was foreground (`resumed`) or backgrounded (`paused` /
  /// `inactive` / `hidden`). Wired in from the same
  /// [WidgetsBindingObserver] that fires [onAppBackgrounded] so the
  /// two hooks stay in lock-step. Cheap (a single field write) so it's
  /// safe to fire on every transition regardless of recording state —
  /// reading [_lifecycleState] from the GPS stream listener is then a
  /// pure local read.
  void onAppLifecycleStateChanged(AppLifecycleState state) {
    _lifecycleState = state;
  }

  /// Exposed for tests — reads back the most recent lifecycle state
  /// pushed in via [onAppLifecycleStateChanged]. Lets a test verify
  /// that a diagnostic was tagged with the right state at the moment
  /// the GPS fix arrived without depending on platform-channel
  /// plumbing.
  @visibleForTesting
  AppLifecycleState get debugLifecycleState => _lifecycleState;

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

  /// Persist a finished trip into the rolling trip-history log (#726).
  /// Shared by both pipelines through the [RecordingPipelineHost]: the
  /// OBD2 pipeline passes the baseline vehicle id + the adapter identity
  /// it snapshotted at start (#1312); the GPS-only path leaves them null.
  Future<void> _saveToHistory(
    TripSummary summary, {
    bool automatic = false,
    List<TripSample> samples = const [],
    List<GpsSampleDiagnostic> gpsSampleDiagnostics = const [],
    String? vehicleId,
    String? adapterMac,
    String? adapterName,
    String? adapterFirmware,
  }) async {
    // Skip stub trips so they never clutter history (#1923). A trip is
    // a stub when the recorder never received a sample (`startedAt`
    // null — service disconnected immediately) OR it covered no
    // distance (a false-start: Stop tapped, or the adapter dropped,
    // before the car moved). The pre-#1923 guard required *both* —
    // `distanceKm < 0.01 && startedAt == null` — so a 20-second 0 km
    // false-start that did capture a few idle samples still landed in
    // history. A real trip always has both a `startedAt` and a
    // non-zero distance, so this never discards a genuine drive.
    if (summary.startedAt == null || summary.distanceKm < 0.01) return;
    try {
      final repo = ref.read(tripHistoryRepositoryProvider);
      if (repo == null) return;
      final id = summary.startedAt?.toIso8601String() ??
          DateTime.now().toIso8601String();
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

  // ---------------------------------------------------------------------------
  // #2025 / #2190 — GPS-only recording path. Lets users record a trajet
  // without an OBD2 dongle: samples come from Geolocator, the TripRecorder
  // accumulator runs the same harsh-event / distance / idle integration
  // it does for OBD2 trips, and the persisted summary carries
  // `kind: TripKind.gpsOnly` so downstream surfaces (confidence-tier
  // badge, recording-screen redesign) can adapt. The pipeline itself now
  // lives in [GpsOnlyRecordingPipeline], selected into `_pipeline` here
  // and driven through the [RecordingPipelineHost] seam below.
  // ---------------------------------------------------------------------------

  /// Start a GPS-only trajet recording (#2025). Skips the OBD2 service
  /// + adapter picker entirely; instead installs a [GpsOnlyRecordingPipeline]
  /// that opens a Geolocator stream and feeds a pure [TripRecorder] with
  /// synthetic samples (speed from `Position.speed`, all engine fields
  /// null, lat/lon/altitude/bearing from the fix).
  ///
  /// Returns:
  ///  - [StartTripOutcome.started] when the stream was opened. Caller
  ///    pushes the recording screen.
  ///  - [StartTripOutcome.alreadyActive] when a trip is already
  ///    running (OBD2 or GPS-only).
  Future<StartTripOutcome> startGpsOnly() async {
    if (state.isActive || _startInProgress) {
      return StartTripOutcome.alreadyActive;
    }
    _startInProgress = true;
    try {
      final pipeline = GpsOnlyRecordingPipeline(
        ref: ref,
        host: _RecordingPipelineHostAdapter(this),
      );
      _pipeline = pipeline;
      pipeline.start();
      return StartTripOutcome.started;
    } finally {
      _startInProgress = false;
    }
  }

  /// #2025 — mid-trip upgrade hook. Appends an externally-built
  /// [TripSample] (carrying OBD2 telemetry) to the in-progress
  /// GPS-only buffer + recorder so the final [TripSummary.kind] flips
  /// to `gpsPlusObd2` via [TripKind.fromSamples].
  ///
  /// No-op when no GPS-only trip is active. Future UX surface
  /// (banner: "OBD2 detected — attach to current trip?") drives
  /// this; until then the API lives here so the acceptance scenario
  /// is testable + the data layer supports it the moment any
  /// caller starts producing OBD2-flavoured samples.
  @visibleForTesting
  void debugAppendObd2SampleToGpsOnly(TripSample sample) {
    final pipeline = _pipeline;
    if (pipeline is! GpsOnlyRecordingPipeline) return;
    pipeline.appendObd2Sample(sample);
  }
}

/// Adapts the [TripRecording] notifier to the [Obd2RecordingPipelineHost]
/// seam its pipelines need (#2190 / #2227). Lives in the same library as
/// the notifier so it can reach the notifier's `state` setter, last-trip
/// identity fields, the active-vehicle read, the shared `_saveToHistory`
/// write, and the #1303 active-trip WAL snapshot helpers without widening
/// the notifier's public API — mirroring the `_DroppedSessionHostAdapter`
/// idiom on the controller (#2188). Implements the wider OBD2 host; a
/// [GpsOnlyRecordingPipeline] only reaches the narrower base subset.
class _RecordingPipelineHostAdapter implements Obd2RecordingPipelineHost {
  _RecordingPipelineHostAdapter(this._n);

  final TripRecording _n;

  @override
  TripRecordingState get state => _n._stateForPipeline();

  @override
  set state(TripRecordingState value) => _n._setStateFromPipeline(value);

  @override
  set lastTripVehicleId(String? value) => _n._lastTripVehicleId = value;

  @override
  set lastTripStartedAt(DateTime? value) => _n._lastTripStartedAt = value;

  @override
  String? readActiveVehicleId() => _n._tryReadActiveVehicle()?.id;

  @override
  Future<void> saveToHistory(
    TripSummary summary, {
    bool automatic = false,
    List<TripSample> samples = const [],
    List<GpsSampleDiagnostic> gpsSampleDiagnostics = const [],
    String? vehicleId,
    String? adapterMac,
    String? adapterName,
    String? adapterFirmware,
  }) =>
      _n._saveToHistory(
        summary,
        automatic: automatic,
        samples: samples,
        gpsSampleDiagnostics: gpsSampleDiagnostics,
        vehicleId: vehicleId,
        adapterMac: adapterMac,
        adapterName: adapterName,
        adapterFirmware: adapterFirmware,
      );

  // #2227 — WAL snapshot hooks driven by the OBD2 pipeline. The
  // GPS-only pipeline does not use these (its [RecordingPipelineHost]
  // calls keep to state + save), so they stay no-ops for it.
  @override
  void seedActiveSnapshot() => _n._seedActiveSnapshot();

  @override
  void maybeFlushActiveSnapshot() => _n._maybeFlushActiveSnapshot();

  @override
  Future<void> flushActiveSnapshot({bool force = false}) =>
      _n._flushActiveSnapshot(force: force);

  @override
  Future<void> clearActiveSnapshot() => _n._clearActiveSnapshot();
}

/// Outcome surfaced by [TripRecording.startTrip] so the UI layer can
/// decide whether to fire the adapter picker (#888).
enum StartTripOutcome {
  /// A service was supplied and the recording session started.
  started,

  /// No service was supplied and the resolved vehicle has no pinned
  /// adapter — the caller should open `showObd2AdapterPicker`, then
  /// hand the resulting service back into [TripRecording.start].
  needsPicker,

  /// A trip is already running; the call was a no-op.
  alreadyActive,
}
