// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../fakes/fake_hive_storage.dart';
import '../../helpers/silence_error_logger.dart';

/// Regression tests for #3077 — TankSync was upload-only for vehicles.
///
/// [VehiclesSync.merge] returns the union (`[...local, ...downloaded]`) but
/// the only caller was the manual device-link flow, so a vehicle profile
/// added on another device never reached this one on connect / launch.
/// These drive the new `VehicleProfileList.pullFromServer` seam with an
/// injected fake merge that simulates server rows, and assert the
/// server-only profile is **persisted to LOCAL storage** (the
/// `vehicleProfiles` settings key the repository reads). They FAIL on master
/// (the method doesn't exist / nothing wired the merge to a trigger) and
/// PASS after.
void main() {
  silenceErrorLoggerSpool();
  late FakeHiveStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeHiveStorage();
  });

  ProviderContainer createContainer() {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  VehicleProfile vehicle(String id, String name) =>
      VehicleProfile(id: id, name: name);

  /// A fake merge that echoes the device's local list plus [serverOnly] —
  /// the real [VehiclesSync.merge] "return local ∪ downloaded" contract.
  VehiclesMergeFn fakeMergeWithServer(List<VehicleProfile> serverOnly) {
    return (local) async => [...local, ...serverOnly];
  }

  group('VehicleProfileList.pullFromServer (#3077 pull-persist)', () {
    test('persists a server-only vehicle into LOCAL storage', () async {
      final container = createContainer();
      final notifier = container.read(vehicleProfileListProvider.notifier);
      await notifier.save(vehicle('local-1', 'Peugeot 107'));

      final added = await notifier.pullFromServer(
        mergeFn: fakeMergeWithServer([vehicle('server-1', 'Renault Clio')]),
      );

      expect(added, 1);
      final storedIds =
          VehicleProfileRepository(fakeStorage).getAll().map((v) => v.id);
      expect(storedIds, containsAll(<String>['local-1', 'server-1']),
          reason: 'server-only vehicle must be written to local storage');
      expect(container.read(vehicleProfileListProvider).map((v) => v.id),
          containsAll(<String>['local-1', 'server-1']));
    });

    test('empty local + server rows → local gets the server vehicle',
        () async {
      final container = createContainer();
      final notifier = container.read(vehicleProfileListProvider.notifier);
      expect(container.read(vehicleProfileListProvider), isEmpty);

      final added = await notifier.pullFromServer(
        mergeFn: fakeMergeWithServer([vehicle('srv-only', 'VW Polo')]),
      );

      expect(added, 1);
      expect(VehicleProfileRepository(fakeStorage).getAll().map((v) => v.id),
          contains('srv-only'),
          reason: 'a fresh device must pull the server vehicle set');
    });

    test('no-op merge (unauthenticated server) leaves local unchanged',
        () async {
      final container = createContainer();
      final notifier = container.read(vehicleProfileListProvider.notifier);
      await notifier.save(vehicle('keep-1', 'Fiat 500'));

      final added =
          await notifier.pullFromServer(mergeFn: (local) async => local);

      expect(added, 0);
      expect(VehicleProfileRepository(fakeStorage).getAll().map((v) => v.id),
          ['keep-1']);
    });
  });
}
