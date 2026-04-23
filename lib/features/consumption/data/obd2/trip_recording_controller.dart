import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../../core/storage/hive_boxes.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../domain/trip_recorder.dart';
import '../trip_history_repository.dart';
import 'elm327_protocol.dart';
import 'obd2_connection_errors.dart';
import 'obd2_service.dart';
import 'paused_trip_repository.dart';
import 'pid_scheduler.dart';

/// Live read-out from the currently-recording trip (#726).
///
/// Emitted on every debounced tick so the recording screen can show the
/// user speed / RPM / distance / estimated fuel without having to
/// ask the recorder for a full summary each time.
@immutable
class TripLiveReading {
  final double? speedKmh;
  final double? rpm;
  final double? fuelRateLPerHour;
  final double? fuelLevelPercent;
  final double? engineLoadPercent;
  /// Absolute throttle position, 0–100 %. Subscribed to the 5 Hz tier
  /// of the [PidScheduler] (#814) so the eco-feedback UI and the
  /// future coasting-detection logic have a direct signal instead of
  /// the engine-load proxy. Null when the adapter hasn't surfaced PID
  /// 11 or the first tick hasn't landed yet.
  final double? throttlePercent;
  final double distanceKmSoFar;
  final double? fuelLitersSoFar;
  final Duration elapsed;
  final double? odometerStartKm;
  final double? odometerNowKm;

  const TripLiveReading({
    this.speedKmh,
    this.rpm,
    this.fuelRateLPerHour,
    this.fuelLevelPercent,
    this.engineLoadPercent,
    this.throttlePercent,
    required this.distanceKmSoFar,
    this.fuelLitersSoFar,
    required this.elapsed,
    this.odometerStartKm,
    this.odometerNowKm,
  });

  /// Live L/100 km estimate — uses trip-so-far totals, so early
  /// samples are noisy and converge as the trip progresses. Returns
  /// null when the car doesn't surface a fuel-rate PID.
  double? get liveAvgLPer100Km {
    if (fuelLitersSoFar == null || distanceKmSoFar < 0.01) return null;
    return fuelLitersSoFar! / distanceKmSoFar * 100.0;
  }
}

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
enum TripRecordingControllerState {
  idle,
  recording,
  paused,
  pausedDueToDrop,
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
///   - a grace timer starts for [_pauseGraceWindow]; if [resume] isn't
///     called before it fires, the paused entry is finalised into the
///     normal trip history as if [stop] had run.
///
/// Phase 1 exposes the state machine without wiring a UI banner —
/// phase 2 brings the auto-reconnect scanner + snackbar UX.
class TripRecordingController {
  final Obd2Service _service;
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

  /// Vehicle id tagged on paused snapshots + trip-history finalisations
  /// (#797 phase 1). The controller itself doesn't know about the
  /// Riverpod-backed active vehicle profile; the provider passes it
  /// through at construction so the paused-trips box row carries it.
  final String? _vehicleId;

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

  /// Optional override — tests inject an in-memory box via a fake
  /// repo so they don't have to spin up the real Hive box. Production
  /// passes null and the controller resolves the box lazily from
  /// [HiveBoxes.obd2PausedTrips] when a drop actually occurs.
  final PausedTripRepository? _pausedRepoOverride;

  /// Optional override — tests inject a lightweight fake that skips
  /// the Hive round-trip when auto-finalising a paused trip after the
  /// grace window elapses. Production uses [TripHistoryRepository]
  /// against the `obd2_trip_history` Hive box.
  final TripHistoryRepository? _historyRepoOverride;

  /// Grace window before a paused-due-to-drop session auto-finalises
  /// (#797 phase 1). Defaults to 15 minutes — long enough for a
  /// toll-booth stop, short enough that a forgotten session can't
  /// clog up the paused-trips box forever. Tests pass small values
  /// (e.g. 100 ms) to exercise the auto-finalise path.
  final Duration _pauseGraceWindow;

  /// Sliding window used for the "3 consecutive transport errors"
  /// heuristic (#797 phase 1). The counter resets on every successful
  /// read. Override for tests that want to pin the exact threshold.
  final Duration _dropWindow;
  final int _dropThreshold;

  final StreamController<TripLiveReading> _liveController =
      StreamController<TripLiveReading>.broadcast();

  final StreamController<TripRecordingControllerState> _stateController =
      StreamController<TripRecordingControllerState>.broadcast();

