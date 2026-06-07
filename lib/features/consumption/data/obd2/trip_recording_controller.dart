// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../vehicle/domain/entities/reference_vehicle.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../domain/driving_coaching.dart' show DrivingCoachingHint;
import '../../domain/entities/gps_sample_diagnostic.dart';
import '../../domain/services/gear_inference.dart';
import '../../domain/services/gps_live_estimate_folder.dart';
import '../../domain/services/trip_consumption_reliability.dart';
import '../../domain/trip_recorder.dart';
import '../trip_history_repository.dart';
import 'adapter_reconnect_scanner.dart';
import 'degraded_gps_emitter.dart';
import 'dropped_session_host.dart';
import 'dropped_session_manager.dart';
import 'elm327_protocol.dart';
import 'gps_only_sample_builder.dart';
import 'live_sample_snapshot.dart';
import 'obd2_breadcrumb_collector.dart';
import 'obd2_connection_errors.dart';
import 'obd2_debug_session.dart';
import 'obd2_service.dart';
import 'paused_trip_repository.dart';
import 'pid_scheduler.dart';
import 'trip_distance_resolver.dart';
import 'trip_drop_detector.dart';
import 'trip_live_reading.dart';
import 'trip_sample_buffer.dart';
import 'virtual_odometer.dart';

// Re-export the DTO + distance-source constants so existing callers
// (providers, widget tests) that import this file keep working after
// the #563 controller-split refactor. New callers should import the
// individual files directly.
export 'trip_distance_source.dart'
    show kDistanceSourceReal, kDistanceSourceVirtual, kDistanceSourceGps;
export 'trip_live_reading.dart' show TripLiveReading;
// #2188 — TripDropReason moved with the drop-RECOVERY state machine into
// DroppedSessionManager. Re-export it here so the providers / widgets /
// tests that import it from this file keep working unchanged.
export 'dropped_session_manager.dart' show TripDropReason;

/// Public recording state exposed by [TripRecordingController]
/// (#797 phase 1).
///
/// Distinguishes the two "not currently polling" reasons so the UI can
/// react differently:
///   - [paused]: user tapped the pause button or navigated away; the
///     polling loop is frozen but the Bluetooth link is still healthy.
///     Resume returns immediately.
///   - [pausedDueToDrop]: the scheduler observed repeated transport
///     errors (or a typed disconnect); the partial trip was persisted
///     to the `obd2_paused_trips` Hive box and a grace timer is
///     ticking. A subsequent [TripRecordingController.resume] must
///     succeed before the window elapses or the session will be
///     auto-finalised into history.
///
/// phase 1 intentionally exposes the state but does NOT wire a UI
/// banner — that lands in phase 2 alongside the auto-reconnect
/// scanner. Phase 1's job is to make the state observable so the
/// follow-up PR can react to it.
///
/// phase 3 (#797) wires an [AdapterReconnectScanner] into the
/// drop-recovery state machine: while the controller is in
/// [TripRecordingControllerState.pausedDueToDrop] the scanner
/// periodically probes for the pinned adapter's MAC. On a
/// reconnect the scanner fires [TripRecordingController.resume]
/// and the grace timer is cancelled before the window elapses.
enum TripRecordingControllerState {
  idle,
  recording,
  paused,
  pausedDueToDrop,

  /// #2565 — OBD2 dropped mid-trip but GPS is alive, so the trip keeps
  /// recording GPS-only samples instead of pausing. An ACTIVE sub-state
  /// (scanner probing to re-attach OBD2); resolves to [recording] on
  /// reconnect or escalates to [pausedDueToDrop] only if GPS also dies.
  degradedGpsOnly,
  stopped,
}

/// Drives the priority-tiered PID polling loop that feeds an
/// [Obd2Service]'s live PIDs into a [TripRecorder] (#726, #814).
///
/// Not a Riverpod notifier — kept as a plain class so the recording
/// screen owns the lifecycle (start on screen mount, stop on tap).
/// The screen subscribes to [live] for UI updates and calls [stop]
/// to finalise the trip.
///
/// ## #814 phase 2 — PidScheduler migration
///
/// Phase 1 (PR #860) shipped the standalone [PidScheduler]. Phase 2
/// wires it here: instead of one monolithic `Timer.periodic(1s)` that
/// reads every PID on every tick, we subscribe each PID at its own
/// target frequency and let the scheduler's weighted round-robin pick
/// the next command:
///
///   - **5 Hz (high priority):** RPM, speed, MAF/MAP, throttle, fuel-
///     rate PID 5E. These drive the eco-feedback band classifier and
///     the live L/100 km readout — users feel a 200 ms refresh.
///   - **1 Hz (medium):** STFT, LTFT, IAT, engine load. Needed for
///     the fuel-rate correction and the situation classifier, but
///     they don't change fast enough to warrant a 200 ms slot.
///   - **0.1 Hz (low):** fuel tank level. 10 s is plenty — the gauge
///     barely moves per tick.
///
/// VIN (Mode 09) is a one-shot read at [start] and is intentionally
/// NOT subscribed — it doesn't change mid-trip, and blasting the
/// adapter with a 0x0902 every 10 s wastes bandwidth the 5 Hz tier
/// needs.
///
/// Emissions are debounced. Every PID response updates an internal
/// snapshot; a secondary timer (running at [_pollInterval]) emits a
/// consolidated [TripLiveReading] off that snapshot. At 5 Hz on the
/// fast tier we would otherwise fire ten+ events per second — more
/// signal than the UI can consume and more state-change churn than
/// the situation/band classifier needs. The debounced approach keeps
/// the event rate bounded at whatever cadence the caller wants
/// (production: 250–500 ms; tests: 1 minute to pin the loop quiet).
///
/// ## #797 phase 1 — survive Bluetooth drops
///
/// Every scheduler-routed transport call is funnelled through
/// [_runTransport] which counts consecutive failures and classifies
/// them. Three consecutive errors within [_dropWindow], OR a typed
/// [Obd2DisconnectedException] / `StateError('Transport closed')`,
/// flip the controller into [TripRecordingControllerState.pausedDueToDrop]:
///   - the scheduler is stopped,
///   - the partial [TripSummary] (distance, fuel estimate so far,
///     harsh counters, odometer reads, VIN) is serialised to the
///     `obd2_paused_trips` Hive box,
///   - a grace timer starts for the configured pause-grace window; if
///     [resume] isn't called before it fires, the paused entry is
///     finalised into the normal trip history as if [stop] had run.
///
/// Phase 1 exposes the state machine without wiring a UI banner —
/// phase 2 brings the auto-reconnect scanner + snackbar UX.
class TripRecordingController {
  /// The OBD2 service the recording loop reads through. NOT `final`
  /// (#2524): an in-trip auto-reconnect builds a brand-new
  /// [Obd2Service] + transport, and [replaceService] swaps this pointer
  /// so [_runTransport] / [refreshOdometer] start polling the LIVE link
  /// instead of the dead old one. Before #2524 this was bound once at
  /// construction and never reassigned — the pipeline's `onConnected`
  /// swapped only its OWN pointer, so the scheduler kept dereferencing
  /// the original (closed) transport, every poll timed out at 2.5 s, a
  /// stranded `_pending` tripped the concurrent-sendCommand guard, and
  /// the rest of the drive recorded nothing.
  Obd2Service _service;
  final TripRecorder _recorder;
  final Duration _pollInterval;
  final DateTime Function() _now;

  /// Active [VehicleProfile] snapshot for the speed-density
  /// fuel-rate fallback (#810, #812 phase 3). Captured once at
  /// construction — the user's vehicle doesn't change mid-trip, and
  /// re-reading the profile every tick would just burn CPU. When
  /// null, `readFuelRateLPerHour` falls back to its generic 1.0 L /
  /// η_v 0.85 defaults — still honest, just less precise.
  final VehicleProfile? _vehicle;

  /// Reference catalog row matched to [_vehicle] at construction
  /// (#1422 phase 1). Drives the engine-tech-derived η_v default so a
  /// fresh Dacia dCi profile resolves 0.95 instead of the legacy 0.85
  /// catalog literal until VeLearner converges. Null when the active
  /// vehicle has no catalog match (custom EV, niche import, etc.) — the
  /// controller falls back to the stored profile value.
  final ReferenceVehicle? _referenceVehicle;

  /// Vehicle id tagged on paused snapshots + trip-history finalisations
  /// (#797 phase 1). The controller itself doesn't know about the
  /// Riverpod-backed active vehicle profile; the provider passes it
  /// through at construction so the paused-trips box row carries it.
  final String? _vehicleId;

  /// Whether this recording was kicked off by the hands-free
  /// [AutoTripCoordinator] (#1004 phase 4-WAL). Plumbed through to the
  /// persisted [PausedTripEntry] so the launch-time recovery service
  /// can decide whether to bump the launcher-icon badge when it
  /// finalises a stale entry — manual trips never counted toward
  /// "unseen" and must not retroactively start counting just because
  /// the app was killed before the disconnect-save timer fired.
  final bool _automatic;

  /// Per-trip 'diagnostic capture' flag (#2459 — default off; an
  /// internal/dev flag, not a user setting, wired from
  /// `Feature.debugMode`). When ON, `_emit` ALSO stamps the raw mixture
  /// inputs (MAF / MAP / STFT / LTFT) onto each persisted [TripSample]
  /// at a SLOW cadence (every [_diagnosticCaptureInterval], carried
  /// forward in between) so a trip's fuel rate can be re-derived
  /// post-hoc. Default OFF ⇒ those four keys are never written ⇒ zero
  /// storage growth for the overwhelming majority of trips.
  final bool _diagnosticCapture;

