// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/fuzzy_classifier.dart';

/// Reachability guard for the fuzzy classifier (#2513, epic #2512).
///
/// Bug #2513: the fuzzy calibration path left `stopAndGo` and
/// `climbing` permanently at 0 samples because `_recordFuzzy` called
/// `classify()` with `grade: 0` and without `isStopAndGoContext`, so
/// those two membership functions could only ever return 0 and were
/// dropped by the `<= 0` guard before any vote was recorded.
///
/// This suite is the unit-level half of the guard that would have
/// caught it: sweep a representative grid of the classifier's inputs
/// and assert that EVERY persistable [Situation] (i.e. every value
/// except the transient [Situation.fuelCut], which the baseline store
/// filters out) receives a normalized membership > 0 on at least one
/// grid point. If a future change re-introduces a permanently-dead
/// bucket, this test goes red.
void main() {
  const classifier = FuzzyClassifier();

  // Persistable situations — everything the baseline store learns a
  // stable mean for. fuelCut is a transient the store drops, so it is
  // intentionally exempt from the "must be reachable" requirement.
  final persistable =
      Situation.values.where((s) => s != Situation.fuelCut).toList();

  test('every persistable Situation is reachable across the input grid',
      () {
    // Representative grids spanning the realistic operating envelope.
    // #2515 — the three new buckets need temperature and a gentle-accel
    // axis to be reachable: a cold coolant (coldStart), a flat high load
    // (sustainedLoad), and the `[-0.5, -0.1)` coast band (partialDecel).
    const speeds = [0.0, 3.0, 15.0, 30.0, 50.0, 75.0, 100.0, 150.0, 200.0];
    const grades = [0.0, 2.0, 5.0, 8.0, 10.0];
    const throttles = [0.0, 3.0, 20.0, 50.0, 80.0, 100.0];
    const rpms = [800.0, 1200.0, 2000.0, 3000.0, 4000.0];
    // -0.3 lands in the partial-decel coast band (between -0.5 and -0.1).
    const accels = [-2.0, -1.0, -0.3, 0.0, 1.0, 2.0];
    const loads = [0.0, 30.0, 50.0, 60.0, 80.0, 100.0];
    const contexts = [false, true];
    // 30 °C ⇒ cold engine (coldStart fires); 80 °C ⇒ warm (no override).
    const coolants = <double?>[null, 30.0, 80.0];
    const pedals = <double?>[null, 0.0, 30.0];

    final reached = <Situation>{};

    for (final speed in speeds) {
      for (final grade in grades) {
        for (final throttle in throttles) {
          for (final rpm in rpms) {
            for (final accel in accels) {
              for (final load in loads) {
                for (final ctx in contexts) {
                  for (final coolant in coolants) {
                    for (final pedal in pedals) {
                      final m = classifier.classify(
                        speedKmh: speed,
                        accel: accel,
                        grade: grade,
                        throttlePct: throttle,
                        rpm: rpm,
                        isStopAndGoContext: ctx,
                        loadPct: load,
                        coolantTempC: coolant,
                        pedalPct: pedal,
                      );
                      // The vector is always a valid probability
                      // distribution.
                      final sum =
                          m.values.fold<double>(0, (acc, v) => acc + v);
                      expect(sum, closeTo(1.0, 1e-6),
                          reason: 'membership must be L1-normalized');
                      for (final entry in m.entries) {
                        if (entry.value > 0) reached.add(entry.key);
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    for (final s in persistable) {
      expect(reached.contains(s), isTrue,
          reason: '$s was never reachable on any grid point — the '
              'fuzzy calibration path can never learn a baseline for '
              'it (regression of #2513)');
    }
  });

  group('the #2513 / #2515 buckets are reachable through their intended '
      'signals', () {
    double member(
      Situation s, {
      double speed = 0,
      double accel = 0,
      double grade = 0,
      double throttle = 10,
      double rpm = 800,
      bool stopAndGo = false,
      double load = 0,
      double? coolantTempC,
      double? oilTempC,
    }) =>
        classifier.classify(
          speedKmh: speed,
          accel: accel,
          grade: grade,
          throttlePct: throttle,
          rpm: rpm,
          isStopAndGoContext: stopAndGo,
          loadPct: load,
          coolantTempC: coolantTempC,
          oilTempC: oilTempC,
        )[s]!;

    test('stopAndGo fills only when the context flag is set', () {
      // 30 km/h is in the urban plateau — without the flag the
      // stopAndGo bucket is 0; with it, it shares the vote.
      expect(member(Situation.stopAndGo, speed: 30, stopAndGo: false),
          0.0);
      expect(member(Situation.stopAndGo, speed: 30, stopAndGo: true),
          greaterThan(0));
    });

    test('climbing fills from a confident GPS road grade alone', () {
      expect(member(Situation.climbing, speed: 60, grade: 6), greaterThan(0));
    });

    test('#2515 — a flat high load registers as sustainedLoad, NOT '
        'climbing (the re-split)', () {
      // grade 0 (no GPS altitude) but the car is working hard at 80 %
      // load → the load now lands in sustainedLoad; climbing needs a
      // grade. The union of the two is unchanged from the pre-#2515
      // climbing bucket — only the means are separated.
      expect(member(Situation.sustainedLoad, speed: 60, grade: 0, load: 80),
          greaterThan(0));
      expect(member(Situation.climbing, speed: 60, grade: 0, load: 80), 0.0);
    });

    test('#2515 — a graded high load reinforces climbing, not '
        'sustainedLoad', () {
      // grade 5 % + 80 % load → the load ramp feeds climbing; the
      // sustainedLoad gate (grade < 2 %) excludes it.
      expect(member(Situation.climbing, speed: 60, grade: 5, load: 80),
          greaterThan(0));
      expect(member(Situation.sustainedLoad, speed: 60, grade: 5, load: 80),
          0.0);
    });

    test('a loafing engine on the flat is neither climbing nor '
        'sustainedLoad', () {
      expect(member(Situation.climbing, speed: 60, grade: 0, load: 30), 0.0);
      expect(
          member(Situation.sustainedLoad, speed: 60, grade: 0, load: 30), 0.0);
    });

    test('#2515 — coldStart fills from a cold coolant (or oil fallback)',
        () {
      expect(member(Situation.coldStart, speed: 30, coolantTempC: 35),
          greaterThan(0));
      expect(member(Situation.coldStart, speed: 30, oilTempC: 25),
          greaterThan(0));
      // Warm engine ⇒ no cold-start.
      expect(member(Situation.coldStart, speed: 30, coolantTempC: 85), 0.0);
    });

    test('#2515 — partialDecel fills in the gentle-coast accel band', () {
      // accel -0.3 ∈ [-0.5, -0.1), throttle closed, moving.
      expect(member(Situation.partialDecel, speed: 40, accel: -0.3, throttle: 2),
          greaterThan(0));
      // A harder lift-off is decel, not partialDecel.
      expect(
          member(Situation.partialDecel, speed: 40, accel: -1.0, throttle: 2),
          0.0);
    });
  });
}
