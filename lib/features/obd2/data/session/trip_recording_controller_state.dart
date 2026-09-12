// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_recording_controller.dart';

/// Per-trip session state for [TripRecordingController], extracted from
/// the controller file as a `part` so it keeps library-private access
/// while the controller stays under the #1680 file-length cap
/// (sanctioned #3760 decomposition — move-only, behaviour preserved).
///
/// [_TripRecordingSessionState] is the base of the controller's private
/// part-mixin chain (the edit_vehicle_screen_catalog_reset pattern): it
/// owns the mutable per-trip fields + collaborator handles, and
/// re-declares the constructor-initialized fields (which stay concrete
/// on the class — an initializer list can only assign fields of the
/// declaring class) as abstract members so the downstream part mixins
/// can reach them. Pure decomposition glue — no behaviour.

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
/// phase 3 (#797) wires an [Obd2ReattachSource] into the
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

mixin _TripRecordingSessionState {
  // -------------------------------------------------------------------
  // Constructor-initialized fields — concrete on [TripRecordingController],
  // re-declared abstractly here so the part-file mixins can reach them
  // (#3760 move-only decomposition glue).
  // -------------------------------------------------------------------
  Obd2Service get _service;
  set _service(Obd2Service value);
  // #3797 — the session lifecycle timeline (always-on, bounded).
  RecordingSessionJournal get _sessionJournal;
  // #3795 — how this session ended; null while running / unattributed.
  TripTermination? get _termination;
  set _termination(TripTermination? value);
  // #3776 — link-ownership seam (null without a supervisor graph). The
  // report seam is reached via the concrete controller (`_c.` in the
  // drop-host adapter), so only the predicate needs the mixin re-decl.
  bool Function(Obd2Service service)? get _isLinkSupervised;
  TripRecorder get _recorder;
  Duration get _pollInterval;
  DateTime Function() get _now;
  // #3862 — auto-record trips end themselves when parked; manual ones ask.
  bool get _automatic;
  // Implemented by the lifecycle part; reached from the emit / transport
  // parts, which sit BELOW it in the mixin chain.
  void _emitState();
  Future<void> _readTripIdentity();
  VehicleProfile? get _vehicle;
  bool get _diagnosticCapture;
  PidScheduler? get _schedulerOverride;
  Duration get _schedulerTickRate;
  TripGpsEstimateOverlay? get _gpsEstimateFolder;
  Obd2BreadcrumbRecorder? get _breadcrumbCollector;

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

  // Closed in stop()'s teardown in the
  // `trip_recording_controller_lifecycle.dart` part (the lint can't see
  // across part files).
  // ignore: close_sinks
  final StreamController<TripLiveReading> _liveController =
      StreamController<TripLiveReading>.broadcast();

  // Closed in stop()'s teardown in the lifecycle part.
  // ignore: close_sinks
  final StreamController<TripRecordingControllerState> _stateController =
      StreamController<TripRecordingControllerState>.broadcast();

  PidScheduler? _scheduler;
  Timer? _emitTimer;
  DateTime? _startedAt;

  // #4034 (epic #4032) — four clusters of this state machine's shared
  // mutable state are OWNED collaborators now, each with its own private
  // fields, instead of bare flags any of the controller's parts could
  // write. The forensic history of each cluster moved with it.

  /// #3602 — the staleness fence that keeps snapshot engine values off a
  /// sample no fresh parse is backing. Was `_lastFreshEngineParseAt` /
  /// `_staleEngineEscalated` / `_lastSampleAt`, written from four parts.
  final TripEngineDataFence _engineFence = TripEngineDataFence();

  /// #3857 (Epic #3855) — the ~10 s `ATRV` voltage watch. Was
  /// `_lastVoltageReadAt` / `_pendingVoltageStamp`.
  final TripVoltageWatch _voltageWatch = TripVoltageWatch();

  /// #3858 — trip identity (odometer / VIN / fuel type) is read once the
  /// bus can answer; a recording that starts with the engine off defers
  /// it to the engine transition. Was `_identityRead`.
  final TripIdentityRead _identity = TripIdentityRead();

  /// #3862 — parked-prompt bookkeeping: when the engine-off wait began,
  /// how long the car has been stationary in it, whether the prompt is
  /// due / was dismissed by the driver ("Keep"). Was five flags written
  /// from three parts.
  final TripParkedPromptWatch _parkedWatch = TripParkedPromptWatch();

  /// #3862 — true when the recording has been parked (engine off, car
  /// stationary) past [TripRecordingController.parkedPromptAfter] and the
  /// driver has not yet answered. Surfaced to the UI as a Stop / Keep pill.
  bool get parkedPromptDue => _parkedWatch.promptDue;

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
  /// #4034 — the trip's odometer bookkeeping (the start reading, the
  /// latest one, when it landed, the trip distance at that instant, the
  /// last refresh attempt and the in-flight guard). Six fields that used
  /// to sit here and be written from four parts; the reading/distance
  /// pairing (#3877) is only ever set together inside the tracker now.
  final TripOdometerTracker _odometer = TripOdometerTracker();

  /// #3878 — the whole-trip sample list the stop path read back from the
  /// WAL, for the finalise passes that need every sample (gear coaching);
  /// null on the legacy in-memory path.
  List<TripSample>? _allSamplesForFinalise;

  /// #3878 — injected by the pipeline: reads the whole trip (WAL + ring)
  /// for the grace-window finalise; null = legacy in-memory buffer.
  Future<List<TripSample>> Function()? _allSamplesReader;

  // #3431 — true instantaneous consumption: EMA-smoothed (τ ≈ 2.5 s)
  // fuel rate ÷ speed, stamped onto every live reading. Fresh per trip
  // (a controller is built per trip), so no explicit reset is needed.
  final InstantConsumptionEma _instantEma = InstantConsumptionEma();

  /// #3883 — rolling "last N s" consumption for the recording screen's
  /// headline: ∫fuelRate·dt ÷ ∫speed·dt over [liveConsumptionWindowSeconds].
  /// The buffer keeps 30 s, so the window can change mid-trip.
  final RollingConsumptionWindow _rollingWindow = RollingConsumptionWindow();

  /// #3883 — the user's live window length (Settings › Driving), read
  /// on every emit so a change applies mid-trip. The pipeline injects
  /// the settings read; the default stands in tests.
  int Function() readLiveConsumptionWindowSeconds =
      () => kDefaultLiveConsumptionWindowSeconds;

  /// #3845 — rolling driving-behaviour band for the live surfaces. Runs
  /// the canonical end-of-trip calculator over a sliding window, so the
  /// live colour and the trip's final grade share one implementation.
  final LiveDrivingBandTracker _liveBandTracker = LiveDrivingBandTracker();

  /// #4034 — the trip's fuel bookkeeping: litres so far, whether any
  /// real fuel rate was ever seen, and the #1858 η_v recompute
  /// provenance. Five fields that used to sit here loose, three of them
  /// only meaningful as a group.
  final TripFuelAccumulator _fuel = TripFuelAccumulator();
  /// #4034 — the five flags that say what the recording is doing
  /// (`started` / `stopped` / `paused` / `pausedDueToDrop` / the #2565
  /// `degradedGpsOnly`). They were bare booleans written from the
  /// lifecycle part AND the drop-host adapter; the compound transitions
  /// are single methods on the collaborator now, so no caller can do
  /// half of one.
  final TripRunState _run = TripRunState();
  // #4073 — derived from `_startedAt` (never cleared), not a second field.
  String? get _sessionId => _startedAt?.toIso8601String();

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
  /// readings ([TripOdometerTracker.startKm] / `latestKm`) and passes them
  /// into the resolver per read. Built in the constructor body so it can
  /// capture the resolved [_now] clock.
  late final TripDistanceResolver _distance;

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

  /// Read-only view of the captured sample buffer (#1040, #3741 —
  /// zero-copy: a cached unmodifiable VIEW, not a per-access copy). The
  /// list is unmodifiable so callers can't accidentally mutate the
  /// controller's state — the provider clones it into the persisted
  /// [TripHistoryEntry] at stop time.
  List<TripSample> get capturedSamples => _sampleBuffer.capturedSamples;

  /// #3878 — whole-trip capture count and the unwritten tail for the WAL
  /// flush; [releaseWrittenSamples] lets the flush shrink the in-memory
  /// ring once the samples are on disk.
  int get capturedTotal => _sampleBuffer.capturedTotal;
  DateTime? get firstCapturedAt => _sampleBuffer.firstCapturedAt;
  List<TripSample> capturedSince(int from) => _sampleBuffer.capturedSince(from);
  void releaseWrittenSamples(int writtenTotal) =>
      _sampleBuffer.releaseWritten(writtenTotal);

  /// O(1) newest captured sample (#3741) — glide-coach per-fix read.
  TripSample? get latestSample => _sampleBuffer.latestSample;

  /// O(1) running max captured RPM (#3741) — WAL flush summary stamp.
  double get maxCapturedRpm => _sampleBuffer.maxCapturedRpm;

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
}
