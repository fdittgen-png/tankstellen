// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3625 — the reattach source must never hand the trip layer a corpse.
// Field flap: after an in-trip drop the supervisor still HELD the very
// service the trip had just dropped (transport closed, reference
// lingering in the ready state); the immediate-fire path delivered it,
// the resumed scheduler polled a dead socket, re-dropped instantly, and
// the dial → adopt → drop cycle recorded a whole trip with zero engine
// data. Only a service whose transport is actually open may fire.
import 'dart:async';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_link_supervisor.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_reattach_source.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';

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

  Future<Obd2Service> connectedService() async {
    final transport = FakeObd2Transport();
    await transport.connect();
    return Obd2Service(transport);
  }

  test('a held-but-DEAD service does not immediate-fire; the next genuine '
      'ready with a live service does', () {
    fakeAsync((async) {
      late Obd2Service svcA;
      late Obd2Service svcB;
      var dialCount = 0;
      unawaited(connectedService().then((s) => svcA = s));
      unawaited(connectedService().then((s) => svcB = s));
      async.flushMicrotasks();

      final sup = build(() async => ++dialCount == 1 ? svcA : svcB);
      unawaited(sup.connect());
      async.flushMicrotasks();
      expect(sup.service, same(svcA));

      // The trip drops the link: its transport closes, but the
      // supervisor still holds the reference in the ready state.
      unawaited(svcA.disconnect());
      async.flushMicrotasks();
      expect(svcA.isConnected, isFalse);
      expect(sup.service, same(svcA),
          reason: 'the corpse scenario: ready state, dead transport');

      final fired = <Obd2Service>[];
      final src = SupervisorReattachSource(
        sup,
        onConnected: fired.add,
        onReconnect: () {},
      );
      unawaited(src.start());
      async.flushMicrotasks();
      expect(fired, isNot(contains(same(svcA))),
          reason: 'firing with the dropped service is the #3625 flap — '
              'a dead transport must never be handed to the trip');

      // #3777 (Epic #3775) — the source is LEVEL-triggered: a deliberate
      // close is suppressed from the drop signal by design, so waiting
      // for an external drop event here was a dead end (the supervisor
      // dedupes `ready`→`ready` and never emits again — the 2026-08-25
      // field trip waited on that edge for the whole drive). The corpse
      // now routes through `supervisor.ensureLive` → recycle → redial,
      // with NO external event needed.
      async.elapse(const Duration(seconds: 6));
      expect(fired, [same(svcB)],
          reason: 'self-healed: the fresh, connected service is adopted '
              'without any external drop signal (#3777)');

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('a held-and-LIVE service still immediate-fires (#3531 fast path)',
      () {
    fakeAsync((async) {
      late Obd2Service svc;
      unawaited(connectedService().then((s) => svc = s));
      async.flushMicrotasks();

      final sup = build(() async => svc);
      unawaited(sup.connect());
      async.flushMicrotasks();

      final fired = <Obd2Service>[];
      final src = SupervisorReattachSource(
        sup,
        onConnected: fired.add,
        onReconnect: () {},
      );
      unawaited(src.start());
      async.flushMicrotasks();
      expect(fired, [same(svc)]);

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });
}
