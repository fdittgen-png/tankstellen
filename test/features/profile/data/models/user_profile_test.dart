// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';

/// Persistence contract for [UserProfile] fields that are read back from
/// JSON-serialized profiles on disk. Focused on the #1602 detour-budget
/// field — the key risk is a stored profile written before the field
/// existed, which must migrate to the default rather than crash
/// deserialization.
void main() {
  group('UserProfile.routeDetourBudgetKm (#1602)', () {
    test('defaults to 5.0 km — the prior hard-coded search corridor', () {
      const p = UserProfile(id: 'p1', name: 'Test');
      expect(p.routeDetourBudgetKm, 5.0);
    });

    test('legacy JSON without the key migrates to the 5.0 default', () {
      // A profile persisted before #1602 has no routeDetourBudgetKm key.
      final p = UserProfile.fromJson(const {'id': 'p1', 'name': 'Test'});
      expect(p.routeDetourBudgetKm, 5.0);
    });

    test('an explicit value survives a JSON round-trip', () {
      const p = UserProfile(id: 'p1', name: 'Test', routeDetourBudgetKm: 14);
      final restored = UserProfile.fromJson(p.toJson());
      expect(restored.routeDetourBudgetKm, 14);
    });
  });

  group('UserProfile.minRouteSavingPerLiter (#1872)', () {
    test('defaults to 0.0 — the minimum-saving filter is off', () {
      const p = UserProfile(id: 'p1', name: 'Test');
      expect(p.minRouteSavingPerLiter, 0.0);
    });

    test('legacy JSON without the key migrates to the 0.0 default', () {
      final p = UserProfile.fromJson(const {'id': 'p1', 'name': 'Test'});
      expect(p.minRouteSavingPerLiter, 0.0);
    });

    test('an explicit value survives a JSON round-trip', () {
      const p =
          UserProfile(id: 'p1', name: 'Test', minRouteSavingPerLiter: 0.08);
      final restored = UserProfile.fromJson(p.toJson());
      expect(restored.minRouteSavingPerLiter, 0.08);
    });
  });
}
