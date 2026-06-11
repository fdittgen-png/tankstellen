// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/services/reconciliation_basis.dart';
import 'package:tankstellen/features/consumption/domain/trip_summary.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';

/// Unit tests for [reconciliationBasis] (#2440). The function is PURE —
/// every test passes window fills + trips directly and asserts on the
/// returned record, without Hive, Riverpod, or any UI.
void main() {
  FillUp makeFill({
    String id = 'fill',
    required double liters,
    bool isCorrection = false,
  }) =>
      FillUp(
        id: id,
        date: DateTime(2026, 4, 10),
        liters: liters,
        totalCost: liters * 1.5,
        odometerKm: 10000,
        fuelType: FuelType.e10,
        vehicleId: 'veh-a',
        isCorrection: isCorrection,
      );

  TripSummary makeTrip({
    required double? fuel,
    String? id,
  }) =>
      TripSummary(
        distanceKm: 100,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        fuelLitersConsumed: fuel,
        // Encode a synthetic identity in startedAt so the virtual
        // predicate has something stable to key on.
        startedAt: id == 'virtual'
            ? DateTime(2026, 4, 11)
            : DateTime(2026, 4, 10),
      );

  group('reconciliationBasis — fuelTotal', () {
    test('counts only real pumped litres; corrections excluded', () {
      final basis = reconciliationBasis(
        windowFills: [
          makeFill(id: 'a', liters: 40),
          makeFill(id: 'b', liters: 10),
          makeFill(id: 'corr', liters: 5, isCorrection: true),
        ],
        windowTrips: const [],
      );
      // Real pumped = 40 + 10; the 5 L correction is NOT in fuelTotal.
      expect(basis.fuelTotalLiters, 50);
    });

    test('zero fills → fuelTotal 0', () {
      final basis = reconciliationBasis(
        windowFills: const [],
        windowTrips: const [],
      );
      expect(basis.fuelTotalLiters, 0);
    });
  });

  group('reconciliationBasis — trajetsTotal', () {
    test('= consumed + correction litres + virtual-trip litres', () {
      final basis = reconciliationBasis(
        windowFills: [
          makeFill(id: 'a', liters: 50),
          makeFill(id: 'corr', liters: 5, isCorrection: true),
        ],
        windowTrips: [
          makeTrip(fuel: 30),
          makeTrip(fuel: 8, id: 'virtual'),
        ],
        isVirtualTrip: (t) => t.startedAt == DateTime(2026, 4, 11),
      );
      // 30 recorded + 5 correction + 8 virtual = 43.
      expect(basis.trajetsTotalLiters, 43);
      // fuelTotal stays honest at the real pumped 50.
      expect(basis.fuelTotalLiters, 50);
    });

    test('null fuelLitersConsumed trips contribute 0', () {
      final basis = reconciliationBasis(
        windowFills: [makeFill(liters: 40)],
        windowTrips: [
          makeTrip(fuel: null),
          makeTrip(fuel: 12),
        ],
      );
      expect(basis.trajetsTotalLiters, 12);
    });

    test('a virtual trip with null fuel contributes 0', () {
      final basis = reconciliationBasis(
        windowFills: [makeFill(liters: 40)],
        windowTrips: [makeTrip(fuel: null, id: 'virtual')],
        isVirtualTrip: (t) => t.startedAt == DateTime(2026, 4, 11),
      );
      expect(basis.trajetsTotalLiters, 0);
    });
  });

  group('reconciliationBasis — residual invariant', () {
    test('residual == gap before any correction/virtual', () {
      // Pumped 50, consumed 42 → gap 8.
      final basis = reconciliationBasis(
        windowFills: [makeFill(liters: 50)],
        windowTrips: [makeTrip(fuel: 42)],
      );
      expect(basis.residualLiters, 8);
    });

    test('residual == 0 when a correction of exactly the gap is added', () {
      // Pumped 50, consumed 42, gap 8 → add an 8 L correction fill.
      final basis = reconciliationBasis(
        windowFills: [
          makeFill(id: 'a', liters: 50),
          makeFill(id: 'corr', liters: 8, isCorrection: true),
        ],
        windowTrips: [makeTrip(fuel: 42)],
      );
      // fuelTotal stays 50 (Total L honesty); trajetsTotal = 42 + 8 = 50.
      expect(basis.fuelTotalLiters, 50);
      expect(basis.trajetsTotalLiters, 50);
      expect(basis.residualLiters, 0);
    });

    test('residual == 0 when a virtual trip of exactly the gap is added', () {
      // Pumped 50, consumed 42, gap 8 → add an 8 L virtual trip.
      final basis = reconciliationBasis(
        windowFills: [makeFill(liters: 50)],
        windowTrips: [
          makeTrip(fuel: 42),
          makeTrip(fuel: 8, id: 'virtual'),
        ],
        isVirtualTrip: (t) => t.startedAt == DateTime(2026, 4, 11),
      );
      expect(basis.fuelTotalLiters, 50);
      expect(basis.trajetsTotalLiters, 50);
      expect(basis.residualLiters, 0);
    });

    test('negative gap → negative residual (sign correctness)', () {
      // Pumped 40, consumed 45 → integrator ran hot, gap −5.
      final basis = reconciliationBasis(
        windowFills: [makeFill(liters: 40)],
        windowTrips: [makeTrip(fuel: 45)],
      );
      expect(basis.residualLiters, -5);
    });

    test('empty window → all zero', () {
      final basis = reconciliationBasis(
        windowFills: const [],
        windowTrips: const [],
      );
      expect(basis.fuelTotalLiters, 0);
      expect(basis.trajetsTotalLiters, 0);
      expect(basis.residualLiters, 0);
    });
  });

  group('reconciliationBasis — virtual predicate default', () {
    test('default treats every trip as recorded (none virtual)', () {
      // Without a predicate, the "virtual" trip counts as recorded burn.
      final basis = reconciliationBasis(
        windowFills: [makeFill(liters: 50)],
        windowTrips: [
          makeTrip(fuel: 30),
          makeTrip(fuel: 8, id: 'virtual'),
        ],
      );
      // 30 + 8 both on the recorded side; no double-count.
      expect(basis.trajetsTotalLiters, 38);
      expect(basis.residualLiters, 12);
    });
  });
}
