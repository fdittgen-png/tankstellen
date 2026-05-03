import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../../core/storage/hive_boxes.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../domain/services/gear_inference.dart';
import '../../domain/trip_recorder.dart';
import '../trip_history_repository.dart';
import 'adapter_reconnect_scanner.dart';
import 'elm327_protocol.dart';
import 'obd2_breadcrumb_collector.dart';
import 'obd2_connection_errors.dart';
import 'obd2_service.dart';
import 'paused_trip_repository.dart';
import 'pid_scheduler.dart';
import 'trip_distance_source.dart';
import 'trip_live_reading.dart';
import 'virtual_odometer.dart';

// Re-export the DTO + distance-source constants so existing callers
// (providers, widget tests) that import this file keep working after
// the #563 controller-split refactor. New callers should import the
// individual files directly.
export 'trip_distance_source.dart'
    show kDistanceSourceReal, kDistanceSourceVirtual;
export 'trip_live_reading.dart' show TripLiveReading;

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
/// phase 3 (#797) wires an [AdapterReconnectScanner] into
/// [_handleDrop]: while the controller is in
/// [TripRecordingControllerState.pausedDueToDrop] the scanner
/// periodically probes for the pinned adapter's MAC. On a
/// reconnect the scanner fires [TripRecordingController.resume]
/// and the grace timer is cancelled before the window elapses.
enum TripRecordingControllerState {
  idle,
  recording,
  paused,
  pausedDueToDrop,
  stopped,
}

/// Why the controller transitioned into
/// [TripRecordingControllerState.pausedDueToDrop] (#1330 phase 3).
///
/// Distinguishes the two failure modes that share the
/// pause-with-grace recovery path:
///
///  * [transportError] — repeated transport-level failures
///    (BT link dropped, three consecutive errors within the window,
///    or a typed `Obd2DisconnectedException`). The user-visible
///    surface is "OBD2 connection lost".
///  * [silentFailure] — adapter is connected and answering, but every
///    high-priority PID parse returns null for [_silentFailureThreshold]
///    consecutive ticks. ECU off, vehicle protocol mismatch, defective
///    adapter firmware. Without this signal the user sees "trip
///    recorded" with empty charts and no notification (#1330).
enum TripDropReason {
  transportError,
  silentFailure,
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

  /// Whether this recording was kicked off by the hands-free
  /// [AutoTripCoordinator] (#1004 phase 4-WAL). Plumbed through to the
  /// persisted [PausedTripEntry] so the launch-time recovery service
  /// can decide whether to bump the launcher-icon badge when it
  /// finalises a stale entry — manual trips never counted toward
  /// "unseen" and must not retroactively start counting just because
  /// the app was killed before the disconnect-save timer fired.
  final bool _automatic;

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

  /// Threshold for the "adapter connected but every PID parse returns
  /// null" silent-failure heuristic (#1330 phase 3). At the 5 Hz fast
  /// tier 50 consecutive null parses ≈ 10 s — long enough to ride out a
  /// brief noise burst, short enough that the user gets a notification
  /// before they've driven a meaningful distance with no data.
  /// Test-only: tests inject a small value (e.g. 3) so a fake service
  /// can drive the counter past the threshold without 50 round-trips.
  final int _silentFailureThreshold;

  /// Pinned adapter MAC that the auto-reconnect scanner (#797 phase 3)
  /// will search for when a drop flips us into
  /// [TripRecordingControllerState.pausedDueToDrop]. Null-able
  /// because the vehicle profile may not carry an adapter pairing
  /// yet (fresh profiles, or users who never ran the picker). When
  /// null the scanner is not started and the grace-window path
  /// remains the only recovery mechanism.
  final String? _pinnedAdapterMac;

  /// Factory used by [_handleDrop] to construct the reconnect
  /// scanner (#797 phase 3). Takes the pinned MAC + the callback to
  /// fire on reconnect and returns a fresh scanner. Tests inject a
  /// fake factory that returns an in-memory scanner with a clock
  /// they control; production passes null and the controller builds
  /// nothing — wiring the real BT scan layer is the provider's job.
  final AdapterReconnectScanner? Function(
    String pinnedMac,
    VoidCallback onReconnect,
  )? _reconnectScannerFactory;

