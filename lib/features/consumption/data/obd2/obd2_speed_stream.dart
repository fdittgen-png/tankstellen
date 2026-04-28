import 'dart:async';

import 'auto_record_trace_log.dart';
import 'obd2_service.dart';

/// Pure-Dart adapter that turns an open [Obd2Service] into a stream of
/// km/h doubles by polling PID 0x0D at a fixed cadence (#1004 phase
/// 2b-3).
///
/// Replaces the GPS-based `Geolocator.getPositionStream()` source the
/// `AutoTripCoordinator` used in phase 2b-2. Reading speed straight
/// from the ECU keeps the auto-record threshold tied to the same
/// signal the trip recorder will sample once a trip has started — no
/// double-counting GPS drift, no permission handshake on cold-boot.
///
/// ## Polling cadence
///
/// Defaults to 1 Hz (1 second between reads). The trip recorder polls
/// the same PID at higher rates once a trip is active; the coordinator
/// only needs to detect "the car started moving," for which 1 Hz is
/// plenty (3 consecutive samples = 3 s of >threshold motion = the
/// driver pulled out and is committed). Tests inject a shorter
/// [pollPeriod] to keep assertions fast.
///
/// ## Failure handling
///
/// `readSpeedKmh()` returns `null` when the adapter is mid-init, the
/// car is parked with the ECU asleep, or the OBD2 transport hiccups.
/// We treat null as silent (no emission) — the consecutive-supra
/// counter on the coordinator only counts emissions, so a string of
/// nulls is indistinguishable from "engine idle." When [
/// failureLogThreshold] consecutive nulls accumulate we log once via
/// [AutoRecordTraceLog] so a flaky link is debuggable. The counter
/// resets on the next successful read.
///
/// ## Lifecycle
///
/// [stream] is a single-subscription stream — the coordinator wraps it
/// in `listen` and calls `cancel` on disconnect. `cancel` stops the
/// polling timer and closes the controller. Calling [stream] twice on
/// the same instance is a programming error.
class Obd2SpeedStream {
  /// The OBD2 service polled for speed. Owned by the caller — closing
  /// the stream does NOT disconnect the service. The `AutoTripCoordinator`
  /// owns the session and decides when to hand it off (to the trip
  /// recorder on threshold-cross) or close it (on disconnect with no
  /// trip active).
  final Obd2Service _service;

  /// MAC of the adapter the service was opened against. Captured here
  /// so trace-log entries can carry it without the caller threading it
  /// through every event. Null when the caller doesn't care to tag.
  final String? _mac;

  /// Time between successive `readSpeedKmh()` calls. Defaults to 1 s
  /// in production; tests pass a shorter value (~10 ms) so the timer
  /// fires inside `pumpEventQueue` without burning real wall-clock
  /// time.
  final Duration pollPeriod;

  /// Number of consecutive null reads that triggers a trace-log
  /// breadcrumb. The coordinator's "did anything run?" debugging
  /// story relies on this — a long quiet stretch with no error
  /// thrown would otherwise be invisible. Default 5 (~5 s of dead
  /// air at the default cadence).
  final int failureLogThreshold;

  late final StreamController<double> _controller;
  Timer? _timer;
  int _consecutiveFailures = 0;
  bool _streamRequested = false;

  Obd2SpeedStream(
    this._service, {
    String? mac,
    this.pollPeriod = const Duration(seconds: 1),
    this.failureLogThreshold = 5,
  }) : _mac = mac {
    _controller = StreamController<double>(
      onListen: _start,
      onCancel: _stop,
    );
  }

  /// Single-subscription stream of km/h samples. Subscribing kicks off
  /// the polling timer; cancelling the subscription stops it. Calling
  /// this getter more than once yields the same [Stream] but only the
  /// first `listen` may attach.
  Stream<double> get stream {
    _streamRequested = true;
    return _controller.stream;
  }

  /// Whether the stream has had at least one [stream] read. Test seam
  /// — production code never asks.
  bool get debugStreamRequested => _streamRequested;

  void _start() {
    // The first read fires immediately so the coordinator sees a
    // sample within `pollPeriod` of subscribe rather than after.
    // `Timer.periodic` only fires AFTER its first interval, so we
    // bridge with an explicit kick.
    _tick();
    _timer = Timer.periodic(pollPeriod, (_) => _tick());
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _timer = null;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  Future<void> _tick() async {
    int? kmh;
    try {
      kmh = await _service.readSpeedKmh();
    } catch (e, st) {
      // The service already swallows + debugPrints its own errors and
      // returns null on the readSpeedKmh path — but a future change
      // could surface a throw. Treat as a failed read so the
      // counter advances and we trace once at threshold.
      _consecutiveFailures++;
      AutoRecordTraceLog.add(
        AutoRecordEventKind.error,
        mac: _mac,
        detail: 'Obd2SpeedStream.readSpeedKmh threw: $e\n$st',
      );
      _maybeLogFailureThreshold();
      return;
    }
    if (kmh == null) {
      _consecutiveFailures++;
      _maybeLogFailureThreshold();
      return;
    }
    // Successful read — reset the failure counter and emit. Guard the
    // `add` against a closed controller (cancel can land while a
    // Future-suspended readSpeedKmh is still in flight).
    _consecutiveFailures = 0;
    if (!_controller.isClosed) {
      _controller.add(kmh.toDouble());
    }
  }

  void _maybeLogFailureThreshold() {
    if (_consecutiveFailures != failureLogThreshold) return;
    AutoRecordTraceLog.add(
      AutoRecordEventKind.obd2SpeedReadFailed,
      mac: _mac,
      detail: 'consecutiveFailures=$_consecutiveFailures',
    );
  }
}
