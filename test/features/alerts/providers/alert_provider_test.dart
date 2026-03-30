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
}) {
  return PriceAlert(
    id: id,
    stationId: stationId,
    stationName: stationName,
    fuelType: fuelType,
    targetPrice: targetPrice,
    isActive: isActive,
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

      // Read initial state so the provider is alive
      expect(container.read(alertProvider), isEmpty);

      final alert = _makeAlert();
      // After save, getAlerts will return the new alert
      var callCount = 0;
      when(() => mockStorage.getAlerts()).thenAnswer((_) {
        callCount++;
        // First call was build(), subsequent calls return the alert
        return callCount > 1 ? [alert.toJson()] : [];
      });

      // Reset to simulate the state after the save
      when(() => mockStorage.getAlerts()).thenReturn([alert.toJson()]);
      await container.read(alertProvider.notifier).addAlert(alert);

      verify(() => mockStorage.saveAlerts(any())).called(1);
      final state = container.read(alertProvider);
      expect(state.length, 1);
      expect(state.first.id, 'alert-1');
    });

    test('removeAlert() removes from repository and updates state', () async {
      final alert = _makeAlert();
      when(() => mockStorage.getAlerts()).thenReturn([alert.toJson()]);

      // Initialize state
      expect(container.read(alertProvider).length, 1);

      // After delete, storage returns empty
      when(() => mockStorage.getAlerts()).thenReturn([]);
      await container
          .read(alertProvider.notifier)
          .removeAlert('alert-1');

      verify(() => mockStorage.saveAlerts(any())).called(1);
      final state = container.read(alertProvider);
      expect(state, isEmpty);
    });

    test('toggleAlert() toggles isActive flag', () async {
      final alert = _makeAlert(isActive: true);
      final toggled = _makeAlert(isActive: false);
      when(() => mockStorage.getAlerts()).thenReturn([alert.toJson()]);

      // Initialize state
      expect(container.read(alertProvider).first.isActive, true);

      // toggleAlert internally calls getAlerts() to find the alert (returns active),
      // then saveAlert (toggled), then getAlerts() again for the new state.
      // We track calls so the final getAlerts() returns the toggled version.
      var getAlertsCallCount = 0;
      when(() => mockStorage.getAlerts()).thenAnswer((_) {
        getAlertsCallCount++;
        // First call inside toggleAlert reads current alerts (active=true).
        // Second call (after save) should return the toggled version.
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
  });
}
