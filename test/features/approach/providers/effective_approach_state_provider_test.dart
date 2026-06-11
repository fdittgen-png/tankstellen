// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/approach_detector.dart';
import 'package:tankstellen/features/approach/providers/approach_simulator_provider.dart';
import 'package:tankstellen/features/approach/providers/effective_approach_state_provider.dart';
import 'package:tankstellen/core/domain/station.dart';

const _station = Station(
  id: 's-test',
  name: 'Test Station',
  brand: 'STAR',
  street: 'Test Street',
  postCode: '10115',
  place: 'Berlin',
  lat: 52.52,
  lng: 13.40,
  isOpen: true,
);

void main() {
  group('effectiveApproachStateProvider (#2163 — merger)', () {
    test('simulator wins over the real detector', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(approachSimulatorProvider.notifier).simulate(_station);

      final effective = container.read(effectiveApproachStateProvider);
      expect(effective, isA<ApproachInRadius>(),
          reason: 'simulator must override the real detector');
      expect((effective as ApproachInRadius).station.id, 's-test');
    });

    test('returns null when simulator is null AND real stream has no value',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Default: no trip active → approachStateProvider yields no value;
      // simulator is null; effective is null.
      expect(container.read(effectiveApproachStateProvider), isNull);
    });

    test('clearing the simulator returns control to the real stream',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(approachSimulatorProvider.notifier).simulate(_station);
      expect(
        container.read(effectiveApproachStateProvider),
        isA<ApproachInRadius>(),
      );

      container.read(approachSimulatorProvider.notifier).clear();
      expect(
        container.read(effectiveApproachStateProvider),
        isNull,
        reason:
            'with no trip running, the real stream yields nothing and '
            'effective falls back to null',
      );
    });
  });
}
