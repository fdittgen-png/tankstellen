import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/obd2/auto_record_trace_log.dart';
import 'package:tankstellen/features/consumption/data/obd2/auto_trip_coordinator.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_protocol.dart';
import 'package:tankstellen/features/consumption/data/obd2/fake_background_adapter_listener.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_speed_stream.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';

/// Coordinator state-machine tests for #1004 phase 2b-3. Drives the
/// coordinator with synthetic adapter events, an injected fake OBD2
/// session, and a queue-backed speed stream so the assertions stay
/// deterministic without a real BLE stack or OBD2 transport.
///
/// The phase 2b-3 swap moved the speed source from a constructor-
/// injected `Stream<double>` to an `Obd2SessionOpener` callback that
/// hands back an `Obd2Service` on `AdapterConnected`. The tests below
/// inject a fake opener that returns a fake service whose
/// `readSpeedKmh()` is wired to a queue.

/// Test-only [Obd2Transport] that returns canned speed values from a
/// queue. The coordinator's [Obd2SpeedStream] only calls
/// `readSpeedKmh`, which itself only sends `Elm327Protocol.vehicleSpeedCommand`
/// — so we map that command to the next item in the queue and
/// otherwise return an empty string.
class _FakeTransport implements Obd2Transport {
  final Queue<int?> speedQueue;
  bool _connected = true;
  int disconnectCalls = 0;

  _FakeTransport(this.speedQueue);

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    disconnectCalls++;
  }

  @override
  Future<String> sendCommand(String command) async {
    if (command == Elm327Protocol.vehicleSpeedCommand) {
      if (speedQueue.isEmpty) return 'NO DATA';
      final value = speedQueue.removeFirst();
      if (value == null) return 'NO DATA';
      // Encode as a Mode 01 PID 0D response: "41 0D <hex>".
      return '41 0D ${value.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    }
    return '';
  }
}

/// Bookkeeping for the injected session opener — captures the MAC each
/// `AdapterConnected` opens against, the services returned, and lets a
/// test fail or queue different responses per call.
class _SessionOpenerHarness {
  /// One queued response per planned `_open` call. Each entry is
  /// either the service to return, `null` to simulate "scan timed
  /// out, no usable adapter," or `_OpenerError` to simulate a throw.
  final Queue<Object?> queue = Queue<Object?>();
  final List<String> openedFor = <String>[];
  int callCount = 0;

  Obd2SessionOpener opener() {
    return (String mac) async {
      callCount++;
      openedFor.add(mac);
      if (queue.isEmpty) return null;
      final next = queue.removeFirst();
      if (next is _OpenerError) throw next.cause;
      return next as Obd2Service?;
    };
  }
}

class _OpenerError {
  final Object cause;
  _OpenerError(this.cause);
}

/// In-memory [TraceRecorder] used to drain `errorLogger.log` calls
/// during failure-path tests. We don't assert on the captured records
/// — we just stop the global logger from reaching Hive.
class _FakeTraceRecorder implements TraceRecorder {
  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  // The default disconnect-save delay in production is 60 s; tests
  // shrink it to 50 ms so the timer fires inside `pumpEventQueue`
  // without burning real wall-clock time.
  const String mac = 'AA:BB:CC:DD:EE:FF';
  const String otherMac = 'FF:EE:DD:CC:BB:AA';
  const Duration shortDelay = Duration(milliseconds: 50);
  const Duration shortPoll = Duration(milliseconds: 5);

  late FakeBackgroundAdapterListener listener;
  late _SessionOpenerHarness opener;
  late int startTripCalls;
  late int stopAndSaveCalls;
  late List<Obd2Service> handedOffServices;
  late AutoTripCoordinator coordinator;

  /// Build a fake [Obd2Service] whose `readSpeedKmh` reads from
  /// [speeds]. Each entry is either an int (returned as-is) or null
  /// (treated as a missed read by the speed stream).
  ({Obd2Service service, _FakeTransport transport}) buildFakeService(
    List<int?> speeds,
  ) {
    final transport = _FakeTransport(Queue<int?>.of(speeds));
    final service = Obd2Service(transport);
    return (service: service, transport: transport);
  }

