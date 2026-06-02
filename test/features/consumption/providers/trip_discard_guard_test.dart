// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_distance_source.dart';
import 'package:tankstellen/features/consumption/domain/trip_summary.dart';
import 'package:tankstellen/features/consumption/providers/trip_discard_guard.dart';

/// #2692 C4-H — the empty-trip discard guard. The 10 empty trips in the
/// 77-trip field backup escaped the pre-fix `distanceKm < 0.01` guard
/// because the virtual dead-reckoning odometer integrated a distance ≥
/// 0.01 km with NO samples and NO GPS fixes. The new virtual-ghost clause
/// discards those regardless of distance, while a counter-test pins that
/// a real GPS-distance trip with fixes is still SAVED (no over-discard).
TripSummary _summary({
  required double distanceKm,
  required String distanceSource,
  DateTime? startedAt,
}) =>
    TripSummary(
      distanceKm: distanceKm,
      maxRpm: 0,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      startedAt: startedAt,
      distanceSource: distanceSource,
    );

void main() {
  group('#2692 C4-H shouldDiscardAsNoMovement', () {
    test(
        'virtual distance 0.5 km with NO samples and NO fixes is DISCARDED '
        '(escaped the < 0.01 km guard before the fix)', () {
      final discard = shouldDiscardAsNoMovement(
        summary: _summary(
          distanceKm: 0.5,
          distanceSource: kDistanceSourceVirtual,
          startedAt: DateTime.utc(2026),
        ),
        sampleCount: 0,
        gpsFixCount: 0,
      );
      expect(discard, isTrue);
    });

    test(
        'GPS-source distance 0.5 km with gpsFixCount > 0 is SAVED '
        '(real GPS-tracked drive — no over-discard)', () {
      final discard = shouldDiscardAsNoMovement(
        summary: _summary(
          distanceKm: 0.5,
          distanceSource: kDistanceSourceGps,
          startedAt: DateTime.utc(2026),
        ),
        sampleCount: 0,
        gpsFixCount: 12,
      );
      expect(discard, isFalse);
    });

    test(
        'a real virtual drive WITH samples is SAVED (only ghost trips with '
        'zero samples AND zero fixes are caught)', () {
      final discard = shouldDiscardAsNoMovement(
        summary: _summary(
          distanceKm: 0.5,
          distanceSource: kDistanceSourceVirtual,
          startedAt: DateTime.utc(2026),
        ),
        sampleCount: 120,
        gpsFixCount: 0,
      );
      expect(discard, isFalse);
    });

    test(
        'the original #1923/#2509 no-movement guard still fires '
        '(zero distance, no start time)', () {
      final discard = shouldDiscardAsNoMovement(
        summary: _summary(
          distanceKm: 0.0,
          distanceSource: kDistanceSourceVirtual,
        ),
        sampleCount: 0,
        gpsFixCount: 0,
      );
      expect(discard, isTrue);
    });

    test('a real-distance trip with a GPS start time is SAVED', () {
      final discard = shouldDiscardAsNoMovement(
        summary: _summary(
          distanceKm: 4.2,
          distanceSource: kDistanceSourceReal,
          startedAt: DateTime.utc(2026),
        ),
        sampleCount: 0,
        gpsFixCount: 0,
      );
      expect(discard, isFalse);
    });
  });
}
