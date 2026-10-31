// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/protocol/diagnostics/diagnostic_report_analyzer.dart';
import 'package:tankstellen/features/obd2/data/protocol/diagnostics/mode01_reply_bytes.dart';
import 'package:tankstellen/features/obd2/domain/diagnostics/diagnostic_report.dart';

/// #4552 — one rule per system, each in its good / check / problem /
/// not-reported shape, from synthetic traces in the recorder's format.
class _Trace {
  final _lines = <String>[
    jsonEncode({'k': 'header', 't': 0, 'schema': 1}),
  ];

  void cmd(int t, String c, String r) =>
      _lines.add(jsonEncode({'k': 'cmd', 't': t, 'c': c, 'r': r, 'ms': 40}));

  void mark(int t, String p, Map<String, Object?> data) =>
      _lines.add(jsonEncode({'k': 'mark', 't': t, 'p': p, ...data}));

  String hex(int v) => v.toRadixString(16).toUpperCase().padLeft(2, '0');

  void rpm(int t, double rpm) {
    final raw = (rpm * 4).round();
    cmd(t, '010C', '41 0C ${hex(raw >> 8)} ${hex(raw & 0xFF)}');
  }

  void speed(int t, int kmh) => cmd(t, '010D', '41 0D ${hex(kmh)}');
  void volts(int t, double v) => cmd(t, 'ATRV', '${v.toStringAsFixed(1)}V');
  void pedal(int t, double pct) =>
      cmd(t, '0149', '41 49 ${hex((pct * 255 / 100).round())}');
  void coolant(int t, int c) => cmd(t, '0105', '41 05 ${hex(c + 40)}');
  void trims(int t, double stft, double ltft) {
    cmd(t, '0106', '41 06 ${hex((stft * 128 / 100 + 128).round())}');
    cmd(t, '0107', '41 07 ${hex((ltft * 128 / 100 + 128).round())}');
  }

  /// Engine running steadily at [v] volts for [seconds] from [from] ms.
  void cruise(int from, int seconds, double v, {int kmh = 60}) {
    for (var s = 0; s < seconds; s++) {
      final t = from + s * 1000;
      rpm(t, 2000);
      speed(t + 100, kmh);
      volts(t + 200, v);
    }
  }

  String get text => _lines.join('\n');
}

