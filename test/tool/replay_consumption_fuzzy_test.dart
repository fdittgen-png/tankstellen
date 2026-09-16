// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// The fuzzy half of the replay harness (#4232). In-process, never spawned
// (#3752). The traces here are hand-written arithmetic fixtures for the
// integration logic — not corpus traces, and they validate no accuracy.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/fuzzy_consumption/fuzzy_consumption_engine.dart';

import '../../tool/replay_consumption.dart';
import '../../tool/replay_consumption_fuzzy.dart';

void main() {
  test('the stamp mapping covers exactly the harness tag sets', () {
    final native = {
      for (final t in kMeasuredTags)
        if (nativeSourceForTag(t) != null) t,
    };
    final physics = {
      for (final t in kEstimatedTags)
        if (physicsBasisForTag(t) != null) t,
    };
    expect(native, kMeasuredTags);
    expect(physics, kEstimatedTags);
    expect(nativeSourceForTag('maf'), isNull);
    expect(physicsBasisForTag('pid5E'), isNull);
  });

  test('the gap horizon matches the harness gate', () {
    expect(kFuzzyReplayMaxGapSeconds, ReplayGates.maxGapSeconds);
  });

  group('sample → engine input', () {
    test('a native stamp becomes a native reading, never physics', () {
      final input = fuzzyInputForSample(
          {'t': 0, 's': 50.0, 'f': 4.0, 'fs': 'pid9D', 'r': 2000.0});
      expect(input.nativeFuelRateLPerHour, const FuzzyReading(4));
      expect(input.nativeSource, NativeFuelRateSource.pid9D);
      expect(input.physicsFuelRateLPerHour, isNull);
      expect(input.rpm, const FuzzyReading(2000));
    });

    test('an air-mass stamp becomes physics with its basis', () {
      final input =
          fuzzyInputForSample({'t': 0, 's': 50.0, 'f': 4.0, 'fs': 'speedDensity'});
      expect(input.physicsBasis, FuzzyPhysicsBasis.speedDensity);
      expect(input.physicsFuelRateLPerHour, const FuzzyReading(4));
      expect(input.nativeSource, isNull);
    });

    test("the GPS estimate 'fe' is road-load physics", () {
      final input = fuzzyInputForSample({'t': 0, 's': 50.0, 'fe': 3.0});
      expect(input.physicsBasis, FuzzyPhysicsBasis.gpsRoadLoad);
      expect(input.physicsFuelRateLPerHour, const FuzzyReading(3));
    });

    test('acceleration comes from the previous sample; the rest is missing',
        () {
      final input = fuzzyInputForSample({'t': 2000, 's': 36.0},
          previous: {'t': 0, 's': 18.0}, dtSeconds: 2);
      expect(input.accelMps2!.value, closeTo(2.5, 1e-12));
      expect(input.gradePercent, isNull,
          reason: 'sampleToJson carries no grade — replayed as missing');
      expect(input.vehicleMassKg, isNull);
    });
  });

  group('integration', () {
    List<Map<String, dynamic>> ticks(int n, Map<String, dynamic> extra,
            {int stepMs = 1000}) =>
        [
          for (var i = 0; i < n; i++)
            <String, dynamic>{'t': i * stepMs, 's': 50.0, ...extra},
        ];

    test('a constant 3.6 L/h over 100 s integrates to 0.1 L', () {
      final out = replayFuzzy(ticks(101, {'f': 3.6, 'fs': 'maf'}));
      expect(out.litres, closeTo(0.1, 1e-12));
      expect(out.incompleteReason, isNull);
      expect(out.kinds[FuzzyOutputKind.estimated], 100);
    });

    test('native ticks integrate as measured', () {
      final out = replayFuzzy(ticks(11, {'f': 7.2, 'fs': 'pid5E'}));
      expect(out.litres, closeTo(0.02, 1e-12));
      expect(out.kinds[FuzzyOutputKind.measured], 10);
    });

    test('samples replay in time order whatever the file order', () {
      final samples = ticks(21, {'f': 3.6, 'fs': 'maf'}).reversed.toList();
      expect(replayFuzzy(samples).litres, closeTo(0.02, 1e-12));
    });

    test('a trace with no fuel input is stated incomplete, not zero', () {
      final out = replayFuzzy(ticks(20, const {}));
      expect(out.incompleteReason, contains('no fuzzy figure'));
      expect(out.kinds[FuzzyOutputKind.unavailable], 19);
    });

    test('a gap longer than the horizon makes the trace incomplete', () {
      final samples = [
        ...ticks(5, {'f': 3.6, 'fs': 'maf'}),
        {'t': 200000, 's': 50.0, 'f': 3.6, 'fs': 'maf'},
      ];
      expect(replayFuzzy(samples).incompleteReason, isNotNull);
    });
  });

  test('the report puts the fuzzy table beside the shipped one', () {
    final tmp = Directory.systemTemp.createTempSync('replay_fuzzy_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    File('${tmp.path}/e1.summary.json').writeAsStringSync(
        '{"distanceKm":10.0,"truthLitres":0.380,"fuelLitersConsumed":0.40}');
    // 20 samples, 20 s apart: 380 s at 3.6 L/h = 0.38 L.
    File('${tmp.path}/e1.samples.ndjson').writeAsStringSync([
      for (var i = 0; i < 20; i++)
        '{"t":${i * 20000},"s":50.0,"fs":"maf","f":3.6}',
    ].join('\n'));

    final report = buildReplayReport(corpusDir: tmp.path);

    expect(report, contains('Error by source class'));
    expect(report, contains('Fuzzy engine (#4232)'));
    expect(report, contains('Model 1, rules 1'));
    // Shipped +5.3 %, fuzzy exact.
    expect(report, contains('+5.3 %'));
    expect(report, matches(RegExp(r'\| [+-]?0\.0 % \|')),
        reason: 'the fuzzy row integrates the per-tick rate exactly');
  });
}
