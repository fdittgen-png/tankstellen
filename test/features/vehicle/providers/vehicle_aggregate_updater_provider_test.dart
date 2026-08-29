// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';
import 'package:tankstellen/features/trips/providers/trip_history_provider.dart';
import 'package:tankstellen/features/vehicle/data/vehicle_aggregate_updater.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_aggregate_updater_provider.dart';

/// Tests for [wireAggregatorIntoTripHistory] (#1193 phase 2 wiring).
///
/// Coverage targets the three branches in the helper:
///   1. trip-history repo is null → returns false, no hook installed
///   2. trip-history repo present → returns true, hook installed
///   3. installed hook delegates to VehicleAggregateUpdater.runForVehicle
void main() {
  group('wireAggregatorIntoTripHistory (#1193 phase 2)', () {
    test('returns false when tripHistoryRepositoryProvider yields null', () {
      final container = ProviderContainer(
        overrides: [
          tripHistoryRepositoryProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final wired = wireAggregatorIntoTripHistory(container);

      expect(wired, isFalse);
    });

    test(
        'returns true and installs onSavedHook when trip repo is present',
        () {
      final fakeRepo = _FakeTripHistoryRepository();
      final fakeUpdater = _FakeVehicleAggregateUpdater();

      final container = ProviderContainer(
        overrides: [
          tripHistoryRepositoryProvider.overrideWithValue(fakeRepo),
          vehicleAggregateUpdaterProvider.overrideWithValue(fakeUpdater),
        ],
      );
      addTearDown(container.dispose);

      expect(fakeRepo.onSavedHook, isNull,
          reason: 'precondition: hook starts unset');

      final wired = wireAggregatorIntoTripHistory(container);

      expect(wired, isTrue);
      expect(fakeRepo.onSavedHook, isNotNull,
          reason: 'wiring should install a hook on the repo');
    });

    test(
        'installed hook forwards vehicleId to '
        'VehicleAggregateUpdater.runForVehicle', () async {
      final fakeRepo = _FakeTripHistoryRepository();
      final fakeUpdater = _FakeVehicleAggregateUpdater();

      final container = ProviderContainer(
        overrides: [
          tripHistoryRepositoryProvider.overrideWithValue(fakeRepo),
          vehicleAggregateUpdaterProvider.overrideWithValue(fakeUpdater),
        ],
      );
      addTearDown(container.dispose);

      final wired = wireAggregatorIntoTripHistory(container);
      expect(wired, isTrue);

      // Invoke the hook the way TripHistoryRepository.save does.
      fakeRepo.onSavedHook!(const TripHistoryEntry(
        id: 't-1',
        vehicleId: 'vehicle-abc',
        summary: TripSummary(
            distanceKm: 1, maxRpm: 0, highRpmSeconds: 0, idleSeconds: 0,
            harshBrakes: 0, harshAccelerations: 0),
      ));

      // The hook fire-and-forgets via unawaited(...); let any
      // microtasks queued by the future flush before asserting.
      await Future<void>.delayed(Duration.zero);

      expect(fakeUpdater.runCalls, equals(<String>['vehicle-abc']));
    });
  });
}

/// Minimal fake exposing only the writable [onSavedHook] field that
/// [wireAggregatorIntoTripHistory] touches. Every other method on the
/// real repository would need a Hive box to be meaningful, so we route
/// them through [noSuchMethod] and let the test fail loudly if the
/// helper ever starts calling something else.
class _FakeTripHistoryRepository implements TripHistoryRepository {
  @override
  void Function(TripHistoryEntry entry)? onSavedHook;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(
        '_FakeTripHistoryRepository.${invocation.memberName} '
        'was not expected to be called by wireAggregatorIntoTripHistory',
      );
}

/// Records every call to [runForVehicle]. All other methods are
/// unimplemented because the wiring helper only ever invokes
/// [runForVehicle] on the updater (via the installed hook).
class _FakeVehicleAggregateUpdater implements VehicleAggregateUpdater {
  final List<String> runCalls = <String>[];

  // #3878 — the hook folds the saved trip in; record its vehicle id.
  @override
  Future<void> runForSavedTrip(TripHistoryEntry entry) async {
    runCalls.add(entry.vehicleId!);
  }

  @override
  Future<void> runForVehicle(String vehicleId) async {
    runCalls.add(vehicleId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(
        '_FakeVehicleAggregateUpdater.${invocation.memberName} '
        'was not expected to be called by wireAggregatorIntoTripHistory',
      );
}
