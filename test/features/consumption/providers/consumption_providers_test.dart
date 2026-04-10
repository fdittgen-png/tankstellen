import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    _data[key] = value;
  }

  @override
  bool get isSetupComplete => false;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}

FillUp _make({
  String id = '1',
  DateTime? date,
  double liters = 40,
  double cost = 60,
  double odo = 10000,
}) =>
    FillUp(
      id: id,
      date: date ?? DateTime(2026, 1, 1),
      liters: liters,
      totalCost: cost,
      odometerKm: odo,
      fuelType: FuelType.e10,
    );

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
      ],
    );
    addTearDown(container.dispose);
  });

  test('fillUpListProvider starts empty', () {
    final list = container.read(fillUpListProvider);
    expect(list, isEmpty);
  });

  test('add, update, remove, clear update state', () async {
    final notifier = container.read(fillUpListProvider.notifier);

    await notifier.add(_make(id: 'a', liters: 40));
    expect(container.read(fillUpListProvider).length, 1);

    await notifier.update(_make(id: 'a', liters: 50));
    expect(container.read(fillUpListProvider).first.liters, 50);

    await notifier.add(_make(id: 'b', date: DateTime(2026, 2, 1)));
    expect(container.read(fillUpListProvider).length, 2);
    // Sorted newest first
    expect(container.read(fillUpListProvider).first.id, 'b');

    await notifier.remove('a');
    expect(container.read(fillUpListProvider).length, 1);
    expect(container.read(fillUpListProvider).first.id, 'b');

    await notifier.clearAll();
    expect(container.read(fillUpListProvider), isEmpty);
  });

  test('consumptionStatsProvider reflects list changes', () async {
    final notifier = container.read(fillUpListProvider.notifier);

    expect(container.read(consumptionStatsProvider).fillUpCount, 0);

    await notifier.add(_make(
      id: '1',
      date: DateTime(2026, 1, 1),
      liters: 40,
      cost: 60,
      odo: 10000,
    ));
    await notifier.add(_make(
      id: '2',
      date: DateTime(2026, 1, 15),
      liters: 50,
      cost: 80,
      odo: 11000,
    ));

    final stats = container.read(consumptionStatsProvider);
    expect(stats.fillUpCount, 2);
    expect(stats.totalLiters, 90);
    expect(stats.avgConsumptionL100km, closeTo(5.0, 0.0001));
  });
}