  AutoTripCoordinator buildCoordinator({
    int consecutive = 3,
    Duration delay = shortDelay,
    double threshold = 5.0,
    Obd2SessionOpener? customOpener,
  }) {
    return AutoTripCoordinator(
      listener: listener,
      startTrip: (Obd2Service service) async {
        startTripCalls++;
        handedOffServices.add(service);
        return null;
      },
      stopAndSaveAutomatic: () async {
        stopAndSaveCalls++;
      },
      sessionOpener: customOpener ?? opener.opener(),
      speedStreamFactory: (Obd2Service service, {String? mac}) {
        return Obd2SpeedStream(
          service,
          mac: mac,
          pollPeriod: shortPoll,
        );
      },
      config: AutoRecordConfig(
        mac: mac,
        movementStartThresholdKmh: threshold,
        disconnectSaveDelay: delay,
      ),
      consecutiveSamplesWindow: consecutive,
    );
  }

  setUp(() {
    AutoRecordTraceLog.clear();
    // Wire the global errorLogger to an in-memory recorder so failure
    // paths don't try to spool through Hive (which is not initialized
    // in plain unit-test mode). Same pattern used by
    // `obd2_vin_reader_test.dart` for error-throwing assertions.
    errorLogger.resetForTest();
    errorLogger.testRecorderOverride = _FakeTraceRecorder();
    listener = FakeBackgroundAdapterListener();
    opener = _SessionOpenerHarness();
    startTripCalls = 0;
    stopAndSaveCalls = 0;
    handedOffServices = <Obd2Service>[];
  });

  tearDown(() async {
    await coordinator.stop();
    await listener.dispose();
    errorLogger.resetForTest();
  });

  /// Pumps the microtask queue until the speed stream has had a
  /// chance to emit at least [count] samples. The polling timer fires
  /// at [shortPoll]; we sleep [shortPoll] × [count] × 2 to add
  /// headroom for the awaits inside `_tick`.
  Future<void> pumpSpeedTicks(int count) async {
    await Future<void>.delayed(shortPoll * (count * 2 + 1));
  }

  test('3 consecutive supra-threshold samples trigger startTrip exactly once',
      () async {
    final fake = buildFakeService([20, 25, 30, 40, 45, 50]);
    opener.queue.add(fake.service);
    coordinator = buildCoordinator();

    await coordinator.start();
    listener.emitConnected(mac);
    // Wait long enough for the opener to resolve and the speed stream
    // to deliver three reads.
    await pumpSpeedTicks(4);

    expect(startTripCalls, 1,
        reason: '3 consecutive supra-threshold samples must trigger '
            'startTrip exactly once');
    expect(handedOffServices, hasLength(1),
        reason: 'startTrip must receive the live OBD2 service');
    expect(identical(handedOffServices.first, fake.service), isTrue,
        reason: 'the coordinator must hand off the SAME service it opened');

    // Trace assertions: the ring should have recorded coordinatorStarted,
    // adapterConnected, three supra-threshold samples, thresholdCrossed,
    // sessionHandedOff, and finally tripStarted in that order.
    final List<AutoRecordEventKind> kinds =
        AutoRecordTraceLog.snapshot().map((e) => e.kind).toList();
    expect(kinds.first, AutoRecordEventKind.coordinatorStarted);
    expect(kinds.contains(AutoRecordEventKind.adapterConnected), isTrue);
    expect(
      kinds
          .where((k) => k == AutoRecordEventKind.speedSampleSupraThreshold)
          .length,
      greaterThanOrEqualTo(3),
      reason: 'three supra-threshold samples must each emit a trace entry',
    );
    final int crossedAt = kinds.indexOf(AutoRecordEventKind.thresholdCrossed);
    final int handedAt = kinds.indexOf(AutoRecordEventKind.sessionHandedOff);
    final int startedAt = kinds.indexOf(AutoRecordEventKind.tripStarted);
    expect(crossedAt, greaterThan(0));
    expect(handedAt, greaterThan(crossedAt),
        reason: 'sessionHandedOff must be emitted after thresholdCrossed');
    expect(startedAt, greaterThan(handedAt),
        reason: 'tripStarted must be emitted after sessionHandedOff');
  });

  test('sub-threshold samples never reach the consecutive window', () async {
    final fake = buildFakeService([2, 1, 3, 0, 1]);
    opener.queue.add(fake.service);
    coordinator = buildCoordinator();

    await coordinator.start();
    listener.emitConnected(mac);
    await pumpSpeedTicks(6);

    expect(startTripCalls, 0,
        reason: 'sub-threshold samples must never trigger startTrip');

    final List<AutoRecordEventKind> kinds =
        AutoRecordTraceLog.snapshot().map((e) => e.kind).toList();
    expect(
      kinds
          .where((k) => k == AutoRecordEventKind.speedSampleSubThreshold)
          .length,
      greaterThanOrEqualTo(5),
      reason: 'each sub-threshold sample must emit a trace entry',
    );
    expect(kinds.contains(AutoRecordEventKind.thresholdCrossed), isFalse);
    expect(kinds.contains(AutoRecordEventKind.tripStarted), isFalse);
  });

