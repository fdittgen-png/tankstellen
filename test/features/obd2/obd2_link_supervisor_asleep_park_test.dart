// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3859 (Epic #3855) — a drop on a car the vehicle power model knows is
// ASLEEP parks the supervisor without a dial. The field storms were made
// of exactly this: the adapter going to sleep behind a parked car, the
// loop dialing a dongle at 3 mA, 23 s RFCOMM timeouts feeding the #3603
// stand-down with failures that were never failures. And the floor: with
// no evidence (`unknown`) the loop dials exactly as it always did.
import 'dart:async';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_link_supervisor.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/obd2/domain/vehicle_power_state.dart';

class _ScriptedDialer {
  final List<Object?> _script = [];
  int calls = 0;
  void enqueue(Object? outcome) => _script.add(outcome);
  Future<Obd2Service?> dial() async {
    calls++;
    final outcome = _script.length > 1 ? _script.removeAt(0) : _script.first;
    if (outcome is Obd2Service) return outcome;
    if (outcome == null) return null;
    throw outcome; // ignore: only_throw_errors
  }
}

class _FakeTransport implements Obd2Transport {
  bool connected = true;
  @override
  Future<void> connect() async => connected = true;
  @override
  Future<void> disconnect() async => connected = false;
  @override
  bool get isConnected => connected;
  @override
  Future<String> sendCommand(String command) async => 'OK';
}

Obd2Service _liveService() => Obd2Service(_FakeTransport());

void main() {
  late StreamController<Obd2LinkDropEvent> drops;
  late _ScriptedDialer dialer;
  late DateTime nowValue;
  late Obd2VehiclePower power;

  Obd2LinkSupervisor build() => Obd2LinkSupervisor(
        dial: dialer.dial,
        drops: drops.stream,
        initialBackoff: const Duration(milliseconds: 500),
        maxBackoff: const Duration(seconds: 2),
        jitter: Random(1),
        now: () => nowValue,
        vehiclePower: power,
      );

  setUp(() {
    drops = StreamController<Obd2LinkDropEvent>.broadcast();
    dialer = _ScriptedDialer();
    nowValue = DateTime(2026, 8, 29, 20);
    power = Obd2VehiclePower(now: () => nowValue);
  });

  tearDown(() async => drops.close());

  test('a drop while the car is ASLEEP parks engineOff — zero dials', () {
    fakeAsync((async) {
      dialer.enqueue(_liveService());
      final sup = build();
      unawaited(sup.connect());
      async.flushMicrotasks();
      expect(sup.state.value, Obd2LinkState.ready);
      final callsAfterConnect = dialer.calls;

      // The voltage watch read 12.4 V and the bus went silent: asleep.
      power.noteVoltage(12.4);
      power.noteBusSilent();
      expect(power.asleep, isTrue);

      drops.add(const Obd2LinkDropEvent(
          transportKind: 'classic', mac: 'AA', reason: 'socket closed'));
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 2));

      expect(sup.state.value, Obd2LinkState.engineOff,
          reason: 'the adapter went to sleep behind a parked car — this '
              'is a park, not a link to recover');
      expect(dialer.calls, callsAfterConnect,
          reason: 'not one dial against a sleeping dongle');
      unawaited(sup.dispose());
    });
  });

  test('the same drop with NO evidence dials exactly as before (the floor)',
      () {
    fakeAsync((async) {
      dialer.enqueue(_liveService());
      final sup = build();
      unawaited(sup.connect());
      async.flushMicrotasks();
      final callsAfterConnect = dialer.calls;
      expect(power.state, VehiclePowerState.unknown);

      drops.add(const Obd2LinkDropEvent(
          transportKind: 'classic', mac: 'AA', reason: 'socket closed'));
      async.flushMicrotasks();

      expect(dialer.calls, callsAfterConnect + 1,
          reason: 'unknown evidence = the pre-#3855 immediate redial');
      expect(sup.state.value, Obd2LinkState.ready);
      unawaited(sup.dispose());
    });
  });

  test('a drop with the engine RUNNING dials immediately', () {
    fakeAsync((async) {
      dialer.enqueue(_liveService());
      final sup = build();
      unawaited(sup.connect());
      async.flushMicrotasks();
      final callsAfterConnect = dialer.calls;

      power.noteVoltage(14.1); // alternator charging
      power.noteBusSilent(); // even a silent probe cannot say asleep now
      expect(power.engineRunning, isTrue);

      drops.add(const Obd2LinkDropEvent(
          transportKind: 'classic', mac: 'AA', reason: 'socket closed'));
      async.flushMicrotasks();

      expect(dialer.calls, callsAfterConnect + 1);
      unawaited(sup.dispose());
    });
  });

  test('the engine transition wakes a park that asleep put it in', () {
    fakeAsync((async) {
      dialer.enqueue(_liveService());
      final sup = build();
      unawaited(sup.connect());
      async.flushMicrotasks();
      power.noteVoltage(12.3);
      power.noteBusSilent();
      drops.add(const Obd2LinkDropEvent(
          transportKind: 'classic', mac: 'AA', reason: 'socket closed'));
      async.flushMicrotasks();
      expect(sup.state.value, Obd2LinkState.engineOff);
      final parkedCalls = dialer.calls;

      // The driver starts the car: the provider layer calls wake() on the
      // engineRunning transition; here we do it directly.
      power.noteVoltage(14.2);
      sup.wake();
      async.flushMicrotasks();

      expect(dialer.calls, parkedCalls + 1);
      expect(sup.state.value, Obd2LinkState.ready);
      unawaited(sup.dispose());
    });
  });
}
