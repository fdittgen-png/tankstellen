import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/broken_map_belief.dart';
import 'package:tankstellen/features/consumption/data/obd2/broken_map_belief_updater.dart';
import 'package:tankstellen/features/vehicle/domain/entities/reference_vehicle.dart';

/// Membership-function tests are unchanged from the #1423 phase 1
/// surface — the four scoring helpers stay put under the Bayesian
/// migration (#1424).
///
/// The `update` mechanics tests were rewritten for the Beta(α, β)
/// posterior: see the bottom group for the two issue-#1424 acceptance
/// tests (5×0.4 → posterior > 0.8; 5×0.9 then 20×0.05 → posterior < 0.4).
void main() {
  // Anchors at the sea-level reference baro (101.325 kPa) so the
  // window is exactly 15-45 kPa — these pin the stock calibration.
  group('vacuumMissingScore (sea-level reference)', () {
    test('returns 0.0 when delta is at the healthy boundary (45 kPa)', () {
      final s = BrokenMapBeliefUpdater.vacuumMissingScore(
        baroKpa: 101.325,
        mapKpa: 56.325,
      );
      expect(s, 0.0);
    });

    test('returns 1.0 when delta is at/below the suspicious boundary (15 kPa)',
        () {
      final s = BrokenMapBeliefUpdater.vacuumMissingScore(
        baroKpa: 101.325,
        mapKpa: 86.325,
      );
      expect(s, 1.0);
    });

    test('linear interp at delta 30 returns 0.5', () {
      final s = BrokenMapBeliefUpdater.vacuumMissingScore(
        baroKpa: 101.325,
        mapKpa: 71.325,
      );
      expect(s, closeTo(0.5, 1e-9));
    });
  });

  group('revDeltaMissingScore', () {
    test('returns 0.0 when |rev - idle| is at healthy boundary (30 kPa)', () {
      final s = BrokenMapBeliefUpdater.revDeltaMissingScore(
        mapIdleKpa: 100,
        mapRevvedKpa: 70,
      );
      expect(s, 0.0);
    });

    test('returns 1.0 when |rev - idle| is at/below suspicious boundary (8 kPa)',
        () {
      final s = BrokenMapBeliefUpdater.revDeltaMissingScore(
        mapIdleKpa: 100,
        mapRevvedKpa: 95,
      );
      expect(s, 1.0);
    });

    test('linear interp at delta 19 returns 0.5', () {
      final s = BrokenMapBeliefUpdater.revDeltaMissingScore(
        mapIdleKpa: 100,
        mapRevvedKpa: 81,
      );
      expect(s, closeTo(0.5, 1e-9));
    });
  });

  // #1623 — membership-anchor scaling for barometric pressure +
  // induction class.
  group('scaledMembershipAnchors (#1623)', () {
    test('sea-level NA leaves the stock window untouched', () {
      final (lo, hi) = BrokenMapBeliefUpdater.scaledMembershipAnchors(
        15.0,
        45.0,
        baroKpa: 101.325,
        inductionType: InductionType.naturallyAspirated,
      );
      expect(lo, closeTo(15.0, 1e-9));
      expect(hi, closeTo(45.0, 1e-9));
    });

    test('a null baro leaves the window stock', () {
      final (lo, hi) = BrokenMapBeliefUpdater.scaledMembershipAnchors(
        8.0,
        30.0,
        baroKpa: null,
        inductionType: null,
      );
      expect(lo, closeTo(8.0, 1e-9));
      expect(hi, closeTo(30.0, 1e-9));
    });

    test('high altitude (low baro) shrinks the window proportionally', () {
      // baro 81.06 kPa ≈ 2000 m → factor 0.8.
      final (lo, hi) = BrokenMapBeliefUpdater.scaledMembershipAnchors(
        15.0,
        45.0,
        baroKpa: 81.06,
        inductionType: null,
      );
      expect(lo, closeTo(12.0, 1e-3));
      expect(hi, closeTo(36.0, 1e-3));
    });

    test('an absurdly low baro is clamped at factor 0.6', () {
      final (lo, hi) = BrokenMapBeliefUpdater.scaledMembershipAnchors(
        15.0,
        45.0,
        baroKpa: 10.0,
        inductionType: null,
      );
      // 0.6 floor → 15*0.6, 45*0.6; window never inverts.
      expect(lo, closeTo(9.0, 1e-6));
      expect(hi, closeTo(27.0, 1e-6));
      expect(hi, greaterThan(lo));
    });

    test('forced induction widens the band symmetrically about its midpoint',
        () {
      final (lo, hi) = BrokenMapBeliefUpdater.scaledMembershipAnchors(
        8.0,
        30.0,
        baroKpa: 101.325,
        inductionType: InductionType.turbocharged,
      );
      // mid = 19; widen 1.3 → lo = 19 - 11*1.3, hi = 19 + 11*1.3.
      expect(lo, closeTo(19.0 - 14.3, 1e-6));
      expect(hi, closeTo(19.0 + 14.3, 1e-6));
      // Midpoint is preserved — widening adds tolerance, not a shift.
      expect((lo + hi) / 2, closeTo(19.0, 1e-6));
    });
  });

  group('membership functions scale for altitude + induction (#1623)', () {
    test(
        'vacuum: the same kPa delta reads healthier at altitude than at '
        'sea level', () {
      // Absolute delta of 40 kPa. At sea level that is mid-band; at
      // altitude the window has shrunk so 40 kPa is clearly healthy.
      final seaLevel = BrokenMapBeliefUpdater.vacuumMissingScore(
        baroKpa: 101.325,
        mapKpa: 61.325, // delta 40
      );
      final altitude = BrokenMapBeliefUpdater.vacuumMissingScore(
        baroKpa: 81.06,
        mapKpa: 41.06, // delta 40
      );
      expect(seaLevel, greaterThan(0.0));
      expect(altitude, lessThan(seaLevel));
      expect(altitude, 0.0);
    });

    test(
        'rev-delta: a turbo diesel scores a borderline swing nearer neutral '
        'than a NA diesel would', () {
      // A 19 kPa swing is exactly mid-band (0.5) for a NA diesel.
      final na = BrokenMapBeliefUpdater.revDeltaMissingScore(
        mapIdleKpa: 100,
        mapRevvedKpa: 119,
        baroKpa: 101.325,
        inductionType: InductionType.naturallyAspirated,
      );
      // The same swing on a turbo diesel: the band is wider, but the
      // midpoint is unchanged, so a mid-band swing still scores ~0.5.
      final turbo = BrokenMapBeliefUpdater.revDeltaMissingScore(
        mapIdleKpa: 100,
        mapRevvedKpa: 119,
        baroKpa: 101.325,
        inductionType: InductionType.turbocharged,
      );
      expect(na, closeTo(0.5, 1e-9));
      expect(turbo, closeTo(0.5, 1e-9));

      // ...but a near-healthy swing (28 kPa) that NA scores as almost
      // clean, the turbo scores less confidently (nearer neutral) —
      // the wider band demands a bigger swing for full confidence.
      final naClean = BrokenMapBeliefUpdater.revDeltaMissingScore(
        mapIdleKpa: 100,
        mapRevvedKpa: 128,
        baroKpa: 101.325,
        inductionType: InductionType.naturallyAspirated,
      );
      final turboClean = BrokenMapBeliefUpdater.revDeltaMissingScore(
        mapIdleKpa: 100,
        mapRevvedKpa: 128,
        baroKpa: 101.325,
        inductionType: InductionType.turbocharged,
      );
      expect(naClean, lessThan(turboClean));
    });
  });

  group('discrepancySeverityScore', () {
    test('returns 0.0 when ratio is at healthy boundary (1.3)', () {
      final s = BrokenMapBeliefUpdater.discrepancySeverityScore(ratio: 1.3);
      expect(s, 0.0);
    });

    test('returns 1.0 when ratio is at/above suspicious boundary (2.2)', () {
      final s = BrokenMapBeliefUpdater.discrepancySeverityScore(ratio: 2.2);
      expect(s, 1.0);
    });

    test('linear interp at ratio 1.75 returns 0.5', () {
      final s = BrokenMapBeliefUpdater.discrepancySeverityScore(ratio: 1.75);
      expect(s, closeTo(0.5, 1e-9));
    });
  });

  group('etaImplausibilityScore', () {
    test('returns 0.0 when proposedEta is at healthy boundary (0.97)', () {
      final s = BrokenMapBeliefUpdater.etaImplausibilityScore(
        proposedEta: 0.97,
      );
      expect(s, 0.0);
    });

    test('returns 1.0 when proposedEta is at/above suspicious boundary (1.22)',
        () {
      final s = BrokenMapBeliefUpdater.etaImplausibilityScore(
        proposedEta: 1.22,
      );
      expect(s, 1.0);
    });

    test('linear interp at proposedEta 1.095 returns 0.5', () {
      final s = BrokenMapBeliefUpdater.etaImplausibilityScore(
        proposedEta: 1.095,
      );
      expect(s, closeTo(0.5, 1e-9));
    });
  });

  group('bayesFactorAdjustment (#1424 § E)', () {
    test('null vehicle → neutral 1.0 (no class boost)', () {
      expect(BrokenMapBeliefUpdater.bayesFactorAdjustment(null), 1.0);
    });

    test('Atkinson cycle → 0.3 (legitimately weird MAP)', () {
      // Atkinson dominates over induction — even a turbo Atkinson
      // (rare but exists, e.g. Toyota's 2.5L hybrid) returns 0.3.
      const atkNa = ReferenceVehicle(
        make: 'Toyota',
        model: 'Yaris',
        generation: 'IV (2020-)',
        yearStart: 2020,
        displacementCc: 1490,
        fuelType: 'hybrid',
        transmission: 'automatic',
        atkinsonCycle: true,
      );
      const atkTurbo = ReferenceVehicle(
        make: 'Toyota',
        model: 'RAV4',
        generation: 'V (2018-)',
        yearStart: 2018,
        displacementCc: 2500,
        fuelType: 'hybrid',
        transmission: 'automatic',
        inductionType: InductionType.turbocharged,
        atkinsonCycle: true,
      );
      expect(BrokenMapBeliefUpdater.bayesFactorAdjustment(atkNa), 0.3);
      expect(BrokenMapBeliefUpdater.bayesFactorAdjustment(atkTurbo), 0.3);
    });

    test('turbocharged or VNT → 1.5 (turbo flat-MAP is stronger evidence)', () {
      const turboPort = ReferenceVehicle(
        make: 'Volkswagen',
        model: 'Golf',
        generation: 'VII (2012-2019)',
        yearStart: 2012,
        yearEnd: 2019,
        displacementCc: 1390,
        fuelType: 'petrol',
        transmission: 'manual',
        inductionType: InductionType.turbocharged,
      );
      const turboDi = ReferenceVehicle(
        make: 'Volkswagen',
        model: 'Golf',
        generation: 'VIII (2019-)',
        yearStart: 2019,
        displacementCc: 1498,
        fuelType: 'petrol',
        transmission: 'manual',
        inductionType: InductionType.turbocharged,
        directInjection: true,
      );
      const vntDiesel = ReferenceVehicle(
        make: 'Peugeot',
        model: '208',
        generation: 'II (2019-)',
        yearStart: 2019,
        displacementCc: 1499,
        fuelType: 'diesel',
        transmission: 'manual',
        inductionType: InductionType.vnt,
        directInjection: true,
      );
      expect(BrokenMapBeliefUpdater.bayesFactorAdjustment(turboPort), 1.5);
      expect(BrokenMapBeliefUpdater.bayesFactorAdjustment(turboDi), 1.5);
      expect(BrokenMapBeliefUpdater.bayesFactorAdjustment(vntDiesel), 1.5);
    });

    test('NA petrol/diesel → 1.0 neutral, with or without DI', () {
      const naPort = ReferenceVehicle(
        make: 'Renault',
        model: 'Clio',
        generation: 'V (2019-)',
        yearStart: 2019,
        displacementCc: 999,
        fuelType: 'petrol',
        transmission: 'manual',
      );
      const naDi = ReferenceVehicle(
        make: 'Mazda',
        model: '3',
        generation: 'IV (2019-)',
        yearStart: 2019,
        displacementCc: 1998,
        fuelType: 'petrol',
        transmission: 'automatic',
        directInjection: true,
      );
      expect(BrokenMapBeliefUpdater.bayesFactorAdjustment(naPort), 1.0);
      expect(BrokenMapBeliefUpdater.bayesFactorAdjustment(naDi), 1.0);
    });

    test('supercharged (no Atkinson) → 1.0 — only turbo/VNT amplify', () {
      const supercharged = ReferenceVehicle(
        make: 'Mercedes-Benz',
        model: 'C-Class',
        generation: 'W205 (2014-2021)',
        yearStart: 2014,
        yearEnd: 2021,
        displacementCc: 1991,
        fuelType: 'petrol',
        transmission: 'automatic',
        inductionType: InductionType.supercharged,
        directInjection: true,
      );
      expect(BrokenMapBeliefUpdater.bayesFactorAdjustment(supercharged), 1.0);
    });
  });

  group('bayesFactor (#1424)', () {
    test('s = 0.5 with null vehicle is approximately 1 (neutral evidence)', () {
      // base = 0.5 / (0.5 + 0.01) ≈ 0.98 — slightly under 1 because
      // the epsilon nudges the denominator.
      final bf = BrokenMapBeliefUpdater.bayesFactor(0.5, null);
      expect(bf, closeTo(0.98, 0.01));
    });

    test('s = 0.9 produces a strong > 1 BF', () {
      final bf = BrokenMapBeliefUpdater.bayesFactor(0.9, null);
      // 0.9 / 0.11 ≈ 8.18.
      expect(bf, closeTo(8.18, 0.05));
    });

    test('turbocharged vehicle scales the BF by 1.5', () {
      const turbo = ReferenceVehicle(
        make: 'BMW',
        model: '3-Series',
        generation: 'F30 (2012-2019)',
        yearStart: 2012,
        yearEnd: 2019,
        displacementCc: 1995,
        fuelType: 'petrol',
        transmission: 'automatic',
        inductionType: InductionType.turbocharged,
        directInjection: true,
      );
      final neutralBf = BrokenMapBeliefUpdater.bayesFactor(0.7, null);
      final turboBf = BrokenMapBeliefUpdater.bayesFactor(0.7, turbo);
      expect(turboBf, closeTo(neutralBf * 1.5, 1e-9));
    });
  });

  group('update — Bayesian mechanics', () {
    final fixedNow = DateTime.utc(2026, 5, 4, 12);

    test('default prior has α=1, β=9 → mean 0.1', () {
      const belief = BrokenMapBelief();
      expect(belief.alpha, 1.0);
      expect(belief.beta, 9.0);
      expect(belief.pointEstimate, closeTo(0.1, 1e-9));
    });

    test('strong observation with reason updates lastTrigger and stamps fields',
        () {
      const prev = BrokenMapBelief();

      final next = BrokenMapBeliefUpdater.update(
        prev,
        0.9,
        now: fixedNow,
        vehicle: null,
        reason: BrokenMapReason.idleVacuumMissing,
      );

      expect(next.lastTrigger, BrokenMapReason.idleVacuumMissing);
      expect(next.observationCount, 1);
      expect(next.lastUpdate, fixedNow);
      // α' = 0.5*1 + 8*0.9*1 = 7.7 ; β' = 0.5*9 + 1*0.1 = 4.6
      expect(next.alpha, closeTo(7.7, 1e-9));
      expect(next.beta, closeTo(4.6, 1e-9));
      expect(next.pointEstimate, closeTo(7.7 / 12.3, 1e-9));
    });

    test('weak observation does NOT overwrite a previously-set lastTrigger',
        () {
      final t0 = DateTime.utc(2026, 5, 4, 12);
      final t1 = DateTime.utc(2026, 5, 4, 12, 5);
      const prev = BrokenMapBelief();

      final after = BrokenMapBeliefUpdater.update(
        prev,
        0.9,
        now: t0,
        vehicle: null,
        reason: BrokenMapReason.idleVacuumMissing,
      );
      expect(after.lastTrigger, BrokenMapReason.idleVacuumMissing);

      final later = BrokenMapBeliefUpdater.update(
        after,
        0.2,
        now: t1,
        vehicle: null,
        reason: BrokenMapReason.revDeltaMissing,
      );
      expect(later.lastTrigger, BrokenMapReason.idleVacuumMissing);
      expect(later.observationCount, 2);
    });

    test('observationScore above 1.0 is clamped — α/β stay finite, point '
        'estimate in [0, 1]', () {
      const prev = BrokenMapBelief();

      final next = BrokenMapBeliefUpdater.update(
        prev,
        1.5,
        now: fixedNow,
        vehicle: null,
      );

      expect(next.alpha.isFinite, isTrue);
      expect(next.beta.isFinite, isTrue);
      expect(next.pointEstimate, lessThanOrEqualTo(1.0));
      expect(next.pointEstimate, greaterThanOrEqualTo(0.0));
      // Score clamped to 1.0:
      // α' = 0.5*1 + 8*1*1 = 8.5 ; β' = 0.5*9 + 1*0 = 4.5.
      expect(next.alpha, closeTo(8.5, 1e-9));
      expect(next.beta, closeTo(4.5, 1e-9));
    });

    test('verified-clean prior is sticky — no observation moves it',
        () {
      // Construct a belief that satisfies the auto-clear gate
      // (observationCount > 50, mean < 0.1, upper-CI < 0.3). Beta(5, 95)
      // has mean 0.05 and a tight CI (~0.014–0.10) — well within
      // the gate.
      const verified = BrokenMapBelief(
        alpha: 5,
        beta: 95,
        observationCount: 60,
      );
      expect(verified.isVerifiedClean, isTrue);

      // Try to fold in a strong "broken" observation — should be
      // silently rejected.
      final next = BrokenMapBeliefUpdater.update(
        verified,
        1.0,
        now: fixedNow,
        vehicle: null,
        reason: BrokenMapReason.idleVacuumMissing,
      );
      expect(next, equals(verified));
    });

    test('vehicle-class boost amplifies α-side of a broken observation',
        () {
      const prev = BrokenMapBelief();
      const turbo = ReferenceVehicle(
        make: 'BMW',
        model: '3-Series',
        generation: 'F30 (2012-2019)',
        yearStart: 2012,
        yearEnd: 2019,
        displacementCc: 1995,
        fuelType: 'petrol',
        transmission: 'automatic',
        inductionType: InductionType.turbocharged,
      );
      // Same observation, neutral vs turbo vehicle:
      final neutral =
          BrokenMapBeliefUpdater.update(prev, 0.7, now: fixedNow, vehicle: null);
      final amplified = BrokenMapBeliefUpdater.update(
        prev,
        0.7,
        now: fixedNow,
        vehicle: turbo,
      );
      expect(amplified.alpha, greaterThan(neutral.alpha));
      expect(amplified.pointEstimate, greaterThan(neutral.pointEstimate));
    });

    test('Atkinson vehicle dampens the α-side of a broken observation',
        () {
      const prev = BrokenMapBelief();
      const atkinson = ReferenceVehicle(
        make: 'Toyota',
        model: 'Prius',
        generation: 'IV (2015-2022)',
        yearStart: 2015,
        yearEnd: 2022,
        displacementCc: 1798,
        fuelType: 'hybrid',
        transmission: 'automatic',
        atkinsonCycle: true,
      );
      final neutral =
          BrokenMapBeliefUpdater.update(prev, 0.7, now: fixedNow, vehicle: null);
      final dampened = BrokenMapBeliefUpdater.update(
        prev,
        0.7,
        now: fixedNow,
        vehicle: atkinson,
      );
      expect(dampened.alpha, lessThan(neutral.alpha));
      expect(dampened.pointEstimate, lessThan(neutral.pointEstimate));
    });
  });

  group('update — issue #1424 acceptance tests', () {
    final fixedNow = DateTime.utc(2026, 5, 4, 12);

    test('5 × score 0.4 against neutral vehicle pushes posterior > 0.8 '
        '(Bayes compounds where EMA didn\'t)', () {
      BrokenMapBelief belief = const BrokenMapBelief();
      for (var i = 0; i < 5; i++) {
        belief = BrokenMapBeliefUpdater.update(
          belief,
          0.4,
          now: fixedNow,
          vehicle: null,
        );
      }
      expect(
        belief.pointEstimate,
        greaterThan(0.8),
        reason:
            'Five borderline-0.4 observations should compound past 0.8 with '
            'γ=0.5, αW=8, βW=1 (#1424 § B calibration). Got '
            'α=${belief.alpha}, β=${belief.beta}.',
      );
      expect(belief.observationCount, 5);
    });

    test('5 × score 0.9 then 20 × score 0.05 against neutral vehicle decays '
        'posterior below 0.4 (contradicting evidence eventually wins)', () {
      BrokenMapBelief belief = const BrokenMapBelief();
      for (var i = 0; i < 5; i++) {
        belief = BrokenMapBeliefUpdater.update(
          belief,
          0.9,
          now: fixedNow,
          vehicle: null,
        );
      }
      // Sanity check — strong observations got us above 0.9.
      expect(
        belief.pointEstimate,
        greaterThan(0.9),
        reason:
            'Five strong observations should put the posterior in the '
            'hard-disable band before we test recovery. Got '
            'α=${belief.alpha}, β=${belief.beta}.',
      );

      for (var i = 0; i < 20; i++) {
        belief = BrokenMapBeliefUpdater.update(
          belief,
          0.05,
          now: fixedNow,
          vehicle: null,
        );
      }
      expect(
        belief.pointEstimate,
        lessThan(0.4),
        reason:
            'Twenty clean (s=0.05) observations should decay the posterior '
            'back below the verifying-band threshold. Got '
            'α=${belief.alpha}, β=${belief.beta}, '
            'mean=${belief.pointEstimate}.',
      );
      expect(
        belief.pointEstimate,
        greaterThan(0.05),
        reason:
            'Even fully-decayed observations leave some residual posterior — '
            'we never fully unlearn the prior strong evidence (#1424 § H).',
      );
      expect(belief.observationCount, 25);
    });
  });
}
