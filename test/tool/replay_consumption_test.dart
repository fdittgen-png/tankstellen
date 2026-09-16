// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Smoke + contract test for the consumption replay harness (#4231).
//
// Runs IN-PROCESS (import + call) — never via a spawned `dart run`
// (#3752: spawned tool processes are slow and flaky on the contended
// runner), the same rule `ratchet_report_test.dart` and
// `test_inventory_test.dart` follow.
//
// The most important case here is the **empty corpus**. That is the
// repository's real state: #4231 needs real recordings (vehicle, paired
// adapter, drives per source class, full-to-full fills) and inventing
// traces would defeat the validation gate built on them. So the harness
// has to be correct and useful with nothing to replay, and this test
// pins that rather than treating it as a degenerate case.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/trip_fuel_source.dart';

import '../../tool/replay_consumption.dart';

void main() {
  group('the tag sets stay in step with the app (#4231)', () {
    // `tool/` scripts must not import the Flutter-dependent app graph,
    // so the harness restates these two sets. The restatement is only
    // safe if something fails when they drift — that is this test, and
    // the tool's own comment promises it exists.
    test('measured tags match trip_fuel_source.dart exactly', () {
      expect(kMeasuredTags, kMeasuredFuelSourceTags,
          reason: 'a tag added app-side but not here would silently '
              'bucket a measured trace as unclassifiable');
    });

    test('estimated tags match trip_fuel_source.dart exactly', () {
      expect(kEstimatedTags, kEstimatedFuelSourceTags);
    });

    test('the two sets are disjoint', () {
      expect(kMeasuredTags.intersection(kEstimatedTags), isEmpty,
          reason: 'a tag in both would make the dominant-stamp winner '
              'ambiguous');
    });
  });

  group('an empty corpus reports honestly', () {
    test('the report says the harness is ready and the corpus is not', () {
      final report = buildReplayReport(corpusDir: 'does/not/exist');

      expect(report, contains('No traces'));
      expect(report, contains('#4231'),
          reason: 'the report should tell the reader what is missing and '
              'why, not just print an empty table');
      expect(report, contains('full-to-full'));
    });

    test('a corpus directory holding only a README yields no traces', () {
      // The committed state: the directory exists so the harness has
      // somewhere to look, and holds documentation rather than data.
      final traces = loadCorpus('test/fixtures/consumption_corpus');

      expect(traces, isEmpty,
          reason: 'a README is not a trace; only a .summary.json with a '
              'matching .samples.ndjson is');
    });
  });

  group('trace loading', () {
    late Directory tmp;

    setUp(() => tmp = Directory.systemTemp.createTempSync('replay_'));
    tearDown(() => tmp.deleteSync(recursive: true));

    void writeTrace(
      String name, {
      required String summary,
      required List<String> sampleLines,
    }) {
      File('${tmp.path}/$name.summary.json').writeAsStringSync(summary);
      File('${tmp.path}/$name.samples.ndjson')
          .writeAsStringSync(sampleLines.join('\n'));
    }

    /// 12 samples one second apart — clears `minSamples` (10) but not
    /// `minDurationSeconds` (120), so it exercises the duration gate.
    List<String> ticks(int count, {String? fs, int stepMs = 1000}) {
      final tag = fs == null ? '' : ',"fs":"$fs"';
      return [
        for (var i = 0; i < count; i++)
          '{"t":${1000000 + i * stepMs},"s":50.0$tag}',
      ];
    }

    test('a summary without its samples file is not a trace', () {
      File('${tmp.path}/lonely.summary.json')
          .writeAsStringSync('{"distanceKm":10.0}');

      expect(loadCorpus(tmp.path), isEmpty,
          reason: 'half a trace cannot be replayed, and silently treating '
              'it as one would report error on no samples');
    });

    test('an unparseable summary is skipped, not crashed on', () {
      writeTrace('broken',
          summary: '{not json', sampleLines: ticks(12, fs: 'pid5E'));

      expect(loadCorpus(tmp.path), isEmpty);
    });

    test('a torn sample line is skipped and the rest survive', () {
      // Same rule as the WAL parser: one torn line per hard kill is
      // expected, and every other sample must still load.
      writeTrace('torn', summary: '{"distanceKm":10.0}', sampleLines: [
        ...ticks(5, fs: 'pid5E'),
        '{"t":9999,"s":', // torn final write
        ...ticks(5, fs: 'pid5E'),
      ]);

      final traces = loadCorpus(tmp.path);
      expect(traces, hasLength(1));
      expect(traces.single.samples, hasLength(10));
    });

    test('traces load in a stable order', () {
      for (final n in ['c_trace', 'a_trace', 'b_trace']) {
        writeTrace(n,
            summary: '{"distanceKm":10.0}',
            sampleLines: ticks(12, fs: 'pid5E'));
      }

      expect(loadCorpus(tmp.path).map((t) => t.name),
          ['a_trace', 'b_trace', 'c_trace'],
          reason: 'a deterministic command must not depend on filesystem '
              'enumeration order');
    });
  });

  group('source classification follows the dominant stamp', () {
    ReplayTrace trace(List<String?> stamps, {String? kind}) => ReplayTrace(
          name: 't',
          summary: {'kind': ?kind},
          samples: [
            for (final s in stamps)
              <String, dynamic>{'t': 0, 's': 1.0, 'fs': ?s},
          ],
        );

    test('a native ECU stamp reads measured', () {
      expect(trace(['pid5E', 'pid5E', 'maf']).sourceClass,
          ReplaySourceClass.measured);
    });

    test('an air-mass stamp reads estimated', () {
      expect(trace(['maf', 'maf', 'pid5E']).sourceClass,
          ReplaySourceClass.estimated);
    });

    test('no stamps plus a gpsOnly kind reads gpsOnly', () {
      expect(trace([null, null], kind: 'gpsOnly').sourceClass,
          ReplaySourceClass.gpsOnly);
    });

    test('no stamps and no gpsOnly kind is honestly unclassifiable', () {
      // Not silently gpsOnly: a trip claiming OBD2 coverage with zero
      // provenance stamps is a recording defect, and calling it GPS-only
      // would hide that.
      expect(trace([null, null]).sourceClass, ReplaySourceClass.none);
    });

    test("the literal 'none' stamp does not count as provenance", () {
      expect(trace(['none', 'none'], kind: 'gpsOnly').sourceClass,
          ReplaySourceClass.gpsOnly);
    });
  });

  group('eligibility is stated, never silent', () {
    ReplayTrace trace({
      required int samples,
      double distanceKm = 10,
      double? truthLitres = 0.7,
      int stepMs = 20000,
    }) =>
        ReplayTrace(
          name: 't',
          summary: {
            'distanceKm': distanceKm,
            'truthLitres': ?truthLitres,
          },
          samples: [
            for (var i = 0; i < samples; i++)
              <String, dynamic>{'t': i * stepMs, 's': 50.0, 'fs': 'pid5E'},
          ],
        );

    test('too few samples says so', () {
      expect(trace(samples: 4).ineligibleReason, contains('samples'));
    });

    test('too short a distance says so', () {
      expect(trace(samples: 20, distanceKm: 0.4).ineligibleReason,
          contains('distance'));
    });

    test('too short a duration says so', () {
      expect(trace(samples: 12, stepMs: 1000).ineligibleReason,
          contains('duration'));
    });

    test('no pump truth says so — coverage without error', () {
      expect(trace(samples: 20, truthLitres: null).ineligibleReason,
          contains('truth'));
    });

    test('a trace clearing every gate is eligible', () {
      expect(trace(samples: 20).ineligibleReason, isNull);
    });

    test('the gates match PhysicsScaleCalibrator, not looser ones', () {
      // A trace production would refuse as ground truth must not become
      // a corpus entry under laxer rules.
      expect(ReplayGates.minDistanceKm, 2.0);
      expect(ReplayGates.minDurationSeconds, 120.0);
      expect(ReplayGates.minSamples, 10);
      expect(ReplayGates.maxGapSeconds, 60.0);
      expect(ReplayGates.minLPer100Km, 0.5);
      expect(ReplayGates.maxLPer100Km, 30.0);
    });
  });

  group('anonymisation is enforced, not assumed', () {
    test('a trace still carrying coordinates is flagged', () {
      final t = ReplayTrace(
        name: 'leaky',
        summary: const {'distanceKm': 10.0},
        samples: [
          <String, dynamic>{'t': 0, 's': 1.0, 'la': 48.85, 'lo': 2.35},
        ],
      );

      expect(t.carriesRawLocation, isTrue);
    });

    test('an offset-and-stripped trace is clean', () {
      final t = ReplayTrace(
        name: 'clean',
        summary: const {'distanceKm': 10.0},
        samples: [
          <String, dynamic>{'t': 0, 's': 1.0, 'al': 120.0},
        ],
      );

      expect(t.carriesRawLocation, isFalse,
          reason: 'altitude alone does not locate a driver; latitude and '
              'longitude do');
    });

    test('the report refuses to stay quiet about a leak', () {
      final tmp = Directory.systemTemp.createTempSync('replay_leak_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      File('${tmp.path}/leaky.summary.json')
          .writeAsStringSync('{"distanceKm":10.0,"truthLitres":0.7}');
      File('${tmp.path}/leaky.samples.ndjson').writeAsStringSync([
        for (var i = 0; i < 20; i++)
          '{"t":${i * 20000},"s":50.0,"fs":"pid5E","la":48.85,"lo":2.35}',
      ].join('\n'));

      final report = buildReplayReport(corpusDir: tmp.path);

      expect(report, contains('Anonymisation failed'));
      expect(report, contains('leaky'));
    });
  });

  group('the report shape', () {
    test('error is bucketed per source class, never one global number', () {
      final tmp = Directory.systemTemp.createTempSync('replay_rep_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      void write(String name, String fs, double shipped) {
        File('${tmp.path}/$name.summary.json').writeAsStringSync(
            '{"distanceKm":10.0,"truthLitres":0.700,'
            '"fuelLitersConsumed":$shipped}');
        File('${tmp.path}/$name.samples.ndjson').writeAsStringSync([
          for (var i = 0; i < 20; i++)
            '{"t":${i * 20000},"s":50.0,"fs":"$fs"}',
        ].join('\n'));
      }

      write('m1', 'pid5E', 0.70); // measured, exact
      write('e1', 'maf', 0.77); // estimated, +10 %

      final report = buildReplayReport(corpusDir: tmp.path);

      expect(report, contains('Error by source class'));
      expect(report, contains('measured'));
      expect(report, contains('estimated'));
      // The estimated bucket's bias must carry its SIGN — a consistently
      // high estimate is a different defect from a noisy one.
      expect(report, contains('+10.0 %'));
    });

    test('excluded traces are listed with their reason', () {
      final tmp = Directory.systemTemp.createTempSync('replay_skip_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      File('${tmp.path}/short.summary.json')
          .writeAsStringSync('{"distanceKm":0.2,"truthLitres":0.1}');
      File('${tmp.path}/short.samples.ndjson').writeAsStringSync([
        for (var i = 0; i < 20; i++) '{"t":${i * 20000},"s":50.0,"fs":"maf"}',
      ].join('\n'));

      final report = buildReplayReport(corpusDir: tmp.path);

      expect(report, contains('excluded from error'));
      expect(report, contains('short'));
      expect(report, contains('distance'));
    });
  });
}