  AdapterReconnectScanner? _reconnectScanner;

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

  /// Consecutive-null-parse counter for the silent-failure heuristic
  /// (#1330 phase 3). Incremented from every high-priority PID
  /// callback when the parser returns null; reset to zero the moment
  /// any high-priority PID parses a non-null value. Distinct from
  /// [_recentErrors] which counts *transport-level* failures —
  /// silent-failure is the case where the transport is healthy but
  /// the ECU never speaks.
  int _consecutiveNullReads = 0;

  /// Sticky flag so the silent-failure handler only fires once per
  /// recording session — even if more null parses keep arriving past
  /// the threshold, we don't want to keep re-entering [_handleDrop].
  /// Reset on stop()/resume() so a subsequent recording (or a manual
  /// resume followed by another silent stretch) can fire again.
  bool _silentFailureFired = false;

  /// Reason the most recent [_handleDrop] fired (#1330 phase 3).
  /// Null when no drop has occurred. Read by the provider so the
  /// pause banner can surface a different message on silent-failure
  /// vs transport-error.
  TripDropReason? _dropReason;

  /// Why the controller flipped into
  /// [TripRecordingControllerState.pausedDueToDrop] (#1330 phase 3).
  /// Null when the controller is not in that state.
  TripDropReason? get dropReason => _dropReason;

  /// Rolling buffer of `(timestamp, speedKmh)` samples used by the
  /// virtual odometer (#800). Populated by the 5 Hz speed
  /// subscription callback; capped at [_virtualOdometerSampleCap] so
  /// a forgotten recording can't eat unbounded memory. Fed to
  /// [VirtualOdometer] at finalisation when the car doesn't expose a
  /// real odometer.
  final List<VirtualOdometerSample> _speedSamples = <VirtualOdometerSample>[];

  /// Per-tick sample buffer used by the trip-detail charts (#1040).
  /// Decimated to ~1 Hz inside [_emit] — the user-facing charts don't
  /// need the 4 Hz emit cadence, and 1 Hz × 8 fields keeps a 39-min
  /// trip's payload well under 20 KB compressed. Capped at
  /// [_capturedSampleCap] so a forgotten recording can't eat unbounded
  /// memory; the cap covers a 33-hour drive at 1 Hz which is more
  /// than enough headroom.
  final List<TripSample> _capturedSamples = <TripSample>[];

  /// Timestamp of the most recently *captured* (decimated) sample.
  /// Distinct from [_lastSampleAt] which tracks the recorder feed at
  /// the full 4 Hz emit cadence.
  DateTime? _lastCapturedAt;

  /// Cap on the captured-sample buffer (#1040). 120000 samples = 33 h
  /// at 1 Hz — comfortably above any plausible single trip — so this
  /// only kicks in if the user forgets to stop a recording overnight.
  static const int _capturedSampleCap = 120000;

  /// Read-only snapshot of the captured sample buffer (#1040). The
  /// list is unmodifiable so callers can't accidentally mutate the
  /// controller's state — the provider clones it into the persisted
  /// [TripHistoryEntry] at stop time.
  List<TripSample> get capturedSamples => List.unmodifiable(_capturedSamples);

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
  double? _latestCoolantTempC;
  double? _latestFuelLevelPercent;
  double? _latestStft;
  double? _latestLtft;
  double? _latestDirectFuelRate;
  String? _vin;