  /// Minimum wall-clock spacing between diagnostic-capture raw-input
  /// stamps (#2459). The fuel-derivation signals drift slowly, so a
  /// ~1 Hz sample is ample for post-hoc re-derivation and keeps the
  /// extra payload roughly 1/4 the per-tick emit cadence. Timestamp of
  /// the last stamp is tracked in [_lastDiagnosticCaptureAt].
  static const Duration _diagnosticCaptureInterval = Duration(seconds: 1);
  DateTime? _lastDiagnosticCaptureAt;

  /// Optional override — tests inject a hand-built scheduler (usually
  /// with a tiny [PidScheduler.tickRate] + a fake transport) to
  /// exercise the scheduler ↔ controller wiring without touching the
  /// real [Obd2Service] chain. Production always passes null and
  /// [start] constructs a scheduler against [service.sendCommand].
  ///
  /// Note: an override bypasses the drop-detection transport wrapper
  /// (#797 phase 1) because the caller pre-wired the transport. Tests
  /// that want to exercise the drop heuristic should use
  /// [schedulerTickRate] instead, which still routes through
  /// [_runTransport].
  final PidScheduler? _schedulerOverride;

  /// Tick rate for the default-constructed scheduler (#797 phase 1).
  /// Lets tests drive the round-robin faster than the 100 ms
  /// production default without having to construct their own
  /// [PidScheduler] — which would bypass the drop-detection wrapper
  /// in [_runTransport].
  final Duration _schedulerTickRate;

  /// Owns the connection-drop *detection* heuristics — the #797
  /// transport-error sliding window and the #1330 silent-failure
  /// null-parse counter — extracted into a focused collaborator
  /// (#1679). The controller keeps only the lifecycle guard
  /// ([_registerTransportError] / [_observeHighPriorityParse]); the
  /// drop *reaction* (grace timer, reconnect scanner, paused/history
  /// persistence) lives in [_droppedSession] (#2188). Built in the
  /// constructor body so it can capture the resolved [_now] clock.
  late final TripDropDetector _dropDetector;

  /// Owns the connection-drop RECOVERY lifecycle — the #1904 silent-
  /// reconnect window, the visible-drop escalation, the #797 grace
  /// timer + auto-finalise, the reconnect-scanner orchestration and the
  /// paused/history Hive persistence — extracted into a focused
  /// collaborator (#2188). The controller keeps the emit loop, the
  /// scheduler, the drop detector, and the trip-identity fields; the
  /// manager reaches those through a [DroppedSessionHost] adapter. Built
  /// in the constructor body so it can capture the resolved [_now]
  /// clock + the host seam.
  late final DroppedSessionManager _droppedSession;

  final StreamController<TripLiveReading> _liveController =
      StreamController<TripLiveReading>.broadcast();

  final StreamController<TripRecordingControllerState> _stateController =
      StreamController<TripRecordingControllerState>.broadcast();

  PidScheduler? _scheduler;
  Timer? _emitTimer;
  DateTime? _startedAt;
  DateTime? _lastSampleAt;

  // #2509 — timestamps of the FIRST and LATEST valid GPS fixes that
  // arrived while the OBD2 link delivered no speed/RPM (so
  // `_recorder.onSample` — the sole setter of the recorder's
  // `startedAt` / `endedAt` — never fired). A dead dongle leaves
  // `_recorder.buildSummary().startedAt`/`endedAt` null even on a real
  // GPS-tracked drive; [_finaliseSummary] falls back to these so the trip
  // carries a start/end time and clears the persist guard instead of
  // being silently discarded. Both stay null on a healthy OBD2 trip (the
  // recorder owns the timestamps then) and on a trip that never saw a GPS
  // fix.
  DateTime? _gpsStartedAt;
  DateTime? _gpsEndedAt;
  double? _odometerStartKm;
  double? _odometerLatestKm;
  double _fuelLitersSoFar = 0;
  bool _fuelRateSeen = false;

  // #1858 — η_v recompute provenance, accumulated per emit tick.
  // [_veWeightedFuelSum] is Σ(η_v_i × fuelRate_i) and
  // [_veDerivedFuelRateSum] is Σ(fuelRate_i), both over speed-density
  // ticks only; [_sawNonVeDerivedFuel] flips true the moment any fuel
  // is integrated from PID 5E or the MAF branch (neither uses η_v).
  // At trip end these collapse into [TripSummary.volumetricEfficiencyUsed].
  // A fresh controller is built per trip, so declaration-time zero is
  // the only reset needed (the values carry correctly across
  // pause/resume — that is all one trip).
  double _veWeightedFuelSum = 0;
  double _veDerivedFuelRateSum = 0;
  bool _sawNonVeDerivedFuel = false;
  bool _paused = false;
  bool _pausedDueToDrop = false;

  /// #2565 — OBD2 dropped mid-trip but GPS is alive: keep recording
  /// GPS-only instead of pausing. Set by the [DroppedSessionManager]
  /// degrade branch; cleared on reconnect or escalated to
  /// [_pausedDueToDrop] when GPS also dies.
  bool _degradedGpsOnly = false;
  bool _started = false;
  bool _stopped = false;
  String? _sessionId; // ISO start-ts, stable across pause→resume cycles

  /// Why the controller flipped into
  /// [TripRecordingControllerState.pausedDueToDrop] (#1330 phase 3).
  /// Null when the controller is not in that state. Delegates to the
  /// drop-recovery state machine (#2188).
  TripDropReason? get dropReason => _droppedSession.dropReason;

  /// #2767 — true while the reconnect scanner has given up active scanning and
  /// is passive-waiting; surfaced into the UI for the calmer banner copy.
  bool get reconnectPassiveWaiting => _droppedSession.reconnectPassiveWaiting;

  /// Owns the trip's distance-resolution concern — the three-tier
  /// odometer-delta / GPS-track / virtual-odometer selection and the two
  /// rolling sample buffers it integrates over — extracted into a focused
  /// pure-Dart collaborator (#2187). The controller keeps the odometer
  /// readings ([_odometerStartKm] / [_odometerLatestKm]) and passes them
  /// into the resolver per read. Built in the constructor body so it can
  /// capture the resolved [_now] clock.
  late final TripDistanceResolver _distance;

  /// #2506 — shared GPS-physics estimate + coaching folder, injected by
  /// `Obd2RecordingPipeline` so the OBD2 live path mirrors the GPS-only
  /// pipeline through ONE implementation (the anti-divergence seam). Null
  /// in harnesses that don't wire it → the live estimate fields stay null.
  final GpsLiveEstimateFolder? _gpsEstimateFolder;

  /// #2506 — latest GPS ground-speed (km/h) latched via [updateGpsFix];
  /// the live speed-read-out fallback when the OBD2 speed PID (0x0D) is
  /// momentarily absent. OBD2 speed always wins when present.
  double? _latestGpsSpeedKmh;

  /// #2963 — last OBD2 speed persisted onto a [TripSample]; lets a later
  /// RPM-only tick hold-last instead of crashing to `0`. Null until the
  /// first real speed lands. See [_emit].
  double? _lastPersistedSpeedKmh;

  /// #2506 — latest GPS coaching hint from the shared folder on a
  /// no-fuel-PID tick. `Obd2RecordingPipeline` publishes it onto
  /// `state.gpsCoachingHint`, which `MinimalDriveSummary` already renders.
  DrivingCoachingHint? get latestGpsCoachingHint => _latestGpsCoachingHint;
  DrivingCoachingHint? _latestGpsCoachingHint;

  /// Owns the #1040 captured-sample buffer and the #1458 GPS
  /// cadence-diagnostics buffer — both per-trip ring buffers
  /// extracted into a focused collaborator (#1679).
  final TripSampleBuffer _sampleBuffer = TripSampleBuffer();

  /// Read-only snapshot of the captured sample buffer (#1040). The
  /// list is unmodifiable so callers can't accidentally mutate the
  /// controller's state — the provider clones it into the persisted
  /// [TripHistoryEntry] at stop time.
  List<TripSample> get capturedSamples => _sampleBuffer.capturedSamples;

  /// Read-only snapshot of the GPS cadence diagnostics buffer
  /// (#1458 phase 2). The list is unmodifiable so callers can't
  /// accidentally mutate the controller's state — the provider clones
  /// it into the persisted [TripHistoryEntry] at stop time.
  List<GpsSampleDiagnostic> get capturedGpsSampleDiagnostics =>
      _sampleBuffer.capturedGpsSampleDiagnostics;

  /// VIN read once at [start]. Null on older ECUs / adapters that
  /// can't answer Mode 09 PID 02.
  String? _vin;

  /// The "clock"-side snapshot — the per-PID latest-value scratch
  /// space, the scheduler subscription wiring, and the tier-1/2/3
  /// fuel-rate derivation — extracted into a focused collaborator
  /// (#1679). The emit timer + [_emit] stay on the controller; this
  /// collaborator owns the values that [_emit] reads. Built in the
  /// constructor body so it can capture the [_observeHighPriorityParse]
  /// and [_recordSpeedSample] tear-offs.
  late final LiveSampleSnapshot _liveSampleSnapshot;

  /// #2565 — owns one emit tick of the GPS-only degraded phase (OBD2
  /// dropped but GPS alive). Extracted so the controller stays near its
  /// grandfathered file-length snapshot.
  late final DegradedGpsEmitter _degradedEmitter;

  /// Maximum Δt (seconds) between samples that the distance / fuel
  /// integrators bridge (#1927). A longer gap is a connection dropout
  /// or pause — integrating across it fabricates distance and fuel, so
  /// `TripRecorder` and `VirtualOdometer` skip it. 15 s is far above
  /// the ~250 ms poll cadence and the 6 s silent-reconnect window.
  static const double _integrationGapCapSeconds = 15.0;