  test('fluctuating samples do not satisfy the consecutive window', () async {
    final fake = buildFakeService([10, 15, 0, 20, 2, 25]);
    opener.queue.add(fake.service);
    coordinator = buildCoordinator();

    await coordinator.start();
    listener.emitConnected(mac);
    await pumpSpeedTicks(7);

    expect(startTripCalls, 0,
        reason: 'A sub-threshold sample in the middle of a run must '
            'reset the consecutive counter');
  });

  test('disconnect arms timer; reconnect within window cancels save',
      () async {
    final fakeOne = buildFakeService([20, 25, 30]);
    final fakeTwo = buildFakeService(<int?>[]);
    opener.queue.addAll(<Object?>[fakeOne.service, fakeTwo.service]);
    coordinator = buildCoordinator();

    await coordinator.start();
    listener.emitConnected(mac);
    await pumpSpeedTicks(4);
    expect(startTripCalls, 1);

    listener.emitDisconnected(mac);
    // Allow the disconnect handler to run.
    await Future<void>.delayed(Duration.zero);
    expect(coordinator.hasPendingDisconnectTimer, isTrue,
        reason: 'disconnect must arm the debounce timer');

    // Reconnect well within the window. Trip is active so the
    // coordinator should NOT re-open a session — it leaves session
    // ownership with the recorder.
    listener.emitConnected(mac);
    await Future<void>.delayed(Duration.zero);
    expect(coordinator.hasPendingDisconnectTimer, isFalse,
        reason: 'reconnect within the debounce window must cancel '
            'the pending save timer');

    // Wait past the original delay — no save should fire.
    await Future<void>.delayed(shortDelay * 2);
    expect(stopAndSaveCalls, 0,
        reason: 'a cancelled timer must not still call stopAndSave');

    final List<AutoRecordEventKind> kinds =
        AutoRecordTraceLog.snapshot().map((e) => e.kind).toList();
    final int timerStartedAt =
        kinds.indexOf(AutoRecordEventKind.disconnectTimerStarted);
    final int reconnectedAt =
        kinds.lastIndexOf(AutoRecordEventKind.adapterConnected);
    final int cancelledAt =
        kinds.indexOf(AutoRecordEventKind.disconnectTimerCancelled);
    expect(timerStartedAt, greaterThan(-1),
        reason: 'disconnect must record disconnectTimerStarted');
    expect(reconnectedAt, greaterThan(timerStartedAt),
        reason: 'reconnect must record adapterConnected after the timer '
            'started');
    expect(cancelledAt, greaterThan(reconnectedAt),
        reason: 'reconnect must trigger disconnectTimerCancelled');
    expect(kinds.contains(AutoRecordEventKind.disconnectTimerFired), isFalse,
        reason: 'a cancelled timer must not record a fired entry');
    expect(kinds.contains(AutoRecordEventKind.tripSavedAuto), isFalse);
  });

  test('disconnect timer fires → stopAndSaveAutomatic called once', () async {
    final fake = buildFakeService([20, 25, 30]);
    opener.queue.add(fake.service);
    coordinator = buildCoordinator();

    await coordinator.start();
    listener.emitConnected(mac);
    await pumpSpeedTicks(4);
    expect(startTripCalls, 1);

    listener.emitDisconnected(mac);
    // Wait past the debounce window so the timer fires.
    await Future<void>.delayed(shortDelay * 3);

    expect(stopAndSaveCalls, 1,
        reason: 'timer fire must call stopAndSaveAutomatic exactly once');

    final List<AutoRecordEventKind> kinds =
        AutoRecordTraceLog.snapshot().map((e) => e.kind).toList();
    final int firedAt =
        kinds.indexOf(AutoRecordEventKind.disconnectTimerFired);
    final int savedAt = kinds.indexOf(AutoRecordEventKind.tripSavedAuto);
    expect(firedAt, greaterThan(-1),
        reason: 'timer fire must record disconnectTimerFired');
    expect(savedAt, greaterThan(firedAt),
        reason: 'tripSavedAuto must follow disconnectTimerFired');
  });