  // #1374 phase 1 — most recent GPS fix, pushed in by the provider
  // when the `Feature.gpsTripPath` flag is enabled. The controller
  // does NOT subscribe to Geolocator itself — that decision lives at
  // the provider layer so the controller stays free of plugin
  // imports and tests can drive the latch with hand-built doubles.
  // When the flag is off the provider never calls [updateGpsFix],
  // both fields stay null, and every persisted sample carries
  // `latitude: null, longitude: null` (matching pre-#1374 behaviour
  // bit-for-bit). When the flag is on but no fix has landed yet
  // (cold-start, indoors, permission revoked), the fields are also
  // null and the corresponding sample is written with both keys
  // absent — better than failing the trip.
  double? _latestLatitude;
  double? _latestLongitude;

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
    int silentFailureThreshold = 50,
    Duration schedulerTickRate = const Duration(milliseconds: 100),
    String? pinnedAdapterMac,
    bool automatic = false,
    AdapterReconnectScanner? Function(
      String pinnedMac,
      VoidCallback onReconnect,
    )? reconnectScannerFactory,
    Obd2BreadcrumbRecorder? breadcrumbCollector,
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
        _silentFailureThreshold = silentFailureThreshold,
        _schedulerTickRate = schedulerTickRate,
        _pinnedAdapterMac = pinnedAdapterMac,
        _automatic = automatic,
        _reconnectScannerFactory = reconnectScannerFactory,
        _breadcrumbCollector = breadcrumbCollector;

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
      _dropReason = null;
      // #1330 phase 3 — clear the silent-failure latch so a
      // post-resume stretch of nulls can fire again. Without this,
      // a user who resumes after a silent-failure drop and then hits
      // a fresh silent failure would never get a second snackbar.
      _silentFailureFired = false;
      _consecutiveNullReads = 0;
      // Also tear down the auto-reconnect scanner (#797 phase 3) —
      // either we got here because the scanner fired its callback
      // (in which case it already stopped itself), or the user
      // tapped "Resume" manually on the pause banner before the
      // scanner reconnected. Either way, no scanner should survive
      // the resume transition.
      unawaited(_stopReconnectScanner());
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
  void updateGpsFix({double? latitude, double? longitude}) {
    _latestLatitude = latitude;
    _latestLongitude = longitude;
  }

  /// Read-only snapshot of the most recent GPS latitude pushed in via
  /// [updateGpsFix] (#1374 phase 1). Exposed for tests + diagnostics;
  /// production reads the value through the persisted [TripSample]
  /// fields, not this getter.
  @visibleForTesting
  double? get debugLatestLatitude => _latestLatitude;

