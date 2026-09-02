// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3915 (Epic #3914) — the dead-but-connected re-adoption livelock.
//
// Field trip 2026-09-01 (43 min, 0/2443 engine samples): every ~8.2 s the
// session journal repeated `serviceRebound → leftDegraded →
// schedulerResumed → protocolEstablish → protocolVerdict silent (+10–20
// ms) → linkDrop transportError (+8.2 s) → degradedGpsOnly →
// serviceRebound (same millisecond)`. The supervisor sat in `ready`
// holding a service whose transport FLAG said connected while every
// command threw instantly (a byte channel whose session was cleared on a
// write-time drop — `_writeChar == null` / `_open == false` — with the
// transport's `_connected` never flipped because the incoming stream got
// no error/done edge). `isConnected` is a flag, not liveness: the
// reattach source handed the corpse back to the trip on every poke, and
// `ensureLive` trusted the same flag, so nothing ever recycled it.
//
// Adoption is now proven by a real round-trip: the source probes the
// held service (`probeLiveness`, an AT-level ATRV through the session
// ladder) BEFORE firing, hands a mute instance back to the owner
// (`reportServiceDead`, reason `adoption-probe`) and waits for the
// genuine replacement.
import 'dart:async';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_link_supervisor.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_reattach_source.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/obd2/domain/obd2_connection_errors.dart';