  test('disconnect with no active trip → orphan session is closed', () async {
    final fake = buildFakeService(<int?>[]);
    opener.queue.add(fake.service);
    coordinator = buildCoordinator();

    await coordinator.start();
    listener.emitConnected(mac);
    // Allow the opener to resolve so the coordinator holds a session.
    await pumpSpeedTicks(2);
    expect(coordinator.hasOpenSession, isTrue,
        reason: 'opener returns a service — the coordinator must hold it');

    // Disconnect with no trip active → orphan session must be closed,
    // not handed off.
    listener.emitDisconnected(mac);
    await Future<void>.delayed(Duration.zero);
    expect(coordinator.hasOpenSession, isFalse,
        reason: 'disconnect with no trip active must close the orphan '
            'session');
    expect(fake.transport.disconnectCalls, greaterThanOrEqualTo(1),
        reason: 'the coordinator must call service.disconnect() to close '
            'the orphan session');

    await Future<void>.delayed(shortDelay * 3);
    expect(startTripCalls, 0);
    expect(stopAndSaveCalls, 0,
        reason: 'no trip was active — nothing to save');
  });

  test('events for a different MAC are ignored', () async {
    coordinator = buildCoordinator();
    await coordinator.start();
    listener.emitConnected(otherMac);
    // Wait for any spurious opener calls — there should be none.
    await pumpSpeedTicks(3);

    expect(opener.callCount, 0,
        reason: 'connect for the wrong MAC must not open a session');
    expect(startTripCalls, 0,
        reason: 'connect for the wrong MAC must not subscribe to speed');

    listener.emitDisconnected(otherMac);
    expect(coordinator.hasPendingDisconnectTimer, isFalse,
        reason: 'disconnect for the wrong MAC must not arm the timer');
    await Future<void>.delayed(shortDelay * 3);
    expect(stopAndSaveCalls, 0);

    // Trace must record the foreign MAC as ignored (so the user can
    // see "an event arrived but it wasn't ours") rather than silently
    // dropping it.
    final List<AutoRecordEvent> events = AutoRecordTraceLog.snapshot();
    final AutoRecordEvent ignoredConnect = events.firstWhere(
      (e) => e.kind == AutoRecordEventKind.adapterConnectIgnoredOtherMac,
    );
    expect(ignoredConnect.mac, otherMac);
    final AutoRecordEvent ignoredDisconnect = events.firstWhere(
      (e) => e.kind == AutoRecordEventKind.adapterDisconnectIgnoredOtherMac,
    );
    expect(ignoredDisconnect.mac, otherMac);
    expect(events.any((e) => e.kind == AutoRecordEventKind.adapterConnected),
        isFalse,
        reason: 'no AdapterConnected for the configured mac should appear');
  });

  test('start() is idempotent — second call does not double-subscribe',
      () async {
    final fake = buildFakeService([20, 25, 30, 40, 45, 50]);
    opener.queue.add(fake.service);
    coordinator = buildCoordinator();

    await coordinator.start();
    await coordinator.start();
    expect(coordinator.isStarted, isTrue);
    expect(listener.startCalls, 1,
        reason: 'second start() must not re-arm the native bridge');

    listener.emitConnected(mac);
    await pumpSpeedTicks(4);

    // If the second start had double-subscribed, the speed handler
    // would run twice and startTrip would fire twice. Even though
    // `_tripActive` gates the callback, the underlying adapter-event
    // subscription would also be doubled.
    expect(startTripCalls, 1,
        reason: 'idempotent start must not duplicate subscriptions');
  });

  test('stop() cancels a pending disconnect timer', () async {
    final fake = buildFakeService([20, 25, 30]);
    opener.queue.add(fake.service);
    coordinator = buildCoordinator();

    await coordinator.start();
    listener.emitConnected(mac);
    await pumpSpeedTicks(4);

    listener.emitDisconnected(mac);
    await Future<void>.delayed(Duration.zero);
    expect(coordinator.hasPendingDisconnectTimer, isTrue);

    await coordinator.stop();
    expect(coordinator.hasPendingDisconnectTimer, isFalse,
        reason: 'stop() must cancel the pending disconnect timer so a '
            'developer-initiated tear-down does not auto-save');

    await Future<void>.delayed(shortDelay * 3);
    expect(stopAndSaveCalls, 0,
        reason: 'a cancelled timer must not still fire stopAndSaveAutomatic '
            'after stop()');
  });