  /// Read-only snapshot of the most recent GPS longitude pushed in via
  /// [updateGpsFix] (#1374 phase 1). Same caveats as
  /// [debugLatestLatitude].
  @visibleForTesting
  double? get debugLatestLongitude => _latestLongitude;

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
  ///
  /// The returned [TripSummary] carries the final [currentDistanceKm]
  /// (#800) — which prefers the real odometer delta over the recorder's
  /// integrated-speed number — and a [TripSummary.distanceSource] flag
  /// distinguishing the two. This lets the fill-up flow and analytics
  /// decide whether the km figure is ground truth or an estimate.
  Future<TripSummary> stop() async {
    _scheduler?.stop();
    _emitTimer?.cancel();
    _emitTimer = null;
    _graceTimer?.cancel();
    _graceTimer = null;
    await _stopReconnectScanner();
    _started = false;
    _stopped = true;
    _pausedDueToDrop = false;
    _silentFailureFired = false;
    _consecutiveNullReads = 0;
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
    // Recompute avgLPer100Km if we swapped the distance out — the
    // recorder's value was keyed to its own integrated distance.
    double? avg = base.avgLPer100Km;
    if (base.fuelLitersConsumed != null && distanceKm > 0.001) {
      avg = base.fuelLitersConsumed! / distanceKm * 100.0;
    } else if (base.fuelLitersConsumed == null) {
      avg = null;
    }
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
    return TripSummary(
      distanceKm: distanceKm,
      maxRpm: base.maxRpm,
      highRpmSeconds: base.highRpmSeconds,
      idleSeconds: base.idleSeconds,
      harshBrakes: base.harshBrakes,
      harshAccelerations: base.harshAccelerations,
      avgLPer100Km: avg,
      fuelLitersConsumed: base.fuelLitersConsumed,
      startedAt: base.startedAt,
      endedAt: base.endedAt,
      distanceSource: source,
      secondsBelowOptimalGear: _computeGearCoachingMetric(),
      fuelRateSuspect: fuelRateSuspect,
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
    if (_capturedSamples.isEmpty) return null;
    final tireC = vehicle.tireCircumferenceMeters;
    if (tireC <= 0) return null;
    final result = inferGears(
      samples: _capturedSamples,
      tireCircumferenceMeters: tireC,
      priorCentroids: vehicle.gearCentroids,
    );
    if (result.centroids.length < 2) return null;
    return computeSecondsBelowOptimalGear(
      gearAssignments: result.samples
          .map((s) => (timestamp: s.timestamp, gear: s.gear))
          .toList(growable: false),
      optimalRpmCeiling: _optimalRpmCeiling,
      samples: _capturedSamples,
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
  /// Prefers the ground truth `odometerLatest - odometerStart` when
  /// both readings are present AND moved forward by more than a
  /// noise-floor epsilon (odometer PIDs are quantised to 0.1 km on
  /// most cars — a 0.09-km delta on a 20-minute trip is a sensor
  /// artefact, not real distance). When the odometer isn't readable
  /// (Peugeot 107 class), falls back to the trapezoidal integral of
  /// buffered speed samples via [VirtualOdometer].
  double get currentDistanceKm {
    final real = _realOdometerDeltaKm();
    if (real != null) return real;
    return VirtualOdometer(samples: _speedSamples).integrateKm();
  }

  /// `'real'` when [currentDistanceKm] came from the car's odometer,
  /// `'virtual'` when it came from [VirtualOdometer] integration
  /// (#800). Persisted on the finalised [TripSummary] so the fill-up
  /// flow and eco-analytics know whether to treat the km as a ground
  /// truth or as an estimate.
  String get distanceSource =>
      _realOdometerDeltaKm() != null
          ? kDistanceSourceReal
          : kDistanceSourceVirtual;

  /// `odometerLatest - odometerStart` if both are present and the
  /// delta is above a small noise-floor epsilon (0.05 km — half the
  /// 0.1 km quantisation most cars apply to PID A6). Returns null
  /// otherwise so callers can fall back to the virtual odometer.
  double? _realOdometerDeltaKm() {
    final start = _odometerStartKm;
    final latest = _odometerLatestKm;
    if (start == null || latest == null) return null;
    final delta = latest - start;
    if (delta < 0.05) return null;
    return delta;
  }

  /// Append a speed sample to the virtual-odometer buffer, dropping
  /// the oldest entry when the cap is hit. Called from the 5 Hz
  /// vehicle-speed subscription.
  void _recordSpeedSample(double speedKmh) {
    _speedSamples.add(VirtualOdometerSample(
      timestamp: _now(),
      speedKmh: speedKmh,
    ));
    if (_speedSamples.length > kVirtualOdometerSampleCap) {
      // Drop the oldest slice to keep memory bounded. Losing the
      // early stretch biases the virtual-odometer low by the km we
      // dropped; on a typical trip the cap is never hit.
      _speedSamples.removeRange(
        0,
        _speedSamples.length - kVirtualOdometerSampleCap,
      );
    }
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
    } catch (e, st) { // ignore: unused_catch_stack
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

  /// Bookkeeping for the silent-failure heuristic (#1330 phase 3).
  ///
  /// Called from every high-priority PID callback right after the
  /// parser returned. A null parse increments the consecutive-null
  /// counter; ANY non-null parse resets it to zero — even from a
  /// different PID, because we're trying to detect "ECU is dead",
  /// not "this specific PID is unsupported".
  ///
  /// Once the counter reaches [_silentFailureThreshold] AND the
  /// transport-error drop hasn't already fired, [_onSilentFailure]
  /// drives the same pause-with-grace path that [_handleDrop] does
  /// for transport errors, but stamps a [TripDropReason.silentFailure]
  /// reason so the UI can surface a different message.
  void _observeHighPriorityParse(Object? parsedValue) {
    if (parsedValue != null) {
      // ANY successful high-priority parse clears the window — we're
      // detecting "ECU is dead", not "this one PID is unsupported".
      _consecutiveNullReads = 0;
      return;
    }
    if (_silentFailureFired) return;
    if (_pausedDueToDrop || _stopped) return;
    _consecutiveNullReads++;
    if (_consecutiveNullReads >= _silentFailureThreshold) {
      _onSilentFailure();
    }
  }

  /// Silent-failure handler (#1330 phase 3). Fired exactly once per
  /// recording session when the consecutive-null counter crosses the
  /// threshold. Drives the same pause-with-grace recovery as
  /// [_handleDrop] for transport errors, but tags the drop with
  /// [TripDropReason.silentFailure] so the UI surfaces "OBD2 adapter
  /// connected but not returning data" instead of "OBD2 connection
  /// lost".
  void _onSilentFailure() {
    if (_silentFailureFired) return;
    if (_pausedDueToDrop || _stopped) {
      // The transport-error drop already paused us — don't double-fire
      // and don't override the reason. The user is already seeing the
      // "connection lost" banner; switching it mid-flight to "not
      // responding" would be misleading.
      return;
    }
    _silentFailureFired = true;
    debugPrint(
      'TripRecordingController: silent-failure detected — '
      '$_consecutiveNullReads consecutive null PID parses',
    );
    _handleDrop(reason: TripDropReason.silentFailure);
  }

  void _handleDrop({
    TripDropReason reason = TripDropReason.transportError,
  }) {
    if (_pausedDueToDrop) return;
    _pausedDueToDrop = true;
    _dropReason = reason;
    _scheduler?.stop();
    _recentErrors.clear();
    _persistPausedSnapshot();
    _graceTimer?.cancel();
    _graceTimer = Timer(_pauseGraceWindow, _onGraceWindowElapsed);
    _startReconnectScanner();
    _emitState();
  }

  /// Kick off the auto-reconnect scanner (#797 phase 3) if both the
  /// vehicle profile has a pinned adapter MAC AND the provider wired
  /// in a scanner factory. No-op in either's absence — the grace
  /// timer remains the sole recovery path in that case.
  ///
  /// The [AdapterReconnectScanner]'s `onReconnect` callback is set
  /// to call [resume] here — which cancels the grace timer, clears
  /// the paused-trips row, and resumes the scheduler. Tests that
  /// want to observe the reconnect path can watch [stateChanges]
  /// for the recording → pausedDueToDrop → recording sequence.
  void _startReconnectScanner() {
    final mac = _pinnedAdapterMac;
    final factory = _reconnectScannerFactory;
    if (mac == null || factory == null) return;
    final scanner = factory(mac, _onScannerReconnect);
    if (scanner == null) return;
    _reconnectScanner = scanner;
    // Fire-and-forget — start() is an async scheduler boot that
    // shouldn't block the drop handler. Errors inside the scanner
    // are already caught internally.
    unawaited(scanner.start());
  }

  void _onScannerReconnect() {
    // The scanner self-stops before firing this callback, so we
    // don't need to call stop() here. Just resume the trip — the
    // ordinary resume() path cancels the grace timer and clears
    // the paused-trips row.
    _reconnectScanner = null;
    if (_pausedDueToDrop) resume();
  }

  Future<void> _stopReconnectScanner() async {
    final scanner = _reconnectScanner;
    if (scanner == null) return;
    _reconnectScanner = null;
    try {
      await scanner.stop();
    } catch (e, st) {
      debugPrint('TripRecordingController stop reconnect scanner: $e\n$st');
    }
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
      // #1004 phase 4-WAL — flag persists so the launch-time recovery
      // service knows whether to bump the launcher-icon badge if the
      // app is killed before the grace timer fires.
      automatic: _automatic,
    );
    // Fire-and-forget: the save is best-effort; Hive errors are
    // logged by the repo and must not throw back into the scheduler
    // callback.
    repo.save(entry);
  }

  Future<void> _onGraceWindowElapsed() async {
    if (!_pausedDueToDrop) return;
    // Stop the scanner before finalising — otherwise a late
    // reconnect would race against an already-finalised trip.
    await _stopReconnectScanner();
    final id = _sessionId;
    final repo = _resolvePausedRepo();
    final historyRepo = _resolveHistoryRepo();
    final summary = _finaliseSummary();
    if (historyRepo != null && id != null) {
      try {
        await historyRepo.save(TripHistoryEntry(
          id: id,
          vehicleId: _vehicleId,
          summary: summary,
        ));
      } catch (e, st) {
        debugPrint('TripRecordingController grace finalise failed: $e\n$st');
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
    } catch (e, st) {
      debugPrint('TripRecordingController paused repo: $e\n$st');
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
    } catch (e, st) {
      debugPrint('TripRecordingController history repo: $e\n$st');
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
        _observeHighPriorityParse(v);
      },
    );
    scheduler.subscribe(
      Elm327Protocol.vehicleSpeedCommand,
      ScheduledPid(hz: 5.0, priority: PidPriority.high),
      (r) {
        final v = Elm327Protocol.parseVehicleSpeed(r);
        if (v != null) {
          _latestSpeedKmh = v.toDouble();
          _recordSpeedSample(v.toDouble());
        }
        _observeHighPriorityParse(v);
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
          _observeHighPriorityParse(v);
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
          _observeHighPriorityParse(v);
        },
      );
    }
    scheduler.subscribe(
      Elm327Protocol.throttlePositionCommand,
      ScheduledPid(hz: 5.0, priority: PidPriority.high),
      (r) {
        final v = Elm327Protocol.parseThrottlePercent(r);
        if (v != null) _latestThrottlePercent = v;
        _observeHighPriorityParse(v);
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
          _observeHighPriorityParse(v);
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
    // Coolant temp drifts slowly — 1 Hz is more than enough resolution
    // for the cold-start surcharge heuristic (#1262 phase 2) to detect
    // whether the trip ever crossed operating temperature.
    scheduler.subscribe(
      Elm327Protocol.coolantTempCommand,
      ScheduledPid(hz: 1.0),
      (r) {
        final v = Elm327Protocol.parseCoolantTempCelsius(r);
        if (v != null) _latestCoolantTempC = v;
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
    } catch (e, st) {
      debugPrint('TripRecordingController VIN read failed: $e\n$st');
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
      final sample = TripSample(
        timestamp: nowTs,
        speedKmh: _latestSpeedKmh ?? 0,
        rpm: _latestRpm ?? 0,
        fuelRateLPerHour: fuelRate,
        throttlePercent: _latestThrottlePercent,
        engineLoadPercent: _latestEngineLoadPercent,
        coolantTempC: _latestCoolantTempC,
        // #1374 phase 1 — stamp the most recent GPS fix when the
        // provider has pushed one in. Both fields stay null when the
        // feature flag is off (no Geolocator subscription was ever
        // started) or before the first fix lands.
        latitude: _latestLatitude,
        longitude: _latestLongitude,
      );
      _recorder.onSample(sample);
      _lastSampleAt = nowTs;
      _maybeCaptureSample(sample);
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
      coolantTempC: _latestCoolantTempC,
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
  ///
  /// AFR + density are chosen from the active vehicle's preferred
  /// fuel type (#800). Diesel profiles get AFR 14.5 / density 832 g/L;
  /// anything else (including null / unknown) stays on the petrol
  /// defaults the pre-#800 path used.
  double? _deriveFuelRateLPerHour() {
    final preferredFuel =
        _vehicle?.preferredFuelType?.trim().toLowerCase() ?? '';
    final isDiesel = preferredFuel.contains('diesel');
    // #1397 — manual overrides take precedence over the inferred /
    // catalog-resolved values. Mirrors the resolution chain in
    // [Obd2Service.readFuelRateLPerHour] so the live integrator and the
    // pull-mode estimator agree on every scalar.
    final afr = _vehicle?.manualAfrOverride ??
        (isDiesel ? Obd2Service.dieselAfr : Obd2Service.petrolAfr);
    final density = _vehicle?.manualFuelDensityGPerLOverride ??
        (isDiesel
            ? Obd2Service.dieselDensityGPerL
            : Obd2Service.petrolDensityGPerL);
    final displacement = _vehicle?.manualEngineDisplacementCcOverride
            ?.round() ??
        _vehicle?.engineDisplacementCc ??
        1000;
    final ve = _vehicle?.manualVolumetricEfficiencyOverride ??
        _vehicle?.volumetricEfficiency ??
        0.85;
    final collector = _breadcrumbCollector;

    // Step 1: direct PID 5E. Already post-trim, no correction.
    final direct = _latestDirectFuelRate;
    if (direct != null) {
      // #1395 — sanity bound A: implausibly-low at non-idle RPM.
      // Same threshold as Obd2Service.readFuelRateLPerHour but evaluated
      // on the controller's most-recent RPM snapshot so this works
      // even when the trip is being driven by raw scheduler callbacks
      // rather than the readFuelRate API.
      String? lowFlag;
      String? lowDetail;
      final rpm = _latestRpm;
      if (direct < 0.3 && rpm != null && rpm > 1500) {
        lowFlag = Obd2BreadcrumbCollector.flagSuspiciousLow;
        lowDetail = 'directRate=${direct.toStringAsFixed(2)};'
            'rpm=${rpm.toStringAsFixed(0)}';
      }
      collector?.record(
        branch: Obd2BranchTag.pid5E,
        fuelRateLPerHour: direct,
        pid5ELPerHour: direct,
        rpm: rpm,
        afr: afr,
        fuelDensityGPerL: density,
        engineDisplacementCc: displacement.toDouble(),
        volumetricEfficiency: ve,
        flag: lowFlag,
        flagDetail: lowDetail,
      );
      // Sanity bound B: 5E vs MAF cross-check on the controller's
      // cached MAF snapshot. Evaluated AFTER the breadcrumb is
      // pushed so [recordFlag] mutates the same row.
      final mafSnapshot = _latestMaf;
      if (mafSnapshot != null) {
        final mafDerived = mafSnapshot * 3600.0 / (afr * density);
        if (mafDerived > 0 &&
            (direct - mafDerived).abs() / mafDerived > 0.5) {
          collector?.recordFlag(
            Obd2BreadcrumbCollector.flag5eVsMafDivergent,
            'direct=${direct.toStringAsFixed(2)};'
                'mafDerived=${mafDerived.toStringAsFixed(2)};'
                'maf=${mafSnapshot.toStringAsFixed(2)}',
          );
        }
      }
      return direct;
    }

    // Step 2: MAF-based. L/h = MAF × 3600 / (AFR × density).
    final maf = _latestMaf;
    if (maf != null) {
      final raw = maf * 3600.0 / (afr * density);
      final corrected = _applyTrim(raw);
      collector?.record(
        branch: Obd2BranchTag.maf,
        fuelRateLPerHour: corrected,
        mafGramsPerSecond: maf,
        rpm: _latestRpm,
        afr: afr,
        fuelDensityGPerL: density,
        engineDisplacementCc: displacement.toDouble(),
        volumetricEfficiency: ve,
      );
      return corrected;
    }

    // Step 3: speed-density from MAP+IAT+RPM. Feeds the pre-#810
    // estimator with the active vehicle's displacement + VE (#812).
    final mapKpa = _latestMapKpa;
    final iat = _latestIatCelsius;
    final rpm = _latestRpm;
    if (mapKpa == null || iat == null || rpm == null) {
      collector?.record(
        branch: Obd2BranchTag.none,
        mapKpa: mapKpa,
        iatCelsius: iat,
        rpm: rpm,
        afr: afr,
        fuelDensityGPerL: density,
        engineDisplacementCc: displacement.toDouble(),
        volumetricEfficiency: ve,
      );
      return null;
    }
    final raw = Obd2Service.estimateFuelRateLPerHourFromMap(
      mapKpa: mapKpa,
      iatCelsius: iat,
      rpm: rpm,
      engineDisplacementCc: displacement,
      volumetricEfficiency: ve,
      afr: afr,
      fuelDensityGPerL: density,
    );
    if (raw == null) {
      collector?.record(
        branch: Obd2BranchTag.none,
        mapKpa: mapKpa,
        iatCelsius: iat,
        rpm: rpm,
        afr: afr,
        fuelDensityGPerL: density,
        engineDisplacementCc: displacement.toDouble(),
        volumetricEfficiency: ve,
      );
      return null;
    }
    final corrected = _applyTrim(raw);
    collector?.record(
      branch: Obd2BranchTag.speedDensity,
      fuelRateLPerHour: corrected,
      mapKpa: mapKpa,
      iatCelsius: iat,
      rpm: rpm,
      afr: afr,
      fuelDensityGPerL: density,
      engineDisplacementCc: displacement.toDouble(),
      volumetricEfficiency: ve,
    );
    return corrected;
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

  /// Append [sample] to the captured-samples buffer when at least
  /// 1 second has elapsed since the previous capture. The 4 Hz emit
  /// loop drops 3 of every 4 candidate samples — the chart layer
  /// renders at 1 Hz and the storage budget is sized for that
  /// cadence (#1040).
  void _maybeCaptureSample(TripSample sample) {
    final last = _lastCapturedAt;
    if (last != null) {
      // Use 950 ms as the gate so a 1 Hz scheduler that's slightly
      // jittered (998 ms / 1003 ms) still captures every tick. Without
      // the slack a 998 ms gap would slip through the >=1000 check
      // and we'd silently halve the captured rate.
      if (sample.timestamp.difference(last).inMilliseconds < 950) return;
    }
    _capturedSamples.add(sample);
    _lastCapturedAt = sample.timestamp;
    if (_capturedSamples.length > _capturedSampleCap) {
      // Drop the oldest slice — losing the early stretch is preferable
      // to letting a forgotten overnight recording eat unbounded memory.
      _capturedSamples.removeRange(
        0,
        _capturedSamples.length - _capturedSampleCap,
      );
    }
  }

  /// Exposed for tests: append a sample to the captured-samples buffer
  /// without going through the scheduler / debounced emit timer
  /// (#1040). Tests use this to populate a deterministic buffer + then
  /// drive [TripRecording.stop] end-to-end.
  @visibleForTesting
  void debugCaptureSample(TripSample sample) {
    _capturedSamples.add(sample);
    _lastCapturedAt = sample.timestamp;
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
  int get debugConsecutiveNullReads => _consecutiveNullReads;

  /// Exposed for tests: whether the silent-failure handler has fired
  /// for this recording session. Resets on resume() / stop().
  @visibleForTesting
  bool get debugSilentFailureFired => _silentFailureFired;

  /// Exposed for tests: synchronously drive the grace-window
  /// finalisation path. Useful with fake-async patterns where
  /// elapsing real wall-clock time is awkward.
  @visibleForTesting
  Future<void> debugExpireGraceWindow() async {
    _graceTimer?.cancel();
    await _onGraceWindowElapsed();
  }

  /// Exposed for tests: the auto-reconnect scanner instance created
  /// by [_handleDrop] (#797 phase 3). Null when no scanner factory
  /// is wired in or no pinned MAC is known — also null again after
  /// a successful reconnect or a stop(), because the controller
  /// releases the reference as soon as it's no longer needed.
  @visibleForTesting
  AdapterReconnectScanner? get debugReconnectScanner => _reconnectScanner;

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

  /// Exposed for tests: append a speed sample to the virtual-odometer
  /// buffer without going through the scheduler (#800). Tests use
  /// this to pre-populate samples + call [currentDistanceKm] /
  /// [distanceSource] deterministically.
  @visibleForTesting
  void debugRecordSpeedSample({
    required double speedKmh,
    required DateTime at,
  }) {
    _speedSamples.add(
      VirtualOdometerSample(timestamp: at, speedKmh: speedKmh),
    );
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
      List.unmodifiable(_speedSamples);
}