  PidScheduler? _scheduler;
  Timer? _emitTimer;
  Timer? _graceTimer;
  DateTime? _startedAt;
  DateTime? _lastSampleAt;
  double? _odometerStartKm;
  double? _odometerLatestKm;
  double _fuelLitersSoFar = 0;
  bool _fuelRateSeen = false;
  bool _paused = false;
  bool _pausedDueToDrop = false;
  bool _started = false;
  bool _stopped = false;
  String? _sessionId; // ISO start-ts, stable across pause→resume cycles

  /// Consecutive-error bookkeeping for the drop heuristic. First entry
  /// is the oldest. Reset on a successful transport read.
  final List<DateTime> _recentErrors = <DateTime>[];

  /// Latest parsed values, keyed by PID command. Written by scheduler
  /// callbacks, read by [_emit] when assembling [TripLiveReading]. Not
  /// using a typed struct because most fields are optional doubles
  /// and adding a freezed class for this scratch space buys nothing.
  double? _latestSpeedKmh;
  double? _latestRpm;
  double? _latestMaf;
  double? _latestMapKpa;
  double? _latestIatCelsius;
  double? _latestThrottlePercent;
  double? _latestEngineLoadPercent;
  double? _latestFuelLevelPercent;
  double? _latestStft;
  double? _latestLtft;
  double? _latestDirectFuelRate;
  String? _vin;

  TripRecordingController({
    required Obd2Service service,
    TripRecorder? recorder,
    Duration pollInterval = const Duration(milliseconds: 250),
    DateTime Function()? now,
    VehicleProfile? vehicle,
    String? vehicleId,
    PidScheduler? scheduler,
    PausedTripRepository? pausedRepo,
    TripHistoryRepository? historyRepo,
    Duration pauseGraceWindow = const Duration(minutes: 15),
    Duration dropWindow = const Duration(seconds: 5),
    int dropThreshold = 3,
    Duration schedulerTickRate = const Duration(milliseconds: 100),
  })  : _service = service,
        _recorder = recorder ?? TripRecorder(),
        _pollInterval = pollInterval,
        _now = now ?? DateTime.now,
        _vehicle = vehicle,
        _vehicleId = vehicleId,
        _schedulerOverride = scheduler,
        _pausedRepoOverride = pausedRepo,
        _historyRepoOverride = historyRepo,
        _pauseGraceWindow = pauseGraceWindow,
        _dropWindow = dropWindow,
        _dropThreshold = dropThreshold,
        _schedulerTickRate = schedulerTickRate;

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
    return TripRecordingControllerState.recording;
  }

