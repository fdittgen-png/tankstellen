// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/notifications/notification_providers.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/sync/alerts_sync.dart';
import 'package:tankstellen/core/sync/sync_helper.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/alerts/providers/alert_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../fakes/fake_hive_storage.dart';
import '../../helpers/silence_error_logger.dart';

/// #3121 — deleted price alerts resurrect at the next launch.
///
/// `removeAlert` deleted only locally; alerts was the ONLY synced entity
/// with neither server-delete propagation nor deletion tombstones. The
/// #3077 launch pull (`pullFromServer` → `_applyMergedAlerts`) then
/// re-persisted the surviving server row, resurrecting the alert the user
/// just removed.
///
/// The fix mirrors FavoritesSync (#3078): `removeAlert` now propagates the
/// delete (server row delete + `deletions` tombstone via
/// [AlertsSync.delete]) and [AlertsSync.merge] filters tombstoned ids
/// through the shared [SyncHelper.removeTombstoned] seam.
///
/// These tests drive the provider flow with a fake server store mutated by
/// the injectable delete fn. They FAIL on the pre-fix code (no delete
/// propagation exists, so the fake server keeps the row and the pull
/// resurrects it) and PASS after.
class _NoopNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> areNotificationsEnabled() async => true;
  @override
  Future<void> showPriceAlert(
      {required int id,
      required String title,
      required String body,
      String? payload}) async {}
  @override
  Future<void> showServiceReminder(
      {required int id, required String title, required String body}) async {}
  @override
  Future<void> cancelNotification(int id) async {}
  @override
  Future<void> cancelAll() async {}
}

PriceAlert _makeAlert({required String id, String stationId = 'station-1'}) {
  return PriceAlert(
    id: id,
    stationId: stationId,
    stationName: 'Test Station',
    fuelType: FuelType.e10,
    targetPrice: 1.50,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  silenceErrorLoggerSpool();
  late FakeHiveStorage fakeStorage;

  /// The fake server: rows surviving on Supabase. The fake merge fn
  /// models the real [AlertsSync.merge] contract (returns
  /// `[local, ...server-only]`); the fake delete fn models the real
  /// [AlertsSync.delete] contract (removes the server row).
  late List<PriceAlert> serverStore;
  late List<String> propagatedDeletes;

  setUp(() {
    fakeStorage = FakeHiveStorage();
    serverStore = [];
    propagatedDeletes = [];
  });

  ProviderContainer createContainer({
    Future<void> Function(String id)? deleteFn,
  }) {
    final container = ProviderContainer(
      overrides: [
        hiveStorageProvider.overrideWithValue(fakeStorage),
        notificationServiceProvider
            .overrideWithValue(_NoopNotificationService()),
        alertsMergeFnProvider.overrideWithValue((local) async {
          final localIds = local.map((a) => a.id).toSet();
          return [
            ...local,
            ...serverStore.where((s) => !localIds.contains(s.id)),
          ];
        }),
        alertsDeleteFnProvider.overrideWithValue(deleteFn ??
            (id) async {
              propagatedDeletes.add(id);
              serverStore.removeWhere((a) => a.id == id);
            }),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('alert delete propagation + resurrection (#3121)', () {
    test('removeAlert propagates the delete to the server', () async {
      await fakeStorage.putSetting('sync_enabled', true);
      final keep = _makeAlert(id: 'keep');
      final gone = _makeAlert(id: 'gone', stationId: 'station-2');
      await fakeStorage.saveAlerts([keep.toJson(), gone.toJson()]);
      serverStore = [keep, gone];

      final container = createContainer();
      container.read(alertProvider);

      await container.read(alertProvider.notifier).removeAlert('gone');

      expect(propagatedDeletes, equals(['gone']),
          reason: 'removeAlert must propagate the delete to the server — '
              'pre-#3121 it deleted only locally');
    });

    test('deleted alert stays dead through the #3077 launch pull', () async {
      await fakeStorage.putSetting('sync_enabled', true);
      final keep = _makeAlert(id: 'keep');
      final gone = _makeAlert(id: 'gone', stationId: 'station-2');
      await fakeStorage.saveAlerts([keep.toJson(), gone.toJson()]);
      serverStore = [keep, gone];

      final container = createContainer();
      container.read(alertProvider);

      await container.read(alertProvider.notifier).removeAlert('gone');
      // The next launch runs the explicit pull (#3077) — without delete
      // propagation the surviving server row resurrects here.
      await container.read(alertProvider.notifier).pullFromServer();

      final stored = fakeStorage.getAlerts().map((a) => a['id']).toSet();
      expect(stored, equals({'keep'}),
          reason: 'the launch pull resurrected the deleted alert');
      expect(container.read(alertProvider).map((a) => a.id).toSet(),
          equals({'keep'}));
    });

    test('local delete succeeds even when the server delete throws',
        () async {
      await fakeStorage.putSetting('sync_enabled', true);
      final gone = _makeAlert(id: 'gone');
      await fakeStorage.saveAlerts([gone.toJson()]);
      serverStore = [gone];

      final container = createContainer(
        deleteFn: (id) async => throw Exception('server unreachable'),
      );
      container.read(alertProvider);

      // Local-first: the server failure must not throw back into the UI
      // flow, and the local delete must stick.
      await expectLater(
          container.read(alertProvider.notifier).removeAlert('gone'),
          completes);
      expect(fakeStorage.getAlerts(), isEmpty);
      expect(container.read(alertProvider), isEmpty);
    });

    test('delete propagation is not invoked when TankSync is disabled',
        () async {
      // sync_enabled not set → SyncHelper gate keeps the server untouched.
      final gone = _makeAlert(id: 'gone');
      await fakeStorage.saveAlerts([gone.toJson()]);

      final container = createContainer();
      container.read(alertProvider);

      await container.read(alertProvider.notifier).removeAlert('gone');

      expect(propagatedDeletes, isEmpty);
      expect(fakeStorage.getAlerts(), isEmpty);
    });
  });

  group('AlertsSync auth guards (#3121)', () {
    test('delete is a no-op when unauthenticated', () async {
      // Mirrors the FavoritesSync.delete guard test — returns normally
      // without a Supabase client.
      await expectLater(AlertsSync.delete('alert-1'), completes);
    });
  });

  group('AlertsSync.merge tombstone seam (#3121)', () {
    test('a tombstoned server alert row is dropped before the union', () {
      // The same shared seam favorites/ignored use (#3078), keyed on the
      // alert row's `id` column — pins the filter shape merge() wires up.
      final serverRows = [
        {'id': 'keep', 'station_id': 's-1'},
        {'id': 'gone', 'station_id': 's-2'},
      ];
      final live = SyncHelper.removeTombstoned(
        serverRows,
        {'gone'},
        key: (r) => r['id'],
      ).toList();
      expect(live, hasLength(1));
      expect(live.single['id'], 'keep');
    });
  });
}
