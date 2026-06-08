// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/consumption/data/repositories/fill_up_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../fakes/fake_hive_storage.dart';
import '../../helpers/silence_error_logger.dart';

/// Regression tests for #3077 — TankSync was upload-only for fill-ups.
///
/// [FillUpsSync.merge] returns the union (`[...local, ...downloaded]`) but
/// the only caller was the manual device-link flow, so a fill-up logged on
/// another device never reached this one on connect / launch. These drive
/// the new `FillUpList.pullFromServer` seam with an injected fake merge that
/// simulates server rows, and assert the server-only fill-up is **persisted
/// to LOCAL storage** (the `consumptionLog` settings key the repository
/// reads). They FAIL on master (the method doesn't exist / nothing wired the
/// merge to a connect-or-launch trigger) and PASS after.
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

  FillUp makeFillUp(String id) => FillUp(
        id: id,
        vehicleId: 'veh-1',
        date: DateTime(2026, 4, 22),
        liters: 40.0,
        totalCost: 70.0,
        odometerKm: 123456,
        fuelType: FuelType.e10,
      );

  /// A fake merge that echoes the device's local list plus [serverOnly] —
  /// the real [FillUpsSync.merge] "return local ∪ downloaded" contract.
  FillUpsMergeFn fakeMergeWithServer(List<FillUp> serverOnly) {
    return (local) async => [...local, ...serverOnly];
  }

  group('FillUpList.pullFromServer (#3077 pull-persist)', () {
    test('persists a server-only fill-up into LOCAL storage', () async {
      final container = createContainer();
      final notifier = container.read(fillUpListProvider.notifier);
      await notifier.add(makeFillUp('local-1'));

      final added = await notifier.pullFromServer(
        mergeFn: fakeMergeWithServer([makeFillUp('server-1')]),
      );

      expect(added, 1);
      // The repository re-reads from `consumptionLog` settings — assert the
      // downloaded id landed there, not just in provider state.
      final storedIds = FillUpRepository(fakeStorage).getAll().map((f) => f.id);
      expect(storedIds, containsAll(<String>['local-1', 'server-1']),
          reason: 'server-only fill-up must be written to local storage');
      // And reflected in provider state.
      expect(container.read(fillUpListProvider).map((f) => f.id),
          containsAll(<String>['local-1', 'server-1']));
    });

    test('empty local + server rows → local gets the server fill-up',
        () async {
      final container = createContainer();
      final notifier = container.read(fillUpListProvider.notifier);
      expect(container.read(fillUpListProvider), isEmpty);

      final added = await notifier.pullFromServer(
        mergeFn: fakeMergeWithServer([makeFillUp('srv-only')]),
      );

      expect(added, 1);
      expect(FillUpRepository(fakeStorage).getAll().map((f) => f.id),
          contains('srv-only'),
          reason: 'a fresh device must pull the server fill-up set');
    });

    test('no-op merge (unauthenticated server) leaves local unchanged',
        () async {
      final container = createContainer();
      final notifier = container.read(fillUpListProvider.notifier);
      await notifier.add(makeFillUp('keep-1'));

      // identity merge — what the real merge returns when unauthenticated.
      final added = await notifier.pullFromServer(mergeFn: (local) async => local);

      expect(added, 0);
      expect(FillUpRepository(fakeStorage).getAll().map((f) => f.id),
          ['keep-1']);
    });
  });
}
