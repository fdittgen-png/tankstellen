// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';

import 'consumption_identity_goldens.dart';
import 'consumption_identity_streams.dart';

/// #4233 (Epic #4222) — wiring the fuzzy engine into the producers changes
/// no figure: every stream in `consumption_identity_streams.dart` must
/// reproduce the float64 bit patterns captured on the tree before the
/// wiring. The engine ships neutral rules (ADR 0023), so the epic's
/// validation gate is satisfied by identity (ADR 0024) — and this is the
/// test that proves it. A red entry is a changed production figure: fix
/// the code, never the golden.
void main() {
  late Map<String, String> actual;

  setUpAll(() async {
    actual = await collectConsumptionFigures();
  });

  test('no stream was dropped or added', () {
    expect(actual.keys.toSet(), kConsumptionIdentityGoldens.keys.toSet());
    expect(actual.length, greaterThan(700),
        reason: 'the matrix must actually run');
  });

  for (final stream in const [
    'live/', // LiveSampleSnapshot.deriveFuelRateLPerHour
    // 'pull/' (Obd2FuelRateReader.read) left with the dead reader, #4315.
    'gps/', // GpsLiveFuelEstimator.onSample
    'folder/', // GpsLiveEstimateFolder.fold
    'backfill/', // backfillGpsTripFuel
    'fallback/', // Obd2GpsEstimateFallback.estimate
    'fallbackFill/', // Obd2GpsEstimateFallback.fillWhenNoFuelPid
    'calibrator/', // PhysicsScaleCalibrator.calibrate
    'recorder', // TripRecorder.buildSummary
  ]) {
    test('$stream figures are bit-identical to the pre-#4233 goldens', () {
      final keys = kConsumptionIdentityGoldens.keys
          .where((k) => k.startsWith(stream))
          .toList();
      expect(keys, isNotEmpty);
      final drift = [
        for (final k in keys)
          if (actual[k] != kConsumptionIdentityGoldens[k])
            '$k: ${kConsumptionIdentityGoldens[k]} → ${actual[k]}',
      ];
      expect(drift, isEmpty, reason: drift.join('\n'));
    });
  }

  test('the bit-pattern comparison distinguishes what == would not', () {
    // −0.0 == 0.0 and a one-ulp change both slip past a tolerance check.
    expect(bitsOf(-0.0), isNot(bitsOf(0.0)));
    expect(bitsOf(0.1 + 0.2), isNot(bitsOf(0.3)));
  });
}
