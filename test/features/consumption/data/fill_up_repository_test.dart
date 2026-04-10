import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/consumption/data/repositories/fill_up_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// In-memory fake [SettingsStorage] for repository tests.
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
  FuelType fuelType = FuelType.e10,
}) =>
    FillUp(
      id: id,
      date: date ?? DateTime(2026, 1, 1),
      liters: liters,
      totalCost: cost,
      odometerKm: odo,
      fuelType: fuelType,
    );

void main() {
  late _FakeSettingsStorage storage;
  late FillUpRepository repo;

  setUp(() {
    storage = _FakeSettingsStorage();
    repo = FillUpRepository(storage);
  });

  test('getAll returns empty when nothing stored', () {
    expect(repo.getAll(), isEmpty);
  });

  test('save adds a new entry', () async {
    await repo.save(_make(id: 'a'));
    final all = repo.getAll();
    expect(all.length, 1);
    expect(all.first.id, 'a');
  });

  test('save updates existing entry by id', () async {
    await repo.save(_make(id: 'a', liters: 40));
    await repo.save(_make(id: 'a', liters: 50));
    final all = repo.getAll();
    expect(all.length, 1);
    expect(all.first.liters, 50);
  });

  test('delete removes entry by id', () async {
    await repo.save(_make(id: 'a'));
    await repo.save(_make(id: 'b'));
    await repo.delete('a');
    final all = repo.getAll();
    expect(all.length, 1);
    expect(all.first.id, 'b');
  });

  test('delete with unknown id is a no-op', () async {
    await repo.save(_make(id: 'a'));
    await repo.delete('nonexistent');
    expect(repo.getAll().length, 1);
  });

  test('clear empties the log', () async {
    await repo.save(_make(id: 'a'));
    await repo.save(_make(id: 'b'));
    await repo.clear();
    expect(repo.getAll(), isEmpty);
  });

  test('getAll returns entries newest first', () async {
    await repo.save(
      _make(id: 'old', date: DateTime(2026, 1, 1)),
    );
    await repo.save(
      _make(id: 'newest', date: DateTime(2026, 3, 1)),
    );
    await repo.save(
      _make(id: 'mid', date: DateTime(2026, 2, 1)),
    );
    final all = repo.getAll();
    expect(all.map((f) => f.id).toList(), ['newest', 'mid', 'old']);
  });

  test('getAll survives JSON round-trip via storage', () async {
    final original = FillUp(
      id: 'x',
      date: DateTime(2026, 3, 15, 10, 30),
      liters: 42.5,
      totalCost: 67.89,
      odometerKm: 15432,
      fuelType: FuelType.diesel,
      stationId: 's1',
      stationName: 'Shell',
      notes: 'hi',
    );
    await repo.save(original);
    final restored = repo.getAll().first;
    expect(restored, original);
  });

  test('getAll tolerates malformed raw entries without crashing', () async {
    // Simulate a previous corrupted store
    await storage.putSetting(StorageKeys.consumptionLog, [
      'not-a-map',
      42,
      _make(id: 'ok').toJson(),
    ]);
    final all = repo.getAll();
    expect(all.length, 1);
    expect(all.first.id, 'ok');
  });

  test('getAll returns empty when stored value is not a list', () async {
    await storage.putSetting(StorageKeys.consumptionLog, 'garbage');
    expect(repo.getAll(), isEmpty);
  });
}
