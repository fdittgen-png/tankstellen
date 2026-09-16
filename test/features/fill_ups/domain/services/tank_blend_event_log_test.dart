// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_event.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_snapshot.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/services/tank_blend_event_log.dart';
import 'package:tankstellen/features/trips/api.dart';

/// #4279 — the recorded history replayed into the #4275 blend engine.
///
/// Every scenario runs the REAL adapter over real [FillUp] / trip records
/// and the real engine — no fake echoes the inputs back — so what is
/// pinned is the lifecycle the provider will actually serve.
void main() {
  const vehicle = VehicleProfile(
    id: 'v1',
    name: 'Flex',
    type: VehicleType.combustion,
    tankCapacityL: 50,
  );
  final t0 = DateTime.utc(2026, 9, 1, 8);
  DateTime day(num n) =>
      t0.add(Duration(minutes: (n * Duration.minutesPerDay).round()));

  FillUp fill(
    String id,
    num d,
    FuelType fuel,
    double litres, {
    bool full = true,
    double? before,
    double? after,
    double odo = 0,
    String vehicleId = 'v1',
    bool correction = false,
  }) =>
      FillUp(
        id: id,
        date: day(d),
        liters: litres,
        totalCost: litres * 1.5,
        odometerKm: odo,
        fuelType: fuel,
        vehicleId: vehicleId,
        isFullTank: full,
        isCorrection: correction,
        fuelLevelBeforeL: before,
        fuelLevelAfterL: after,
      );

  TripHistoryEntry trip(String id, num d, double km, double litres,
          {bool measured = true, String vehicleId = 'v1'}) =>
      TripHistoryEntry(
        id: id,
        vehicleId: vehicleId,
        summary: TripSummary(
          distanceKm: km,
          maxRpm: 3000,
          highRpmSeconds: 0,
          idleSeconds: 0,
          harshBrakes: 0,
          harshAccelerations: 0,
          fuelLitersConsumed: litres,
          avgLPer100Km: litres / km * 100,
          startedAt: day(d),
          endedAt: day(d).add(const Duration(hours: 2)),
          dominantFuelSource: measured ? 'pid5E' : 'maf',
        ),
      );

  TankBlendSnapshot derive(List<FillUp> fills,
          {List<TripHistoryEntry> trips = const [],
          VehicleProfile? profile = vehicle}) =>
      deriveTankBlend(
          vehicleId: 'v1', vehicle: profile, fillUps: fills, trips: trips);

  group('grade switches', () {
    test('E10 → E85: a full E85 fill onto 20 L of E10 is 40 / 60', () {
      final s = derive([
        fill('a', 0, FuelType.e10, 50),
        fill('b', 5, FuelType.e85, 30),
      ]);

      expect(s.exactShare(FuelGrade.e10), closeTo(0.4, 1e-12));
      expect(s.exactShare(FuelGrade.e85), closeTo(0.6, 1e-12));
      expect(s.confidence, 1);
    });

    test('E85 → E10: the reverse switch mixes the other way', () {
      final s = derive([
        fill('a', 0, FuelType.e85, 50),
        fill('b', 5, FuelType.e10, 20),
      ]);

      expect(s.exactShare(FuelGrade.e85), closeTo(0.6, 1e-12));
      expect(s.exactShare(FuelGrade.e10), closeTo(0.4, 1e-12));
    });
  });

  group('partial fills and top-ups', () {
    test('a partial fill with no level reading keeps only the guarantee',
        () {
      final s = derive([
        fill('a', 0, FuelType.e85, 50),
        fill('b', 3, FuelType.e10, 10, full: false),
      ]);

      // Residual anywhere in [0, 40]: E10 ≥ 10/50, E85 ≥ 0.
      expect(s.minimumShare(FuelGrade.e10), closeTo(0.2, 1e-12));
      expect(s.minimumShare(FuelGrade.e85), 0);
      expect(s.unknownShare, closeTo(0.8, 1e-12));
      expect(s.exactShare(FuelGrade.e10), isNull,
          reason: 'estimated, not measured — the summary must say so');
    });

    test('a pre-pump level reading makes the partial fill exact', () {
      final viaBefore = derive([
        fill('a', 0, FuelType.e85, 50),
        fill('b', 3, FuelType.e10, 10, full: false, before: 20),
      ]);
      final viaAfter = derive([
        fill('a', 0, FuelType.e85, 50),
        fill('b', 3, FuelType.e10, 10, full: false, after: 30),
      ]);

      expect(viaBefore.exactShare(FuelGrade.e10), closeTo(1 / 3, 1e-12));
      expect(viaAfter.toJson(), viaBefore.toJson());
    });

    test('repeated same-grade top-ups stay exactly that grade', () {
      final s = derive([
        fill('a', 0, FuelType.e85, 50),
        fill('b', 2, FuelType.e85, 10, full: false),
        fill('c', 4, FuelType.e85, 8, full: false),
        fill('d', 6, FuelType.e85, 12, full: false),
      ]);

      expect(s.exactShare(FuelGrade.e85), 1);
      expect(s.anomalies, isEmpty);
    });
  });

  group('consumption between fills', () {
    test('a measured trip covering the odometer delta pins the residual',
        () {
      final s = derive(
        [
          fill('a', 0, FuelType.e10, 50, odo: 1000),
          fill('b', 2, FuelType.e85, 10, full: false, odo: 1200),
        ],
        trips: [trip('t1', 1, 200, 30)],
      );

      expect(s.exactShare(FuelGrade.e10), closeTo(20 / 30, 1e-12));
      expect(s.exactShare(FuelGrade.e85), closeTo(10 / 30, 1e-12));
    });

    test('an estimated trip is a model, so it is not trusted as litres', () {
      final s = derive(
        [
          fill('a', 0, FuelType.e10, 50, odo: 1000),
          fill('b', 2, FuelType.e85, 10, full: false, odo: 1200),
        ],
        trips: [trip('t1', 1, 200, 30, measured: false)],
      );

      expect(s.exactShare(FuelGrade.e85), isNull);
      expect(s.minimumShare(FuelGrade.e85), closeTo(0.2, 1e-12));
    });

    test('driving no trip recorded is an unmeasured gap', () {
      final events = tankBlendEventsFor(
        vehicleId: 'v1',
        fillUps: [
          fill('a', 0, FuelType.e10, 50, odo: 1000),
          fill('b', 2, FuelType.e85, 10, full: false, odo: 1300),
        ],
        trips: [trip('t1', 1, 200, 30)],
      );

      final gap = events.whereType<TankConsumptionEvent>()
          .singleWhere((e) => e.id == 'gap:b');
      expect(gap.maxLitres, isNull);
      expect(events.map((e) => e.id), contains('gap-since-last-fill'));
    });
  });

  group('idempotency — restart, duplicates, order', () {
    final fills = [
      fill('a', 0, FuelType.e10, 50, odo: 1000),
      fill('b', 2, FuelType.e85, 10, full: false, odo: 1200),
      fill('c', 4, FuelType.e85, 30, odo: 1500),
    ];
    final trips = [trip('t1', 1, 200, 30), trip('t2', 3, 300, 20)];

    test('recomputing after a restart gives the identical snapshot', () {
      expect(derive(fills, trips: trips).toJson(),
          derive([...fills], trips: [...trips]).toJson());
    });

    test('a duplicated fill-up or trip is applied exactly once', () {
      expect(
        derive([...fills, fills[1], fills.first],
                trips: [...trips, trips.first])
            .toJson(),
        derive(fills, trips: trips).toJson(),
      );
    });

    test('delivery order of the records does not matter', () {
      expect(
        derive(fills.reversed.toList(), trips: trips.reversed.toList())
            .toJson(),
        derive(fills, trips: trips).toJson(),
      );
    });
  });

  group('corrections and edits', () {
    test('a reconciliation correction is not fuel bought', () {
      final base = [
        fill('a', 0, FuelType.e85, 50),
        fill('b', 5, FuelType.e10, 20),
      ];
      final withCorrection = [
        ...base,
        fill('correction_b', 5, FuelType.e10, 5, full: false, correction: true),
      ];

      final events = tankBlendEventsFor(
          vehicleId: 'v1', fillUps: withCorrection, trips: const []);
      expect(events.whereType<TankFillEvent>().map((e) => e.id),
          ['fill:a', 'fill:b']);
      expect(
          events.whereType<TankConsumptionEvent>()
              .singleWhere((e) => e.id == 'correction:correction_b')
              .maxLitres,
          isNull);
      expect(derive(withCorrection).gradeShares, derive(base).gradeShares);
    });

    test('editing a fill-up grade recomputes from the edited history', () {
      final before = derive([
        fill('a', 0, FuelType.e85, 50),
        fill('b', 5, FuelType.e10, 20),
      ]);
      final after = derive([
        fill('a', 0, FuelType.e85, 50),
        fill('b', 5, FuelType.e85, 20),
      ]);

      expect(before.exactShare(FuelGrade.e85), closeTo(0.6, 1e-12));
      expect(after.exactShare(FuelGrade.e85), 1);
    });

    test('deleting a fill-up recomputes as if it never happened', () {
      final withB = derive([
        fill('a', 0, FuelType.e85, 50),
        fill('b', 5, FuelType.e10, 20),
      ]);
      final withoutB = derive([fill('a', 0, FuelType.e85, 50)]);

      expect(withB.exactShare(FuelGrade.e85), closeTo(0.6, 1e-12));
      expect(withoutB.exactShare(FuelGrade.e85), 1);
      expect(withoutB.appliedEventIds, isNot(contains('fill:b')));
    });
  });

  group('missing or insufficient history stays explicitly unknown', () {
    test('no records at all', () {
      final s = derive(const []);

      expect(s.unknownShare, 1);
      expect(s.confidence, 0);
      expect(s.totalLitres, isNull);
      expect(s.maxLitres, 50);
    });

    test('an unknown vehicle has no capacity, so no full fill can pin', () {
      final s = derive([fill('a', 0, FuelType.e10, 50)], profile: null);

      expect(s.unknownShare, 1,
          reason: 'without a capacity the residual under the pump is '
              'unbounded — nothing can be claimed');
      expect(s.tankCapacityLitres, isNull);
    });

    test('other vehicles, non-liquid fills and the wildcard grade', () {
      final events = tankBlendEventsFor(
        vehicleId: 'v1',
        fillUps: [
          fill('x', 0, FuelType.e85, 40, vehicleId: 'v2'),
          fill('ev', 1, FuelType.electric, 30),
          fill('w', 2, FuelType.all, 30),
        ],
        trips: [trip('other', 1, 10, 1, vehicleId: 'v2')],
      );

      final fills = events.whereType<TankFillEvent>().toList();
      expect(fills.map((e) => e.id), ['fill:w']);
      expect(fills.single.grade, FuelGrade.unknown);
      expect(events.map((e) => e.id), isNot(contains('trip:other')));
    });
  });
}
