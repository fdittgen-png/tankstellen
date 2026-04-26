import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/auto_record_trace_log.dart';
import 'package:tankstellen/features/consumption/data/obd2/auto_trip_coordinator.dart';
import 'package:tankstellen/features/consumption/data/obd2/fake_background_adapter_listener.dart';

/// Coordinator state-machine tests for #1004 phase 2a. Drives the
/// scaffolding from synthetic adapter events + a stream-controlled
/// speed source so the assertions stay deterministic without a real
/// BLE stack or OBD2 transport.
void main() {
  // The default disconnect-save delay in production is 60 s; tests
  // shrink it to 50 ms so the timer fires inside `pumpEventQueue`
  // without burning real wall-clock time.
  const String mac = 'AA:BB:CC:DD:EE:FF';
  const String otherMac = 'FF:EE:DD:CC:BB:AA';
  const Duration shortDelay = Duration(milliseconds: 50);

  late FakeBackgroundAdapterListener listener;
  late StreamController<double> speed;
  late int startTripCalls;
  late int stopAndSaveCalls;
  late AutoTripCoordinator coordinator;

  AutoTripCoordinator buildCoordinator({
    int consecutive = 3,
    Duration delay = shortDelay,
    double threshold = 5.0,
  }) {
    return AutoTripCoordinator(
      listener: listener,
      startTrip: () async {
        startTripCalls++;
        return null;
      },
      stopAndSaveAutomatic: () async {
        stopAndSaveCalls++;
      },
      speedStream: speed.stream,
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
    listener = FakeBackgroundAdapterListener();
    speed = StreamController<double>.broadcast();
    startTripCalls = 0;
    stopAndSaveCalls = 0;
    coordinator = buildCoordinator();
  });

  tearDown(() async {
    await coordinator.stop();
    await speed.close();
    await listener.dispose();
  });

  test('3 consecutive supra-threshold samples trigger startTrip exactly once',
      () async {
    await coordinator.start();
    listener.emitConnected(mac);
    // Allow the coordinator's listener subscription to wire through
    // the broadcast queue before we push speed samples.
    await Future<void>.delayed(Duration.zero);

    // Push 3 samples > threshold; coordinator should fire startTrip.
    speed.add(20);
    speed.add(25);
    speed.add(30);
    await Future<void>.delayed(Duration.zero);

    expect(startTripCalls, 1,
        reason: '3 consecutive supra-threshold samples must trigger '
            'startTrip exactly once');

    // Pushing more samples while the trip is active does not fire
    // again — the coordinator gates on `_tripActive`.
    speed.add(40);
    speed.add(45);
    speed.add(50);
    await Future<void>.delayed(Duration.zero);

    expect(startTripCalls, 1,
        reason: 'startTrip is idempotent within a single connect '
            'cycle — extra samples should not double-fire');

    // Trace assertions: the ring should have recorded coordinatorStarted,
    // adapterConnected, three supra-threshold samples, thresholdCrossed,
    // and finally tripStarted in that order.
    final List<AutoRecordEventKind> kinds =
        AutoRecordTraceLog.snapshot().map((e) => e.kind).toList();
    expect(kinds.first, AutoRecordEventKind.coordinatorStarted);
    expect(kinds.contains(AutoRecordEventKind.adapterConnected), isTrue);
    expect(
      kinds.where((k) => k == AutoRecordEventKind.speedSampleSupraThreshold)
          .length,
      3,
      reason: 'three supra-threshold samples must each emit a trace entry',
    );
    final int crossedAt = kinds.indexOf(AutoRecordEventKind.thresholdCrossed);
    final int startedAt = kinds.indexOf(AutoRecordEventKind.tripStarted);
    expect(crossedAt, greaterThan(0));
    expect(startedAt, greaterThan(crossedAt),
        reason: 'thresholdCrossed must be emitted before tripStarted');
  });

  test('sub-threshold samples never reach the consecutive window', () async {
    await coordinator.start();
    listener.emitConnected(mac);
    await Future<void>.delayed(Duration.zero);

    // Five sub-threshold samples — well past the consecutive window
    // count, but each one resets the counter.
    for (int i = 0; i < 5; i++) {
      speed.add(2.0);
    }
    await Future<void>.delayed(Duration.zero);

    expect(startTripCalls, 0,
        reason: 'sub-threshold samples must never trigger startTrip');

    final List<AutoRecordEventKind> kinds =
        AutoRecordTraceLog.snapshot().map((e) => e.kind).toList();
    expect(
      kinds.where((k) => k == AutoRecordEventKind.speedSampleSubThreshold)
          .length,
      5,
      reason: 'each sub-threshold sample must emit a trace entry',
    );
    expect(kinds.contains(AutoRecordEventKind.thresholdCrossed), isFalse);
    expect(kinds.contains(AutoRecordEventKind.tripStarted), isFalse);
  });

  test('fluctuating samples do not satisfy the consecutive window', () async {
    await coordinator.start();
    listener.emitConnected(mac);
    await Future<void>.delayed(Duration.zero);

    // Pattern: above, above, below — counter must reset on the third
    // sample so the window is never satisfied.
    speed.add(10);
    speed.add(15);
    speed.add(0);
    speed.add(20);
    speed.add(2);
    speed.add(25);
    await Future<void>.delayed(Duration.zero);

    expect(startTripCalls, 0,
        reason: 'A sub-threshold sample in the middle of a run must '
            'reset the consecutive counter');
  });

  test('disconnect arms timer; reconnect within window cancels save',
      () async {
    await coordinator.start();
    listener.emitConnected(mac);
    await Future<void>.delayed(Duration.zero);
    speed.add(20);
    speed.add(25);
    speed.add(30);
    await Future<void>.delayed(Duration.zero);
    expect(startTripCalls, 1);

    listener.emitDisconnected(mac);
    // Broadcast streams deliver asynchronously — flush the microtask
    // queue so the coordinator's _onAdapterEvent has run before we
    // peek at the timer state.
    await Future<void>.delayed(Duration.zero);
    expect(coordinator.hasPendingDisconnectTimer, isTrue,
        reason: 'disconnect must arm the debounce timer');

    // Reconnect well within the window.
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
    await coordinator.start();
    listener.emitConnected(mac);
    await Future<void>.delayed(Duration.zero);
    speed.add(20);
    speed.add(25);
    speed.add(30);
    await Future<void>.delayed(Duration.zero);
    expect(startTripCalls, 1);

    listener.emitDisconnected(mac);
    // Wait past the debounce window so the timer fires.
    await Future<void>.delayed(shortDelay * 3);

    expect(stopAndSaveCalls, 1,
        reason: 'timer fire must call stopAndSaveAutomatic exactly once');

    final List<AutoRecordEventKind> kinds =
        AutoRecordTraceLog.snapshot().map((e) => e.kind).toList();
    final int firedAt = kinds.indexOf(AutoRecordEventKind.disconnectTimerFired);
    final int savedAt = kinds.indexOf(AutoRecordEventKind.tripSavedAuto);
    expect(firedAt, greaterThan(-1),
        reason: 'timer fire must record disconnectTimerFired');
    expect(savedAt, greaterThan(firedAt),
        reason: 'tripSavedAuto must follow disconnectTimerFired');
  });

  test('disconnect with no active trip → timer fires but no save', () async {
    await coordinator.start();
    listener.emitConnected(mac);
    await Future<void>.delayed(Duration.zero);
    // No speed samples — startTrip never fires.
    listener.emitDisconnected(mac);
    await Future<void>.delayed(shortDelay * 3);

    expect(startTripCalls, 0);
    expect(stopAndSaveCalls, 0,
        reason: 'no trip was active — nothing to save');
  });

  test('events for a different MAC are ignored', () async {
    await coordinator.start();
    listener.emitConnected(otherMac);
    await Future<void>.delayed(Duration.zero);
    speed.add(20);
    speed.add(25);
    speed.add(30);
    await Future<void>.delayed(Duration.zero);
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
    await coordinator.start();
    await coordinator.start();
    expect(coordinator.isStarted, isTrue);
    expect(listener.startCalls, 1,
        reason: 'second start() must not re-arm the native bridge');

    listener.emitConnected(mac);
    await Future<void>.delayed(Duration.zero);
    speed.add(20);
    speed.add(25);
    speed.add(30);
    await Future<void>.delayed(Duration.zero);

    // If the second start had double-subscribed, the speed handler
    // would run twice and startTrip would fire twice (since
    // `_tripActive` is set inside the callback path that fires).
    // Even though `_tripActive` gates the callback, the underlying
    // adapter-event subscription would also be doubled, leading to
    // doubled `_onConnected` runs which would re-subscribe speed
    // doubly. Either way the count must stay at 1.
    expect(startTripCalls, 1,
        reason: 'idempotent start must not duplicate subscriptions');
  });

  test('stop() cancels a pending disconnect timer', () async {
    await coordinator.start();
    listener.emitConnected(mac);
    await Future<void>.delayed(Duration.zero);
    speed.add(20);
    speed.add(25);
    speed.add(30);
    await Future<void>.delayed(Duration.zero);

    listener.emitDisconnected(mac);
    // Flush microtasks so the coordinator's adapter-event handler has
    // armed the timer before we inspect it.
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

  test('connect → disconnect → reconnect → 3 supra samples → only one save',
      () async {
    // The reconnect-within-window path needs to leave the trip
    // running; a second supra-threshold burst must NOT re-fire
    // startTrip (the trip is still active from the first burst).
    await coordinator.start();
    listener.emitConnected(mac);
    await Future<void>.delayed(Duration.zero);
    speed.add(20);
    speed.add(25);
    speed.add(30);
    await Future<void>.delayed(Duration.zero);
    expect(startTripCalls, 1);

    listener.emitDisconnected(mac);
    listener.emitConnected(mac);
    await Future<void>.delayed(Duration.zero);
    // Push another supra burst — trip is still active, must not
    // re-fire.
    speed.add(40);
    speed.add(45);
    speed.add(50);
    await Future<void>.delayed(Duration.zero);

    expect(startTripCalls, 1,
        reason: 'reconnect must NOT clear `_tripActive`; the trip '
            'survives the brief drop and a new supra burst is just '
            'continued movement, not a new trip');
  });
}
