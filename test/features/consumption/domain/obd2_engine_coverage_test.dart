// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/obd2_engine_coverage.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

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
}