  bool get isRecording => _started && !_paused && !_pausedDueToDrop;
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
      _graceTimer?.cancel();
      _graceTimer = null;
      _pausedDueToDrop = false;
      // Clear the paused-trips box row — the session is live again,
      // so leaving the partial behind would let a subsequent pause
      // stomp over the in-memory state. Best-effort.
      final id = _sessionId;
      if (id != null) {
        final repo = _resolvePausedRepo();
        repo?.delete(id);
      }
    }
    _paused = false;
    _scheduler?.start();
    _emitState();
  }

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
    _subscribeAllTiers(_scheduler!);
    _scheduler!.start();

    _emitTimer = Timer.periodic(_pollInterval, (_) => _emit());
    _emitState();
  }

  /// Stop the polling loop and return the accumulated summary.
  /// Idempotent — calling twice returns the same summary.
  Future<TripSummary> stop() async {
    _scheduler?.stop();
    _emitTimer?.cancel();
    _emitTimer = null;
    _graceTimer?.cancel();
    _graceTimer = null;
    _started = false;
    _stopped = true;
    _pausedDueToDrop = false;
    _emitState();
    if (!_stateController.isClosed) {
      await _stateController.close();
    }
    if (!_liveController.isClosed) {
      await _liveController.close();
    }
    return _recorder.buildSummary();
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
      final response = await _service.sendCommand(command);
      // A clean read is the only signal strong enough to clear the
      // error window; ELM327 NO DATA responses come back via the
      // response string, not an exception.
      _recentErrors.clear();
      return response;
    } catch (e) {
      _registerTransportError(e);
      rethrow;
    }
  }

  void _registerTransportError(Object error) {
    if (_pausedDueToDrop || _stopped) return;
    final now = _now();
    _recentErrors.add(now);
    // Keep only errors inside the window so the heuristic doesn't
    // count a ten-minute-old blip.
    _recentErrors.removeWhere(
      (ts) => now.difference(ts) > _dropWindow,
    );
    final typedDisconnect = _isTypedDisconnect(error);
    if (typedDisconnect || _recentErrors.length >= _dropThreshold) {
      _handleDrop();
    }
  }

  bool _isTypedDisconnect(Object error) {
    if (error is Obd2DisconnectedException) return true;
    // The live Bluetooth transport throws `StateError('Transport
    // closed')` once its channel is shut down by the OS / user.
    // Match by message so the controller works against the real
    // implementation without reaching into platform-specific
    // exception types.
    if (error is StateError) {
      final msg = error.message.toLowerCase();
      if (msg.contains('transport closed')) return true;
      if (msg.contains('not connected')) return true;
    }
    return false;
  }

  void _handleDrop() {
    if (_pausedDueToDrop) return;
    _pausedDueToDrop = true;
    _scheduler?.stop();
    _recentErrors.clear();
    _persistPausedSnapshot();
    _graceTimer?.cancel();
    _graceTimer = Timer(_pauseGraceWindow, _onGraceWindowElapsed);
    _emitState();
  }

  void _persistPausedSnapshot() {
    final repo = _resolvePausedRepo();
    final id = _sessionId;
    if (repo == null || id == null) return;
    final summary = _recorder.buildSummary();
    final entry = PausedTripEntry(
      id: id,
      vehicleId: _vehicleId,
      vin: _vin,
      summary: summary,
      odometerStartKm: _odometerStartKm,
      odometerLatestKm: _odometerLatestKm,
      pausedAt: _now(),
    );
    // Fire-and-forget: the save is best-effort; Hive errors are
    // logged by the repo and must not throw back into the scheduler
    // callback.
    repo.save(entry);
  }

  Future<void> _onGraceWindowElapsed() async {
    if (!_pausedDueToDrop) return;
    final id = _sessionId;
    final repo = _resolvePausedRepo();
    final historyRepo = _resolveHistoryRepo();
    final summary = _recorder.buildSummary();
    if (historyRepo != null && id != null) {
      try {
        await historyRepo.save(TripHistoryEntry(
          id: id,
          vehicleId: _vehicleId,
          summary: summary,
        ));
      } catch (e) {
        debugPrint('TripRecordingController grace finalise failed: $e');
      }
    }
    if (repo != null && id != null) {
      await repo.delete(id);
    }
    _pausedDueToDrop = false;
    _stopped = true;
    _started = false;
    _graceTimer = null;
    _emitState();
  }

  PausedTripRepository? _resolvePausedRepo() {
    final override = _pausedRepoOverride;
    if (override != null) return override;
    if (!Hive.isBoxOpen(HiveBoxes.obd2PausedTrips)) return null;
    try {
      return PausedTripRepository(
        box: Hive.box<String>(HiveBoxes.obd2PausedTrips),
      );
    } catch (e) {
      debugPrint('TripRecordingController paused repo: $e');
      return null;
    }
  }

  TripHistoryRepository? _resolveHistoryRepo() {
    final override = _historyRepoOverride;
    if (override != null) return override;
    if (!Hive.isBoxOpen(TripHistoryRepository.boxName)) return null;
    try {
      return TripHistoryRepository(
        box: Hive.box<String>(TripHistoryRepository.boxName),
      );
    } catch (e) {
      debugPrint('TripRecordingController history repo: $e');
      return null;
    }
  }

  void _emitState() {
    if (_stateController.isClosed) return;
    _stateController.add(currentState);
  }

  void _subscribeAllTiers(PidScheduler scheduler) {
    // ---- 5 Hz tier (high priority) --------------------------------
    // RPM and speed are consumed directly by TripSample → TripRecorder
    // for distance/idle/harsh-accel accumulation, so they need the
    // highest refresh we can squeeze out of the adapter.
    scheduler.subscribe(
      Elm327Protocol.engineRpmCommand,
      ScheduledPid(hz: 5.0, priority: PidPriority.high),
      (r) {
        final v = Elm327Protocol.parseEngineRpm(r);
        if (v != null) _latestRpm = v;
      },
    );
    scheduler.subscribe(
      Elm327Protocol.vehicleSpeedCommand,
      ScheduledPid(hz: 5.0, priority: PidPriority.high),
      (r) {
        final v = Elm327Protocol.parseVehicleSpeed(r);
        if (v != null) _latestSpeedKmh = v.toDouble();
      },
    );
    // MAF and MAP are the two alternate air-mass inputs to the fuel-
    // rate derivation. Cheap cars (Peugeot 107) only have MAP+IAT;
    // modern cars expose MAF. We subscribe both and let the snapshot-
    // based derivation pick whichever landed most recently.
    if (_service.supportsPid(0x10)) {
      scheduler.subscribe(
        Elm327Protocol.mafCommand,
        ScheduledPid(hz: 5.0, priority: PidPriority.high),
        (r) {
          final v = Elm327Protocol.parseMafGramsPerSecond(r);
          if (v != null) _latestMaf = v;
        },
      );
    }
    if (_service.supportsPid(0x0B)) {
      scheduler.subscribe(
        Elm327Protocol.intakeManifoldPressureCommand,
        ScheduledPid(hz: 5.0, priority: PidPriority.high),
        (r) {
          final v = Elm327Protocol.parseManifoldPressureKpa(r);
          if (v != null) _latestMapKpa = v;
        },
      );
    }
    scheduler.subscribe(
      Elm327Protocol.throttlePositionCommand,
      ScheduledPid(hz: 5.0, priority: PidPriority.high),
      (r) {
        final v = Elm327Protocol.parseThrottlePercent(r);
        if (v != null) _latestThrottlePercent = v;
      },
    );
    // PID 5E is only present on ~2014+ ECUs. Skip when #811 discovery
    // already proved the car rejects it, to save the 200 ms round-
    // trip of a guaranteed NO DATA.
    if (_service.supportsPid(0x5E)) {
      scheduler.subscribe(
        Elm327Protocol.engineFuelRateCommand,
        ScheduledPid(hz: 5.0, priority: PidPriority.high),
        (r) {
          final v = Elm327Protocol.parseFuelRateLPerHour(r);
          if (v != null) _latestDirectFuelRate = v;
        },
      );
    }

    // ---- 1 Hz tier (medium priority) ------------------------------
    scheduler.subscribe(
      Elm327Protocol.engineLoadCommand,
      ScheduledPid(hz: 1.0),
      (r) {
        final v = Elm327Protocol.parseEngineLoad(r);
        if (v != null) _latestEngineLoadPercent = v;
      },
    );
    scheduler.subscribe(
      Elm327Protocol.intakeAirTempCommand,
      ScheduledPid(hz: 1.0),
      (r) {
        final v = Elm327Protocol.parseIntakeAirTempCelsius(r);
        if (v != null) _latestIatCelsius = v;
      },
    );
    scheduler.subscribe(
      Elm327Protocol.shortTermFuelTrimCommand,
      ScheduledPid(hz: 1.0),
      (r) {
        final v = Elm327Protocol.parseShortTermFuelTrim(r);
        if (v != null) _latestStft = v;
      },
    );
    scheduler.subscribe(
      Elm327Protocol.longTermFuelTrimCommand,
      ScheduledPid(hz: 1.0),
      (r) {
        final v = Elm327Protocol.parseLongTermFuelTrim(r);
        if (v != null) _latestLtft = v;
      },
    );

    // ---- 0.1 Hz tier (low priority) -------------------------------
    scheduler.subscribe(
      Elm327Protocol.fuelTankLevelCommand,
      ScheduledPid(hz: 0.1, priority: PidPriority.low),
      (r) {
        final v = Elm327Protocol.parseFuelLevelPercent(r);
        if (v != null) _latestFuelLevelPercent = v;
      },
    );
  }

  /// Read the VIN exactly once at [start]. Wrapped so the one-shot
  /// decision is visible to readers of [start] — if we ever need to
  /// re-read mid-trip (e.g. user hot-swaps cars) this is the place
  /// to add the timer. Returns null on NO DATA / malformed response.
  Future<String?> _readVinOnce() async {
    try {
      final raw = await _service.sendCommand(Elm327Protocol.vinCommand);
      return Elm327Protocol.parseVin(raw);
    } catch (e) {
      debugPrint('TripRecordingController VIN read failed: $e');
      return null;
    }
  }

  /// Called by the debounced emit timer. Snapshots current state into
  /// a [TripLiveReading], integrates any new fuel/distance since the
  /// last emit, and pushes to [live].
  void _emit() {
    if (_paused || _pausedDueToDrop) return; // don't flood while paused
    if (_liveController.isClosed) return;

    final nowTs = _now();
    final fuelRate = _deriveFuelRateLPerHour();
    // The recorder integrates fuel rate and Δt itself, so we only
    // hand it one TripSample per emit — not per PID callback. At a
    // 250 ms emit cadence that's 4 Hz into the recorder, matching
    // the pre-#814 1 Hz loop's behavior closely enough that the
    // distance/fuelLitersConsumed integration is unchanged.
    if (_latestSpeedKmh != null || _latestRpm != null) {
      _recorder.onSample(TripSample(
        timestamp: nowTs,
        speedKmh: _latestSpeedKmh ?? 0,
        rpm: _latestRpm ?? 0,
        fuelRateLPerHour: fuelRate,
      ));
      _lastSampleAt = nowTs;
    }
    if (fuelRate != null) {
      _fuelRateSeen = true;
      _fuelLitersSoFar =
          (_recorder.buildSummary().fuelLitersConsumed) ?? _fuelLitersSoFar;
    }
    final reading = TripLiveReading(
      speedKmh: _latestSpeedKmh,
      rpm: _latestRpm,
      fuelRateLPerHour: fuelRate,
      fuelLevelPercent: _latestFuelLevelPercent,
      engineLoadPercent: _latestEngineLoadPercent,
      throttlePercent: _latestThrottlePercent,
      distanceKmSoFar: _recorder.buildSummary().distanceKm,
      fuelLitersSoFar: _fuelRateSeen ? _fuelLitersSoFar : null,
      elapsed: nowTs.difference(_startedAt ?? nowTs),
      odometerStartKm: _odometerStartKm,
      odometerNowKm: _odometerLatestKm,
    );
    _liveController.add(reading);
  }

  /// Derive the current fuel rate (L/h) from whatever snapshot
  /// values have landed so far. Mirrors the tier-1/2/3 fallback in
  /// [Obd2Service.readFuelRateLPerHour], but over snapshot values
  /// instead of live I/O — the scheduler has already done the
  /// reads. Returns null when not enough inputs have arrived yet
  /// (e.g. first 200 ms of a trip before MAP/IAT both land).
  double? _deriveFuelRateLPerHour() {
    // Step 1: direct PID 5E. Already post-trim, no correction.
    final direct = _latestDirectFuelRate;
    if (direct != null) return direct;

    // Step 2: MAF-based. Stoich petrol: AFR 14.7, density 740 g/L.
    final maf = _latestMaf;
    if (maf != null) {
      final raw = maf * 3600.0 / (14.7 * 740.0);
      return _applyTrim(raw);
    }

    // Step 3: speed-density from MAP+IAT+RPM. Feeds the pre-#810
    // estimator with the active vehicle's displacement + VE (#812).
    final mapKpa = _latestMapKpa;
    final iat = _latestIatCelsius;
    final rpm = _latestRpm;
    if (mapKpa == null || iat == null || rpm == null) return null;
    final raw = Obd2Service.estimateFuelRateLPerHourFromMap(
      mapKpa: mapKpa,
      iatCelsius: iat,
      rpm: rpm,
      engineDisplacementCc: _vehicle?.engineDisplacementCc ?? 1000,
      volumetricEfficiency: _vehicle?.volumetricEfficiency ?? 0.85,
    );
    if (raw == null) return null;
    return _applyTrim(raw);
  }

  /// Apply the STFT + LTFT correction used on the MAF / speed-density
  /// branches (#813). Returns [raw] unchanged when either trim hasn't
  /// landed yet — better an uncorrected estimate than one shifted by
  /// half the real signal.
  double _applyTrim(double raw) {
    final stft = _latestStft;
    final ltft = _latestLtft;
    if (stft == null || ltft == null) return raw;
    return Obd2Service.applyFuelTrimCorrection(raw, stft: stft, ltft: ltft);
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
  /// times in a row still exercise the state transition.
  @visibleForTesting
  void debugTriggerDrop() {
    _handleDrop();
  }

  /// Exposed for tests: synchronously drive the grace-window
  /// finalisation path. Useful with fake-async patterns where
  /// elapsing real wall-clock time is awkward.
  @visibleForTesting
  Future<void> debugExpireGraceWindow() async {
    _graceTimer?.cancel();
    await _onGraceWindowElapsed();
  }

  /// Exposed for tests: inject a hand-crafted [TripSample] directly
  /// into the underlying [TripRecorder]. Used by the #797 phase 1
  /// tests to accumulate captured data deterministically without
  /// driving the scheduler + parsers end-to-end.
  @visibleForTesting
  void debugInjectSample({
    required double speedKmh,
    required double rpm,
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
}
