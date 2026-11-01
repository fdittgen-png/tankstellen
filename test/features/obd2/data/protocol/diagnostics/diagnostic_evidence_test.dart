// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/protocol/diagnostics/diagnostic_evidence.dart';

void main() {
  late DiagnosticEvidence evidence;
  void reply(String c, String r, [int t = 1000]) =>
      evidence.addLine(jsonEncode({'k': 'cmd', 't': t, 'c': c, 'r': r}));
  Map<String, dynamic> signal(String name) =>
      (evidence.toJson()['signals'] as Map)[name] as Map<String, dynamic>;
  setUp(() => evidence = DiagnosticEvidence());

  test(
    'narrowband voltage, trims, pressure, timing and wideband are separate',
    () {
      reply('0114', '41 14 80 FF'); // O2 voltage, trim not reported
      reply('0106', '41 06 90'); // +12.5%
      reply('0107', '41 07 88'); // +6.25%
      reply('010A', '41 0A 64'); // 300kPa
      reply('010E', '41 0E 98'); // 12deg
      reply('0124', '41 24 80 00 20 00'); // phi1.0
      expect(signal('o2Sensor1Voltage')['mean'], 0.64);
      expect(signal('o2Sensor1Trim')['mean'], isNull);
      expect(signal('stftBank1')['mean'], 12.5);
      expect(signal('ltftBank1')['mean'], 6.25);
      expect(signal('fuelPressureGauge')['mean'], 300.0);
      expect(signal('ignitionTimingAdvance')['mean'], 12.0);
      expect(signal('widebandVoltageSensor1Lambda')['mean'], 1.0);
      expect(signal('widebandCurrentSensor1Lambda')['mean'], isNull);
    },
  );

  test('0x41 inside sensor payload is data, not a reply boundary', () {
    reply('010B', '41 0B 41');
    reply('0142', '41 42 30 41');
    expect(signal('map')['mean'], 65.0);
    expect(signal('controlModuleVoltage')['mean'], 12.353);
  });

  test('absent, NO DATA, invalid and failed reads never fabricate zero', () {
    reply('010A', 'NO DATA');
    reply('010A', '41 0A 64', 3000);
    reply('0124', '41 24 80'); // incomplete payload
    evidence.addLine(
      jsonEncode({'k': 'cmd', 'c': '0106', 'e': 'TimeoutException'}),
    );
    expect(signal('fuelPressureGauge')['attempts'], 2);
    expect(signal('fuelPressureGauge')['decodedReadings'], 1);
    expect(signal('stftBank1')['status'], 'requestedWithoutUsableReply');
    expect(signal('ltftBank1')['status'], 'notRequested');
    expect(signal('widebandVoltageSensor1Lambda')['decodedReadings'], 0);
    expect(signal('widebandVoltageSensor1Lambda')['mean'], isNull);
  });

  test(
    'intermittent codes remain observed even after the ECU clears its list',
    () {
      reply('03', '43 01 71 00 00');
      reply('03', '43 00', 4000);
      reply('07', 'NO DATA');
      reply('0101', '41 01 81 07 65 00');
      reply('020600', '42 06 00 90');
      final faults = evidence.toJson()['faults'] as Map;
      expect((faults['stored'] as Map)['observedCodes'], ['P0171']);
      expect((faults['stored'] as Map)['latestCodes'], isEmpty);
      expect((faults['pending'] as Map)['latestCodes'], isNull);
      expect(faults['milOn'], isTrue);
      expect(faults['reportedDtcCount'], 1);
      expect(evidence.toJson()['freezeFrameReplies'], contains('020600'));
    },
  );

  test(
    'closed loop states, actual gaps and interrupted traces are explicit',
    () {
      reply('0103', '41 03 02 00');
      reply('0106', '41 06 88');
      reply('0106', '41 06 90', 9000);
      expect(signal('stftBank1')['maxGapMs'], 8000);
      expect(signal('stftBank1')['maxAtEpochMs'], 9000);
      expect(
        (evidence.toJson()['fuelSystemStatus'] as Map)['counts'],
        containsPair('system1_0x02', 1),
      );
      expect(evidence.toJson()['completeTrace'], isFalse);
      evidence.addLine('{torn');
      evidence.addLine(jsonEncode({'k': 'mark', 'p': 'end'}));
      expect(evidence.toJson()['completeTrace'], isFalse);
      expect(evidence.toJson()['malformedLines'], 1);
    },
  );
  test(
    'truncated positive replies do not clear codes or claim usable readings',
    () {
      reply('03', '43 01 71');
      reply('03', '43', 2000);
      reply('03', '43 02 01 71', 3000);
      reply('0124', '41 24 80');
      final stored = (evidence.toJson()['faults'] as Map)['stored'] as Map;
      expect(stored['latestCodes'], ['P0171']);
      expect(stored['outcomes'], {'answered': 1, 'invalidReply': 2});
      expect((evidence.toJson()['faults'] as Map)['changes'], hasLength(1));
      expect(
        signal('widebandVoltageSensor1Lambda')['status'],
        'requestedWithoutUsableReply',
      );
      expect(signal('widebandVoltageSensor1Lambda')['outcomes'], {
        'invalidReply': 1,
      });
    },
  );

  test(
    'decoded sensor timeline keeps real request timestamps without resampling',
    () {
      reply('0106', '41 06 90', 1234);
      reply('0107', '41 07 88', 1678);
      reply('0103', '41 03 02 00', 1900);
      final timeline = evidence.toJson()['sensorTimeline'] as Map;
      final rows = timeline['rows'] as List;
      expect(rows, hasLength(3));
      expect(rows[0], containsPair('atEpochMs', 1234));
      expect((rows[0] as Map)['values'], containsPair('stftBank1', 12.5));
      expect((rows[1] as Map)['values'], containsPair('ltftBank1', 6.25));
      expect(timeline['resampled'], isFalse);
      expect(timeline['omittedRows'], 0);
    },
  );

  test(
    'timeline cap is explicit while statistics still include later readings',
    () {
      for (var i = 0; i < DiagnosticEvidence.timelineRowCap + 2; i++) {
        reply('0106', '41 06 90', i);
      }
      final timeline = evidence.toJson()['sensorTimeline'] as Map;
      expect(timeline['rows'], hasLength(DiagnosticEvidence.timelineRowCap));
      expect(timeline['omittedRows'], 2);
      expect(
        signal('stftBank1')['decodedReadings'],
        DiagnosticEvidence.timelineRowCap + 2,
      );
    },
  );
}
