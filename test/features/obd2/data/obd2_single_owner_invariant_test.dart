// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3533 (Epic #3527) — locks the rewrite's core single-owner invariant:
// the trip layer NEVER dials. A [SupervisorReattachSource] is a pure
// subscriber to the ONE [Obd2LinkSupervisor]; whatever the trip layer
// does with it (start/stop churn, staying subscribed across state
// changes, receiving an already-live link), the dial count only ever
// moves from the supervisor's own loop.
//
// The other two rewrite invariants are already test-locked by
// `test/features/obd2/obd2_link_supervisor_test.dart` and are referenced
// here instead of duplicated:
//  * NO dead-end state — 'misses keep retrying with growing backoff —
//    NO terminal state' drives the loop far past the old attempt cap and
//    asserts it is still scheduling retries at the capped cadence.
//  * ONE intent flag — 'user disconnect parks the loop; later drops do
//    not dial', 'connect() clears the intent flag and dials again' and
//    'engineOff parks; wake() re-dials' cover the park/re-arm pair.

import 'dart:async';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_supervisor.dart';
import 'package:tankstellen/features/obd2/data/obd2_reattach_source.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';

Obd2Service _liveService() => Obd2Service(FakeObd2Transport());

/// Counting dialer: returns whatever [outcome] currently produces
/// (null = miss) and counts every invocation — the probe that proves
/// exactly one component ever dials.
class _CountingDialer {
  Obd2Service? Function() outcome = () => null;
  int calls = 0;

  Future<Obd2Service?> dial() async {
    calls++;
    return outcome();
  }
}

void main() {
  late StreamController<Obd2LinkDropEvent> drops;
  late _CountingDialer dialer;

  Obd2LinkSupervisor build() => Obd2LinkSupervisor(
        dial: dialer.dial,
        drops: drops.stream,
        initialBackoff: const Duration(milliseconds: 500),
        maxBackoff: const Duration(seconds: 30),
        jitter: Random(42),
      );

  SupervisorReattachSource source(
    Obd2LinkSupervisor sup, {
    void Function(Obd2Service service)? onConnected,
    VoidCallback? onReconnect,
  }) =>
      SupervisorReattachSource(
        sup,
        onConnected: onConnected ?? (_) {},
        onReconnect: onReconnect ?? () {},
      );

  setUp(() {
    drops = StreamController<Obd2LinkDropEvent>.broadcast();
    dialer = _CountingDialer();
  });

  tearDown(() => drops.close());

  group('#3533 single-owner invariant — the trip layer never dials', () {
    test('reattach-source start()/stop() churn places ZERO dials of its own',
        () {
      fakeAsync((async) {
        final sup = build();

        // An idle supervisor: hammer the reattach source. No dial may fire.
        final src = source(sup);
        for (var i = 0; i < 5; i++) {
          unawaited(src.start());
          unawaited(src.stop());
        }
        async.flushMicrotasks();
        expect(dialer.calls, 0,
            reason: 'a reattach source performs zero dialing of its own — '
                'starting/stopping it must never touch the adapter');

        unawaited(sup.dispose());
        async.flushMicrotasks();
      });
    });

    test(
        'while the supervisor reconnects, only ITS backoff loop moves the '
        'dial count — subscriber churn adds nothing', () {
      fakeAsync((async) {
        final sup = build(); // dialer misses forever

        drops.add(const Obd2LinkDropEvent(
            transportKind: 'classic', reason: 'socket-error'));
        async.flushMicrotasks();
        expect(sup.state.value, Obd2LinkState.reconnecting);
        final callsAfterDrop = dialer.calls;
        expect(callsAfterDrop, 1,
            reason: 'the drop triggers exactly one immediate dial — the '
                'supervisor\'s');

        // Hammer reattach sources mid-loop with NO time elapsing: were the
        // trip layer a second dial authority (the #3386 war), the count
        // would move here.
        final src = source(sup);
        for (var i = 0; i < 5; i++) {
          unawaited(src.start());
          unawaited(src.stop());
        }
        unawaited(source(sup).start()); // one left subscribed, too
        async.flushMicrotasks();
        expect(dialer.calls, callsAfterDrop,
            reason: 'subscriber churn while reconnecting must not add a '
                'single dial — reconnection has exactly ONE owner');

        // Time passes: the count grows — from the supervisor's own timer,
        // the only dial path that exists.
        async.elapse(const Duration(seconds: 10));
        expect(dialer.calls, greaterThan(callsAfterDrop),
            reason: 'the supervisor\'s own backoff loop is what dials');

        unawaited(sup.dispose());
        async.flushMicrotasks();
      });
    });

    test(
        'an already-ready link is delivered to the subscriber immediately — '
        'still zero dials from the trip layer', () {
      fakeAsync((async) {
        dialer.outcome = _liveService;
        final sup = build();
        unawaited(sup.connect());
        async.flushMicrotasks();
        expect(sup.state.value, Obd2LinkState.ready);
        expect(dialer.calls, 1);

        Obd2Service? delivered;
        var reconnected = false;
        final src = source(
          sup,
          onConnected: (s) => delivered = s,
          onReconnect: () => reconnected = true,
        );
        unawaited(src.start());
        async.flushMicrotasks();

        expect(delivered, isNotNull,
            reason: 'a supervisor that re-attached before the trip layer '
                'subscribed must deliver the live service immediately');
        expect(reconnected, isTrue);
        expect(dialer.calls, 1,
            reason: 'delivery consumed the EXISTING link — no new dial');

        unawaited(sup.dispose());
        async.flushMicrotasks();
      });
    });

    test(
        'user intent outranks the trip layer — a subscribed reattach source '
        'cannot un-park a user disconnect', () {
      fakeAsync((async) {
        final sup = build(); // dialer misses, for now
        unawaited(sup.disconnect());
        async.flushMicrotasks();
        expect(sup.state.value, Obd2LinkState.userDisconnected);

        var reconnected = false;
        final src = source(sup, onReconnect: () => reconnected = true);
        unawaited(src.start());
        drops.add(const Obd2LinkDropEvent(
            transportKind: 'ble', reason: 'disconnect-edge'));
        async.elapse(const Duration(minutes: 1));

        expect(dialer.calls, 0,
            reason: 'parked by the user — a waiting trip-layer subscriber '
                'adds no dialing pressure whatsoever');
        expect(reconnected, isFalse);

        // Only the supervisor's own connect() (the ONE re-arm) revives the
        // link — and the subscriber then gets its re-attach through the
        // subscription, not through any dial of its own.
        dialer.outcome = _liveService;
        unawaited(sup.connect());
        async.flushMicrotasks();
        expect(sup.state.value, Obd2LinkState.ready);
        expect(reconnected, isTrue,
            reason: 'the re-attach reaches the subscriber via the '
                'supervisor\'s state stream');
        expect(dialer.calls, 1,
            reason: 'exactly one dial — the supervisor\'s connect()');

        unawaited(sup.dispose());
        async.flushMicrotasks();
      });
    });
  });
}
