// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/engine_power_factor.dart';

/// Unit tests for the inverse-power weight applied to the hard-acceleration
/// penalty / waste (Epic #3015). The factor must be 1.0 at the reference,
/// monotonically decreasing in power, clamped at both ends, and a safe
/// identity (1.0) for unknown / non-physical power.
void main() {
  group('enginePowerAccelFactor (Epic #3015)', () {
    test('reference power → exactly 1.0 (today\'s penalty, unchanged)', () {
      expect(enginePowerAccelFactor(kReferenceEnginePowerKw), 1.0);
    });

    test('null power → 1.0 (legacy / power-unknown identity)', () {
      expect(enginePowerAccelFactor(null), 1.0);
    });

    test('zero and negative power → 1.0 (division guard)', () {
      expect(enginePowerAccelFactor(0), 1.0);
      expect(enginePowerAccelFactor(-100), 1.0);
    });

    test('low power → factor > 1 (penalised MORE)', () {
      // 80 kW (catalog median) → 100/80 = 1.25, within bounds.
      expect(enginePowerAccelFactor(80), closeTo(1.25, 1e-9));
      expect(enginePowerAccelFactor(80), greaterThan(1.0));
    });

    test('high power → factor < 1 (penalised LESS)', () {
      // 125 kW → 100/125 = 0.8, within bounds.
      expect(enginePowerAccelFactor(125), closeTo(0.8, 1e-9));
      expect(enginePowerAccelFactor(125), lessThan(1.0));
    });

    test('strictly decreasing in power across the unclamped band', () {
      final f60 = enginePowerAccelFactor(60);
      final f100 = enginePowerAccelFactor(100);
      final f160 = enginePowerAccelFactor(160);
      expect(f60, greaterThan(f100));
      expect(f100, greaterThan(f160));
    });

    test('clamps to fMax for very small engines (no runaway 3×)', () {
      // 33 kW (catalog minimum) → 100/33 = 3.03 → clamped to fMax.
      expect(enginePowerAccelFactor(33), kEnginePowerFactorMax);
      expect(enginePowerAccelFactor(1), kEnginePowerFactorMax);
    });

    test('clamps to fMin for very large engines (never near-zero)', () {
      // 5000 kW → 100/5000 = 0.02 → clamped to fMin.
      expect(enginePowerAccelFactor(5000), kEnginePowerFactorMin);
      expect(enginePowerAccelFactor(400), kEnginePowerFactorMin);
    });

    test('bounds are sane (fMin < 1 < fMax) and reference is mainstream', () {
      expect(kEnginePowerFactorMin, lessThan(1.0));
      expect(kEnginePowerFactorMax, greaterThan(1.0));
      // 100 kW sits in a plausible mainstream band (60..160 kW).
      expect(kReferenceEnginePowerKw, inInclusiveRange(60, 160));
    });
  });
}