  /// #2565 — how recent a real GPS fix must be for an OBD2 drop to
  /// degrade to GPS-only recording (and the window past which a degraded
  /// trip whose GPS also died escalates to "paused"). Pinned to the same
  /// 15 s Δt the integrators refuse to bridge (`_integrationGapCapSeconds`).
  static const Duration _gpsAliveWindow = Duration(seconds: 15);

  TripRecordingController({
    required Obd2Service service,
    TripRecorder? recorder,
    Duration pollInterval = const Duration(milliseconds: 250),
    DateTime Function()? now,
    VehicleProfile? vehicle,
    ReferenceVehicle? referenceVehicle,
    String? vehicleId,
    PidScheduler? scheduler,
    PausedTripRepository? pausedRepo,
    TripHistoryRepository? historyRepo,
    Duration pauseGraceWindow = const Duration(minutes: 15),
    Duration silentReconnectWindow = const Duration(seconds: 6),
    Duration dropWindow = const Duration(seconds: 5),
    int dropThreshold = 3,
    int silentFailureThreshold = 50,
    Duration schedulerTickRate = const Duration(milliseconds: 100),
    String? pinnedAdapterMac,
    bool automatic = false,
    bool diagnosticCapture = false,
    AdapterReconnectScanner? Function(
      String pinnedMac,
      VoidCallback onReconnect,
    )? reconnectScannerFactory,
    Obd2BreadcrumbRecorder? breadcrumbCollector,
    GpsLiveEstimateFolder? gpsEstimateFolder,
    void Function(HarshEvent event)? onHarshEvent,
  })  : _service = service,
        _diagnosticCapture = diagnosticCapture,
        _gpsEstimateFolder = gpsEstimateFolder,
        _recorder = recorder ??
            TripRecorder(
              maxIntegrationGapSeconds: _integrationGapCapSeconds,
              onHarshEvent: onHarshEvent,
            ),
        _pollInterval = pollInterval,
        _now = now ?? DateTime.now,
        _vehicle = vehicle,
        _referenceVehicle = referenceVehicle,
        _vehicleId = vehicleId,
        _schedulerOverride = scheduler,
        _schedulerTickRate = schedulerTickRate,
        _automatic = automatic,
        _breadcrumbCollector = breadcrumbCollector {
    _dropDetector = TripDropDetector(
      now: _now,
      dropWindow: dropWindow,
      dropThreshold: dropThreshold,
      silentFailureThreshold: silentFailureThreshold,
    );
    _droppedSession = DroppedSessionManager(
      host: _DroppedSessionHostAdapter(this),
      now: _now,
      pauseGraceWindow: pauseGraceWindow,
      silentReconnectWindow: silentReconnectWindow,
      pinnedAdapterMac: pinnedAdapterMac,
      reconnectScannerFactory: reconnectScannerFactory,
      pausedRepo: pausedRepo,
      historyRepo: historyRepo,
    );
    _distance = TripDistanceResolver(
      maxIntegrationGapSeconds: _integrationGapCapSeconds,
      now: _now,
    );
    _liveSampleSnapshot = LiveSampleSnapshot(
      service: _service,
      vehicle: _vehicle,
      referenceVehicle: _referenceVehicle,
      breadcrumbCollector: _breadcrumbCollector,
      onHighPriorityParse: _observeHighPriorityParse,
      onSpeedSample: _recordSpeedSample,
    );
    _degradedEmitter = DegradedGpsEmitter(
      now: _now,
      recorder: _recorder,
      sampleBuffer: _sampleBuffer,
      gpsAliveWindow: _gpsAliveWindow,
      onEscalate: _droppedSession.escalateDegradedToPaused,
      onSampleAt: (at) => _lastSampleAt = at,
      overlayEstimate: (reading,
              {required nowTs, required effectiveSpeedKmh, required altitudeM}) =>
          _overlayGpsEstimate(
        reading,
        nowTs: nowTs,
        fuelRate: null,
        effectiveSpeedKmh: effectiveSpeedKmh,
        rpm: null,
        altitudeM: altitudeM,
      ),
    );
  }

  /// Optional fuel-rate diagnostic breadcrumb sink (#1395). Wired in
  /// by [tripRecordingProvider] when a recording starts so the
  /// controller can record the resolved branch + AFR/density/
  /// displacement/VE actually used by [_deriveFuelRateLPerHour] each
  /// emit, plus surface the running suspicion-rate at trip-end via
  /// [TripSummary.fuelRateSuspect]. Typed as the [Obd2BreadcrumbRecorder]
  /// interface so production passes the Riverpod notifier
  /// (state-republishing) and unit tests pass a raw
  /// [Obd2BreadcrumbCollector].
  final Obd2BreadcrumbRecorder? _breadcrumbCollector;

  /// Live metrics stream — subscribe to update the recording UI.
  Stream<TripLiveReading> get live => _liveController.stream;

  /// State-transition stream (#797 phase 1). Emits the new state on
  /// every controller-driven transition (start → recording, pause →
  /// paused, drop → pausedDueToDrop, resume → recording, grace →
  /// stopped, manual stop → stopped). Phase 2 binds this to the UI
  /// reaction; phase 1 just needs it observable.
  Stream<TripRecordingControllerState> get stateChanges =>
      _stateController.stream;

  /// Current logical state. Mirrors [stateChanges] for callers that
  /// want a pull-style read (widget tests, initial value).
  TripRecordingControllerState get currentState {
    // Check stopped first: an auto-finalised drop sets both
    // `_stopped = true` AND `_started = false`, so the order matters.
    if (_stopped) return TripRecordingControllerState.stopped;
    if (!_started) return TripRecordingControllerState.idle;
    if (_pausedDueToDrop) return TripRecordingControllerState.pausedDueToDrop;
    if (_paused) return TripRecordingControllerState.paused;
    // #2565 — degraded GPS-only: checked after the true-pause states but
    // is still an ACTIVE, recording state.
    if (_degradedGpsOnly) return TripRecordingControllerState.degradedGpsOnly;
    return TripRecordingControllerState.recording;
  }

  bool get isRecording =>
      (_started && !_paused && !_pausedDueToDrop) || _degradedGpsOnly;
  bool get isPaused => _paused || _pausedDueToDrop;
  bool get isPausedDueToDrop => _pausedDueToDrop;
  bool get isActive => _started;

  /// Pause the polling loop without tearing down the recorder. The
  /// scheduler is stopped (no wasted Bluetooth chatter while the user
  /// is looking at another screen) but the emit timer keeps ticking so
  /// a frozen `TripLiveReading` still flushes if UI subscribed late.
  /// [resume] restarts the scheduler. Safe to call when not recording
  /// — no-op.
  void pause() {
    if (!_started) return;
    if (_paused || _pausedDueToDrop) return;
    _paused = true;
    _scheduler?.stop();
    _emitState();
  }

  /// Resume a paused recording. Works from both user-pause and
  /// drop-pause states. Idempotent; no-op if not paused.
  void resume() {
    if (!_paused && !_pausedDueToDrop) return;
    if (_pausedDueToDrop) {
      // Cancel the grace timer + clear the drop-reaction reason.
      _droppedSession.cancelGrace();
      _pausedDueToDrop = false;
      // #1330 phase 3 — clear the silent-failure latch so a
      // post-resume stretch of nulls can fire again. Without this,
      // a user who resumes after a silent-failure drop and then hits
      // a fresh silent failure would never get a second snackbar.
      _dropDetector.reset();
      // Also tear down the auto-reconnect scanner (#797 phase 3) —
      // either we got here because the scanner fired its callback
      // (in which case it already stopped itself), or the user
      // tapped "Resume" manually on the pause banner before the
      // scanner reconnected. Either way, no scanner should survive
      // the resume transition.
      unawaited(_droppedSession.stopReconnectScanner());
      _droppedSession.clearPausedTripRow();
      // #2671 — a drop-pause gated the scheduler's dispatch (pauseScheduler);
      // the link is back, so re-open it + reset the per-PID failure streaks
      // before the timer resumes ticking.
      _scheduler?.resume();
    }
    _paused = false;
    _scheduler?.start();
    _emitState();
  }

  /// Swap the recording loop onto a freshly-reconnected [Obd2Service]
  /// (#2524).
  ///
  /// An in-trip auto-reconnect ([ReconnectConnector]) builds a BRAND-NEW
  /// service + transport for the recovered link. [_runTransport] and
  /// [refreshOdometer] dereference [_service] at call time, so until this
  /// runs the scheduler keeps polling the DEAD old transport — every read
  /// times out and the rest of the drive records nothing. Pointing
  /// [_service] at the live service fixes that for every subsequent poll.
  ///
  /// The OLD service is torn down ([Obd2Service.disconnect]) so its
  /// channel closes and any command stranded in its transport's `_pending`
  /// is failed cleanly via the transport's `_failPending` — otherwise the
  /// abandoned half-dead instance leaks its subscription and a stranded
  /// pending could later trip the concurrent-sendCommand guard. A no-op
  /// when [service] is already the current one (idempotent / defensive).
  /// Best-effort: a disconnect failure on the already-dead old link must
  /// never derail the just-recovered recording, so it is swallowed to a
  /// breadcrumb.
  void replaceService(Obd2Service service) {
    final old = _service;
    if (identical(old, service)) return;
    _service = service;
    // #2907 — the reconnected link is healthy: clear the drop detector's
    // error window (incl. any dead-transport short-circuits the [_runTransport]
    // gate logged against the OLD service) so the first poll on the new live
    // transport starts clean instead of re-tripping a drop. The scanner resume
    // path also resets it, but doing it AT the swap makes recovery robust to
    // swap-vs-resume call ordering.
    _dropDetector.reset();
    // Tear down the abandoned link off the hot path. `disconnect()` is
    // idempotent and never throws for the typed-closed states, but guard
    // anyway — the old transport is already dead, so any error here is
    // expected and must not reach the user error log.
    unawaited(() async {
      try {
        await old.disconnect();
      } catch (e, st) {
        debugPrint('TripRecordingController.replaceService: '
            'old service disconnect failed (already dead) — $e\n$st');
      }
    }());
  }

