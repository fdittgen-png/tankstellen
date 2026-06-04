// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/gps_kpi_verdict.dart';

/// Unit coverage for the GPS-efficiency KPI verdict bands (#2795 C6).
///
/// Locks down the conservative default thresholds AND the load-bearing
/// grounding assertion: the one labelled trip in the trace fixtures
/// (RPA 0.224 / PKE 0.331 / VAPOS 1.42 / coast 0.18 — a score-78
/// "good but mixed" drive) must band MODERATE on every axis, so the
/// verdict never contradicts the driving score / smooth-driving lesson.
void main() {
  group('GpsKpiVerdicts — RPA (lower is better)', () {
    test('low RPA is good', () {
      expect(GpsKpiVerdicts.rpa(0.10), GpsKpiVerdict.good);
    });
    test('mid RPA is moderate', () {
      expect(GpsKpiVerdicts.rpa(0.224), GpsKpiVerdict.moderate);
    });
    test('high RPA is aggressive', () {
      expect(GpsKpiVerdicts.rpa(0.45), GpsKpiVerdict.aggressive);
    });
    test('boundary at goodMax is still good (inclusive)', () {
      expect(GpsKpiVerdicts.rpa(GpsKpiVerdicts.rpaGoodMax), GpsKpiVerdict.good);
    });
  });

  group('GpsKpiVerdicts — PKE (lower is better)', () {
    test('low PKE is good', () {
      expect(GpsKpiVerdicts.pke(0.15), GpsKpiVerdict.good);
    });
    test('fixture PKE 0.331 is moderate', () {
      expect(GpsKpiVerdicts.pke(0.331), GpsKpiVerdict.moderate);
    });
    test('high PKE is aggressive', () {
      expect(GpsKpiVerdicts.pke(0.80), GpsKpiVerdict.aggressive);
    });
  });

  group('GpsKpiVerdicts — VAPOS (lower is better)', () {
    test('low VAPOS is good', () {
      expect(GpsKpiVerdicts.vapos(0.8), GpsKpiVerdict.good);
    });
    test('fixture VAPOS 1.42 is moderate', () {
      expect(GpsKpiVerdicts.vapos(1.42), GpsKpiVerdict.moderate);
    });
    test('high VAPOS is aggressive', () {
      expect(GpsKpiVerdicts.vapos(3.5), GpsKpiVerdict.aggressive);
    });
  });

  group('GpsKpiVerdicts — coasting (higher is better, inverted)', () {
    test('lots of coasting is good', () {
      expect(GpsKpiVerdicts.coast(0.35), GpsKpiVerdict.good);
    });
    test('fixture coast 0.18 is moderate', () {
      expect(GpsKpiVerdicts.coast(0.18), GpsKpiVerdict.moderate);
    });
    test('almost no coasting is aggressive', () {
      expect(GpsKpiVerdicts.coast(0.03), GpsKpiVerdict.aggressive);
    });
    test('coast good floor matches the road-use praise threshold (0.25)', () {
      // The road-use panel praises at coast >= 0.25; the KPI good floor must
      // agree so a praised trip never reads "moderate" on coasting here.
      expect(GpsKpiVerdicts.coastGoodMin, 0.25);
      expect(GpsKpiVerdicts.coast(0.25), GpsKpiVerdict.good);
    });
  });

  group('grounding — the labelled trace fixture bands MODERATE everywhere', () {
    test('RPA 0.224 / PKE 0.331 / VAPOS 1.42 / coast 0.18 all moderate', () {
      expect(GpsKpiVerdicts.rpa(0.224), GpsKpiVerdict.moderate);
      expect(GpsKpiVerdicts.pke(0.331), GpsKpiVerdict.moderate);
      expect(GpsKpiVerdicts.vapos(1.42), GpsKpiVerdict.moderate);
      expect(GpsKpiVerdicts.coast(0.18), GpsKpiVerdict.moderate);
    });
  });
}
