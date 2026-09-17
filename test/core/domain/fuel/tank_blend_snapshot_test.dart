// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel/fuel_composition.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/fuel/grade_composition_bounds.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_engine.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_event.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_snapshot.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_state.dart';

/// #4275 — the persisted snapshot, its #4274 view, and the event contracts.
void main() {
  final at = DateTime.utc(2026, 9, 1);

  TankBlendSnapshot mixed() => TankBlendEngine(tankCapacityLitres: 50).replay([
        TankFillEvent(
            id: 'a', at: at, grade: FuelGrade.e10, litres: 20,
            levelBeforeLitres: 0),
        TankFillEvent(
            id: 'b', at: at.add(const Duration(days: 1)),
            grade: FuelGrade.e85, litres: 30, fillsTank: true),
        TankConsumptionEvent.unmeasured(
            id: 'c', at: at.add(const Duration(days: 2))),
        TankFillEvent(
            id: 'd', at: at.add(const Duration(days: 3)),
            grade: FuelGrade.diesel, litres: 60),
      ]);

  group('JSON persistence', () {
    test('round-trips every field, anomalies included', () {
      final original = mixed();
      expect(original.anomalies, isNotEmpty);

      final decoded = TankBlendSnapshot.fromJson(original.toJson());

      expect(decoded.toJson(), original.toJson());
      expect(decoded.anomalies.single.kind,
          TankBlendAnomalyKind.fillExceedsCapacity);
    });

    test('an unbounded volume round-trips as null, never as zero', () {
      final s = TankBlendEngine().replay([
        TankConsumptionEvent.unmeasured(id: 'c', at: at),
      ]);
      final decoded = TankBlendSnapshot.fromJson(s.toJson());

      expect(decoded.maxLitres, isNull);
      expect(decoded.tankCapacityLitres, isNull);
    });

    test('a grade key from a newer build folds into unknown', () {
      final json = mixed().toJson()
        ..['gradeShares'] = {'e10': 0.5, 'e20': 0.3, 'unknown': 0.2};

      final decoded = TankBlendSnapshot.fromJson(json);

      expect(decoded.minimumShare(FuelGrade.e10), 0.5);
      expect(decoded.unknownShare, closeTo(0.5, 1e-12));
    });

    test('an anomaly kind from a newer build is dropped, not fatal', () {
      final json = mixed().toJson()
        ..['anomalies'] = [
          {'eventId': 'x', 'kind': 'somethingNew'},
          {'eventId': 'd', 'kind': 'fillExceedsCapacity'},
        ];

      expect(TankBlendSnapshot.fromJson(json).anomalies.single.eventId, 'd');
    });
  });

  group('invariants', () {
    TankBlendSnapshot build({
      Map<FuelGrade, double> shares = const {FuelGrade.e10: 1.0},
      double min = 0,
      double? max = 10,
      double? cap,
    }) =>
        TankBlendSnapshot(
          gradeShares: shares,
          minLitres: min,
          maxLitres: max,
          tankCapacityLitres: cap,
          appliedEventIds: const [],
          logFingerprint: 0,
        );

    test('shares must sum to one', () {
      expect(() => build(shares: const {FuelGrade.e10: 0.7}),
          throwsArgumentError);
    });

    test('the volume interval must be ordered and non-negative', () {
      expect(() => build(min: -1), throwsArgumentError);
      expect(() => build(min: 5, max: 4), throwsArgumentError);
    });

    test('capacity must be positive when present', () {
      expect(() => build(cap: 0), throwsArgumentError);
    });

    test('collections are unmodifiable', () {
      final s = build();
      expect(() => s.gradeShares[FuelGrade.e85] = 0, throwsUnsupportedError);
      expect(() => s.appliedEventIds.add('x'), throwsUnsupportedError);
    });
  });

  group('the #4274 TankBlendState view', () {
    test('composition is the share-weighted guaranteed composition', () {
      // 40 % E10 (petrol ≥ .90) + 60 % E85 (ethanol ≥ .50).
      final s = TankBlendEngine(tankCapacityLitres: 50).replay([
        TankFillEvent(
            id: 'a', at: at, grade: FuelGrade.e10, litres: 20,
            levelBeforeLitres: 0),
        TankFillEvent(
            id: 'b', at: at.add(const Duration(days: 1)),
            grade: FuelGrade.e85, litres: 30, levelBeforeLitres: 20),
      ]);
      final state = s.toTankBlendState();

      final f = state.composition.fractions;
      expect(f[FuelComponent.petrol], closeTo(0.36, 1e-12));
      expect(f[FuelComponent.ethanol], closeTo(0.30, 1e-12));
      expect(f[FuelComponent.unknown], closeTo(0.34, 1e-12));
      expect(state.composition.exactFraction(FuelComponent.ethanol), isNull,
          reason: 'a grade label never yields an exact ethanol percentage');
      expect(state.totalLitres, closeTo(50, 1e-12));
      expect(state.confidence, 1,
          reason: 'confidence is about which grades are in the tank');
      expect(state.provenance, ['a', 'b']);
      expect(state.modelVersion, TankBlendState.currentModelVersion);
    });

    test('an interval volume maps to a null total', () {
      final state = mixed().toTankBlendState();
      expect(state.totalLitres, 50,
          reason: 'the over-capacity fill pinned the tank full');

      final open = TankBlendEngine(tankCapacityLitres: 50)
          .replay(const [])
          .toTankBlendState();
      expect(open.totalLitres, isNull);
      expect(open.composition.unknownFraction, 1);
      expect(open.confidence, 0);
    });
  });

  group('guaranteedCompositionOf', () {
    test('every grade yields a valid composition', () {
      for (final grade in FuelGrade.values) {
        expect(() => guaranteedCompositionOf(grade), returnsNormally,
            reason: grade.key);
      }
    });

    test('ethanol-bearing grades never claim an exact ethanol fraction', () {
      for (final grade in [
        FuelGrade.e5,
        FuelGrade.e10,
        FuelGrade.e98,
        FuelGrade.e85,
      ]) {
        expect(
            guaranteedCompositionOf(grade)
                .exactFraction(FuelComponent.ethanol),
            isNull,
            reason: grade.key);
      }
    });

    test('E98 is octane on the E5 base, not 98 % ethanol', () {
      expect(guaranteedCompositionOf(FuelGrade.e98).fractions,
          guaranteedCompositionOf(FuelGrade.e5).fractions);
    });

    test('LPG is the only grade characterised completely', () {
      expect(guaranteedCompositionOf(FuelGrade.lpg).unknownFraction, 0);
      expect(guaranteedCompositionOf(FuelGrade.electric).unknownFraction, 1);
    });
  });

  // #4322 — the grade `tankFuelKey` may name: only a lead the unknown
  // share cannot overturn.
  group('establishedLeadingGrade', () {
    TankBlendSnapshot of(Map<FuelGrade, double> shares) => TankBlendSnapshot(
          gradeShares: shares,
          minLitres: 10,
          maxLitres: 40,
          tankCapacityLitres: 50,
          appliedEventIds: const [],
          logFingerprint: 0,
        );

    test('a lead larger than the runner-up plus ALL the unknown share', () {
      expect(
          of({FuelGrade.e10: 0.57, FuelGrade.unknown: 0.43})
              .establishedLeadingGrade,
          FuelGrade.e10,
          reason: '0.57 > 0 + 0.43: no attribution of the rest can win');
      expect(
          of({FuelGrade.e85: 0.6, FuelGrade.e10: 0.3, FuelGrade.unknown: 0.1})
              .establishedLeadingGrade,
          FuelGrade.e85);
    });

    test('an unknown share that could overturn the lead leaves it open', () {
      // 0.5 vs 0.3 + 0.2 = 0.5: the unknown could make it a tie.
      expect(
          of({FuelGrade.e85: 0.5, FuelGrade.e10: 0.3, FuelGrade.unknown: 0.2})
              .establishedLeadingGrade,
          isNull);
      // A best guess would have said E85 here; the evidence does not.
      expect(
          of({FuelGrade.e85: 0.4, FuelGrade.unknown: 0.6})
              .establishedLeadingGrade,
          isNull);
    });

    test('an exact tie, and a tank nothing is attributed to, have no lead',
        () {
      expect(of({FuelGrade.e85: 0.5, FuelGrade.e10: 0.5})
          .establishedLeadingGrade, isNull);
      expect(of({FuelGrade.unknown: 1}).establishedLeadingGrade, isNull);
    });
  });

  group('event contracts', () {
    test('a fill must add a positive, finite amount of a liquid grade', () {
      TankFillEvent make({FuelGrade g = FuelGrade.e10, double l = 1}) =>
          TankFillEvent(id: 'x', at: at, grade: g, litres: l);

      expect(() => make(l: 0), throwsArgumentError);
      expect(() => make(l: double.nan), throwsArgumentError);
      expect(() => make(g: FuelGrade.electric), throwsArgumentError);
      expect(() => make(g: FuelGrade.wildcard), throwsArgumentError);
      expect(make(g: FuelGrade.unknown).grade, FuelGrade.unknown,
          reason: 'an unknown grade is a real, if uncharacterised, litre');
    });

    test('a consumption interval must be ordered', () {
      expect(
          () => TankConsumptionEvent(
              id: 'x', at: at, minLitres: 5, maxLitres: 4),
          throwsArgumentError);
      expect(TankConsumptionEvent.unmeasured(id: 'x', at: at).isExact, isFalse);
    });

    test('an empty id is rejected — identity is the idempotency key', () {
      expect(() => TankConsumptionEvent.exact(id: '', at: at, litres: 1),
          throwsArgumentError);
    });
  });
}
