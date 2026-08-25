// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3776 / #3777 (Epic #3775) — the supervisor's link-ownership seams.
//
// Deliberate closes are suppressed from the transport drop signal by
// design (`_closing` latches, the ElmSession detach), so a layer that
// deliberately kills a supervisor-owned link MUST report it through
// `reportServiceDead` — otherwise the supervisor sits in `ready`
// holding a corpse forever (its `_setState` dedupes, so no consumer
// waiting on a `ready` transition ever wakes: the 2026-08-25 field trip
// recorded 0/309 engine samples exactly this way). `ensureLive` is the
// level-triggered self-heal for whatever corpse still slips through.

import 'dart:async';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_link_supervisor.dart';
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

  test('reportServiceDead on the owned service: leaves ready synchronously, '
      'closes the corpse, redials to a fresh ready', () {
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

      final taken = sup.reportServiceDead(svcA, reason: 'test-verdict');
      expect(taken, isTrue);
      // Synchronous truth: the corpse is out of circulation before any
      // await — no consumer may adopt it in the closing window.
      expect(sup.service, isNull);
      expect(sup.state.value, Obd2LinkState.reconnecting);

      async.elapse(const Duration(seconds: 2));
      expect(svcA.isConnected, isFalse,
          reason: 'the owner closes the reported corpse');
      expect(sup.state.value, Obd2LinkState.ready);
      expect(sup.service, same(svcB),
          reason: 'the ladder redialed to a fresh service');
      expect(dialCount, 2);

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('reportServiceDead on a service the supervisor does NOT hold: '
      'declined, state untouched, no dial', () {
    fakeAsync((async) {
      late Obd2Service owned;
      late Obd2Service foreign;
      var dialCount = 0;
      unawaited(connectedService().then((s) => owned = s));
      unawaited(connectedService().then((s) => foreign = s));
      async.flushMicrotasks();

      final sup = build(() async {
        dialCount++;
        return owned;
      });
      unawaited(sup.connect());
      async.flushMicrotasks();
      final dialsAfterConnect = dialCount;

      expect(sup.reportServiceDead(foreign, reason: 'test'), isFalse);
      async.elapse(const Duration(seconds: 2));
      expect(sup.state.value, Obd2LinkState.ready);
      expect(sup.service, same(owned));
      expect(dialCount, dialsAfterConnect, reason: 'no extra dial');
      expect(foreign.isConnected, isTrue,
          reason: 'a declined report closes nothing — the caller owns it');

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('ensureLive: ready holding a dead transport recycles to a fresh '
      'ready; a live link is a no-op', () {
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

      // Live link: ensureLive must not touch anything.
      sup.ensureLive(reason: 'test');
      async.elapse(const Duration(seconds: 1));
      expect(sup.service, same(svcA));
      expect(dialCount, 1);

      // The corpse shape: transport dies with the drop signal suppressed
      // (a deliberate close) — the supervisor still says ready.
      unawaited(svcA.disconnect());
      async.flushMicrotasks();
      expect(sup.state.value, Obd2LinkState.ready);

      sup.ensureLive(reason: 'test');
      async.elapse(const Duration(seconds: 2));
      expect(sup.state.value, Obd2LinkState.ready);
      expect(sup.service, same(svcB), reason: 'recycled through the ladder');
      expect(dialCount, 2);

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });
}
