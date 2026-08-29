// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/obd2_engine_coverage.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';

/// #3499 (epic #3498) — engine-sample coverage classification: the honest
/// explanation for a `gpsPlusObd2` trip whose fuel figures fell back to the
/// GPS-physics estimate.
void main() {
  List<bool> flags(String pattern) => [for (final c in pattern.split('')) c == 'e'];

  test('zero engine samples → noEngineData (the field-export case)', () {
    final c = Obd2EngineCoverage.fromFlags(flags('....................'))!;
    expect(c.reason, Obd2EngineCoverageReason.noEngineData);
    expect(c.engineSamples, 0);
    expect(c.share, 0);
    expect(c.lastEngineAtShare, 0);
  });

  test('engine PIDs on ~every sample → full', () {
    final c = Obd2EngineCoverage.fromFlags(flags('eeeeeeeeee.eeeeeeeee'))!;
    expect(c.reason, Obd2EngineCoverageReason.full);
    expect(c.share, closeTo(0.95, 0.001));
  });

  test('engine data ends mid-trip → droppedMidTrip, drop point exposed', () {
    // Engine on the first half only — the adapter-dropped signature.
    final c = Obd2EngineCoverage.fromFlags(flags('eeeeeeeeee..........'))!;
    expect(c.reason, Obd2EngineCoverageReason.droppedMidTrip);
    expect(c.lastEngineAtShare, closeTo(9 / 19, 0.001));
  });

  test('patchy coverage reaching the trip end → partial, not dropped', () {
    final c = Obd2EngineCoverage.fromFlags(flags('e...e...e...e...e..e'))!;
    expect(c.reason, Obd2EngineCoverageReason.partial);
    expect(c.lastEngineAtShare, 1.0);
  });

  test('empty trip → null (nothing to classify)', () {
    expect(Obd2EngineCoverage.fromFlags(const []), isNull);
  });

  test('fromTripSamples uses the measured-engine predicate — an estimated '
      'fuel rate does NOT count', () {
    final t0 = DateTime(2026, 7, 5, 8);
    TripSample sample({double? rpm}) => TripSample(
          timestamp: t0,
          speedKmh: 50,
          rpm: rpm,
        );
    // No engine field set anywhere → noEngineData even on a moving trip.
    final none = Obd2EngineCoverage.fromTripSamples(
        [for (var i = 0; i < 10; i++) sample()])!;
    expect(none.reason, Obd2EngineCoverageReason.noEngineData);
    final full = Obd2EngineCoverage.fromTripSamples(
        [for (var i = 0; i < 10; i++) sample(rpm: 1800)])!;
    expect(full.reason, Obd2EngineCoverageReason.full);
  });

  test('toJson carries the schema-v4 export keys', () {
    final c = Obd2EngineCoverage.fromFlags(flags('eeeee...............'))!;
    final json = c.toJson();
    expect(json['engineSamples'], 5);
    expect(json['totalSamples'], 20);
    expect(json['engineSampleShare'], 0.25);
    expect(json['reason'], 'droppedMidTrip');
  });

  group('#3861 the engine-running envelope', () {
    // 'r' = running (rpm at the floor, engine-bearing), 'e' = engine-bearing
    // but rpm 0 (ignition on), '.' = GPS-only.
    Obd2EngineCoverage build(String pattern, {int secondsPerSample = 10}) {
      final chars = pattern.split('');
      final t0 = DateTime(2026, 8, 29, 8);
      return Obd2EngineCoverage.fromFlags(
        [for (final c in chars) c != '.'],
        isRunningBySample: [for (final c in chars) c == 'r'],
        timestamps: [
          for (var i = 0; i < chars.length; i++)
            t0.add(Duration(seconds: i * secondsPerSample)),
        ],
      )!;
    }

    test('a parked tail is NOT a mid-trip drop', () {
      // 12 running samples, then 8 GPS-only — the user switched the engine
      // off with the recording running. Whole-trip this read 60 % and
      // "engine data stopped 58 % into the trip (connection dropped)".
      final c = build('rrrrrrrrrrrr........');
      expect(c.reason, Obd2EngineCoverageReason.full);
      expect(c.share, 1.0);
      expect(c.envelopeSamples, 12);
      expect(c.headOffSeconds, 0);
      expect(c.tailOffSeconds, closeTo(80, 0.01));
      expect(c.hasEngineOffEdges, isTrue);
    });

    test('an engine-off start is a head, not missing data', () {
      final c = build('......rrrrrrrrrrrrrr');
      expect(c.reason, Obd2EngineCoverageReason.full);
      expect(c.headOffSeconds, closeTo(60, 0.01));
      expect(c.tailOffSeconds, 0);
    });

    test('a real drop INSIDE the envelope is still a drop', () {
      // Engine ran at both ends; the link died for the middle 60 %.
      final c = build('rrrr............rrrr');
      expect(c.envelopeSamples, 20);
      expect(c.share, closeTo(0.4, 0.001));
      expect(c.reason, Obd2EngineCoverageReason.partial,
          reason: 'engine data reaches the trip end, so patchy, not dropped');
      expect(c.hasEngineOffEdges, isFalse);
    });

    test('a link that died and never came back inside the envelope reads '
        'droppedMidTrip — the envelope ends where running data ends', () {
      // Running, then the ADAPTER died: rpm gone, but GPS-only samples
      // carry no running flag either, so the envelope ends at the drop.
      // That is indistinguishable from an engine-off tail on samples
      // alone — which is exactly why the recording session classifies
      // the drop live (#3859) and the envelope note only fires on `full`.
      final c = build('rrrrrrrrrr..........');
      expect(c.reason, Obd2EngineCoverageReason.full);
      expect(c.tailOffSeconds, closeTo(100, 0.01));
    });

    test('ignition-on samples (rpm 0) count as engine data but do not open '
        'the envelope', () {
      final c = build('eeeerrrrrrrrrrrreeee');
      expect(c.envelopeSamples, 12);
      expect(c.reason, Obd2EngineCoverageReason.full);
      expect(c.headOffSeconds, closeTo(40, 0.01));
    });

    test('a short key-on shuffle is below the note floor', () {
      final c = build('..rrrrrrrrrrrrrrrrrr', secondsPerSample: 5);
      expect(c.headOffSeconds, closeTo(10, 0.01));
      expect(c.hasEngineOffEdges, isFalse);
    });

    test('no running sample at all keeps the whole-trip behaviour', () {
      final c = build('eeeeeeeeee..........');
      expect(c.envelopeSamples, 20,
          reason: 'no envelope → the whole trip, exactly as before');
      expect(c.reason, Obd2EngineCoverageReason.droppedMidTrip);
    });

    test('toJson carries the envelope only when it exists', () {
      final c = build('rrrrrrrrrr..........');
      expect(c.toJson()['envelopeSamples'], 10);
      expect(c.toJson()['tailOffSeconds'], 100.0);
      final legacy = Obd2EngineCoverage.fromFlags([true, true, false])!;
      expect(legacy.toJson().containsKey('envelopeSamples'), isFalse);
    });
  });
}