  test('stop() called twice is safe', () async {
    coordinator = buildCoordinator();
    await coordinator.start();
    await coordinator.stop();
    await coordinator.stop(); // No throw, no double tear-down side effects.
    expect(coordinator.isStarted, isFalse);
    expect(listener.stopCalls, 2,
        reason: 'each stop() call forwards once to the listener');

    // Both stop() calls record a coordinatorStopped entry — the trace
    // is "what happened from the coordinator's POV", not "what changed
    // state".
    final List<AutoRecordEventKind> kinds =
        AutoRecordTraceLog.snapshot().map((e) => e.kind).toList();
    expect(
      kinds.where((k) => k == AutoRecordEventKind.coordinatorStopped).length,
      2,
    );
  });

  test('connect → disconnect → reconnect → trip stays active, no second start',
      () async {
    final fake = buildFakeService([20, 25, 30]);
    opener.queue.add(fake.service);
    coordinator = buildCoordinator();

    await coordinator.start();
    listener.emitConnected(mac);
    await pumpSpeedTicks(4);
    expect(startTripCalls, 1);

    listener.emitDisconnected(mac);
    await Future<void>.delayed(Duration.zero);
    listener.emitConnected(mac);
    await Future<void>.delayed(Duration.zero);

    // Trip is still active — no opener call expected on the reconnect
    // (the recorder owns the session). And no second startTrip.
    expect(opener.callCount, 1,
        reason: 'reconnect with active trip must NOT open a second '
            'OBD2 session — the recorder still owns the original');
    expect(startTripCalls, 1,
        reason: 'reconnect must NOT clear `_tripActive`; the trip '
            'survives the brief drop and a new supra burst is just '
            'continued movement, not a new trip');
  });

  test('opener returning null leaves coordinator idle for that connect cycle',
      () async {
    // First connect: opener returns null (scan timeout). Coordinator
    // stays idle; no speed stream wired; no startTrip fires even if
    // the listener emits more events.
    opener.queue.add(null);
    coordinator = buildCoordinator();

    await coordinator.start();
    listener.emitConnected(mac);
    await pumpSpeedTicks(3);

    expect(coordinator.hasOpenSession, isFalse,
        reason: 'opener returned null — no session held');
    expect(startTripCalls, 0,
        reason: 'no speed source means no threshold-cross');

    // Trace records the failure so the user can see "we tried but
    // couldn't open a session."
    final List<AutoRecordEventKind> kinds =
        AutoRecordTraceLog.snapshot().map((e) => e.kind).toList();
    expect(kinds.contains(AutoRecordEventKind.sessionOpenFailed), isTrue,
        reason: 'a null opener result must record sessionOpenFailed');
  });

  test('opener throwing is logged; coordinator stays idle', () async {
    opener.queue.add(_OpenerError(StateError('boom')));
    coordinator = buildCoordinator();

    await coordinator.start();
    listener.emitConnected(mac);
    await pumpSpeedTicks(3);

    expect(coordinator.hasOpenSession, isFalse,
        reason: 'opener throw must leave the coordinator session-less');
    expect(startTripCalls, 0);

    final List<AutoRecordEvent> events = AutoRecordTraceLog.snapshot();
    expect(
      events.where((e) => e.kind == AutoRecordEventKind.sessionOpenFailed),
      isNotEmpty,
      reason: 'opener throw must record sessionOpenFailed',
    );
  });

  test('threshold-cross hands the live service into startTrip', () async {
    final fake = buildFakeService([20, 25, 30]);
    opener.queue.add(fake.service);
    coordinator = buildCoordinator();

    await coordinator.start();
    listener.emitConnected(mac);
    await pumpSpeedTicks(4);

    expect(handedOffServices, hasLength(1));
    expect(identical(handedOffServices.first, fake.service), isTrue,
        reason: 'the service handed to startTrip must be the SAME instance '
            'opened on AdapterConnected — ownership transfer, not copy');
    expect(coordinator.hasOpenSession, isFalse,
        reason: 'after hand-off the coordinator must release its '
            'session pointer so a follow-up disconnect does not close '
            'the recorder\'s service');
  });

  test('stop() closes a held orphan session', () async {
    final fake = buildFakeService([0, 0, 0]);
    opener.queue.add(fake.service);
    coordinator = buildCoordinator();

    await coordinator.start();
    listener.emitConnected(mac);
    await pumpSpeedTicks(2);
    expect(coordinator.hasOpenSession, isTrue);

    await coordinator.stop();
    expect(coordinator.hasOpenSession, isFalse,
        reason: 'stop() must close any held session');
    expect(fake.transport.disconnectCalls, greaterThanOrEqualTo(1),
        reason: 'stop() must call service.disconnect() on the held session');
  });
}