  /// Push the most recent GPS fix into the per-tick snapshot
  /// (#1374 phase 1).
  ///
  /// Called by the trip-recording provider when the
  /// `Feature.gpsTripPath` flag is enabled and a Geolocator position
  /// stream has produced an update. The next [_emit] tick stamps the
  /// stored values onto the [TripSample] it builds. Pass `null` for
  /// either coord to clear the latch — the sample is then written
  /// with that field omitted (legacy-compatible behaviour).
  ///
  /// Intentionally takes raw doubles instead of a `Position` so this
  /// file stays free of `package:geolocator` imports — the GPS plugin
  /// only lives at the provider seam, which keeps unit-testing the
  /// controller cheap (no Geolocator mocks required) and lets the
  /// flag-off path skip the plugin entirely.
  void updateGpsFix({
    double? latitude,
    double? longitude,
    double? altitudeM,
    double? hAccuracyM,
    double? bearingDeg,
    double? speedKmh,
  }) {
    _liveSampleSnapshot.updateGpsFix(
      latitude: latitude,
      longitude: longitude,
      altitudeM: altitudeM,
      // #2648 — forward GPS horizontal accuracy + bearing so the next
      // emit stamps them onto the TripSample. The OBD2 / degraded paths
      // used to drop these (the `Position` carried them but they were
      // never threaded through), so they reached only 0.3 % of samples.
      hAccuracyM: hAccuracyM,
      bearingDeg: bearingDeg,
    );
    // #2506 — latch the GPS ground-speed for the live speed fallback. A
    // null / non-finite / negative speed (cold GPS warm-up) is ignored so
    // the latch never regresses to a bogus value. Stored on the controller
    // (not the off-limits live snapshot) so the OBD2 speed PID 0x0D, when
    // present, always wins in [_emit]; this only fills the gap.
    if (speedKmh != null && speedKmh.isFinite && speedKmh >= 0) {
      _latestGpsSpeedKmh = speedKmh;
    }
    // #1979 — buffer every real fix for the GPS-distance source. A
    // null-coord call only clears the per-tick latch; it is not a fix.
    if (latitude != null && longitude != null) {
      // #2509 — latch the first GPS-fix timestamp as a start-time
      // fallback. On a dead OBD2 link no speed/RPM sample ever reaches
      // the recorder, so `_recorder` never stamps `startedAt`; without
      // this the finalised summary's `startedAt` is null and the
      // persist guard discards a real GPS-tracked drive. Only the FIRST
      // fix wins so the start time is the start of the drive, not the
      // latest fix. A healthy OBD2 trip ignores this value (the recorder
      // owns `startedAt`); it is consulted only as a fallback in
      // [_finaliseSummary].
      final fixAt = _now();
      // #2963 — forward the fix's accuracy + timestamp so the haversine
      // distance source can reject a parked car's GPS jitter (accuracy gate)
      // and a cold-start position jump (teleport gate). Dropped here before,
      // so a 22 s idle scatter at σ≈25 m accumulated ~0.93 phantom km.
      _distance.addGpsFix(
        latitude,
        longitude,
        hAccuracyM: hAccuracyM,
        at: fixAt,
      );
      _gpsStartedAt ??= fixAt;
      _gpsEndedAt = fixAt;
    }
  }

  /// #1615 — push the most recent exact-litre OEM-PID fuel reading into
  /// the live snapshot. The next [_emit] tick reads it back onto
  /// [TripLiveReading.fuelLevelLitres]. Pass `null` to clear the latch.
  ///
  /// Like [updateGpsFix], this is the provider seam: the OEM read (a
  /// multi-command async sequence against `OemPidRegistry`) lives in
  /// `TripOemFuelLevelController` at the provider layer, so this file
  /// stays free of feature-flag and registry imports and the flag-off
  /// path never constructs an OEM read.
  void updateOemFuelLevelLitres(double? litres) {
    _liveSampleSnapshot.updateOemFuelLevelLitres(litres);
  }

  /// #1458 phase 2 — append one cadence-diagnostic record at [now]
  /// with the given app [lifecycleState]. The provider calls this from
  /// its position-stream listener immediately AFTER [updateGpsFix] so
  /// the two streams stay aligned: the user-facing
  /// [TripSample.latitude]/[TripSample.longitude] capture path is
  /// unchanged, and the diagnostic is a strictly additive observation
  /// of "did this fix arrive while the app was foreground or paused".
  ///
  /// The index assigned to the diagnostic is the buffer's length at
  /// insertion time so it is monotonic per trip and stable across
  /// process restarts (a forgotten recording that bumps into
  /// [_gpsSampleDiagnosticCap] drops the OLDEST samples first — the
  /// `index` field surfaces those gaps).
  void recordGpsSampleDiagnostic({
    required DateTime now,
    required String lifecycleState,
  }) {
    _sampleBuffer.recordGpsSampleDiagnostic(
      now: now,
      lifecycleState: lifecycleState,
    );
  }

  /// Exposed for tests: append a cadence diagnostic without going
  /// through [recordGpsSampleDiagnostic]. Lets the provider tests
  /// pre-seed a controller's buffer + drive [stop] end-to-end without
  /// needing a real Geolocator stream.
  @visibleForTesting
  void debugCaptureGpsSampleDiagnostic(GpsSampleDiagnostic diagnostic) {
    _sampleBuffer.debugCaptureGpsSampleDiagnostic(diagnostic);
  }

  /// Read-only snapshot of the most recent GPS latitude pushed in via
  /// [updateGpsFix] (#1374 phase 1). Exposed for tests + diagnostics;
  /// production reads the value through the persisted [TripSample]
  /// fields, not this getter.
  @visibleForTesting
  double? get debugLatestLatitude => _liveSampleSnapshot.latestLatitude;

  /// Read-only snapshot of the most recent GPS longitude pushed in via
  /// [updateGpsFix] (#1374 phase 1). Same caveats as
  /// [debugLatestLatitude].
  @visibleForTesting
  double? get debugLatestLongitude => _liveSampleSnapshot.latestLongitude;

  /// Read-only snapshot of the most recent GPS altitude (metres) pushed
  /// in via [updateGpsFix] (#1935 child A). Same caveats as
  /// [debugLatestLatitude].
  @visibleForTesting
  double? get debugLatestAltitudeM => _liveSampleSnapshot.latestAltitudeM;

  /// Read-only snapshots of the most recent GPS horizontal accuracy
  /// (metres) + bearing (compass degrees) pushed in via [updateGpsFix]
  /// (#2648). Same caveats as [debugLatestLatitude].
  @visibleForTesting
  double? get debugLatestHAccuracyM => _liveSampleSnapshot.latestHAccuracyM;
  @visibleForTesting
  double? get debugLatestBearingDeg => _liveSampleSnapshot.latestBearingDeg;

  /// Start polling. Reads the odometer and VIN ONCE to pin trip
  /// identity; subsequent ticks are scheduled per-PID by
  /// [PidScheduler]. Safe to call multiple times — no-op when already
  /// recording.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _stopped = false;
    _startedAt = _now();
    _sessionId = _startedAt!.toIso8601String();
    _odometerStartKm = await _service.readOdometerKm();
    _odometerLatestKm = _odometerStartKm;

    // One-shot VIN read (#814). VIN is Mode 09 PID 02 — it never
    // changes mid-trip, so subscribing it to the 0.1 Hz tier would
    // just waste one Bluetooth round-trip per 10 s on a value we
    // already have. Best-effort: a car that can't answer 0902 simply
    // leaves [_vin] null.
    _vin = await _readVinOnce();

    _scheduler = _schedulerOverride ?? _buildScheduler();
    _liveSampleSnapshot.subscribeAllTiers(_scheduler!);
    _scheduler!.start();

