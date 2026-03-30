import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/alerts/data/repositories/alert_repository.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';

void main() {
  late AlertRepository repo;

  setUpAll(() async {
    // Use a temporary directory for Hive in tests
    final dir = '${Directory.systemTemp.path}/hive_test_${DateTime.now().millisecondsSinceEpoch}';
    Hive.init(dir);
    await Hive.openBox('alerts');
  });

  setUp(() async {
    // Clear alerts box before each test
    final box = Hive.box('alerts');
    await box.clear();
    repo = AlertRepository(HiveStorage());
  });

  tearDownAll(() async {
    await Hive.close();
  });

  PriceAlert makeAlert({
    String id = 'test_alert_1',
    String stationId = 'station_1',
    String stationName = 'Test Station',
    FuelType fuelType = FuelType.diesel,
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
      createdAt: DateTime(2026, 1, 1),
    );
  }

  Station makeStation({
    String id = 'station_1',
    double? diesel,
    double? e5,
    double? e10,
  }) {
    return Station(
      id: id,
      name: 'Test Station',
      brand: 'Test Brand',
      street: 'Test Street',
      postCode: '12345',
      place: 'Test City',
      lat: 48.0,
      lng: 2.0,
      isOpen: true,
      diesel: diesel,
      e5: e5,
      e10: e10,
    );
  }

  test('getAlerts returns empty list initially', () {
    expect(repo.getAlerts(), isEmpty);
  });

  test('saveAlert adds an alert and getAlerts retrieves it', () async {
    final alert = makeAlert();
    await repo.saveAlert(alert);

    final alerts = repo.getAlerts();
    expect(alerts, hasLength(1));
    expect(alerts.first.id, 'test_alert_1');
    expect(alerts.first.stationId, 'station_1');
    expect(alerts.first.targetPrice, 1.50);
  });

  test('deleteAlert removes the alert', () async {
    await repo.saveAlert(makeAlert(id: 'a1'));
    await repo.saveAlert(makeAlert(id: 'a2'));
    expect(repo.getAlerts(), hasLength(2));

    await repo.deleteAlert('a1');
    final remaining = repo.getAlerts();
    expect(remaining, hasLength(1));
    expect(remaining.first.id, 'a2');
  });

  test('saveAlert updates existing alert with same id', () async {
    await repo.saveAlert(makeAlert(id: 'a1', targetPrice: 1.50));
    await repo.saveAlert(makeAlert(id: 'a1', targetPrice: 1.30));

    final alerts = repo.getAlerts();
    expect(alerts, hasLength(1));
    expect(alerts.first.targetPrice, 1.30);
  });

  test('deleteAlert with non-existent id does nothing', () async {
    await repo.saveAlert(makeAlert(id: 'a1'));
    await repo.deleteAlert('non_existent');

    final alerts = repo.getAlerts();
    expect(alerts, hasLength(1));
    expect(alerts.first.id, 'a1');
  });

  test('saveAlert preserves other alerts when updating', () async {
    await repo.saveAlert(makeAlert(id: 'a1', targetPrice: 1.50));
    await repo.saveAlert(makeAlert(id: 'a2', targetPrice: 1.60));
    await repo.saveAlert(makeAlert(id: 'a1', targetPrice: 1.30));

    final alerts = repo.getAlerts();
    expect(alerts, hasLength(2));
    final a1 = alerts.firstWhere((a) => a.id == 'a1');
    final a2 = alerts.firstWhere((a) => a.id == 'a2');
    expect(a1.targetPrice, 1.30);
    expect(a2.targetPrice, 1.60);
  });

  test('saveAlert and getAlerts preserve fuel type', () async {
    await repo.saveAlert(makeAlert(id: 'a1', fuelType: FuelType.e10));
    await repo.saveAlert(makeAlert(id: 'a2', fuelType: FuelType.lpg));

    final alerts = repo.getAlerts();
    expect(alerts[0].fuelType, FuelType.e10);
    expect(alerts[1].fuelType, FuelType.lpg);
  });

  test('evaluateAlerts returns empty list when no stations match alert stationIds', () async {
    await repo.saveAlert(makeAlert(
      id: 'a1',
      stationId: 'unknown_station',
      fuelType: FuelType.diesel,
      targetPrice: 2.00,
    ));

    final stations = [makeStation(id: 'station_1', diesel: 1.50)];
    final triggered = repo.evaluateAlerts(stations);
    expect(triggered, isEmpty);
  });

  test('evaluateAlerts returns empty list when no fuel price available', () async {
    await repo.saveAlert(makeAlert(
      id: 'a1',
      stationId: 'station_1',
      fuelType: FuelType.lpg, // No LPG price in the makeStation
      targetPrice: 2.00,
    ));

    final stations = [makeStation(id: 'station_1', diesel: 1.50)];
    final triggered = repo.evaluateAlerts(stations);
    expect(triggered, isEmpty);
  });

  test('evaluateAlerts triggers when price equals target exactly', () async {
    await repo.saveAlert(makeAlert(
      id: 'a1',
      stationId: 'station_1',
      fuelType: FuelType.diesel,
      targetPrice: 1.50,
    ));

    final stations = [makeStation(id: 'station_1', diesel: 1.50)];
    final triggered = repo.evaluateAlerts(stations);
    expect(triggered, hasLength(1));
  });

  test('evaluateAlerts does not trigger when price is above target', () async {
    await repo.saveAlert(makeAlert(
      id: 'a1',
      stationId: 'station_1',
      fuelType: FuelType.diesel,
      targetPrice: 1.40,
    ));

    final stations = [makeStation(id: 'station_1', diesel: 1.50)];
    final triggered = repo.evaluateAlerts(stations);
    expect(triggered, isEmpty);
  });

  test('evaluateAlerts triggers multiple alerts for different stations', () async {
    await repo.saveAlert(makeAlert(
      id: 'a1',
      stationId: 'station_1',
      fuelType: FuelType.diesel,
      targetPrice: 1.60,
    ));
    await repo.saveAlert(makeAlert(
      id: 'a2',
      stationId: 'station_2',
      fuelType: FuelType.e5,
      targetPrice: 1.80,
    ));

    final stations = [
      makeStation(id: 'station_1', diesel: 1.55),
      makeStation(id: 'station_2', e5: 1.70),
    ];

    final triggered = repo.evaluateAlerts(stations);
    expect(triggered, hasLength(2));
  });

  test('evaluateAlerts sets lastTriggeredAt on triggered alerts', () async {
    await repo.saveAlert(makeAlert(
      id: 'a1',
      stationId: 'station_1',
      fuelType: FuelType.diesel,
      targetPrice: 2.00,
    ));

    final stations = [makeStation(id: 'station_1', diesel: 1.50)];
    final triggered = repo.evaluateAlerts(stations);

    expect(triggered.first.lastTriggeredAt, isNotNull);
    // Should be roughly now
    final diff = DateTime.now().difference(triggered.first.lastTriggeredAt!);
    expect(diff.inSeconds, lessThan(5));
  });

  test('evaluateAlerts with e10 fuel type', () async {
    await repo.saveAlert(makeAlert(
      id: 'a1',
      stationId: 'station_1',
      fuelType: FuelType.e10,
      targetPrice: 1.60,
    ));

    final stations = [makeStation(id: 'station_1', e10: 1.50)];
    final triggered = repo.evaluateAlerts(stations);
    expect(triggered, hasLength(1));
  });

  test('evaluateAlerts returns triggered alerts when price meets target', () async {
    await repo.saveAlert(makeAlert(
      id: 'a1',
      stationId: 'station_1',
      fuelType: FuelType.diesel,
      targetPrice: 1.60,
    ));
    await repo.saveAlert(makeAlert(
      id: 'a2',
      stationId: 'station_1',
      fuelType: FuelType.diesel,
      targetPrice: 1.40,
      isActive: false, // inactive — should not trigger
    ));
    await repo.saveAlert(makeAlert(
      id: 'a3',
      stationId: 'station_2',
      fuelType: FuelType.e5,
      targetPrice: 1.70,
    ));

    final stations = [
      makeStation(id: 'station_1', diesel: 1.55),
      makeStation(id: 'station_2', e5: 1.80), // price above target
    ];

    final triggered = repo.evaluateAlerts(stations);
    expect(triggered, hasLength(1));
    expect(triggered.first.id, 'a1');
    expect(triggered.first.lastTriggeredAt, isNotNull);
  });
}
