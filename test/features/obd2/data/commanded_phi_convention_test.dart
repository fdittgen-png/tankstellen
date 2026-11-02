// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/protocol/elm327_parsers.dart';
import 'package:tankstellen/features/obd2/domain/fuel_mixture_model.dart';
import 'package:tankstellen/features/obd2/domain/fuel_rate_estimator.dart';

/// #4572: J1979 wire ratios are lambda, retained in historical lm/mq.
/// The true-phi math API receives their reciprocal exactly once.
void main() {
  for (final c in [
    (frame: '41 44 66 66>', lambda: 0.8), (frame: '41 44 80 00>', lambda: 1.0),
    (frame: '41 44 99 9A>', lambda: 1.2),
  ]) {
    test('raw ${c.frame} remains lambda ${c.lambda} through the adapter', () {
      final lambda =
          Elm327Parsers.parseCommandedEquivalenceRatio(c.frame)!;
      expect(lambda, closeTo(c.lambda, 0.0001));
      final afr = effectiveAfrForObdMixture(
        kPetrolAfr,
        commandedLambda: lambda,
        isDiesel: false,
      );
      expect(afr, closeTo(kPetrolAfr * c.lambda, 0.002));
      final relativeFuel = kPetrolAfr / afr;
      expect(relativeFuel, closeTo(1 / c.lambda, 0.001));
    });
  }
  test('invalid measured lambda falls back to valid commanded lambda', () {
    for (final bad in [0.0, -1.0, double.nan, double.infinity]) {
      expect(
        effectiveAfrForObdMixture(kPetrolAfr,
          measuredLambda: bad,
          commandedLambda: 0.8,
          isDiesel: false,
        ),
        closeTo(kPetrolAfr * 0.8, 1e-12));
      expect(
        effectiveAfrForObdMixture(kPetrolAfr,
          commandedLambda: bad,
          isDiesel: false,
        ),
        kPetrolAfr,
      );
    }
  });

    test('measured diesel lean lambda is retained, commanded lambda ignored', () {
    expect(
      effectiveAfrForObdMixture(
        kDieselAfr,
        measuredLambda: 1.6,
        commandedLambda: 0.8,
        isDiesel: true,
      ), closeTo(kDieselAfr * 1.6, 1e-12));
      expect(
      effectiveAfrForObdMixture(
        kDieselAfr,
        commandedLambda: 0.8,
        isDiesel: true,
      ),
      kDieselAfr,
    );
    });
  }
