import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/alerts/data/repositories/alert_repository.dart';
import 'package:tankstellen/features/alerts/providers/alert_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../../fakes/fake_hive_storage.dart';

PriceAlert _makeAlert({
  String id = 'alert-1',
  String stationId = 'station-1',
  String stationName = 'Test Station',
  FuelType fuelType = FuelType.e10,
  double targetPrice = 1.50,
  bool isActive = true,
  DateTime? lastTriggeredAt,
}) {
  return PriceAlert(
    id: id,
    stationId: stationId,
    stationName: stationName,
    fuelType: fuelType,
    targetPrice: targetPrice,
    isActive: isActive,
    lastTriggeredAt: lastTriggeredAt,
    createdAt: DateTime(2025, 1, 1),
  );
}

void main() {
  late FakeHiveStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeHiveStorage();
  });

  group('AlertRepository', () {
    late AlertRepository repo;

    setUp(() {
      repo = AlertRepository(fakeStorage);
    });

    test('getAlerts returns empty list when storage is empty', () {
      final alerts = repo.getAlerts();
      expect(alerts, isEmpty);
    });

    test('getAlerts returns parsed alerts from storage', () async {
      final alert = _makeAlert();
      await fakeStorage.saveAlerts([alert.toJson()]);

      final alerts = repo.getAlerts();
      expect(alerts.length, 1);
      expect(alerts.first.id, 'alert-1');
      expect(alerts.first.stationId, 'station-1');
      expect(alerts.first.fuelType, FuelType.e10);
      expect(alerts.first.targetPrice, 1.50);
    });

    test('getAlerts preserves lastTriggeredAt through JSON round-trip',
        () async {
      final triggeredTime = DateTime(2026, 3, 15, 14, 30);
      final alert = _makeAlert(lastTriggeredAt: triggeredTime);
      await fakeStorage.saveAlerts([alert.toJson()]);

      final alerts = repo.getAlerts();
      expect(alerts.first.lastTriggeredAt, isNotNull);
      expect(alerts.first.lastTriggeredAt, triggeredTime);
    });

    test('getAlerts handles alert with null lastTriggeredAt', () async {
      final alert = _makeAlert(lastTriggeredAt: null);
      await fakeStorage.saveAlerts([alert.toJson()]);

      final alerts = repo.getAlerts();
      expect(alerts.first.lastTriggeredAt, isNull);
    });

    test('saveAlert adds a new alert to storage', () async {
      final alert = _makeAlert();
      await repo.saveAlert(alert);

      expect(fakeStorage.getAlerts(), hasLength(1));
      expect(fakeStorage.getAlerts().first['id'], 'alert-1');
    });

    test('saveAlert updates existing alert with same id', () async {
      final existing = _makeAlert(targetPrice: 1.50);
      await fakeStorage.saveAlerts([existing.toJson()]);

      final updated = _makeAlert(targetPrice: 1.30);
      await repo.saveAlert(updated);

      expect(fakeStorage.getAlerts(), hasLength(1));
      expect(fakeStorage.getAlerts().first['targetPrice'], 1.30);
    });

    test('saveAlert preserves isActive flag correctly', () async {
      final alert = _makeAlert(isActive: false);

      await repo.saveAlert(alert);

      expect(fakeStorage.getAlerts().first['isActive'], false);
    });

    test('deleteAlert removes alert by id', () async {
      final alert = _makeAlert();
      await fakeStorage.saveAlerts([alert.toJson()]);

      await repo.deleteAlert('alert-1');

      expect(fakeStorage.getAlerts(), isEmpty);
    });

    test('deleteAlert does nothing when id not found', () async {
      final alert = _makeAlert();
      await fakeStorage.saveAlerts([alert.toJson()]);

      await repo.deleteAlert('nonexistent');

      expect(fakeStorage.getAlerts(), hasLength(1));
    });

    test('PriceAlert JSON round-trip preserves all fields', () {
      final alert = _makeAlert(
        id: 'test_123',
        stationId: 'station_456',
        stationName: 'Shell Berlin',
        fuelType: FuelType.diesel,
        targetPrice: 1.459,
        isActive: false,
        lastTriggeredAt: DateTime(2026, 3, 20, 10, 0),
      );

      final json = alert.toJson();
      final restored = PriceAlert.fromJson(json);

      expect(restored.id, alert.id);
      expect(restored.stationId, alert.stationId);
      expect(restored.stationName, alert.stationName);
      expect(restored.fuelType, alert.fuelType);
      expect(restored.targetPrice, alert.targetPrice);
      expect(restored.isActive, alert.isActive);
      expect(restored.lastTriggeredAt, alert.lastTriggeredAt);
      expect(restored.createdAt, alert.createdAt);
    });

    test('PriceAlert fromJson handles all fuel types', () {
      for (final fuelType in FuelType.values) {
        final alert = _makeAlert(fuelType: fuelType);
        final json = alert.toJson();
        final restored = PriceAlert.fromJson(json);
        expect(restored.fuelType, fuelType,
            reason: 'Failed for ${fuelType.name}');
      }
    });
  });

  group('AlertNotifier (via ProviderContainer)', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          hiveStorageProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(container.dispose);
    });

    test('build() returns alerts from AlertRepository', () async {
      final alert = _makeAlert();
      await fakeStorage.saveAlerts([alert.toJson()]);

      final alerts = container.read(alertProvider);
      expect(alerts.length, 1);
      expect(alerts.first.id, 'alert-1');
    });

    test('build() returns empty list when no alerts stored', () {
      final alerts = container.read(alertProvider);
      expect(alerts, isEmpty);
    });

    test('addAlert() saves to repository and updates state', () async {
      expect(container.read(alertProvider), isEmpty);

      final alert = _makeAlert();
      await container.read(alertProvider.notifier).addAlert(alert);

      expect(fakeStorage.getAlerts(), hasLength(1));
      final state = container.read(alertProvider);
      expect(state.length, 1);
      expect(state.first.id, 'alert-1');
    });

    test('addAlert() saves correct data to storage', () async {
      container.read(alertProvider);

      final alert = _makeAlert(
        id: 'my-alert',
        stationId: 'my-station',
        stationName: 'My Station',
        fuelType: FuelType.diesel,
        targetPrice: 1.35,
      );

      await container.read(alertProvider.notifier).addAlert(alert);

      final saved = fakeStorage.getAlerts().first;
      expect(saved['id'], 'my-alert');
      expect(saved['stationId'], 'my-station');
      expect(saved['stationName'], 'My Station');
      expect(saved['fuelType'], 'diesel');
      expect(saved['targetPrice'], 1.35);
    });

    test('removeAlert() removes from repository and updates state',
        () async {
      final alert = _makeAlert();
      await fakeStorage.saveAlerts([alert.toJson()]);

      expect(container.read(alertProvider).length, 1);

      await container.read(alertProvider.notifier).removeAlert('alert-1');

      expect(fakeStorage.getAlerts(), isEmpty);
      final state = container.read(alertProvider);
      expect(state, isEmpty);
    });

    test('removeAlert() with non-existent id does not crash', () async {
      final alert = _makeAlert();
      await fakeStorage.saveAlerts([alert.toJson()]);

      container.read(alertProvider);
      await container
          .read(alertProvider.notifier)
          .removeAlert('non-existent');

      // Alert should still be there
      final state = container.read(alertProvider);
      expect(state.length, 1);
    });

    test('toggleAlert() toggles isActive flag', () async {
      final alert = _makeAlert(isActive: true);
      await fakeStorage.saveAlerts([alert.toJson()]);

      expect(container.read(alertProvider).first.isActive, true);

      await container.read(alertProvider.notifier).toggleAlert('alert-1');

      expect(fakeStorage.getAlerts().first['isActive'], false);
      final state = container.read(alertProvider);
      expect(state.first.isActive, false);
    });

    test('toggleAlert() with non-existent id does nothing', () async {
      final alert = _makeAlert(isActive: true);
      await fakeStorage.saveAlerts([alert.toJson()]);

      container.read(alertProvider);
      final before = fakeStorage.getAlerts().first['isActive'];
      await container
          .read(alertProvider.notifier)
          .toggleAlert('non-existent');
      final after = fakeStorage.getAlerts().first['isActive'];

      // Existing alert state unchanged.
      expect(after, before);
    });

    test('toggleAlert() saves correct toggled data', () async {
      final alert = _makeAlert(isActive: true);
      await fakeStorage.saveAlerts([alert.toJson()]);

      container.read(alertProvider);
      await container.read(alertProvider.notifier).toggleAlert('alert-1');

      expect(fakeStorage.getAlerts().first['isActive'], false);
    });

    test('getAlertStationIds() returns unique active station IDs', () async {
      final alerts = [
        _makeAlert(id: 'a1', stationId: 'station-1', isActive: true),
        _makeAlert(id: 'a2', stationId: 'station-2', isActive: true),
        _makeAlert(id: 'a3', stationId: 'station-1', isActive: true), // dup
        _makeAlert(id: 'a4', stationId: 'station-3', isActive: false), // off
      ];
      await fakeStorage
          .saveAlerts(alerts.map((a) => a.toJson()).toList());

      container.read(alertProvider);
      final stationIds =
          container.read(alertProvider.notifier).getAlertStationIds();

      expect(stationIds, hasLength(2));
      expect(stationIds, containsAll(['station-1', 'station-2']));
      expect(stationIds, isNot(contains('station-3')));
    });

    test('getAlertStationIds() returns empty list when no active alerts',
        () async {
      final alert = _makeAlert(isActive: false);
      await fakeStorage.saveAlerts([alert.toJson()]);

      container.read(alertProvider);
      final stationIds =
          container.read(alertProvider.notifier).getAlertStationIds();

      expect(stationIds, isEmpty);
    });

    test('multiple add/remove operations update state correctly', () async {
      container.read(alertProvider);

      // Add first alert
      final alert1 = _makeAlert(id: 'a1', stationId: 's1');
      await container.read(alertProvider.notifier).addAlert(alert1);
      expect(container.read(alertProvider), hasLength(1));

      // Add second alert
      final alert2 = _makeAlert(id: 'a2', stationId: 's2');
      await container.read(alertProvider.notifier).addAlert(alert2);
      expect(container.read(alertProvider), hasLength(2));

      // Remove first
      await container.read(alertProvider.notifier).removeAlert('a1');
      expect(container.read(alertProvider), hasLength(1));
      expect(container.read(alertProvider).first.id, 'a2');
    });
  });
}