void main() {
  test('mode01Bytes picks the first answering ECU and stops at the next '
      'echo', () {
    expect(mode01Bytes('41 0C 1A F8', 0x0C), [0x1A, 0xF8]);
    expect(mode01Bytes('41 0C 1A F8 | 41 0C 00 00', 0x0C), [0x1A, 0xF8]);
    expect(mode01Bytes('NO DATA', 0x0C), isNull);
    expect(mode01Bytes('41 0D 32', 0x0C), isNull);
  });

  group('electrical', () {
    test('healthy charging is good', () {
      final t = _Trace()..cruise(0, 30, 14.1);
      final r = analyzeDiagnosticRecording(t.text).electrical;
      expect(r.verdict, HealthVerdict.good);
      expect(r.runningAvgV, closeTo(14.1, 0.01));
      expect(r.dipCount, 0);
    });

    test('a dip below 12 V with the engine on is a problem, counted once '
        'per episode, cranking excluded', () {
      final t = _Trace()
        ..rpm(0, 800)
        ..volts(500, 9.8) // cranking — ignored
        ..cruise(6000, 10, 14.0)
        ..volts(16500, 11.6)
        ..rpm(16600, 1200)
        ..volts(17000, 11.4)
        ..rpm(17100, 1200)
        ..cruise(18000, 5, 14.0);
      final r = analyzeDiagnosticRecording(t.text).electrical;
      expect(r.verdict, HealthVerdict.problem);
      expect(r.dipCount, 1);
      expect(r.runningMinV, closeTo(11.4, 0.01));
    });

    test('a low charging average is a problem', () {
      final t = _Trace()..cruise(0, 20, 12.6);
      expect(analyzeDiagnosticRecording(t.text).electrical.verdict,
          HealthVerdict.problem);
    });

    test('no voltage at all is not reported', () {
      final t = _Trace()..rpm(0, 2000);
      expect(analyzeDiagnosticRecording(t.text).electrical.verdict,
          HealthVerdict.notReported);
    });
  });

  group('drive', () {
    test('engine near idle at 15 km/h with the pedal pressed is an episode, '
        'stamped with the voltage', () {
      final t = _Trace()..cruise(0, 10, 14.0);
      for (var i = 0; i < 4; i++) {
        final at = 10000 + i * 400;
        t
          ..pedal(at, 40)
          ..volts(at + 50, 11.8)
          ..speed(at + 100, 15)
          ..rpm(at + 200, 780);
      }
      t.cruise(20000, 5, 14.0, kmh: 20);
      final r = analyzeDiagnosticRecording(t.text).transmission;
      expect(r.episodes, hasLength(1));
      final ep = r.episodes.single;
      expect(ep.at.inSeconds, 10);
      expect(ep.speedKmh, 15);
      expect(ep.voltageV, closeTo(11.8, 0.01));
      expect(r.verdict, HealthVerdict.check);
      expect(r.gearReported, isFalse);
    });

    test('coasting at idle with the foot off the pedal is NOT an episode', () {
      final t = _Trace()..cruise(0, 5, 14.0);
      for (var i = 0; i < 5; i++) {
        final at = 6000 + i * 400;
        t
          ..pedal(at, 0)
          ..speed(at + 100, 15)
          ..rpm(at + 200, 780);
      }
      final r = analyzeDiagnosticRecording(t.text).transmission;
      expect(r.episodes, isEmpty);
      expect(r.verdict, HealthVerdict.good);
    });

    test('the gearbox reporting neutral while moving is a problem', () {
      final t = _Trace()..cruise(0, 3, 14.0, kmh: 20);
      t.cmd(3100, '01A4', '41 A4 02 00 00 00'); // supported, gear 0
      t.speed(3200, 18);
      t.rpm(3300, 1500);
      final r = analyzeDiagnosticRecording(t.text).transmission;
      expect(r.gearReported, isTrue);
      expect(r.episodes.single.neutral, isTrue);
      expect(r.verdict, HealthVerdict.problem);
    });

    test('no speed/rpm at all is not reported', () {
      expect(analyzeDiagnosticRecording(_Trace().text).transmission.verdict,
          HealthVerdict.notReported);
    });
  });

  group('engine + mixture', () {
    test('overheating is a problem', () {
      final t = _Trace()..cruise(0, 3, 14)..coolant(500, 115);
      final e = analyzeDiagnosticRecording(t.text).engine;
      expect(e.verdict, HealthVerdict.problem);
      expect(e.coolantMaxC, 115);
    });

    test('a warm engine trimming −15 % runs rich: check', () {
      final t = _Trace()..coolant(0, 90);
      for (var s = 0; s < 10; s++) {
        t
          ..rpm(s * 1000, 2000)
          ..trims(s * 1000 + 100, -10, -5);
      }
      final m = analyzeDiagnosticRecording(t.text).mixture;
      expect(m.avgTrimPct, closeTo(-15, 1));
      expect(m.verdict, HealthVerdict.check);
    });

    test('balanced trims are good', () {
      final t = _Trace()..coolant(0, 90);
      for (var s = 0; s < 5; s++) {
        t
          ..rpm(s * 1000, 2000)
          ..trims(s * 1000 + 100, 2, -1);
      }
      expect(analyzeDiagnosticRecording(t.text).mixture.verdict,
          HealthVerdict.good);
    });
  });

  group('fault codes', () {
    test('MIL on and a stored code: problem, with the codes', () {
      final t = _Trace()
        ..cmd(0, '0101', '41 01 81 07 65 00')
        ..cmd(100, '03', '43 01 07 30')
        ..mark(150, 'dtc', {'c': '03', 'codes': ['P0730']});
      final f = analyzeDiagnosticRecording(t.text).faults;
      expect(f.milOn, isTrue);
      expect(f.stored, ['P0730']);
      expect(f.verdict, HealthVerdict.problem);
      expect(dtcGroupOf('P0730'), DtcGroup.transmission);
    });

    test('only a pending code: check', () {
      final t = _Trace()
        ..cmd(0, '0101', '41 01 00 07 65 00')
        ..mark(100, 'dtc', {'c': '07', 'codes': ['P0301']});
      expect(analyzeDiagnosticRecording(t.text).faults.verdict,
          HealthVerdict.check);
    });

    test('clean: good', () {
      final t = _Trace()
        ..cmd(0, '0101', '41 01 00 07 65 00')
        ..cmd(100, '03', '43 00');
      expect(analyzeDiagnosticRecording(t.text).faults.verdict,
          HealthVerdict.good);
    });
  });

  test('summary counts and the never-answered list (AT commands excluded)',
      () {
    final t = _Trace()
      ..cruise(0, 61, 14.0)
      ..cmd(500, '01A4', 'NO DATA')
      ..cmd(600, 'ATH1', '?');
    final r = analyzeDiagnosticRecording(t.text);
    expect(r.duration.inSeconds, 60);
    expect(r.distinctValues, 3);
    expect(r.unanswered, ['01A4']);
  });

  test('a torn last line (crash mid-write) is skipped, not fatal', () {
    final t = _Trace()..cruise(0, 10, 14.0); // past the 5 s cranking window
    final r = analyzeDiagnosticRecording('${t.text}\n{"k":"cmd","t":9');
    expect(r.electrical.verdict, HealthVerdict.good);
  });
}