void main() {
  late StreamController<Obd2LinkDropEvent> drops;

  setUp(() => drops = StreamController<Obd2LinkDropEvent>.broadcast());
  tearDown(() => drops.close());

  Obd2LinkSupervisor build(Future<Obd2Service?> Function() dial) =>
      Obd2LinkSupervisor(
        dial: dial,
        drops: drops.stream,
        initialBackoff: const Duration(milliseconds: 500),
        maxBackoff: const Duration(seconds: 30),
        jitter: Random(42),
      );

  Future<Obd2Service> healthyService() async {
    final transport = FakeObd2Transport();
    await transport.connect();
    return Obd2Service(transport);
  }

  test(
      '#3915 — a connected-FLAG service that refuses every command is '
      'never handed to the trip: the source hands it to the owner and '
      'fires on the healthy replacement', () {
    fakeAsync((async) {
      final corpseTransport = _ConnectedButMuteTransport();
      final corpse = Obd2Service(corpseTransport);
      late Obd2Service healthy;
      unawaited(healthyService().then((s) => healthy = s));
      async.flushMicrotasks();

      var dialCount = 0;
      final sup = build(() async => ++dialCount == 1 ? corpse : healthy);
      unawaited(sup.connect());
      async.flushMicrotasks();
      expect(sup.service, same(corpse));
      expect(corpse.isConnected, isTrue,
          reason: 'the field shape: the transport flag lies "connected"');

      final fired = <Obd2Service>[];
      var reconnects = 0;
      final src = SupervisorReattachSource(
        sup,
        onConnected: fired.add,
        onReconnect: () => reconnects++,
      );
      unawaited(src.start());
      async.flushMicrotasks();

      expect(fired, isNot(contains(same(corpse))),
          reason: 'the same-millisecond rebound of the field loop — a '
              'service that cannot complete one round-trip must never '
              'be adopted');
      expect(corpseTransport.sentCommands, isNotEmpty,
          reason: 'adoption is proven by a real round-trip, not a flag');

      // The owner recycles the mute instance and redials.
      async.elapse(const Duration(seconds: 3));
      expect(corpseTransport.isConnected, isFalse,
          reason: 'the corpse is closed by its owner (fresh-socket rule)');
      expect(dialCount, 2, reason: 'the supervisor redialed exactly once');
      expect(fired, [same(healthy)],
          reason: 'the genuine replacement is adopted');
      expect(reconnects, 1);

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test(
      '#3915 — a REFUSED instance (the cycle breaker\'s verdict) is never '
      'fired even though it answers: it is handed back to the owner and '
      'the next instance is adopted', () {
    fakeAsync((async) {
      late Obd2Service a;
      late Obd2Service b;
      unawaited(healthyService().then((s) => a = s));
      unawaited(healthyService().then((s) => b = s));
      async.flushMicrotasks();

      // The redial is GATED so the intermediate state is observable.
      final redial = Completer<Obd2Service?>();
      var dialCount = 0;
      final sup = build(() => ++dialCount == 1 ? Future.value(a) : redial.future);
      unawaited(sup.connect());
      async.flushMicrotasks();
      expect(sup.service, same(a));

      final gate = _RecordingGate(refused: [a]);
      final fired = <Obd2Service>[];
      final src = SupervisorReattachSource(
        sup,
        onConnected: fired.add,
        onReconnect: () {},
      )..adoptionGate = gate;
      unawaited(src.start());
      async.flushMicrotasks();
      expect(fired, isEmpty, reason: 'a refused instance never fires');
      expect(sup.state.value, Obd2LinkState.reconnecting,
          reason: 'the refused instance is recycled through the owner');
      expect(a.isConnected, isFalse, reason: 'closed by the owner');
      expect(dialCount, 2, reason: 'the owner is already redialing');

      redial.complete(b);
      async.elapse(const Duration(seconds: 3));
      expect(fired, [same(b)]);
      expect(gate.adopted, [same(b)],
          reason: 'every adoption is reported to the gate');
      expect(dialCount, 2);

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test(
      '#3915 — the supervisor CLOSES the instance it abandons on a drop '
      'signal, so a consumer still holding it reads a dead flag', () {
    fakeAsync((async) {
      late Obd2Service a;
      late Obd2Service b;
      unawaited(healthyService().then((s) => a = s));
      unawaited(healthyService().then((s) => b = s));
      async.flushMicrotasks();

      // The redial is GATED so the intermediate state is observable.
      final redial = Completer<Obd2Service?>();
      var dialCount = 0;
      final sup = build(() => ++dialCount == 1 ? Future.value(a) : redial.future);
      unawaited(sup.connect());
      async.flushMicrotasks();
      expect(sup.service, same(a));

      drops.add(const Obd2LinkDropEvent(
          transportKind: 'ble', reason: 'session:stale'));
      async.flushMicrotasks();
      expect(sup.state.value, Obd2LinkState.reconnecting,
          reason: 'state leaves ready before the release — no consumer '
              'adopts the corpse meanwhile');
      expect(a.isConnected, isFalse,
          reason: 'the abandoned instance is closed, not leaked open with '
              'a lying connected flag');
      expect(dialCount, 2, reason: 'the socket closed BEFORE the redial');

      redial.complete(b);
      async.elapse(const Duration(seconds: 2));
      expect(sup.service, same(b));

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test(
      '#3915 — ensureLive recycles a connected-FLAG instance that fails '
      'the round-trip; a live one is untouched', () {
    fakeAsync((async) {
      final corpseTransport = _ConnectedButMuteTransport();
      final corpse = Obd2Service(corpseTransport);
      late Obd2Service healthy;
      unawaited(healthyService().then((s) => healthy = s));
      async.flushMicrotasks();

      var dialCount = 0;
      final sup = build(() async => ++dialCount == 1 ? corpse : healthy);
      unawaited(sup.connect());
      async.flushMicrotasks();
      expect(sup.service, same(corpse));

      sup.ensureLive(reason: 'test');
      async.elapse(const Duration(seconds: 3));
      expect(corpseTransport.isConnected, isFalse);
      expect(sup.service, same(healthy),
          reason: 'the flag lied; the probe told the truth; recycled');
      expect(dialCount, 2);

      // A live link: ensureLive probes and leaves it alone.
      sup.ensureLive(reason: 'test');
      async.elapse(const Duration(seconds: 3));
      expect(sup.service, same(healthy));
      expect(dialCount, 2);

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });
}

/// Gate that refuses a fixed set of instances and records adoptions.
class _RecordingGate implements Obd2AdoptionGate {
  _RecordingGate({required List<Obd2Service> refused})
      : _refused = Set<Obd2Service>.identity()..addAll(refused);

  final Set<Obd2Service> _refused;
  final List<Obd2Service> adopted = [];

  @override
  bool isRefused(Obd2Service service) => _refused.contains(service);

  @override
  void noteAdopted(Obd2Service service) => adopted.add(service);
}

/// The field corpse: `isConnected` stays true while every command throws
/// instantly (a byte channel whose session was cleared by a write-time
/// drop — the transport's connected flag never flipped).
class _ConnectedButMuteTransport implements Obd2Transport {
  bool _connected = true;
  final List<String> sentCommands = [];

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async => _connected = true;

  @override
  Future<void> disconnect() async => _connected = false;

  @override
  Future<String> sendCommand(String command) async {
    sentCommands.add(command.trim());
    throw const Obd2DisconnectedException(
      'FlutterBluePlusElmChannel: not open',
    );
  }
}
