// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3534 (Epic #3527) — the induced-drop recovery chain is visible in the
// breadcrumb export: detect (`OBD2 link drop`) → failed dial(s)
// (`OBD2 dial failed`) → recovery (`OBD2 link ready — recovered after N
// dial(s)`), plus the engine-off park marker. This is the fake-level
// counterpart of the adapter-unplug test in
// docs/guides/obd2-link-rewrite-validation.md.

import 'dart:async';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_supervisor.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';

Obd2Service _liveService() => Obd2Service(FakeObd2Transport());

class _ScriptedDialer {
  final List<Object?> _script = [];
  int calls = 0;

  void enqueue(Object? outcome) => _script.add(outcome);

  Future<Obd2Service?> dial() async {
    calls++;
    final outcome = _script.length > 1 ? _script.removeAt(0) : _script.first;
    if (outcome is Obd2Service) return outcome;
    if (outcome == null) return null;
    throw outcome;
  }
}

void main() {
  late StreamController<Obd2LinkDropEvent> drops;
  late _ScriptedDialer dialer;

  Obd2LinkSupervisor build() => Obd2LinkSupervisor(
        dial: dialer.dial,
        drops: drops.stream,
        initialBackoff: const Duration(milliseconds: 500),
        maxBackoff: const Duration(seconds: 30),
        jitter: Random(42),
      );

  setUp(() {
    BreadcrumbCollector.clear();
    drops = StreamController<Obd2LinkDropEvent>.broadcast();
    dialer = _ScriptedDialer();
  });

  tearDown(() {
    BreadcrumbCollector.clear();
    return drops.close();
  });

  List<String> crumbs() => BreadcrumbCollector.snapshot()
      .map((b) => '${b.action}|${b.detail ?? ''}')
      .toList();

  test('induced drop → the export shows the full detect→dial→recovered '
      'chain in order', () {
    fakeAsync((async) {
      dialer.enqueue(StateError('adapter out of range')); // dial 1: fault
      dialer.enqueue(null); // dial 2: clean miss
      dialer.enqueue(_liveService()); // dial 3: back
      final sup = build();

      drops.add(const Obd2LinkDropEvent(
          transportKind: 'classic', reason: 'socket-error'));
      async.flushMicrotasks(); // immediate dial (fault) → backoff armed
      async.elapse(const Duration(seconds: 2)); // miss → second backoff
      async.elapse(const Duration(seconds: 4)); // success

      expect(sup.state.value, Obd2LinkState.ready);
      final chain = crumbs();
      final dropAt =
          chain.indexWhere((c) => c.startsWith('OBD2 link drop|'));
      final failAt =
          chain.indexWhere((c) => c.startsWith('OBD2 dial failed|'));
      final readyAt =
          chain.indexWhere((c) => c.startsWith('OBD2 link ready|'));
      expect(dropAt, isNot(-1), reason: 'detect marker missing: $chain');
      expect(failAt, greaterThan(dropAt),
          reason: 'failed dial must follow the drop: $chain');
      expect(readyAt, greaterThan(failAt),
          reason: 'recovery must close the chain: $chain');
      expect(chain[dropAt], contains('classic:socket-error'),
          reason: 'the drop breadcrumb carries the transport + cause');
      expect(chain[readyAt], contains('recovered after 3 dial(s)'),
          reason: 'the recovery breadcrumb counts the dials it took');

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('a plain first connect breadcrumbs "first connect", not a recovery',
      () {
    fakeAsync((async) {
      dialer.enqueue(_liveService());
      final sup = build();

      unawaited(sup.connect());
      async.flushMicrotasks();

      expect(sup.state.value, Obd2LinkState.ready);
      expect(
        crumbs().any((c) => c == 'OBD2 link ready|first connect'),
        isTrue,
        reason: 'crumbs: ${crumbs()}',
      );
      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('engine-off parks the loop with its own marker', () {
    fakeAsync((async) {
      dialer.enqueue(_liveService());
      final sup = build();
      unawaited(sup.connect());
      async.flushMicrotasks();

      sup.noteEngineOff();

      expect(sup.state.value, Obd2LinkState.engineOff);
      expect(
        crumbs().any((c) => c == 'OBD2 link parked|engine off'),
        isTrue,
        reason: 'crumbs: ${crumbs()}',
      );
      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });
}
