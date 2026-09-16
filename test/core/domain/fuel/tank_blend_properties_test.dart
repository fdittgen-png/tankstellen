// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_engine.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_event.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_snapshot.dart';

/// #4275 — property-style invariants over many seeded random sequences.
///
/// Seeded, so a failure reproduces exactly: the reason names the seed.
///
/// The strongest property is **soundness**: a hidden "true" tank is
/// simulated alongside the engine, the engine only ever sees evidence that
/// is TRUE about that tank (exact where the simulation says so, intervals
/// or "unmeasured" otherwise), and every guaranteed-minimum share the
/// engine reports must then be ≤ the true share, with the true volume
/// inside the reported interval. A model that invents precision fails this.
void main() {
  const grades = [
    FuelGrade.e5,
    FuelGrade.e10,
    FuelGrade.e98,
    FuelGrade.e85,
  ];
  const sequences = 400;

  void expectWellFormed(TankBlendSnapshot s, String why) {
    final sum = s.gradeShares.values.fold(0.0, (a, b) => a + b);
    expect(sum, closeTo(1, 1e-9), reason: '$why: shares sum');
    for (final v in s.gradeShares.values) {
      expect(v, inInclusiveRange(0, 1), reason: '$why: share range');
    }
    expect(s.minLitres, greaterThanOrEqualTo(0), reason: '$why: min >= 0');
    final max = s.maxLitres;
    if (max != null) {
      expect(max, greaterThanOrEqualTo(s.minLitres), reason: '$why: max>=min');
      final cap = s.tankCapacityLitres;
      if (cap != null) {
        expect(max, lessThanOrEqualTo(cap + 1e-9), reason: '$why: max<=cap');
      }
    }
    expect(s.confidence, closeTo(1 - s.unknownShare, 1e-12));
  }

  test('soundness: reported minimums never exceed the true tank', () {
    for (var seed = 0; seed < sequences; seed++) {
      final rng = Random(seed);
      const trueCap = 60.0;
      final engineCap = rng.nextBool() ? trueCap : null;
      final engine = TankBlendEngine(tankCapacityLitres: engineCap);

      // The hidden truth: litres per grade.
      final truth = <FuelGrade, double>{
        grades[rng.nextInt(grades.length)]: rng.nextDouble() * trueCap,
      };
      double volume() => truth.values.fold(0.0, (a, b) => a + b);

      var state = engine.initial();
      var clock = DateTime.utc(2026);
      final steps = 1 + rng.nextInt(25);
      for (var i = 0; i < steps; i++) {
        clock = clock.add(const Duration(hours: 1));
        final why = 'seed $seed step $i';
        if (rng.nextDouble() < 0.5 && volume() < trueCap - 1) {
          final grade = grades[rng.nextInt(grades.length)];
          final full = rng.nextDouble() < 0.4;
          final litres = full
              ? trueCap - volume()
              : 1 + rng.nextDouble() * (trueCap - volume() - 1);
          final before = volume();
          final event = TankFillEvent(
            id: 'f$i',
            at: clock,
            grade: rng.nextDouble() < 0.15 ? FuelGrade.unknown : grade,
            litres: litres,
            fillsTank: full,
            levelBeforeLitres: rng.nextDouble() < 0.3 ? before : null,
          );
          truth.update(grade, (v) => v + litres, ifAbsent: () => litres);
          state = engine.apply(state, event);
        } else {
          final burned = rng.nextDouble() * volume();
          final fraction = volume() == 0 ? 0.0 : burned / volume();
          truth.updateAll((_, v) => v * (1 - fraction));
          final pick = rng.nextInt(3);
          final event = switch (pick) {
            0 => TankConsumptionEvent.exact(
                id: 'c$i', at: clock, litres: burned),
            1 => TankConsumptionEvent(
                id: 'c$i',
                at: clock,
                minLitres: burned * rng.nextDouble(),
                maxLitres: burned + rng.nextDouble() * 5),
            _ => TankConsumptionEvent.unmeasured(id: 'c$i', at: clock),
          };
          state = engine.apply(state, event);
        }

        expectWellFormed(state, why);
        final v = volume();
        expect(v, greaterThanOrEqualTo(state.minLitres - 1e-6),
            reason: '$why: true volume below reported minimum');
        if (state.maxLitres != null) {
          expect(v, lessThanOrEqualTo(state.maxLitres! + 1e-6),
              reason: '$why: true volume above reported maximum');
        }
        for (final grade in grades) {
          final trueShare = v <= 1e-9 ? 1.0 : (truth[grade] ?? 0) / v;
          if (v <= 1e-9) continue; // an empty tank has no shares to check
          expect(state.minimumShare(grade), lessThanOrEqualTo(trueShare + 1e-6),
              reason: '$why: ${grade.key} minimum exceeds the truth');
        }
        expect(state.anomalies, isEmpty,
            reason: '$why: true evidence must never read as a contradiction');
      }
    }
  });

  test('replay is deterministic, order- and duplicate-independent', () {
    for (var seed = 0; seed < sequences; seed++) {
      final rng = Random(10000 + seed);
      final engine =
          TankBlendEngine(tankCapacityLitres: rng.nextBool() ? 55 : null);
      final events = _randomEvents(rng, grades);

      final reference = engine.replay(events).toJson();
      expect(engine.replay(events).toJson(), reference,
          reason: 'seed $seed: same log, same answer');

      final shuffled = [...events, ...events.take(rng.nextInt(events.length))]
        ..shuffle(rng);
      expect(engine.replay(shuffled).toJson(), reference,
          reason: 'seed $seed: shuffled + duplicated delivery');

      var incremental = engine.initial();
      for (final e in TankBlendEngine.canonicalLog(events)) {
        incremental = engine.apply(incremental, e);
        incremental = engine.apply(incremental, e); // duplicate delivery
        expectWellFormed(incremental, 'seed $seed');
      }
      expect(incremental.toJson(), reference,
          reason: 'seed $seed: incremental == replay');

      final cut = rng.nextInt(events.length + 1);
      final prefix = TankBlendEngine.canonicalLog(events).take(cut);
      final stored = TankBlendSnapshot.fromJson(engine.replay(prefix).toJson());
      expect(engine.resume(stored: stored, events: events).toJson(), reference,
          reason: 'seed $seed: resume from a persisted prefix of $cut');
    }
  });
}

List<TankBlendEvent> _randomEvents(Random rng, List<FuelGrade> grades) {
  final events = <TankBlendEvent>[];
  final n = 1 + rng.nextInt(20);
  for (var i = 0; i < n; i++) {
    // Coarse timestamps so same-instant ties are exercised.
    final at = DateTime.utc(2026, 1, 1 + rng.nextInt(10));
    if (rng.nextBool()) {
      events.add(TankFillEvent(
        id: 'f$i',
        at: at,
        grade: rng.nextDouble() < 0.1
            ? FuelGrade.unknown
            : grades[rng.nextInt(grades.length)],
        litres: 1 + rng.nextDouble() * 70,
        fillsTank: rng.nextBool(),
        levelBeforeLitres: rng.nextDouble() < 0.3 ? rng.nextDouble() * 60 : null,
      ));
    } else {
      final min = rng.nextDouble() * 40;
      events.add(TankConsumptionEvent(
        id: 'c$i',
        at: at,
        minLitres: min,
        maxLitres: rng.nextDouble() < 0.3 ? null : min + rng.nextDouble() * 10,
      ));
    }
  }
  return events;
}
