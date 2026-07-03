// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_recovery_natives.dart';
import 'package:tankstellen/features/obd2/data/obd2_wedge_detector.dart';
import 'package:tankstellen/features/obd2/data/obd2_wedge_recovery.dart';

import '../../../helpers/silence_error_logger.dart';

/// Scriptable fake natives recording every call in order, so the tests
/// assert the LADDER ORDERING (#3422) without any platform channel.
class _FakeNatives implements Obd2WedgeRecoveryNatives {
  final calls = <String>[];

  bool sdpAccepts = true;
  bool removeBondOk = true;
  bool createBondOk = true;
  bool disableResolves = true;
  bool fireOk = true;
  bool settingsOk = true;

  /// Scripted adapter-enabled answers, consumed in order (sticky last).
  List<bool> adapterStates = [true];
  int _adapterIdx = 0;

  @override
  Future<bool> fetchUuidsWithSdp(String mac) async {
    calls.add('sdp:$mac');
    return sdpAccepts;
  }

  @override
  Future<bool> removeBond(String mac) async {
    calls.add('removeBond:$mac');
    return removeBondOk;
  }

  @override
  Future<bool> createBond(String mac) async {
    calls.add('createBond:$mac');
    return createBondOk;
  }

  @override
  Future<bool> adapterEnabled() async {
    calls.add('adapterEnabled');
    final i = _adapterIdx < adapterStates.length
        ? _adapterIdx
        : adapterStates.length - 1;
    _adapterIdx++;
    return adapterStates[i];
  }

  @override
  Future<bool> resolveBtIntent(String action) async {
    calls.add('resolve:$action');
    return action == kBtActionRequestDisable ? disableResolves : true;
  }

  @override
  Future<bool> fireBtIntent(String action) async {
    calls.add('fire:$action');
    return fireOk;
  }

  @override
  Future<bool> openBluetoothSettings() async {
    calls.add('openSettings');
    return settingsOk;
  }
}

const _instant = Obd2WedgeRecoveryTimings(
  sdpSettle: Duration.zero,
  bondSettle: Duration.zero,
  bondWait: Duration.zero,
  adapterPoll: Duration(milliseconds: 1),
  adapterOffWait: Duration(milliseconds: 3),
  adapterOnWait: Duration(milliseconds: 3),
  postEnableSettle: Duration.zero,
  settingsGrace: Duration.zero,
);

