// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// #3459 — idle-reconnect flap latch. Field evidence (2026-07-03 export,
// build 2026061861): liveReconnect SUCCESS every ~9 s for minutes while
// parked — each success reset the backoff, so the loop never converged.
// These tests pin: 3 young-death sessions latch the stand-down; a
// surviving session or an explicit user action clears it; a flapping
// SUCCESS alone never does.

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/obd2/data/last_good_adapter_store.dart';
import 'package:tankstellen/features/obd2/data/obd2_flap_latch.dart';
import 'package:tankstellen/features/obd2/data/obd2_reconnect_controller.dart';

class _MapStorage implements SettingsStorage {
  final Map<String, dynamic> data = {};
  @override
  dynamic getSetting(String key) => data[key];
  @override
  Future<void> putSetting(String key, dynamic value) async =>
      data[key] = value;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  group('Obd2FlapLatch (pure)', () {
    late DateTime t;
    late Obd2FlapLatch latch;

    setUp(() {
      t = DateTime(2026, 7, 3, 8, 49);
      latch = Obd2FlapLatch();
    });

    void session(Duration lived) {
      latch.noteConnected(t);
      t = t.add(lived);
      latch.noteDropped(t);
      t = t.add(const Duration(seconds: 2));
    }

    test('three consecutive short sessions latch; the third returns true '
        'exactly once', () {
      latch.noteConnected(t);
      t = t.add(const Duration(seconds: 9));
      expect(latch.noteDropped(t), isFalse);
      latch.noteConnected(t);
      t = t.add(const Duration(seconds: 9));
      expect(latch.noteDropped(t), isFalse);
      latch.noteConnected(t);
      t = t.add(const Duration(seconds: 9));
      expect(latch.noteDropped(t), isTrue, reason: 'third strike latches');
      expect(latch.flapping, isTrue);
      // A fourth short session stays latched without re-signalling.
      latch.noteConnected(t);
      t = t.add(const Duration(seconds: 9));
      expect(latch.noteDropped(t), isFalse);
      expect(latch.flapping, isTrue);
    });

    test('a flapping SUCCESS alone never clears the latch — only session '
        'lifetime or clear() do', () {
      session(const Duration(seconds: 9));
      session(const Duration(seconds: 9));
      session(const Duration(seconds: 9));
      expect(latch.flapping, isTrue);
      latch.noteConnected(t); // connect succeeds again…
      expect(latch.flapping, isTrue,
          reason: 'success is the symptom, not the recovery');
    });

    test('a session surviving the short threshold clears organically', () {
      session(const Duration(seconds: 9));
      session(const Duration(seconds: 9));
      session(const Duration(seconds: 9));
      expect(latch.flapping, isTrue);
      session(const Duration(seconds: 45));
      expect(latch.flapping, isFalse);
      expect(latch.shortSessionCount, 0);
    });

    test('clear() (user action) re-arms', () {
      session(const Duration(seconds: 9));
      session(const Duration(seconds: 9));
      session(const Duration(seconds: 9));
      latch.clear();
      expect(latch.flapping, isFalse);
      expect(latch.shortSessionCount, 0);
    });

    test('a drop with no tracked session is neutral', () {
      expect(latch.noteDropped(t), isFalse);
      expect(latch.shortSessionCount, 0);
    });
  });

  group('Obd2ReconnectController + flap latch (#3459)', () {
    late DateTime now;
    late Obd2ReconnectController ctl;
    late List<Obd2ReconnectState> states;
    var dials = 0;

    setUp(() {
      now = DateTime(2026, 7, 3, 8, 49);
      dials = 0;
      states = [];
      ctl = Obd2ReconnectController(
        pinStore: LastGoodAdapterStore(_MapStorage()),
        pinnedConnect: (_) async {
          dials++;
          return Obd2ReconnectAttemptResult.failed;
        },
        rescanConnect: (_) async {
          dials++;
          return Obd2ReconnectAttemptResult.failed;
        },
        now: () => now,
      );
      ctl.onState = states.add;
    });

    void flapCycle({int seconds = 9}) {
      ctl.notifyConnected();
      now = now.add(Duration(seconds: seconds));
      ctl.notifyDropped(reason: 'classic-socket-error');
    }

    test('after 3 success→instant-drop cycles the controller goes terminal '
        'WITHOUT scheduling a 4th automatic dial', () async {
      flapCycle();
      // Cycle 1+2 start reconnect episodes; a success ends each.
      expect(states.last, Obd2ReconnectState.reconnecting);
      flapCycle();
      flapCycle();
      expect(states.last, Obd2ReconnectState.terminalFailed,
          reason: 'the third young death latches the stand-down');
      expect(ctl.isFlapLatched, isTrue);
      final dialsAtLatch = dials;
      // Another success→drop while latched: still no new episode.
      flapCycle();
      expect(states.last, Obd2ReconnectState.terminalFailed);
      expect(dials, dialsAtLatch, reason: 'no automatic dial while latched');
    });

    test('a session surviving the threshold clears the latch and the next '
        'drop starts a normal episode', () {
      flapCycle();
      flapCycle();
      flapCycle();
      expect(ctl.isFlapLatched, isTrue);
      ctl.notifyConnected();
      now = now.add(const Duration(seconds: 45));
      ctl.notifyDropped(reason: 'classic-socket-error');
      expect(ctl.isFlapLatched, isFalse);
      expect(states.last, Obd2ReconnectState.reconnecting,
          reason: 'organic recovery re-arms the dialler');
      ctl.stop();
    });

    test('retry() clears the latch', () {
      flapCycle();
      flapCycle();
      flapCycle();
      expect(ctl.isFlapLatched, isTrue);
      ctl.retry();
      expect(ctl.isFlapLatched, isFalse);
      expect(states.last, Obd2ReconnectState.reconnecting);
      ctl.stop();
    });
  });
}
