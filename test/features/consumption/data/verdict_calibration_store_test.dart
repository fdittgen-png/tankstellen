// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/verdict_calibration_store.dart';
import 'package:tankstellen/features/consumption/domain/gps_kpi_verdict.dart';

/// #3503 (epic #3498) — the verdict-driven KPI band derivation. Pure rules:
/// widen "good" only (smooth p75 above default), tighten "aggressive" only
/// (aggressive p25 below default), monotonic bands, defaults below the row
/// minimums.
void main() {
  VerdictCalibrationRow row(String v,
          {double rpa = 0.2, double coast = 0.2}) =>
      VerdictCalibrationRow(
          verdict: v, rpa: rpa, pke: 0.3, vapos: 1.2, coast: coast);

  test('below the row minimums the defaults stand untouched', () {
    final bands = VerdictCalibrationStore.deriveBandsFrom([
      for (var i = 0; i < 4; i++) row('smooth', rpa: 0.5),
      row('aggressive', rpa: 0.1),
    ]);
    expect(bands.rpaGoodMax, GpsKpiBands.defaults.rpaGoodMax);
    expect(bands.rpaModerateMax, GpsKpiBands.defaults.rpaModerateMax);
  });

  test('smooth-labelled trips above the default good ceiling WIDEN it '
      '(heavier car / hillier commute), never narrow it', () {
    final wide = VerdictCalibrationStore.deriveBandsFrom([
      for (var i = 0; i < 6; i++) row('smooth', rpa: 0.22),
    ]);
    expect(wide.rpaGoodMax, greaterThan(GpsKpiBands.defaults.rpaGoodMax));
    // Genuinely-below-default smooth trips must NOT narrow the ceiling.
    final calm = VerdictCalibrationStore.deriveBandsFrom([
      for (var i = 0; i < 6; i++) row('smooth', rpa: 0.05),
    ]);
    expect(calm.rpaGoodMax, GpsKpiBands.defaults.rpaGoodMax);
  });

  test('aggressive-labelled trips below the default moderate ceiling '
      'TIGHTEN it, floored at goodMax × 1.2 (monotonic bands)', () {
    final bands = VerdictCalibrationStore.deriveBandsFrom([
      for (var i = 0; i < 3; i++) row('aggressive', rpa: 0.22),
    ]);
    expect(
        bands.rpaModerateMax, lessThan(GpsKpiBands.defaults.rpaModerateMax));
    expect(bands.rpaModerateMax,
        greaterThanOrEqualTo(bands.rpaGoodMax * 1.2 - 1e-9));
  });

  test('coasting (inverted polarity) mirrors the rules: smooth p25 may '
      'LOWER the good floor', () {
    final bands = VerdictCalibrationStore.deriveBandsFrom([
      for (var i = 0; i < 6; i++) row('smooth', coast: 0.12),
    ]);
    expect(bands.coastGoodMin, lessThan(GpsKpiBands.defaults.coastGoodMin));
    expect(bands.coastModerateMin,
        lessThanOrEqualTo(bands.coastGoodMin / 1.2 + 1e-9));
  });

  test('rows round-trip through JSON; corrupt rows are skipped', () {
    final r = row('moderate', rpa: 0.33);
    final back = VerdictCalibrationRow.fromJson(
        r.toJson().cast<String, dynamic>());
    expect(back, isNotNull);
    expect(back!.rpa, 0.33);
    expect(back.verdict, 'moderate');
    expect(VerdictCalibrationRow.fromJson({'v': 1, 'rpa': 'x'}), isNull);
  });
}
