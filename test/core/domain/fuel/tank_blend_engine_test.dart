// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_engine.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_event.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_snapshot.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_state.dart';

/// #4275 — worked examples of the deterministic blend transitions.
///
/// Every number here is hand-computable from the mixing rule on
/// [TankBlendEngine]: `share_k = (L·[k=g] + R·C_k) / (L + R)`, with the
/// smaller endpoint kept when the residual `R` is only an interval.
void main() {
  final t0 = DateTime.utc(2026, 9, 1);
  DateTime day(int n) => t0.add(Duration(days: n));

  TankFillEvent fill(String id, int d, FuelGrade grade, double litres,
          {bool full = false, double? before}) =>
      TankFillEvent(
          id: id,
          at: day(d),
          grade: grade,
          litres: litres,
          fillsTank: full,
          levelBeforeLitres: before);

  TankConsumptionEvent burn(String id, int d, double litres) =>
      TankConsumptionEvent.exact(id: id, at: day(d), litres: litres);

  TankConsumptionEvent drive(String id, int d) =>
      TankConsumptionEvent.unmeasured(id: id, at: day(d));

  group('weighted mixing with an exact residual', () {
    test('20 L E10 residual + 30 L E85 is exactly 40 % / 60 %', () {
      final s = TankBlendEngine(tankCapacityLitres: 50).replay([
        fill('a', 0, FuelGrade.e10, 20, before: 0),
        fill('b', 1, FuelGrade.e85, 30, before: 20),
      ]);

      expect(s.exactShare(FuelGrade.e10), closeTo(0.4, 1e-12));
      expect(s.exactShare(FuelGrade.e85), closeTo(0.6, 1e-12));
      expect(s.unknownShare, 0);
      expect(s.confidence, 1);
      expect(s.totalLitres, closeTo(50, 1e-12));
    });

    test('a full-tank fill with known capacity pins the residual', () {
      // Same tank as above, but the evidence is "full" not a level read.
      final s = TankBlendEngine(tankCapacityLitres: 50).replay([
        fill('a', 0, FuelGrade.e10, 20, before: 0),
        fill('b', 1, FuelGrade.e85, 30, full: true),
      ]);

      expect(s.exactShare(FuelGrade.e85), closeTo(0.6, 1e-12));
      expect(s.totalLitres, 50);
    });

    test('an exact burn then a partial fill mixes against what is left', () {
      final s = TankBlendEngine(tankCapacityLitres: 50).replay([
        fill('a', 0, FuelGrade.e85, 40, before: 0),
        burn('t1', 1, 30),
        fill('b', 2, FuelGrade.e10, 10),
      ]);

      expect(s.exactShare(FuelGrade.e85), closeTo(0.5, 1e-12));
      expect(s.exactShare(FuelGrade.e10), closeTo(0.5, 1e-12));
      expect(s.totalLitres, closeTo(20, 1e-12));
    });

    test('three grades blend in sequence (E5 + E10 + E85)', () {
      final s = TankBlendEngine().replay([
        fill('a', 0, FuelGrade.e5, 10, before: 0),
        fill('b', 1, FuelGrade.e10, 10, before: 10),
        fill('c', 2, FuelGrade.e85, 20, before: 20),
      ]);

      expect(s.exactShare(FuelGrade.e5), closeTo(0.25, 1e-12));
      expect(s.exactShare(FuelGrade.e10), closeTo(0.25, 1e-12));
      expect(s.exactShare(FuelGrade.e85), closeTo(0.5, 1e-12));
    });

    test('consumption never changes the shares, only the volume', () {
      final engine = TankBlendEngine(tankCapacityLitres: 50);
      final before = engine.replay([
        fill('a', 0, FuelGrade.e10, 20, before: 0),
        fill('b', 1, FuelGrade.e85, 30, before: 20),
      ]);
      final after = engine.apply(before, burn('t', 2, 12));

      expect(after.gradeShares, before.gradeShares);
      expect(after.totalLitres, closeTo(38, 1e-12));
    });
  });

  group('unknown is not zero — ambiguity grows the slack', () {
    test('an unmeasured drive turns a known volume into an interval', () {
      final s = TankBlendEngine(tankCapacityLitres: 50).replay([
        fill('a', 0, FuelGrade.e85, 40, before: 0),
        drive('gap', 1),
      ]);

      expect(s.minLitres, 0);
      expect(s.maxLitres, 40);
      expect(s.totalLitres, isNull, reason: 'an interval is not a volume');
      expect(s.exactShare(FuelGrade.e85), 1,
          reason: 'driving does not change what the fuel is');
    });

    test('a partial fill onto an unknown residual keeps only the guarantee',
        () {
      // Residual in [0, 40] of pure E85; 10 L E10 added.
      //   E10 ≥ min(10/10, 10/50) = 0.2
      //   E85 ≥ min(0/10, 40/50)  = 0     (the tank may have been empty)
      final s = TankBlendEngine(tankCapacityLitres: 50).replay([
        fill('a', 0, FuelGrade.e85, 40, before: 0),
        drive('gap', 1),
        fill('b', 2, FuelGrade.e10, 10),
      ]);

      expect(s.minimumShare(FuelGrade.e10), closeTo(0.2, 1e-12));
      expect(s.minimumShare(FuelGrade.e85), 0);
      expect(s.unknownShare, closeTo(0.8, 1e-12));
      expect(s.confidence, closeTo(0.2, 1e-12));
      expect(s.exactShare(FuelGrade.e10), isNull);
      expect(s.minLitres, 10);
      expect(s.maxLitres, 50);
    });

    test('a same-grade top-up onto an unknown residual stays certain', () {
      // Whatever R was, E85 onto pure E85 is pure E85.
      final s = TankBlendEngine().replay([
        fill('a', 0, FuelGrade.e85, 40, before: 0),
        drive('gap', 1),
        fill('b', 2, FuelGrade.e85, 10),
      ]);

      expect(s.exactShare(FuelGrade.e85), 1);
      expect(s.totalLitres, isNull);
    });

    test('an unknown grade adds uncharacterised litres', () {
      final s = TankBlendEngine().replay([
        fill('a', 0, FuelGrade.e10, 20, before: 0),
        fill('b', 1, FuelGrade.unknown, 20, before: 20),
      ]);

      expect(s.minimumShare(FuelGrade.e10), closeTo(0.5, 1e-12));
      expect(s.unknownShare, closeTo(0.5, 1e-12));
      expect(s.exactShare(FuelGrade.e10), isNull);
      expect(s.totalLitres, 40, reason: 'the volume is still known');
    });

    test('no history at all is fully unknown, not an empty tank', () {
      final s = TankBlendEngine(tankCapacityLitres: 50).replay(const []);

      expect(s.unknownShare, 1);
      expect(s.confidence, 0);
      expect(s.minLitres, 0);
      expect(s.maxLitres, 50);
      expect(s.totalLitres, isNull);
    });

    test('without capacity or level, a first fill establishes nothing', () {
      // The residual is unbounded, so it could dwarf the 30 L pumped.
      final s = TankBlendEngine().replay([
        fill('a', 0, FuelGrade.e10, 30, full: true),
      ]);

      expect(s.unknownShare, 1);
      expect(s.maxLitres, isNull);
    });

    test('repeated full fills converge on the grade, never overshoot', () {
      // Capacity 50, 40 L E85 each time: residual 10 L pinned, so the
      // unknown slack shrinks by ×0.2 per fill.
      final engine = TankBlendEngine(tankCapacityLitres: 50);
      var s = engine.initial();
      for (var i = 1; i <= 4; i++) {
        s = engine.apply(s, fill('f$i', i, FuelGrade.e85, 40, full: true));
        expect(s.unknownShare, closeTo(_pow(0.2, i), 1e-12));
      }
      expect(s.minimumShare(FuelGrade.e85), closeTo(1 - 0.0016, 1e-12));
    });
  });

  group('capacity and contradictions are recorded, never clamped silently',
      () {
    test('a fill larger than the tank is flagged and fills the tank', () {
      final s = TankBlendEngine(tankCapacityLitres: 50).replay([
        fill('a', 0, FuelGrade.diesel, 60),
      ]);

      expect(s.anomalies.single.kind, TankBlendAnomalyKind.fillExceedsCapacity);
      expect(s.anomalies.single.eventId, 'a');
      expect(s.exactShare(FuelGrade.diesel), 1);
      expect(s.totalLitres, 50);
    });

    test('a level reading that cannot fit beside the pumped litres', () {
      final s = TankBlendEngine(tankCapacityLitres: 50).replay([
        fill('a', 0, FuelGrade.e10, 20, before: 45),
      ]);

      expect(s.anomalies.map((a) => a.kind),
          contains(TankBlendAnomalyKind.residualExceedsCapacity));
      expect(s.minLitres, 20, reason: 'residual lower bound dropped to 0');
      expect(s.maxLitres, 50, reason: 'residual capped at capacity − litres');
    });

    test('consumption above the most the tank held is an anomaly', () {
      final s = TankBlendEngine(tankCapacityLitres: 50).replay([
        fill('a', 0, FuelGrade.e10, 40, before: 0),
        burn('t', 1, 45),
      ]);

      expect(s.anomalies.single.kind,
          TankBlendAnomalyKind.consumptionExceedsVolume);
      expect(s.minLitres, 0);
      expect(s.maxLitres, 40,
          reason: 'volume widened to [0, previous max], not set to empty');
    });

    test('a full-tank pin outside the tracked interval wins but is kept', () {
      // Tracked 40 L after the first fill; the full fill says 45 L were
      // already in there (50 − 5).
      final s = TankBlendEngine(tankCapacityLitres: 50).replay([
        fill('a', 0, FuelGrade.e10, 40, before: 0),
        fill('b', 1, FuelGrade.e10, 5, full: true),
      ]);

      expect(s.anomalies.single.kind,
          TankBlendAnomalyKind.observationContradictsTrackedVolume);
      expect(s.totalLitres, 50);
    });

    test('consistent evidence produces no anomalies', () {
      final s = TankBlendEngine(tankCapacityLitres: 50).replay([
        fill('a', 0, FuelGrade.e10, 50, before: 0),
        burn('t', 1, 30),
        fill('b', 2, FuelGrade.e85, 30, full: true),
      ]);

      expect(s.anomalies, isEmpty);
      expect(s.exactShare(FuelGrade.e85), closeTo(0.6, 1e-12));
    });
  });

  group('identity, order and replay', () {
    test('applying an already-applied id is a no-op', () {
      final engine = TankBlendEngine(tankCapacityLitres: 50);
      final once = engine.apply(
          engine.initial(), fill('a', 0, FuelGrade.e10, 20, before: 0));

      expect(identical(engine.apply(once, fill('a', 0, FuelGrade.e10, 20)),
          once), isTrue);
    });

    test('duplicates and delivery order do not change the replay', () {
      final engine = TankBlendEngine(tankCapacityLitres: 50);
      final a = fill('a', 0, FuelGrade.e10, 20, before: 0);
      final t = burn('t', 1, 5);
      final b = fill('b', 2, FuelGrade.e85, 30, full: true);

      final canonical = engine.replay([a, t, b]).toJson();
      expect(engine.replay([b, a, t, a, b]).toJson(), canonical);
    });

    test('at the same instant, consumption is applied before the fill', () {
      final at = day(3);
      final log = TankBlendEngine.canonicalLog([
        TankFillEvent(id: 'a', at: at, grade: FuelGrade.e10, litres: 5),
        TankConsumptionEvent.exact(id: 'z', at: at, litres: 1),
      ]);

      expect(log.map((e) => e.id), ['z', 'a']);
    });

    test('one id carrying two different facts is rejected', () {
      expect(
        () => TankBlendEngine.canonicalLog([
          fill('a', 0, FuelGrade.e10, 20),
          fill('a', 0, FuelGrade.e85, 20),
        ]),
        throwsArgumentError,
      );
    });

    test('apply refuses a snapshot from another capacity', () {
      final foreign = TankBlendEngine(tankCapacityLitres: 40).initial();

      expect(
        () => TankBlendEngine(tankCapacityLitres: 50)
            .apply(foreign, burn('t', 0, 1)),
        throwsArgumentError,
      );
    });
  });

  group('resume — persisted snapshot vs the event log', () {
    final engine = TankBlendEngine(tankCapacityLitres: 50);
    final a = fill('a', 0, FuelGrade.e10, 20, before: 0);
    final t = burn('t', 1, 5);
    final b = fill('b', 2, FuelGrade.e85, 30, full: true);

    test('no stored snapshot replays everything', () {
      expect(engine.resume(stored: null, events: [a, t, b]).toJson(),
          engine.replay([a, t, b]).toJson());
    });

    test('a stored prefix continues with the tail only', () {
      final stored = TankBlendSnapshot.fromJson(engine.replay([a, t]).toJson());

      expect(engine.resume(stored: stored, events: [a, t, b]).toJson(),
          engine.replay([a, t, b]).toJson());
    });

    test('an edited event forces a full recompute', () {
      final stored = engine.replay([a, t]);
      final edited = burn('t', 1, 15);

      final resumed = engine.resume(stored: stored, events: [a, edited, b]);
      expect(resumed.toJson(), engine.replay([a, edited, b]).toJson());
      expect(resumed.totalLitres, 50);
    });

    test('a deleted event forces a full recompute', () {
      final stored = engine.replay([a, t, b]);

      expect(engine.resume(stored: stored, events: [a, b]).toJson(),
          engine.replay([a, b]).toJson());
    });

    test('a back-dated insertion forces a full recompute', () {
      final stored = engine.replay([a, b]);
      final late = burn('late', 1, 10);

      expect(engine.resume(stored: stored, events: [a, late, b]).toJson(),
          engine.replay([a, late, b]).toJson());
    });

    test('a snapshot from another model version is recomputed', () {
      final json = engine.replay([a, t]).toJson()
        ..['modelVersion'] = TankBlendState.currentModelVersion + 1
        ..['gradeShares'] = {'e98': 1.0};
      final stale = TankBlendSnapshot.fromJson(json);

      final resumed = engine.resume(stored: stale, events: [a, t, b]);
      expect(resumed.modelVersion, TankBlendState.currentModelVersion);
      expect(resumed.toJson(), engine.replay([a, t, b]).toJson());
    });

    test('a snapshot computed for another capacity is recomputed', () {
      final stored = TankBlendEngine(tankCapacityLitres: 60).replay([a, t]);

      expect(engine.resume(stored: stored, events: [a, t, b]).toJson(),
          engine.replay([a, t, b]).toJson());
    });
  });
}

double _pow(double base, int exp) {
  var r = 1.0;
  for (var i = 0; i < exp; i++) {
    r *= base;
  }
  return r;
}
