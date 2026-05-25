// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/trip_summary.dart';

void main() {
  group('TripKind (#2025)', () {
    test('wireName round-trips through fromWireName', () {
      for (final k in TripKind.values) {
        expect(TripKind.fromWireName(k.wireName), k);
      }
    });

    test('fromWireName defaults to gpsPlusObd2 for null / unknown', () {
      expect(TripKind.fromWireName(null), TripKind.gpsPlusObd2);
      expect(TripKind.fromWireName('garbage'), TripKind.gpsPlusObd2);
      expect(TripKind.fromWireName(''), TripKind.gpsPlusObd2);
    });

    test('TripSummary defaults kind to gpsPlusObd2 — preserves legacy trips',
        () {
      const summary = TripSummary(
        distanceKm: 1.0,
        maxRpm: 1000,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
      );
      expect(summary.kind, TripKind.gpsPlusObd2);
    });

    test('copyWith preserves and overrides kind correctly', () {
      const original = TripSummary(
        distanceKm: 1.0,
        maxRpm: 1000,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        kind: TripKind.gpsOnly,
      );
      expect(original.copyWith().kind, TripKind.gpsOnly);
      expect(
          original.copyWith(kind: TripKind.gpsPlusObd2).kind,
          TripKind.gpsPlusObd2);
    });
  });
}