void main() {
  silenceErrorLoggerSpool();

  late _FakeNatives natives;
  late Obd2WedgeDetector detector;
  late List<String> traces;
  late List<String> probes;
  late bool recordingLease;

  setUp(() {
    natives = _FakeNatives();
    detector = Obd2WedgeDetector();
    traces = [];
    probes = [];
    recordingLease = false;
  });

  Obd2WedgeRecovery recovery({List<bool>? probeAnswers}) {
    final answers = probeAnswers ?? const <bool>[];
    var probeIdx = 0;
    final r = Obd2WedgeRecovery(
      natives: natives,
      detector: detector,
      timings: _instant,
      wait: (_) async {},
      recordingLeaseHeld: () => recordingLease,
    );
    r.onTrace = (event, data) => traces.add(event);
    r.probeConnect = (mac) async {
      probes.add(mac);
      if (probeIdx < answers.length) return answers[probeIdx++];
      return false;
    };
    return r;
  }

  /// Latch the wedge the way production does — via 3 exhausted ladders.
  void wedge() {
    for (var i = 0; i < 3; i++) {
      detector.noteClassicConnectOutcome(
          mac: 'AA:BB', ok: false, strategy: 'exhausted');
    }
    expect(detector.isWedged, isTrue);
  }

  group('Obd2WedgeRecovery ladder ordering (#3422)', () {
    test('rung 1 success (SDP refresh + probe) recovers without touching '
        'later rungs', () async {
      wedge();
      final r = recovery(probeAnswers: [true]);
      await r.start('AA:BB');

      expect(natives.calls, ['sdp:AA:BB']);
      expect(probes, ['AA:BB']);
      expect(detector.isWedged, isFalse, reason: 'rung success clears wedge');
      expect(traces, contains('wedge: wedge-recovered'));
      expect(r.hintPending.value, isFalse);
    });

    test('rung 1 gets exactly one bounded retry before escalating', () async {
      wedge();
      final r = recovery(); // every probe misses
      await r.start('AA:BB');

      expect(natives.calls.where((c) => c == 'sdp:AA:BB').length, 2);
      // Escalated past rung 2 (config-off) into rung 3.
      expect(traces, contains('wedge: rung-rebond-skipped'));
      expect(natives.calls, contains('resolve:$kBtActionRequestDisable'));
    });

    test('rung 2 is OFF by default (developer flag) — no bond calls', () async {
      wedge();
      await recovery().start('AA:BB');
      expect(natives.calls.where((c) => c.startsWith('removeBond')), isEmpty);
      expect(natives.calls.where((c) => c.startsWith('createBond')), isEmpty);
    });

    test('rung 2 runs remove+create bond when the flag is on and no '
        'recording lease holds the link', () async {
      wedge();
      natives.disableResolves = false;
      natives.settingsOk = false; // stop rung 3 side effects for clarity
      final r = recovery(probeAnswers: [false, false, true]);
      r.rebondEnabled = true;
      await r.start('AA:BB');

      final i = natives.calls.indexOf('removeBond:AA:BB');
      expect(i, greaterThan(0), reason: 'after the SDP rung');
      expect(natives.calls.indexOf('createBond:AA:BB'), greaterThan(i));
      expect(detector.isWedged, isFalse, reason: 'third probe recovered');
    });

    test('rung 2 never runs while a recording lease holds the link', () async {
      wedge();
      recordingLease = true;
      final r = recovery();
      r.rebondEnabled = true;
      await r.start('AA:BB');
      expect(natives.calls.where((c) => c.startsWith('removeBond')), isEmpty);
      expect(traces, contains('wedge: rung-rebond-skipped'));
    });

    test('rung 3 consent cycle: disable dialog → adapter-off edge → enable '
        'dialog → adapter-on edge → probe', () async {
      wedge();
      // Off after the first poll, back on after the next.
      natives.adapterStates = [false, true];
      final r = recovery(probeAnswers: [false, false, true]);
      await r.start('AA:BB');

      final fires = natives.calls.where((c) => c.startsWith('fire:')).toList();
      expect(fires, [
        'fire:$kBtActionRequestDisable',
        'fire:$kBtActionRequestEnable',
      ]);
      expect(detector.isWedged, isFalse);
      expect(natives.calls, isNot(contains('openSettings')),
          reason: 'consent path resolved — no deep-link fallback');
    });

    test('rung 3 falls back to the Settings deep-link when REQUEST_DISABLE '
        'does not resolve on this OEM', () async {
      wedge();
      natives.disableResolves = false;
      await recovery().start('AA:BB');

      expect(natives.calls.where((c) => c.startsWith('fire:')), isEmpty);
      expect(natives.calls, contains('openSettings'));
    });

    test('all rungs dry → the one-time hint is raised — and only once per '
        'wedge episode across ladder re-runs', () async {
      wedge();
      natives.disableResolves = false;
      natives.settingsOk = false;
      final r = recovery();
      await r.start('AA:BB');
      expect(r.hintPending.value, isTrue);

      r.dismissHint();
      await r.start('AA:BB'); // a second run in the SAME wedge episode
      expect(r.hintPending.value, isFalse,
          reason: 'the hint is one-time per wedge episode');
      expect(traces, contains('wedge: rung-hint-suppressed'));

      // A NEW wedge episode re-arms the one-shot.
      detector.noteRecovered('user');
      wedge();
      await r.start('AA:BB');
      expect(r.hintPending.value, isTrue);
    });

    test('the wedge clearing externally mid-ladder stops the escalation '
        '(stand-down semantics)', () async {
      wedge();
      final r = recovery();
      // Clear the wedge the moment rung 1 runs its first probe.
      r.probeConnect = (mac) async {
        detector.noteClassicConnectOutcome(mac: mac, ok: true);
        return false; // the probe itself reports a miss
      };
      await r.start('AA:BB');
      expect(natives.calls.where((c) => c.startsWith('resolve:')), isEmpty,
          reason: 'rung 3 must not run once the wedge cleared');
      expect(r.hintPending.value, isFalse);
    });

    test('start() never throws — a throwing probe seam is logged and the '
        'ladder continues to the hint (fault injection)', () async {
      wedge();
      natives.disableResolves = false;
      natives.settingsOk = false;
      final r = recovery();
      r.probeConnect = (_) async => throw StateError('probe blew up');
      await expectLater(r.start('AA:BB'), completes);
      expect(r.hintPending.value, isTrue);
    });

    test('a second start() while running is ignored (re-entrancy guard)',
        () async {
      wedge();
      final r = recovery();
      final first = r.start('AA:BB');
      await r.start('AA:BB');
      expect(traces, contains('wedge: ladder-already-running'));
      await first;
    });

    test('every rung start/result is traced for the field export', () async {
      wedge();
      natives.adapterStates = [false, true];
      final r = recovery();
      r.rebondEnabled = true;
      await r.start('AA:BB');
      expect(
        traces,
        containsAllInOrder([
          'wedge: ladder-start',
          'wedge: rung-sdp-start',
          'wedge: rung-sdp-kickoff',
          'wedge: rung-rebond-removebond',
          'wedge: rung-btcycle-disable-fired',
          'wedge: rung-hint-raised',
        ]),
      );
    });
  });
}
