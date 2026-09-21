// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/features/obd2/domain/fuel_mixture_model.dart';
import 'package:tankstellen/features/obd2/domain/fuel_rate_estimator.dart';
import 'package:tankstellen/features/obd2/domain/signal_reading.dart';
import 'package:tankstellen/features/obd2/domain/signal_plausibility.dart';
import 'package:tankstellen/features/obd2/domain/vehicle_signal.dart';

/// #4159 — implausible inputs are MARKED against the exact band the fuel
/// math clamps to, and the clamp (so every fuel figure) stays as it was.

const _plausible = SignalPlausibility.plausible;
const _implausible = SignalPlausibility.implausible;

void main() {
  group('bands are the clamp bands, inclusive', () {
    test('commanded φ 0.5 … 1.5', () {
      expect(classifyCommandedPhi(0.5), _plausible);
      expect(classifyCommandedPhi(1.5), _plausible);
      expect(classifyCommandedPhi(0.4999), _implausible);
      expect(classifyCommandedPhi(1.5001), _implausible);
      expect(classifyCommandedPhi(double.nan), _implausible);
    });

    test('measured φ: diesel 0.05 … 1.2, otherwise the commanded band', () {
      expect(classifyMeasuredPhi(0.1, isDiesel: true), _plausible);
      expect(classifyMeasuredPhi(0.1, isDiesel: false), _implausible);
      expect(classifyMeasuredPhi(0.05, isDiesel: true), _plausible);
      expect(classifyMeasuredPhi(0.04, isDiesel: true), _implausible);
      expect(classifyMeasuredPhi(1.2, isDiesel: true), _plausible);
      expect(classifyMeasuredPhi(1.3, isDiesel: true), _implausible);
      expect(classifyMeasuredPhi(1.3, isDiesel: false), _plausible);
    });

    test('baro: density factor 0.6 … 1.1 of sea level', () {
      expect(classifyBaroKpa(kSeaLevelBaroKpa), _plausible);
      expect(classifyBaroKpa(0.6 * kSeaLevelBaroKpa), _plausible);
      expect(classifyBaroKpa(1.1 * kSeaLevelBaroKpa), _plausible);
      expect(classifyBaroKpa(0.59 * kSeaLevelBaroKpa), _implausible);
      expect(classifyBaroKpa(120), _implausible);
    });
  });

  group('the clamps are unchanged — marking does not touch the math', () {
    test('an implausible φ still clamps to the band edge', () {
      expect(effectiveAfrForPhi(kPetrolAfr, 1.9),
          effectiveAfrForPhi(kPetrolAfr, kMaxCommandedPhi));
      expect(
        effectiveAfrForMixture(kDieselAfr, measuredPhi: 0.01, isDiesel: true),
        effectiveAfrForMixture(kDieselAfr,
            measuredPhi: kMinDieselMeasuredPhi, isDiesel: true),
      );
    });

    test('an implausible baro still clamps the air-density factor', () {
      double? sd(double baro) => estimateFuelRateLPerHourFromMap(
            mapKpa: 60,
            iatCelsius: 20,
            rpm: 2000,
            engineDisplacementCc: 1000,
            volumetricEfficiency: 0.85,
            baroKpa: baro,
          );
      expect(sd(20), closeTo(sd(0.6 * kSeaLevelBaroKpa)!, 1e-12));
      expect(sd(200), closeTo(sd(1.1 * kSeaLevelBaroKpa)!, 1e-12));
      expect(kMinBaroDensityFactor, 0.6);
      expect(kMaxBaroDensityFactor, 1.1);
    });
  });

  group('markPlausibility', () {
    SignalReading r(VehicleSignal s, double? v) => SignalReading(
          signal: s,
          value: v == null
              ? const DataValue<double>.unknown(
                  reason: DataUnknownReason.notMeasuredYet)
              : DataValue<double>.measured(v),
        );

    test('marks φ and baro, leaves everything else unchecked', () {
      expect(markPlausibility(r(VehicleSignal.commandedPhi, 1.9),
              isDiesel: false)
          .plausibility, _implausible);
      expect(markPlausibility(r(VehicleSignal.baroPressure, 95),
              isDiesel: false)
          .plausibility, _plausible);
      expect(markPlausibility(r(VehicleSignal.widebandPhi, 0.1),
              isDiesel: true)
          .plausibility, _plausible);
      expect(markPlausibility(r(VehicleSignal.widebandPhi, 0.1),
              isDiesel: false)
          .plausibility, _implausible);
      expect(markPlausibility(r(VehicleSignal.coolantTemp, 500),
              isDiesel: false)
          .plausibility, SignalPlausibility.notChecked);
    });

    test('keeps the unclamped value, and leaves a missing value unmarked',
        () {
      final marked =
          markPlausibility(r(VehicleSignal.commandedPhi, 1.9), isDiesel: false);
      expect(marked.valueOrNull, 1.9);
      expect(markPlausibility(r(VehicleSignal.commandedPhi, null),
              isDiesel: false)
          .plausibility, SignalPlausibility.notChecked);
    });

    test('a stale value is still marked', () {
      const stale = SignalReading(
        signal: VehicleSignal.baroPressure,
        value: Stale<double>(30, age: Duration(minutes: 1)),
      );
      expect(markPlausibility(stale, isDiesel: false).plausibility,
          _implausible);
    });
  });
}
