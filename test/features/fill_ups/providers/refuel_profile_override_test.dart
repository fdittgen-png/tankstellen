// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/refuel_economics.dart';
import 'package:tankstellen/core/domain/refuel_profile_provider.dart';
import 'package:tankstellen/features/fill_ups/providers/refuel_profile_override.dart';

/// #4089 — the vehicle side of Best Value, and the inversion that keeps
/// `features/search` from importing `features/fill_ups`.
void main() {
  test('the core default withholds Best Value rather than guessing', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final profile = container.read(refuelProfileProvider);
    expect(profile.consumptionLPer100km, isNull);
    expect(profile.canRankByValue, isFalse,
        reason: 'a fabricated default would turn a missing measurement '
            'into a confident recommendation');
    expect(profile.litresIntended, kDefaultRefuelLitres);
  });

  test('the override replaces it with the measured profile', () {
    final container = ProviderContainer(overrides: [
      ...refuelProfileOverrides(),
      realRefuelProfileProvider.overrideWithValue(
        const RefuelProfile(consumptionLPer100km: 6.4, litresIntended: 38),
      ),
    ]);
    addTearDown(container.dispose);
    final profile = container.read(refuelProfileProvider);
    expect(profile.consumptionLPer100km, 6.4);
    expect(profile.litresIntended, 38);
    expect(profile.canRankByValue, isTrue);
  });

  test('the override list names exactly the core provider', () {
    // A regression here would silently leave the app on the empty
    // default — Best Value would quietly stop working with no error.
    expect(refuelProfileOverrides(), hasLength(1));
  });
}
