// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/approach_detector.dart';
import 'package:tankstellen/features/approach/providers/approach_simulator_provider.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

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
  group('ApproachSimulator (#2163)', () {
    test('starts null — no simulation by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(approachSimulatorProvider), isNull);
    });

    test('simulate() emits ApproachInRadius with the picked station',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(approachSimulatorProvider.notifier).simulate(_station);
      final state = container.read(approachSimulatorProvider);

      expect(state, isA<ApproachInRadius>());
      expect((state as ApproachInRadius).station.id, 's-test');
      expect(state.distanceMeters, greaterThan(0));
    });

    test('after [duration], advances to ApproachLeaving then null',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(approachSimulatorProvider.notifier)
          .simulate(_station, duration: const Duration(milliseconds: 30));

      expect(container.read(approachSimulatorProvider), isA<ApproachInRadius>());

      // Phase 1 expires → ApproachLeaving
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(
        container.read(approachSimulatorProvider),
        isA<ApproachLeaving>(),
        reason: 'simulator must mirror the real detector grace transition',
      );

      // ApproachDetector.exitGrace (5 s) is too long to wait in a unit
      // test — verify clear() short-circuits it instead.
      container.read(approachSimulatorProvider.notifier).clear();
      expect(container.read(approachSimulatorProvider), isNull);
    });

    test('clear() aborts any in-flight simulation immediately', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(approachSimulatorProvider.notifier).simulate(_station);
      container.read(approachSimulatorProvider.notifier).clear();

      expect(container.read(approachSimulatorProvider), isNull);
    });

    test('simulate() replaces a previous simulation', () async {
      const otherStation = Station(
        id: 's-other',
        name: 'Other',
        brand: 'BRAND',
        street: 'Other Street',
        postCode: '10117',
        place: 'Berlin',
        lat: 52.5,
        lng: 13.4,
        isOpen: true,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(approachSimulatorProvider.notifier).simulate(_station);
      container
          .read(approachSimulatorProvider.notifier)
          .simulate(otherStation);

      final state = container.read(approachSimulatorProvider);
      expect((state as ApproachInRadius).station.id, 's-other');
    });
  });
}
