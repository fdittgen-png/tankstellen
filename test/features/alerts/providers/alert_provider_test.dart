import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/alerts/data/repositories/alert_repository.dart';
import 'package:tankstellen/features/alerts/providers/alert_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

class MockHiveStorage extends Mock implements HiveStorage {}

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
  late MockHiveStorage mockStorage;

  setUp(() {
    mockStorage = MockHiveStorage();
    // Default stubs
    when(() => mockStorage.getAlerts()).thenReturn([]);
    when(() => mockStorage.saveAlerts(any())).thenAnswer((_) async {});
    when(() => mockStorage.getSetting(any())).thenReturn(null);
  });

  group('AlertRepository', () {
    late AlertRepository repo;

    setUp(() {
      repo = AlertRepository(mockStorage);
    });

    test('getAlerts returns empty list when storage is empty', () {
      when(() => mockStorage.getAlerts()).thenReturn([]);
      final alerts = repo.getAlerts();
      expect(alerts, isEmpty);
    });

    test('getAlerts returns parsed alerts from storage', () {
      final alert = _makeAlert();
      when(() => mockStorage.getAlerts()).thenReturn([alert.toJson()]);

      final alerts = repo.getAlerts();
      expect(alerts.length, 1);
      expect(alerts.first.id, 'alert-1');
      expect(alerts.first.stationId, 'station-1');
      expect(alerts.first.fuelType, FuelType.e10);
      expect(alerts.first.targetPrice, 1.50);
    });

    test('getAlerts preserves lastTriggeredAt through JSON round-trip', () {
      final triggeredTime = DateTime(2026, 3, 15, 14, 30);
      final alert = _makeAlert(lastTriggeredAt: triggeredTime);
      when(() => mockStorage.getAlerts()).thenReturn([alert.toJson()]);

      final alerts = repo.getAlerts();
      expect(alerts.first.lastTriggeredAt, isNotNull);
      expect(alerts.first.lastTriggeredAt, triggeredTime);
    });

    test('getAlerts handles alert with null lastTriggeredAt', () {
      final alert = _makeAlert(lastTriggeredAt: null);
      when(() => mockStorage.getAlerts()).thenReturn([alert.toJson()]);

      final alerts = repo.getAlerts();
      expect(alerts.first.lastTriggeredAt, isNull);
    });

    test('saveAlert adds a new alert to storage', () async {
      when(() => mockStorage.getAlerts()).thenReturn([]);
      final alert = _makeAlert();

      await repo.saveAlert(alert);

      final captured =
          verify(() => mockStorage.saveAlerts(captureAny())).captured;
      expect(captured.length, 1);
      final savedList = captured.first as List<Map<String, dynamic>>;
      expect(savedList.length, 1);
      expect(savedList.first['id'], 'alert-1');
    });

    test('saveAlert updates existing alert with same id', () async {
      final existing = _makeAlert(targetPrice: 1.50);
      when(() => mockStorage.getAlerts()).thenReturn([existing.toJson()]);

      final updated = _makeAlert(targetPrice: 1.30);
      await repo.saveAlert(updated);

      final captured =
          verify(() => mockStorage.saveAlerts(captureAny())).captured;
      final savedList = captured.first as List<Map<String, dynamic>>;
      expect(savedList.length, 1);
      expect(savedList.first['targetPrice'], 1.30);
    });

    test('saveAlert preserves isActive flag correctly', () async {
      when(() => mockStorage.getAlerts()).thenReturn([]);
      final alert = _makeAlert(isActive: false);

      await repo.saveAlert(alert);

      final captured =
          verify(() => mockStorage.saveAlerts(captureAny())).captured;
      final savedList = captured.first as List<Map<String, dynamic>>;
      expect(savedList.first['isActive'], false);
    });

    test('deleteAlert removes alert by id', () async {
      final alert = _makeAlert();
      when(() => mockStorage.getAlerts()).thenReturn([alert.toJson()]);

      await repo.deleteAlert('alert-1');

      final captured =
          verify(() => mockStorage.saveAlerts(captureAny())).captured;
      final savedList = captured.first as List<Map<String, dynamic>>;
      expect(savedList, isEmpty);
    });

    test('deleteAlert does nothing when id not found', () async {
      final alert = _makeAlert();
      when(() => mockStorage.getAlerts()).thenReturn([alert.toJson()]);

      await repo.deleteAlert('nonexistent');

      final captured =
          verify(() => mockStorage.saveAlerts(captureAny())).captured;
      final savedList = captured.first as List<Map<String, dynamic>>;
      expect(savedList.length, 1);
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
          hiveStorageProvider.overrideWithValue(mockStorage),
        ],
      );
      addTearDown(container.dispose);
    });

    test('build() returns alerts from AlertRepository', () {
      final alert = _makeAlert();
      when(() => mockStorage.getAlerts()).thenReturn([alert.toJson()]);

      final alerts = container.read(alertProvider);
      expect(alerts.length, 1);
      expect(alerts.first.id, 'alert-1');
    });

    test('build() returns empty list when no alerts stored', () {
      when(() => mockStorage.getAlerts()).thenReturn([]);

      final alerts = container.read(alertProvider);
      expect(alerts, isEmpty);
    });

    test('addAlert() saves to repository and updates state', () async {
      when(() => mockStorage.getAlerts()).thenReturn([]);

      expect(container.read(alertProvider), isEmpty);

      final alert = _makeAlert();
      when(() => mockStorage.getAlerts()).thenReturn([alert.toJson()]);
      await container.read(alertProvider.notifier).addAlert(alert);

      verify(() => mockStorage.saveAlerts(any())).called(1);
      final state = container.read(alertProvider);
      expect(state.length, 1);
      expect(state.first.id, 'alert-1');
    });

    test('addAlert() saves correct data to storage', () async {
      when(() => mockStorage.getAlerts()).thenReturn([]);
      container.read(alertProvider);

      final alert = _makeAlert(
        id: 'my-alert',
        stationId: 'my-station',
        stationName: 'My Station',
        fuelType: FuelType.diesel,
        targetPrice: 1.35,
      );

      when(() => mockStorage.getAlerts()).thenReturn([alert.toJson()]);
      await container.read(alertProvider.notifier).addAlert(alert);

      final captured =
          verify(() => mockStorage.saveAlerts(captureAny())).captured;
      final savedList = captured.first as List<Map<String, dynamic>>;
      expect(savedList.first['id'], 'my-alert');
      expect(savedList.first['stationId'], 'my-station');
      expect(savedList.first['stationName'], 'My Station');
      expect(savedList.first['fuelType'], 'diesel');
      expect(savedList.first['targetPrice'], 1.35);
    });

    test('removeAlert() removes from repository and updates state', () async {
      final alert = _makeAlert();
      when(() => mockStorage.getAlerts()).thenReturn([alert.toJson()]);

      expect(container.read(alertProvider).length, 1);

      when(() => mockStorage.getAlerts()).thenReturn([]);
      await container
          .read(alertProvider.notifier)
          .removeAlert('alert-1');

      verify(() => mockStorage.saveAlerts(any())).called(1);
      final state = container.read(alertProvider);
      expect(state, isEmpty);
    });

    test('removeAlert() with non-existent id does not crash', () async {
      final alert = _makeAlert();
      when(() => mockStorage.getAlerts()).thenReturn([alert.toJson()]);

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
      final toggled = _makeAlert(isActive: false);
      when(() => mockStorage.getAlerts()).thenReturn([alert.toJson()]);

      expect(container.read(alertProvider).first.isActive, true);

      var getAlertsCallCount = 0;
      when(() => mockStorage.getAlerts()).thenAnswer((_) {
        getAlertsCallCount++;
        if (getAlertsCallCount <= 1) return [alert.toJson()];
        return [toggled.toJson()];
      });

      await container
          .read(alertProvider.notifier)
          .toggleAlert('alert-1');

      verify(() => mockStorage.saveAlerts(any())).called(1);
      final state = container.read(alertProvider);
      expect(state.first.isActive, false);
    });

    test('toggleAlert() with non-existent id does nothing', () async {
      final alert = _makeAlert(isActive: true);
      when(() => mockStorage.getAlerts()).thenReturn([alert.toJson()]);

      container.read(alertProvider);
      await container
          .read(alertProvider.notifier)
          .toggleAlert('non-existent');

      // saveAlerts should NOT have been called (alert not found)
      verifyNever(() => mockStorage.saveAlerts(any()));
    });

    test('toggleAlert() saves correct toggled data', () async {
      final alert = _makeAlert(isActive: true);
      when(() => mockStorage.getAlerts()).thenReturn([alert.toJson()]);

      container.read(alertProvider);

      // After toggle, mock returns toggled version
      final toggled = _makeAlert(isActive: false);
      var callCount = 0;
      when(() => mockStorage.getAlerts()).thenAnswer((_) {
        callCount++;
        return callCount <= 1 ? [alert.toJson()] : [toggled.toJson()];
      });

      await container.read(alertProvider.notifier).toggleAlert('alert-1');

      final captured =
          verify(() => mockStorage.saveAlerts(captureAny())).captured;
      final savedList = captured.first as List<Map<String, dynamic>>;
      expect(savedList.first['isActive'], false);
    });

    test('getAlertStationIds() returns unique active station IDs', () {
      final alerts = [
        _makeAlert(id: 'a1', stationId: 'station-1', isActive: true),
        _makeAlert(id: 'a2', stationId: 'station-2', isActive: true),
        _makeAlert(id: 'a3', stationId: 'station-1', isActive: true), // duplicate
        _makeAlert(id: 'a4', stationId: 'station-3', isActive: false), // inactive
      ];
      when(() => mockStorage.getAlerts())
          .thenReturn(alerts.map((a) => a.toJson()).toList());

      container.read(alertProvider);
      final stationIds =
          container.read(alertProvider.notifier).getAlertStationIds();

      expect(stationIds, hasLength(2));
      expect(stationIds, containsAll(['station-1', 'station-2']));
      expect(stationIds, isNot(contains('station-3')));
    });

    test('getAlertStationIds() returns empty list when no active alerts', () {
      final alert = _makeAlert(isActive: false);
      when(() => mockStorage.getAlerts()).thenReturn([alert.toJson()]);

      container.read(alertProvider);
      final stationIds =
          container.read(alertProvider.notifier).getAlertStationIds();

      expect(stationIds, isEmpty);
    });

    test('multiple add/remove operations update state correctly', () async {
      when(() => mockStorage.getAlerts()).thenReturn([]);
      container.read(alertProvider);

      // Add first alert
      final alert1 = _makeAlert(id: 'a1', stationId: 's1');
      when(() => mockStorage.getAlerts()).thenReturn([alert1.toJson()]);
      await container.read(alertProvider.notifier).addAlert(alert1);
      expect(container.read(alertProvider), hasLength(1));

      // Add second alert
      final alert2 = _makeAlert(id: 'a2', stationId: 's2');
      when(() => mockStorage.getAlerts())
          .thenReturn([alert1.toJson(), alert2.toJson()]);
      await container.read(alertProvider.notifier).addAlert(alert2);
      expect(container.read(alertProvider), hasLength(2));

      // Remove first
      when(() => mockStorage.getAlerts()).thenReturn([alert2.toJson()]);
      await container.read(alertProvider.notifier).removeAlert('a1');
      expect(container.read(alertProvider), hasLength(1));
      expect(container.read(alertProvider).first.id, 'a2');
    });
  });
}
