// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3756 — reliability-first stand-down taming. Field report 2026-08-22
// ("adapter works only for a short time, then nothing"): three young
// links dying in a row tripped the #3603 flap stand-down and held the
// reconnect loop off for 5–15 minutes WHILE THE CAR WAS DRIVING
// (2026-08-17 export: "flap x3 — holding 303s" mid-trip). Two fixes:
//
//  1. Fresh ENGINE EVIDENCE (a parsed speed / rpm>0 within 10 min)
//     suppresses the stand-down entirely — mid-drive drops keep the
//     fast ladder for the whole drive. Parked cars produce no engine
//     parses, so the #3642 battery protection is untouched there.
//  2. A dying link that completed >=5 real OBD commands is PROOF the
//     link works — its drop clears the flap streak instead of feeding
//     it (the flap concept targets the zero-traffic corpse-adopt).
import 'dart:async';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_link_supervisor.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/obd2/domain/obd2_engine_evidence.dart';
import 'package:tankstellen/features/obd2/domain/obd2_reconnect_stand_down.dart';

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

void main() {
  late StreamController<Obd2LinkDropEvent> drops;
  late _ScriptedDialer dialer;
  late DateTime nowValue;
  late Obd2EngineEvidence evidence;

  void elapse(FakeAsync async, Duration d) {
    nowValue = nowValue.add(d);
    async.elapse(d);
  }

  const storm = Duration(minutes: 5);

  Obd2LinkSupervisor build() => Obd2LinkSupervisor(
        dial: dialer.dial,
        drops: drops.stream,
        initialBackoff: const Duration(milliseconds: 500),
        maxBackoff: const Duration(seconds: 30),
        stormBackoff: storm,
        jitter: Random(42),
        now: () => nowValue,
        engineEvidence: evidence,
      );

  setUp(() {
    drops = StreamController<Obd2LinkDropEvent>.broadcast();
    dialer = _ScriptedDialer();
    nowValue = DateTime(2026, 8, 22, 8, 30);
    evidence = Obd2EngineEvidence(now: () => nowValue);
  });

  tearDown(() => drops.close());

  void dropNow() => drops.add(const Obd2LinkDropEvent(
      transportKind: 'classic', reason: 'socket-error'));

  test('fresh engine evidence suppresses the miss-streak stand-down — '
      'mid-drive drops keep the fast ladder', () {
    fakeAsync((async) {
      dialer.enqueue(TimeoutException('ladder budget'));
      final sup = build();
      evidence.noteEngineOn(); // the car was demonstrably driving

      dropNow();
      async.flushMicrotasks();
      elapse(async, const Duration(seconds: 3));
      expect(dialer.calls, 3);
      expect(sup.inStandDown, isFalse,
          reason: 'three identical faults WOULD stand down, but the '
              'engine was on 3 s ago — keep dialing');

      // The fast ladder keeps firing through what would have been the
      // 5-minute storm hold (2 s → 4 s → 8 s … capped at 30 s).
      elapse(async, const Duration(minutes: 2));
      expect(dialer.calls, greaterThanOrEqualTo(8),
          reason: 'no 5-minute silence mid-drive');

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('stale evidence (>10 min) restores full stand-down protection — '
      'the parked-car battery shape is untouched', () {
    fakeAsync((async) {
      dialer.enqueue(TimeoutException('ladder budget'));
      final sup = build();
      evidence.noteEngineOn();
      // Park: 11 minutes pass before the fault streak forms.
      elapse(async, const Duration(minutes: 11));

      dropNow();
      async.flushMicrotasks();
      elapse(async, const Duration(seconds: 3));
      expect(dialer.calls, 3);
      expect(sup.inStandDown, isTrue,
          reason: 'no fresh evidence — the storm hold engages exactly '
              'as before #3756');
      final callsAtHold = dialer.calls;
      elapse(async, const Duration(minutes: 2));
      expect(dialer.calls, callsAtHold,
          reason: 'parked: no dial inside the storm hold');

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('a trafficked ready (>=5 completed OBD commands) clears the flap '
      'streak on drop instead of feeding it', () {
    final standDown = ReconnectStandDown(now: () => nowValue);
    // Three zero-traffic flaps arm the stand-down…
    for (var i = 0; i < ReconnectStandDown.threshold; i++) {
      standDown.noteReady();
      nowValue = nowValue.add(const Duration(seconds: 4));
      standDown.noteDrop();
    }
    expect(standDown.active, isTrue);

    // …but ONE ready that carried real traffic clears the streak even
    // though it died inside the flap window.
    standDown.noteReady();
    nowValue = nowValue.add(const Duration(seconds: 4));
    standDown.noteDrop(trafficked: true);
    expect(standDown.active, isFalse,
        reason: 'completed OBD commands are proof the link works — not '
            'the corpse-adopt shape the flap counter targets');
  });

  test('engine evidence is stamped by parsed engine PIDs, not by '
      'adapter-only liveness', () async {
    final shared = Obd2EngineEvidence.instance..reset();
    addTearDown(shared.reset);
    final transport = FakeObd2Transport({
      '010D': '41 0D 3C', // 60 km/h — parses
      '010C': 'NO DATA', // ECU silent — must NOT stamp
    });
    await transport.connect();
    final service = Obd2Service(transport);

    expect(await service.readRpm(), isNull);
    expect(shared.isFresh(), isFalse,
        reason: 'NO DATA answers come from powered-but-parked adapters '
            'too — never evidence');

    expect(await service.readSpeedKmh(), 60);
    expect(shared.isFresh(), isTrue,
        reason: 'a parsed road speed only comes from an awake ECU');
  });
}