    _emitTimer = Timer.periodic(_pollInterval, (_) => _emit());
    _emitState();
  }

  /// Stop the polling loop and return the accumulated summary.
  /// Idempotent — calling twice returns the same summary.
  ///
  /// The returned [TripSummary] carries the final [currentDistanceKm]
  /// (#800) — which prefers the real odometer delta over the recorder's
  /// integrated-speed number — and a [TripSummary.distanceSource] flag
  /// distinguishing the two. This lets the fill-up flow and analytics
  /// decide whether the km figure is ground truth or an estimate.
  Future<TripSummary> stop() async {
    // #1925 — finalise the opt-in OBD2 debug session so its summary
    // (duration, reconnects, data gaps) is complete for export.
    Obd2DebugSessionRecorder.endSession();
    _scheduler?.stop();
    _emitTimer?.cancel();
    _emitTimer = null;
    // #1904 / #2188 — tear down the grace timer + the pending silent-
    // reconnect window so neither can fire after the trip has stopped,
    // and stop the reconnect scanner.
    _droppedSession.cancelAllTimers();
    await _droppedSession.stopReconnectScanner();
    _started = false;
    _stopped = true;
    _pausedDueToDrop = false;
    // #2565 — clear the degrade flag so a stop while degraded finalises
    // cleanly (the drop-window GPS samples persist in the mixed trip).
    _degradedGpsOnly = false;
    _dropDetector.reset();
    _emitState();
    if (!_stateController.isClosed) {
      await _stateController.close();
    }
    if (!_liveController.isClosed) {
      await _liveController.close();
    }
    return _finaliseSummary();
  }

  /// RPM ceiling used by the gear-inference coaching metric (#1263
  /// phase 2). The "seconds below optimal gear" heuristic counts an
  /// interval when the next gear up would still keep the engine at or
  /// above this value — i.e. the current selection is unnecessarily
  /// low. 2200 RPM matches the issue body's reference point: well
  /// above the 1500-1800 RPM lugging band on most petrol engines but
  /// still within the cruise sweet-spot the coaching line targets.
  /// Hardcoded for phase 2; phase 3+ may promote this to a per-
  /// vehicle field if the spread between engine families warrants it.
  static const double _optimalRpmCeiling = 2200.0;

  /// Build the trip's final [TripSummary] from the recorder's
  /// in-flight accumulator plus the controller-owned distance
  /// provenance (#800). The recorder still owns distance integration
  /// for live UI reads; the controller overrides at finalisation only
  /// when a real odometer delta beats the virtual estimate.
  ///
  /// #1263 phase 2 — when the active vehicle is combustion / hybrid
  /// AND there are enough captured samples to drive [inferGears], the
  /// gear-inference metric `secondsBelowOptimalGear` is computed and
  /// stamped onto the returned summary. EVs (and any vehicle whose
  /// type resolves to [VehicleType.ev]) bypass the inference entirely
  /// — no gears, no coaching. Failures inside the pure-logic helpers
  /// fall back to a null metric rather than throw, so a degenerate
  /// fixture never derails the trip-stop flow.
  TripSummary _finaliseSummary() {
    final base = _recorder.buildSummary();
    final distanceKm = currentDistanceKm;
    final source = distanceSource;
    // Recompute avgLPer100Km against the swapped distance. #2835 —
    // re-apply the tiny-distance floor (ratio blows up below it; the
    // measured litres are kept). Sparse-cadence trips already arrive
    // with `base.fuelLitersConsumed == null` from the recorder.
    final avg = (base.fuelLitersConsumed != null &&
            isDistanceReliableForRatio(distanceKm))
        ? base.fuelLitersConsumed! / distanceKm * 100.0
        : null;
    // #1395 — roll the running breadcrumb flag-counts into a single
    // suspect bit on the trip summary. Threshold matches the spec:
    // when more than 30 % of fuel-rate samples tripped a sanity flag
    // (suspicious-low at cruise OR 5E-vs-MAF divergent > 50 %), the
    // resulting L/100 km is unreliable and a downstream UI chip
    // (#1395 phase 4) will warn the user. The snapshot resets the
    // running counters so a subsequent recording starts clean.
    var fuelRateSuspect = false;
    final collector = _breadcrumbCollector;
    if (collector != null) {
      final snapshot = collector.snapshotAndResetCounters();
      if (snapshot.total > 0 &&
          snapshot.suspicious / snapshot.total > 0.3) {
        fuelRateSuspect = true;
      }
    }
    // #1858 — η_v recompute provenance. Non-null ONLY when every litre
    // of the trip's fuel was speed-density-derived (η_v-scalable) and
    // some fuel was burned; then it is the fuel-weighted mean of the
    // per-tick η_v applied. Any PID 5E / MAF fuel — or no fuel — leaves
    // it null, marking the trip "not recalculable".
    final double? veUsed =
        (!_sawNonVeDerivedFuel && _veDerivedFuelRateSum > 0)
            ? _veWeightedFuelSum / _veDerivedFuelRateSum
            : null;
    // #2509 — GPS start/end fallback. When the OBD2 link was dead the
    // recorder never saw a sample, so `base.startedAt` / `base.endedAt`
    // are null even though GPS fixes were buffered into the distance
    // resolver and produced a real distance. Without a `startedAt` the
    // persist guard discards the whole drive (silent data loss). Fall
    // back to the first/last GPS-fix timestamp captured in [updateGpsFix]
    // ONLY when the recorder did not supply its own — a healthy OBD2 trip
    // keeps the recorder's authoritative timestamps untouched.
    final startedAt = base.startedAt ?? _gpsStartedAt;
    final endedAt = base.endedAt ?? _gpsEndedAt;
    return TripSummary(
      distanceKm: distanceKm,
      maxRpm: base.maxRpm,
      highRpmSeconds: base.highRpmSeconds,
      idleSeconds: base.idleSeconds,
      harshBrakes: base.harshBrakes,
      harshAccelerations: base.harshAccelerations,
      avgLPer100Km: avg,
      fuelLitersConsumed: base.fuelLitersConsumed,
      startedAt: startedAt,
      endedAt: endedAt,
      distanceSource: source,
      secondsBelowOptimalGear: _computeGearCoachingMetric(),
      fuelRateSuspect: fuelRateSuspect,
      volumetricEfficiencyUsed: veUsed,
    );
  }

  /// Compute the gear-inference coaching metric (#1263 phase 2).
  ///
  /// Returns null when:
  ///  - no vehicle profile is wired (we don't know the tyre size);
  ///  - the vehicle type is [VehicleType.ev] (no gears to coach);
  ///  - the captured-samples buffer is empty (no data to cluster);
  ///  - [inferGears] returns fewer than two centroids (degenerate);
  ///  - [computeSecondsBelowOptimalGear] reports the heuristic as
  ///    not computable.
  ///
  /// Returns a non-negative double otherwise — seconds during the
  /// trip where a higher gear would have kept RPM above
  /// [_optimalRpmCeiling].
  double? _computeGearCoachingMetric() {
    final vehicle = _vehicle;
    if (vehicle == null) return null;
    // EV bypass — pure-electric drivetrains have no manual / discrete
    // gears. Hybrids DO have a step-ratio transmission on the
    // combustion side, so they fall through to the inference path.
    if (vehicle.type == VehicleType.ev) return null;
    final captured = _sampleBuffer.capturedSamples;
    if (captured.isEmpty) return null;
    final tireC = vehicle.tireCircumferenceMeters;
    if (tireC <= 0) return null;
    final result = inferGears(
      samples: captured,
      tireCircumferenceMeters: tireC,
      priorCentroids: vehicle.gearCentroids,
    );
    if (result.centroids.length < 2) return null;
    return computeSecondsBelowOptimalGear(
      gearAssignments: result.samples
          .map((s) => (timestamp: s.timestamp, gear: s.gear))
          .toList(growable: false),
      optimalRpmCeiling: _optimalRpmCeiling,
      samples: captured,
      centroids: result.centroids,
    );
  }

  /// Odometer reading at trip start. Null when the adapter can't
  /// read the odometer (no PID A6, no PID 31 fallback, unknown
  /// manufacturer). Exposed so the save-as-fill-up flow can pre-fill
  /// the "odometer" field with the END km — which is start + the
  /// recorder's accumulated distance.
  double? get odometerStartKm => _odometerStartKm;

  /// Latest odometer reading read during the trip. Returns null
  /// until the first successful odometer poll. The recording UI
  /// doesn't poll the odometer every tick (it's an expensive Mode
  /// 22 query on some cars) — just once at start and once near the
  /// end via [refreshOdometer].
  double? get odometerLatestKm => _odometerLatestKm;

  /// VIN read once at [start]. Null on older ECUs / adapters that
  /// can't answer Mode 09 PID 02. Exposed so the fill-up screen can
  /// stamp the trip with a vehicle identity independent of the
  /// user's selected profile.
  String? get vin => _vin;

  /// Stable session id (ISO start timestamp). Matches the primary
  /// key used by [TripHistoryEntry] and [PausedTripEntry] so a
  /// paused → finalised transition keeps the row together. Null
  /// before [start] runs.
  String? get sessionId => _sessionId;

  /// Refresh the odometer reading. Call this just before [stop] so
  /// the save-as-fill-up gets a ground-truth end km rather than a
  /// derived value.
  Future<void> refreshOdometer() async {
    final km = await _service.readOdometerKm();
    if (km != null) _odometerLatestKm = km;
  }

  /// Distance covered by the current trip so far (#800).
  ///
  /// Resolution order (#800 / #1979):
  ///   1. the ground-truth `odometerLatest - odometerStart` when both
  ///      readings are present AND moved forward by more than a
  ///      noise-floor epsilon (odometer PIDs are quantised to 0.1 km
  ///      on most cars — a 0.09-km delta is a sensor artefact);
  ///   2. the haversine-summed GPS track, when a usable one was
  ///      recorded — true road distance, free of the speed sensor's
  ///      over-read;
  ///   3. the trapezoidal integral of buffered speed samples via
  ///      [VirtualOdometer], when the car exposes no odometer
  ///      (Peugeot 107 class) and no GPS track was captured.
  double get currentDistanceKm => _distance.distanceKm(
        odometerStartKm: _odometerStartKm,
        odometerLatestKm: _odometerLatestKm,
      );

  /// `'real'` when [currentDistanceKm] came from the car's odometer,
  /// `'gps'` when it came from the haversine-summed GPS track (#1979),
  /// `'virtual'` when it came from [VirtualOdometer] integration
  /// (#800). Persisted on the finalised [TripSummary] so the fill-up
  /// flow and eco-analytics know whether to treat the km as a ground
  /// truth or as an estimate.
  String get distanceSource => _distance.distanceSource(
        odometerStartKm: _odometerStartKm,
        odometerLatestKm: _odometerLatestKm,
      );

  /// Number of GPS fixes buffered for the distance resolver this trip
  /// (#2509). Surfaced so the save path can distinguish a genuinely
  /// stationary trip (no movement AND no fixes → discard, #1923) from a
  /// real GPS-tracked drive whose OBD2 link was dead (fixes present →
  /// persist). Delegates to [TripDistanceResolver.gpsFixCount].
  int get gpsFixCount => _distance.gpsFixCount;

  /// Append a speed sample to the virtual-odometer buffer, dropping
  /// the oldest entry when the cap is hit. Called from the 5 Hz
  /// vehicle-speed subscription. Delegates to [TripDistanceResolver]
  /// which owns the buffer (#2187).
  void _recordSpeedSample(double speedKmh) =>
      _distance.addSpeedSample(speedKmh);

  // ---------------------------------------------------------------------------
  // Scheduler wiring
  // ---------------------------------------------------------------------------

  PidScheduler _buildScheduler() {
    return PidScheduler(
      transport: _runTransport,
      tickRate: _schedulerTickRate,
      clock: _now,
    );
  }

  /// Wrap [Obd2Service.sendCommand] with drop-detection bookkeeping
  /// (#797 phase 1). Successful reads reset the consecutive-error
  /// counter; repeated failures in a short window flip the controller
  /// into [TripRecordingControllerState.pausedDueToDrop].
  ///
  /// The scheduler itself still swallows the exception (it logs and
  /// marks `lastReadAt` to keep other PIDs from starving) — we rethrow
  /// because throwing keeps the scheduler's "something went wrong"
  /// branch in play, but we *also* short-circuit by stopping the
  /// scheduler the moment we cross the threshold.
  Future<String> _runTransport(String command) async {
    try {
      final response = await _sendOrShortCircuit(command);
      // A clean read is the only signal strong enough to clear the
      // error window; ELM327 NO DATA responses come back via the
      // response string, not an exception.
      _dropDetector.registerSuccess();
      return response;
    } catch (_) {
      // #1904 — one silent retry before a transport error counts
      // toward a drop. Bluetooth links hiccup briefly (a single lost
      // write, a momentary RF collision); retrying once after a short
      // pause absorbs that common transient case so it never reaches
      // the drop detector. Only a failure that survives the retry is
      // a real drop signal.
      await Future<void>.delayed(_transportRetryDelay);
      try {
        final response = await _sendOrShortCircuit(command);
        _dropDetector.registerSuccess();
        return response;
      } catch (e, st) { // ignore: unused_catch_stack
        _registerTransportError(e);
        rethrow;
      }
    }
  }

  /// #2907 — never write into a DEAD transport. A drop disconnects the service
  /// (`isConnected == false`); the reconnect [replaceService]-swaps a fresh
  /// one. If a poll dereferences a service that is no longer connected — the
  /// orphaned-reconnect window, or a swap that hasn't landed — fail FAST with
  /// a recoverable typed disconnect instead of writing into a closed socket
  /// and waiting out the full per-command read timeout. Throwing here routes
  /// through [_runTransport]'s existing retry → [_registerTransportError]
  /// path unchanged, so the drop threshold + timing behaviour is identical to
  /// a real dead-link `sendCommand` throw — it just never spins the radio.
  Future<String> _sendOrShortCircuit(String command) {
    if (!_service.isConnected) {
      throw const Obd2DisconnectedException(
        'TripRecordingController: transport not connected — link is recovering',
      );
    }
    return _service.sendCommand(command);
  }

  /// #1904 — pause before the single transport retry, giving the
  /// Bluetooth link a moment to settle rather than hammering it.
  static const Duration _transportRetryDelay = Duration(milliseconds: 150);

  /// Funnel a transport error through the drop detector and react to
  /// its verdict (#797 phase 1). The lifecycle guard stays here — the
  /// detector counts, the controller owns the "are we already
  /// pausing?" state.
  void _registerTransportError(Object error) {
    if (_pausedDueToDrop || _stopped) return;
    if (_dropDetector.registerTransportError(error)) {
      _droppedSession.handleDrop();
    }
  }

  /// Bookkeeping for the silent-failure heuristic (#1330 phase 3).
  ///
  /// Called from every high-priority PID callback right after the
  /// parser returned. A null parse increments the consecutive-null
  /// counter; ANY non-null parse resets it to zero — even from a
  /// different PID, because we're trying to detect "ECU is dead",
  /// not "this specific PID is unsupported".
  ///
  /// Once the counter reaches the silent-failure threshold AND the
  /// transport-error drop hasn't already fired, [_onSilentFailure]
  /// drives the same pause-with-grace path that the drop-recovery
  /// manager runs for transport errors, but stamps a
  /// [TripDropReason.silentFailure] reason so the UI can surface a
  /// different message.
  void _observeHighPriorityParse(Object? parsedValue) {
    if (parsedValue != null) {
      // ANY successful high-priority parse clears the window — we're
      // detecting "ECU is dead", not "this one PID is unsupported".
      _dropDetector.observeHighPriorityParse(parsedValue);
      return;
    }
    // The transport-error drop already paused us — don't let a stretch
    // of nulls double-fire into a second drop. The lifecycle guard
    // stays here; the detector just counts.
    if (_pausedDueToDrop || _stopped) return;
    if (_dropDetector.observeHighPriorityParse(parsedValue)) {
      _onSilentFailure();
    }
  }

  /// Silent-failure handler (#1330 phase 3). Fired exactly once per
  /// recording session when the drop detector's consecutive-null
  /// counter crosses the threshold. Drives the same pause-with-grace
  /// recovery the drop-recovery manager runs for transport errors, but
  /// tags the drop with [TripDropReason.silentFailure] so the UI
  /// surfaces "OBD2 adapter connected but not returning data" instead
  /// of "OBD2 connection lost".
  void _onSilentFailure() {
    debugPrint(
      'TripRecordingController: silent-failure detected — '
      '${_dropDetector.consecutiveNullReads} consecutive null PID parses',
    );
    _droppedSession.handleDrop(reason: TripDropReason.silentFailure);
  }

  void _emitState() {
    if (_stateController.isClosed) return;
    _stateController.add(currentState);
  }

  /// Read the VIN exactly once at [start]. Wrapped so the one-shot
  /// decision is visible to readers of [start] — if we ever need to
  /// re-read mid-trip (e.g. user hot-swaps cars) this is the place
  /// to add the timer. Returns null on NO DATA / malformed response.
  Future<String?> _readVinOnce() async {
    try {
      final raw = await _service.sendCommand(Elm327Protocol.vinCommand);
      return Elm327Protocol.parseVin(raw);
    } catch (_) {
      // #2428 (follow-up to #2379/#2424) — the one-shot VIN (0902) read is
      // best-effort: a flaky/slow ELM327 times it out, the legacy
      // concurrent-sendCommand StateError can fire, or the device drops
      // mid-probe — and old ECUs / clone adapters never answer 0902. All
      // EXPECTED and recoverable: we return null and the trip records fine
      // without a VIN, so a transient here must NOT pollute the user error
      // log (it was mis-tagged `[storage]`). The null return IS the signal.
      debugPrint('OBD2 VIN read failed — recording trip without a VIN');
      return null;
    }
  }

  /// Called by the debounced emit timer. Snapshots current state into
  /// a [TripLiveReading], integrates any new fuel/distance since the
  /// last emit, and pushes to [live].
  void _emit() {
    // Don't emit/integrate while paused, while a drop is on the pause
    // banner, OR during the #1904 silent-reconnect window (#1912): the
    // scheduler is stopped then, so the snapshot is stale — feeding it
    // to the recorder would integrate phantom distance/fuel from a
    // frozen speed over real elapsed time.
    if (_paused || _pausedDueToDrop || _droppedSession.silentlyReconnecting) {
      return;
    }
    if (_liveController.isClosed) return;
    // #2565 — `degradedGpsOnly` is NOT gated above: OBD2 is gone (the PID
    // snapshot is stale) but GPS is alive, so build a GPS-only sample +
    // run the estimate overlay instead of freezing.
    if (_degradedGpsOnly) {
      _emitDegradedGpsOnly();
      return;
    }

    final snap = _liveSampleSnapshot;
    final nowTs = _now();
    final fuelRate = snap.deriveFuelRateLPerHour();
    // #1858 — fold this tick into the trip's η_v recompute provenance.
    // Speed-density fuel is the only η_v-derived branch; PID 5E / MAF
    // fuel marks the trip non-recalculable.
    if (fuelRate != null && fuelRate > 0) {
      final veUsed = snap.lastFuelRateBranch == Obd2BranchTag.speedDensity
          ? snap.lastFuelRateVe
          : null;
      if (veUsed != null && veUsed > 0) {
        _veWeightedFuelSum += veUsed * fuelRate;
        _veDerivedFuelRateSum += fuelRate;
      } else {
        _sawNonVeDerivedFuel = true;
      }
    }
    final speedKmh = snap.latestSpeedKmh;
    final rpm = snap.latestRpm;
    final throttlePercent = snap.latestThrottlePercent;
    final engineLoadPercent = snap.latestEngineLoadPercent;
    final coolantTempC = snap.latestCoolantTempC;
    // #2459 — should this tick ALSO carry the diagnostic-capture raw
    // mixture inputs? Only when the per-trip flag is on AND we're past
    // the slow-cadence interval since the last stamp; otherwise the four
    // raw keys stay null (carried-forward = simply not re-written) so the
    // payload doesn't balloon at the 4 Hz emit rate.
    final captureRaw = _diagnosticCapture &&
        (_lastDiagnosticCaptureAt == null ||
            nowTs.difference(_lastDiagnosticCaptureAt!) >=
                _diagnosticCaptureInterval);
    if (captureRaw) _lastDiagnosticCaptureAt = nowTs;
    // The recorder integrates fuel rate and Δt itself, so we only
    // hand it one TripSample per emit — not per PID callback. At a
    // 250 ms emit cadence that's 4 Hz into the recorder, matching
    // the pre-#814 1 Hz loop's behavior closely enough that the
    // distance/fuelLitersConsumed integration is unchanged.
    // #2963 — never persist `speedKmh ?? 0`. A fabricated leading `0`
    // (RPM PID 0x0C acquired before the speed PID 0x0D parses), followed by
    // the car's actual non-zero speed once 0x0D answers, manufactures a
    // `0 → real` step the accel gate scores as a phantom hard-accel (a 22 s
    // idle OBD2 trip surfaced `hardAccelPenalty = 3.0`). Guard:
    //   1. Until the FIRST real speed lands, an RPM-only tick has no usable
    //      speed (idle needs `speed≤0.5`, accel needs the derivative), so
    //      skip persisting it rather than invent a `0`. A measured idle
    //      (`41 0D 00`) is a real `0` and starts the series cleanly.
    //   2. After that, hold-last for a later RPM-only tick (defence-in-depth;
    //      the live snapshot already holds-last).
    final hasEverReadSpeed = speedKmh != null || _lastPersistedSpeedKmh != null;
    if ((speedKmh != null || rpm != null) && hasEverReadSpeed) {
      final persistedSpeedKmh = speedKmh ?? _lastPersistedSpeedKmh!;
      if (speedKmh != null) _lastPersistedSpeedKmh = speedKmh;
      final sample = TripSample(
        timestamp: nowTs,
        speedKmh: persistedSpeedKmh,
        rpm: rpm, // #2692 C4-G — keep null (gate above still admits on speed).
        fuelRateLPerHour: fuelRate,
        throttlePercent: throttlePercent,
        engineLoadPercent: engineLoadPercent,
        coolantTempC: coolantTempC,
        // #1374 phase 1 — stamp the most recent GPS fix when the
        // provider has pushed one in. The fields stay null when the
        // feature flag is off (no Geolocator subscription was ever
        // started) or before the first fix lands. Altitude added in
        // #1935 child A for the road-grade calculator.
        latitude: snap.latestLatitude,
        longitude: snap.latestLongitude,
        altitudeM: snap.latestAltitudeM,
        // #2648 — GPS horizontal accuracy + bearing. Both already
        // round-trip through the codec ('ha' / 'be') and TripSample has
        // had the fields; the OBD2 path simply dropped them. Stamping
        // them here revives the cornering analytic (bearing) and the
        // harsh-event accuracy-gate. Null when no GPS fix has landed.
        hAccuracyM: snap.latestHAccuracyM,
        bearingDeg: snap.latestBearingDeg,
        // #2459 — the consumed-but-previously-unstored signals, stamped
        // from the snapshot latest-value getters exactly like throttle.
        // Each stays null on cars that don't expose the PID, so the
        // compact-key serialization writes zero bytes for them.
        lambda: snap.latestLambda,
        baroKpa: snap.latestBaroKpa,
        absLoadPercent: snap.latestAbsLoadPercent,
        pedalPercent: snap.latestPedalPercent,
        oilTempC: snap.latestOilTempC,
        ambientTempC: snap.latestAmbientTempC,
        // #2459 — diagnostic-capture raw mixture inputs, only on the
        // slow-cadence ticks while the flag is on (else null = not
        // written). Each is independently null-safe per PID support.
        mafGramsPerSecond: captureRaw ? snap.latestMaf : null,
        mapKpa: captureRaw ? snap.latestMapKpa : null,
        stft: captureRaw ? snap.latestStft : null,
        ltft: captureRaw ? snap.latestLtft : null,
      );
      // #2653 — thread the live distance provenance so the detector
      // suppresses harsh scoring on the `virtual` dead-reckoning source.
      _recorder.onSample(sample, distanceSource: distanceSource);
      _lastSampleAt = nowTs;
      // #1925 — ping the opt-in debug recorder so a stretch of silence
      // surfaces as a data-gap event in the exported session log.
      // #1930 — pass the vehicle state so a gap records what the car
      // was doing when data stopped (driving vs engine-off).
      Obd2DebugSessionRecorder.recordData(nowTs, speedKmh: speedKmh, rpm: rpm);
      _sampleBuffer.maybeCapture(sample);
    }
    // #2304 — build the integrated summary once per tick and reuse it for
    // the fuel-litres and distance reads below. Computed after the sample
    // (if any) was fed to the recorder so it reflects this tick. Was two
    // separate `buildSummary()` calls = two TripSummary allocations per
    // 4 Hz emit.
    final summary = _recorder.buildSummary();
    if (fuelRate != null) {
      _fuelRateSeen = true;
      _fuelLitersSoFar = summary.fuelLitersConsumed ?? _fuelLitersSoFar;
    }
    // #2506 — live Speed/Distance GPS fallback. The OBD2 speed PID (0x0D)
    // always wins when present; when it's momentarily absent (the no-fuel-
    // PID Peugeot in the field report drops it intermittently) the latched
    // GPS ground-speed fills the read-out instead of dashing to "—". For
    // distance, prefer the resolver's three-tier pick (GPS track > virtual
    // integral) when it has advanced past the recorder's integrated number
    // — matching what `_finaliseSummary` already does at stop, so live and
    // persisted agree.
    final effectiveSpeedKmh = speedKmh ?? _latestGpsSpeedKmh;
    final resolverDistanceKm = currentDistanceKm;
    final effectiveDistanceKm = resolverDistanceKm > summary.distanceKm
        ? resolverDistanceKm
        : summary.distanceKm;
    var reading = TripLiveReading(
      speedKmh: effectiveSpeedKmh,
      rpm: rpm,
      fuelRateLPerHour: fuelRate,
      fuelLevelPercent: snap.latestFuelLevelPercent,
      // #1615 — exact OEM-PID litres when the provider layer has pushed
      // one in; null (and consumers fall back to percent×capacity) when
      // the `experimentalOemPids` flag is off or the adapter is not
      // OEM-capable.
      fuelLevelLitres: snap.latestOemFuelLevelLitres,
      engineLoadPercent: engineLoadPercent,
      // #2513 — carry the wider-range absolute load + latest GPS
      // altitude through to the baseline recorder so its fuzzy path can
      // fill the climbing/loaded bucket from a real road grade and/or a
      // load ramp. Both stay null on cars / trips that don't surface
      // them, and the recorder degrades gracefully.
      absLoadPercent: snap.latestAbsLoadPercent,
      altitudeM: snap.latestAltitudeM,
      throttlePercent: throttlePercent,
      coolantTempC: coolantTempC,
      // #2515 — surface the precision signals the snapshot already
      // latches (oil/ambient temp gate the cold-start bucket now; λ /
      // baro / MAP / fuel-trim / pedal feed PR 2's mixture-precision
      // folding + altitude stratification). All null on cars without
      // the PID, so the calibration path degrades gracefully.
      oilTempC: snap.latestOilTempC,
      ambientTempC: snap.latestAmbientTempC,
      lambda: snap.latestLambda,
      baroKpa: snap.latestBaroKpa,
      mapKpa: snap.latestMapKpa,
      stft: snap.latestStft,
      ltft: snap.latestLtft,
      pedalPercent: snap.latestPedalPercent,
      distanceKmSoFar: effectiveDistanceKm,
      fuelLitersSoFar: _fuelRateSeen ? _fuelLitersSoFar : null,
      elapsed: nowTs.difference(_startedAt ?? nowTs),
      odometerStartKm: _odometerStartKm,
      odometerNowKm: _odometerLatestKm,
    );
    // #2506 — when NO fuel-rate PID is measurable (every tick null), fold
    // the GPS-physics estimate + coaching into the live reading so the
    // recording screen mirrors the proven post-trip
    // `Obd2GpsEstimateFallback` instead of dashing the whole drive. The
    // shared [GpsLiveEstimateFolder] is the same implementation the
    // GPS-only pipeline uses, so the two paths can't diverge. The fold is
    // driven by the EFFECTIVE speed (GPS latch when OBD2 0x0D is absent),
    // so the physics still runs on a car that exposes neither a fuel PID
    // nor a reliable speed PID. Skipped once any real fuel rate is seen —
    // measured data is never overwritten; a stale GPS coaching hint is then
    // cleared so `MinimalDriveSummary` swaps back to the OBD2 triplet.
    reading = _overlayGpsEstimate(
      reading,
      nowTs: nowTs,
      fuelRate: fuelRate,
      effectiveSpeedKmh: effectiveSpeedKmh,
      rpm: rpm,
      altitudeM: snap.latestAltitudeM,
    );
    _liveController.add(reading);
  }

  /// #2506 / #2565 — fold the GPS-physics live estimate + coaching into
  /// [reading] when NO fuel-rate PID is measurable. Shared by the healthy
  /// `_emit` and the degraded GPS-only path so they can't diverge. Skipped
  /// once a real fuel rate is seen (a stale coaching hint is then cleared).
  TripLiveReading _overlayGpsEstimate(
    TripLiveReading reading, {
    required DateTime nowTs,
    required double? fuelRate,
    required double? effectiveSpeedKmh,
    required double? rpm,
    required double? altitudeM,
  }) {
    final folder = _gpsEstimateFolder;
    if (fuelRate == null && !_fuelRateSeen && folder != null) {
      final overlaid = folder.overlay(
        base: reading,
        now: nowTs,
        effectiveSpeedKmh: effectiveSpeedKmh ?? 0,
        rpm: rpm,
        altitudeM: altitudeM,
      );
      _latestGpsCoachingHint = overlaid.coachingHint;
      return overlaid.reading;
    } else if (_fuelRateSeen) {
      _latestGpsCoachingHint = null;
    }
    return reading;
  }

  /// #2565 — one emit tick while in the `degradedGpsOnly` phase, delegated
  /// to the [DegradedGpsEmitter] collaborator (which builds the GPS-only
  /// sample + live reading and escalates to paused when GPS also dies).
  void _emitDegradedGpsOnly() {
    final snap = _liveSampleSnapshot;
    final reading = _degradedEmitter.emitTick(
      latestGpsSpeedKmh: _latestGpsSpeedKmh,
      latitude: snap.latestLatitude,
      longitude: snap.latestLongitude,
      altitudeM: snap.latestAltitudeM,
      // #2648 — carry accuracy + bearing through the degraded path too.
      hAccuracyM: snap.latestHAccuracyM,
      bearingDeg: snap.latestBearingDeg,
      lastGpsFixAt: _gpsEndedAt,
      startedAt: _startedAt,
      resolverDistanceKm: currentDistanceKm,
      odometerStartKm: _odometerStartKm,
      odometerLatestKm: _odometerLatestKm,
    );
    if (reading != null) _liveController.add(reading);
  }

  /// Exposed for tests: append a sample to the captured-samples buffer
  /// without going through the scheduler / debounced emit timer
  /// (#1040). Tests use this to populate a deterministic buffer + then
  /// drive [TripRecording.stop] end-to-end.
  @visibleForTesting
  void debugCaptureSample(TripSample sample) {
    _sampleBuffer.debugCaptureSample(sample);
  }

  /// Exposed for tests: force an emit immediately instead of waiting
  /// for the debounced timer. Useful when a test injects a tiny
  /// scheduler tickRate but wants deterministic TripLiveReading
  /// emission on demand.
  @visibleForTesting
  void debugEmitNow() => _emit();

  /// Exposed for tests: the last sample timestamp pushed to
  /// [TripRecorder]. Null until the first emit with non-null speed
  /// or RPM.
  @visibleForTesting
  DateTime? get debugLastSampleAt => _lastSampleAt;

  /// Exposed for tests: trigger the drop-handling path directly, so
  /// tests that can't easily convince a fake transport to throw three
  /// times in a row still exercise the state transition. [reason]
  /// defaults to a transport drop; pass [TripDropReason.silentFailure]
  /// to exercise the dead-ECU path.
  @visibleForTesting
  void debugTriggerDrop({
    TripDropReason reason = TripDropReason.transportError,
  }) {
    _droppedSession.handleDrop(reason: reason);
  }

  /// Exposed for tests: whether the controller is inside the #1904
  /// invisible reconnect window (a transport drop the scanner is
  /// trying to clear before it ever reaches the pause banner).
  @visibleForTesting
  bool get debugSilentlyReconnecting => _droppedSession.silentlyReconnecting;

  /// Exposed for tests: run one command through the retrying transport
  /// path so the #1904 single-retry-on-transient-error behaviour can
  /// be unit-tested without driving the whole PID scheduler.
  @visibleForTesting
  Future<String> debugRunTransport(String command) =>
      _runTransport(command);

  /// Exposed for tests: drive the silent-failure observer with a
  /// hand-built parse outcome so tests don't have to spin up a fake
  /// service that returns null forever (#1330 phase 3). Pass `null`
  /// to increment the counter, any non-null value to reset it.
  @visibleForTesting
  void debugObserveHighPriorityParse(Object? parsedValue) {
    _observeHighPriorityParse(parsedValue);
  }

  /// Exposed for tests: current consecutive-null count. Lets the
  /// silent-failure tests assert "49 nulls did NOT trigger" before
  /// the 50th lands (#1330 phase 3).
  @visibleForTesting
  int get debugConsecutiveNullReads => _dropDetector.consecutiveNullReads;

  /// Exposed for tests: whether the silent-failure handler has fired
  /// for this recording session. Resets on resume() / stop().
  @visibleForTesting
  bool get debugSilentFailureFired => _dropDetector.silentFailureFired;

  /// Exposed for tests: synchronously drive the grace-window
  /// finalisation path. Useful with fake-async patterns where
  /// elapsing real wall-clock time is awkward.
  @visibleForTesting
  Future<void> debugExpireGraceWindow() =>
      _droppedSession.expireGraceWindowNow();

  /// Exposed for tests: the auto-reconnect scanner instance created
  /// by the drop-recovery state machine (#797 phase 3 / #2188). Null
  /// when no scanner factory is wired in or no pinned MAC is known —
  /// also null again after a successful reconnect or a stop(), because
  /// the manager releases the reference as soon as it's no longer
  /// needed.
  @visibleForTesting
  AdapterReconnectScanner? get debugReconnectScanner =>
      _droppedSession.reconnectScanner;

  /// Exposed for tests: inject a hand-crafted [TripSample] directly
  /// into the underlying [TripRecorder]. Used by the #797 phase 1
  /// tests to accumulate captured data deterministically without
  /// driving the scheduler + parsers end-to-end.
  @visibleForTesting
  void debugInjectSample({
    required double speedKmh,
    double? rpm,
    required DateTime at,
    double? fuelRateLPerHour,
  }) {
    _recorder.onSample(TripSample(
      timestamp: at,
      speedKmh: speedKmh,
      rpm: rpm,
      fuelRateLPerHour: fuelRateLPerHour,
    ));
  }

  /// Exposed for tests: append a speed sample to the virtual-odometer
  /// buffer without going through the scheduler (#800). Tests use
  /// this to pre-populate samples + call [currentDistanceKm] /
  /// [distanceSource] deterministically.
  @visibleForTesting
  void debugRecordSpeedSample({
    required double speedKmh,
    required DateTime at,
  }) {
    _distance.debugAddSpeedSample(speedKmh: speedKmh, at: at);
  }

  /// Exposed for tests: override the trip's start/latest odometer
  /// readings without driving a fake transport through
  /// [refreshOdometer] (#800). Useful when the test just needs to
  /// assert that a `'real'` delta wins over the virtual path.
  @visibleForTesting
  void debugSetOdometerReadings({double? startKm, double? latestKm}) {
    if (startKm != null) _odometerStartKm = startKm;
    if (latestKm != null) _odometerLatestKm = latestKm;
  }

  /// Exposed for tests: read-only view of the captured speed samples.
  @visibleForTesting
  List<VirtualOdometerSample> get debugSpeedSamples =>
      _distance.debugSpeedSamples;

  /// Exposed for tests: append a GPS fix to the #1979 track buffer
  /// without a live Geolocator stream, so tests can drive the
  /// GPS-distance path of [currentDistanceKm] / [distanceSource]
  /// deterministically. Optional [hAccuracyM] / [at] are forwarded onto the
  /// buffered point (matching production [updateGpsFix]) so a test can drive
  /// the #2963 gates and the #3004 ~1 Hz decimation; null `at` = controller
  /// clock.
  @visibleForTesting
  void debugAppendGpsFix({
    required double latitude,
    required double longitude,
    double? hAccuracyM,
    DateTime? at,
  }) {
    _distance.debugAddGpsFix(
      latitude: latitude,
      longitude: longitude,
      hAccuracyM: hAccuracyM,
      at: at,
    );
  }
}

