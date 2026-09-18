// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4343 (Epic #4195) — the latest user action wins over a pending
// manual dial. A connect the user started and then cancelled with
// disconnect() may still complete successfully afterwards; that late
// result must be released, never adopted: no `ready`, no held service,
// no later dial on its behalf. Every dial below is held open by a
// Completer so the ordering is exact — no timing sleeps.

import 'dart:async';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_link_supervisor.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';

/// A connected fake transport that counts its teardowns, so "released
/// exactly once" is observable.
class _CountingTransport extends FakeObd2Transport {
  int disconnects = 0;

  @override
  Future<void> disconnect() {
    disconnects++;
    return super.disconnect();
  }
}

/// One held-open dial: the test decides when (and with what) it lands.
class _GatedDial {
  _GatedDial() {
    unawaited(transport.connect());
  }

  final Completer<Obd2Service?> gate = Completer<Obd2Service?>();
  final _CountingTransport transport = _CountingTransport();
  late final Obd2Service service = Obd2Service(transport);
  int calls = 0;

  Future<Obd2Service?> dial() {
    calls++;
    return gate.future;
  }

  void succeed() => gate.complete(service);
}

void main() {
  late StreamController<Obd2LinkDropEvent> drops;

  setUp(() => drops = StreamController<Obd2LinkDropEvent>.broadcast());
  tearDown(() => drops.close());

  /// Builds a supervisor whose DEFAULT dialer serves [dials] in order,
  /// recording every state it publishes into [published].
  Obd2LinkSupervisor build(
      List<_GatedDial> dials, List<Obd2LinkState> published) {
    var next = 0;
    final sup = Obd2LinkSupervisor(
      dial: () => dials[next++].dial(),
      drops: drops.stream,
      jitter: Random(42),
    );
    sup.states.listen(published.add);
    return sup;
  }

  void expectLateResultDiscarded(
    Obd2LinkSupervisor sup,
    _GatedDial late,
    List<Obd2LinkState> publishedAfterDisconnect,
  ) {
    expect(sup.state.value, Obd2LinkState.userDisconnected);
    expect(sup.service, isNull, reason: 'the late service must not be adopted');
    expect(publishedAfterDisconnect, isNot(contains(Obd2LinkState.ready)),
        reason: 'no consumer may see a ready link the user already closed');
    expect(late.transport.isConnected, isFalse,
        reason: 'the obsolete link must be torn down, not leaked');
    expect(late.transport.disconnects, 1,
        reason: 'released exactly once');
  }

  test('connect → disconnect → late success is released, not adopted', () {
    fakeAsync((async) {
      final first = _GatedDial();
      final published = <Obd2LinkState>[];
      final sup = build([first], published);

      Obd2Service? connectResult = first.service;
      unawaited(sup.connect().then((svc) => connectResult = svc));
      async.flushMicrotasks();
      expect(first.calls, 1);
      expect(sup.state.value, Obd2LinkState.connecting);

      unawaited(sup.disconnect());
      async.flushMicrotasks();
      published.clear();

      first.succeed();
      async.flushMicrotasks();

      expectLateResultDiscarded(sup, first, published);
      expect(connectResult, isNull,
          reason: 'the cancelled caller must not receive a live service');

      // Parked: no automatic dial may follow on the cancelled intent.
      async.elapse(const Duration(minutes: 5));
      expect(first.calls, 1);
      expect(sup.state.value, Obd2LinkState.userDisconnected);
      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('connectWith → disconnect → late success is released, not adopted',
      () {
    fakeAsync((async) {
      final override = _GatedDial();
      final published = <Obd2LinkState>[];
      final sup = build(const [], published);

      unawaited(sup.connectWith(override.dial));
      async.flushMicrotasks();
      unawaited(sup.disconnect());
      async.flushMicrotasks();
      published.clear();

      override.succeed();
      async.flushMicrotasks();

      expectLateResultDiscarded(sup, override, published);
      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('an override queued behind a pending dial never dials once the user '
      'disconnected', () {
    fakeAsync((async) {
      final first = _GatedDial();
      final queued = _GatedDial();
      final published = <Obd2LinkState>[];
      final sup = build([first], published);

      unawaited(sup.connect());
      async.flushMicrotasks();
      unawaited(sup.connectWith(queued.dial));
      async.flushMicrotasks();
      expect(queued.calls, 0, reason: 'single flight — it waits its turn');

      unawaited(sup.disconnect());
      async.flushMicrotasks();

      // The predecessor misses — the path that used to start the queue.
      first.gate.complete(null);
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 5));

      expect(queued.calls, 0,
          reason: 'a cancelled queued override must never initiate a dial');
      expect(sup.state.value, Obd2LinkState.userDisconnected);
      expect(sup.service, isNull);
      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('a disconnect during the pre-dial recycle stops the attempt before '
      'it dials', () {
    fakeAsync((async) {
      // A live supervised link whose teardown the test holds open.
      final teardown = Completer<void>();
      final blocking = _BlockingTransport(teardown.future);
      unawaited(blocking.connect());
      final recycle = _GatedDial();
      final sup = Obd2LinkSupervisor(
        dial: recycle.dial,
        drops: drops.stream,
        jitter: Random(42),
      );
      unawaited(sup.connectWith(() async => Obd2Service(blocking)));
      async.flushMicrotasks();
      expect(sup.state.value, Obd2LinkState.ready);

      unawaited(sup.connect()); // recycles the held link first
      async.flushMicrotasks();
      unawaited(sup.disconnect());
      async.flushMicrotasks();
      teardown.complete();
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 5));

      expect(recycle.calls, 0, reason: 'the cancelled attempt must not dial');
      expect(sup.state.value, Obd2LinkState.userDisconnected);
      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('a connect with no disconnect still adopts its result', () {
    fakeAsync((async) {
      final first = _GatedDial();
      final published = <Obd2LinkState>[];
      final sup = build([first], published);

      Obd2Service? connectResult;
      unawaited(sup.connect().then((svc) => connectResult = svc));
      async.flushMicrotasks();
      first.succeed();
      async.flushMicrotasks();

      expect(sup.state.value, Obd2LinkState.ready);
      expect(sup.service, same(first.service));
      expect(connectResult, same(first.service));
      expect(published.last, Obd2LinkState.ready);
      expect(first.transport.isConnected, isTrue);
      expect(first.transport.disconnects, 0);
      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('connect → disconnect → connect adopts only the second attempt', () {
    fakeAsync((async) {
      final first = _GatedDial();
      final second = _GatedDial();
      final published = <Obd2LinkState>[];
      final sup = build([first, second], published);

      unawaited(sup.connect());
      async.flushMicrotasks();
      unawaited(sup.disconnect());
      async.flushMicrotasks();
      Obd2Service? secondResult;
      unawaited(sup.connect().then((svc) => secondResult = svc));
      async.flushMicrotasks();
      expect(second.calls, 0,
          reason: 'single flight — the new attempt waits for the old dial');

      // The obsolete dial lands first: released, and the newer intent
      // gets its own fresh dial.
      first.succeed();
      async.flushMicrotasks();
      expect(first.transport.isConnected, isFalse);
      expect(first.transport.disconnects, 1);
      expect(sup.service, isNull);
      expect(second.calls, 1);

      second.succeed();
      async.flushMicrotasks();

      expect(sup.state.value, Obd2LinkState.ready);
      expect(sup.service, same(second.service));
      expect(secondResult, same(second.service));
      expect(second.transport.isConnected, isTrue,
          reason: 'old work must never disconnect the newer service');
      expect(second.transport.disconnects, 0);
      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });
}

/// A transport whose teardown is held open by [release] — the recycle
/// window between "old link taken out" and "fresh dial".
class _BlockingTransport extends FakeObd2Transport {
  _BlockingTransport(this.release);

  final Future<void> release;

  @override
  Future<void> disconnect() async {
    await release;
    await super.disconnect();
  }
}
