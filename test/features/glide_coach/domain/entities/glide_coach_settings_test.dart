// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/glide_coach/domain/entities/glide_coach_settings.dart';

void main() {
  group('GlideCoachSettings (#1125 phase 3a)', () {
    test('defaults match the issue acceptance criteria', () {
      const settings = GlideCoachSettings();
      // "Setting toggle, default OFF" — the master toggle MUST default
      // to false so the feature stays dormant until the user opts in.
      expect(settings.enabled, isFalse);
      // Throttle threshold matches the evaluator default (kept in
      // sync via the entity-side default).
      expect(settings.throttleThresholdPercent, 20.0);
      // 15-second cool-down matches the issue's "long quiet between
      // buzzes" preference.
      expect(settings.cooldown, const Duration(seconds: 15));
    });

    test('equality and hashCode agree for equal-valued instances', () {
      const a = GlideCoachSettings(
        enabled: true,
        throttleThresholdPercent: 25.0,
        cooldown: Duration(seconds: 20),
      );
      const b = GlideCoachSettings(
        enabled: true,
        throttleThresholdPercent: 25.0,
        cooldown: Duration(seconds: 20),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('equality is field-sensitive (enabled flip is not equal)', () {
      const enabled = GlideCoachSettings(enabled: true);
      const disabled = GlideCoachSettings();
      expect(enabled, isNot(equals(disabled)));
    });

    test('copyWith overrides only the fields supplied', () {
      const base = GlideCoachSettings();
      final flipped = base.copyWith(enabled: true);
      expect(flipped.enabled, isTrue);
      expect(
        flipped.throttleThresholdPercent,
        base.throttleThresholdPercent,
      );
      expect(flipped.cooldown, base.cooldown);
    });

    test('toString surfaces all three fields (debug-friendly)', () {
      const s = GlideCoachSettings();
      final out = s.toString();
      expect(out, contains('enabled: false'));
      expect(out, contains('throttleThresholdPercent: 20.0'));
      expect(out, contains('cooldown'));
    });
  });
}