/// Adapts [TripRecordingController]'s recording loop to the narrow
/// [DroppedSessionHost] seam the drop-recovery state machine needs
/// (#2188). Lives in the same library as the controller so it can
/// delegate to its private lifecycle flags + collaborators without
/// widening the controller's public API.
///
/// Every method here is a thin pass-through; the behaviour-preserving
/// extraction lives in [DroppedSessionManager]. The adapter exists only
/// so the manager stays unit-testable against a fake host while
/// production wires the real controller.
class _DroppedSessionHostAdapter implements DroppedSessionHost {
  _DroppedSessionHostAdapter(this._c);

  final TripRecordingController _c;

  @override
  void stopScheduler() => _c._scheduler?.stop();

  @override
  void pauseScheduler() => _c._scheduler?.pause();

  @override
  void resumeScheduler() => _c._scheduler?.resume();

  @override
  void disconnectDroppedService() {
    // #2524 — fail the dead transport's stranded `_pending` + close its
    // channel off the hot path. Best-effort; the link is already gone.
    final svc = _c._service;
    unawaited(() async {
      try {
        await svc.disconnect();
      } catch (e, st) {
        debugPrint('TripRecordingController: dropped-service disconnect '
            'failed (already dead) — $e\n$st');
      }
    }());
  }

  @override
  void startScheduler() => _c._scheduler?.start();

  @override
  void resetDropDetector() => _c._dropDetector.reset();

  @override
  void clearDropDetectorErrorWindow() => _c._dropDetector.clearErrorWindow();

  @override
  void emitState() => _c._emitState();

  @override
  void resumeFromReconnect() => _c.resume();

  @override
  TripSummary buildInProgressSummary() => _c._recorder.buildSummary();

  @override
  TripSummary buildFinalSummary() => _c._finaliseSummary();

  @override
  bool get pausedDueToDrop => _c._pausedDueToDrop;
  @override
  set pausedDueToDrop(bool value) => _c._pausedDueToDrop = value;

  @override
  bool get degradedGpsOnly => _c._degradedGpsOnly;
  @override
  set degradedGpsOnly(bool value) => _c._degradedGpsOnly = value;

  @override
  bool get gpsAlive => GpsOnlySampleBuilder.gpsAlive(
        lastGpsFixAt: _c._gpsEndedAt,
        now: _c._now(),
        window: TripRecordingController._gpsAliveWindow,
      );

  @override
  bool get stopped => _c._stopped;
  @override
  set stopped(bool value) => _c._stopped = value;

  @override
  bool get started => _c._started;
  @override
  set started(bool value) => _c._started = value;

  @override
  bool get paused => _c._paused;

  @override
  String? get sessionId => _c._sessionId;

  @override
  String? get vehicleId => _c._vehicleId;

  @override
  String? get vin => _c._vin;

  @override
  double? get odometerStartKm => _c._odometerStartKm;

  @override
  double? get odometerLatestKm => _c._odometerLatestKm;

  @override
  bool get automatic => _c._automatic;

  @override
  List<TripSample> get capturedSamples => _c._sampleBuffer.capturedSamples;

  @override
  List<GpsSampleDiagnostic> get capturedGpsSampleDiagnostics =>
      _c._sampleBuffer.capturedGpsSampleDiagnostics;
}
