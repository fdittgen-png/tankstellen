import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/ev/data/repositories/ev_station_repository.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;

void main() {
  group('EvStationRepository', () {
    late _FakeSettings storage;
    late EvStationRepository repo;

    setUp(() {
      storage = _FakeSettings();
      repo = EvStationRepository(storage);
    });

    ChargingStation makeStation(String id, {double lat = 48.0}) =>
        ChargingStation(
          id: id,
          name: 'Station $id',
          latitude: lat,
          longitude: 2.0,
          connectors: const [
            EvConnector(
              id: 'c1',
              type: ConnectorType.ccs,
              maxPowerKw: 50,
              status: ConnectorStatus.available,
            ),
          ],
        );

    test('getAll returns empty when nothing is stored', () {
      expect(repo.getAll(), isEmpty);
    });

    test('save and retrieve station', () async {
      await repo.save(makeStation('a'));
      final all = repo.getAll();
      expect(all, hasLength(1));
      expect(all.first.id, 'a');
      expect(all.first.connectors.single.type, ConnectorType.ccs);
    });

    test('save updates existing entry by id', () async {
      await repo.save(makeStation('a', lat: 48.0));
      await repo.save(makeStation('a', lat: 49.0));
      final all = repo.getAll();
      expect(all, hasLength(1));
      expect(all.first.latitude, 49.0);
    });

    test('saveAll replaces the whole list', () async {
      await repo.save(makeStation('a'));
      await repo.saveAll([makeStation('x'), makeStation('y')]);
      expect(repo.getAll().map((s) => s.id), ['x', 'y']);
    });

    test('delete removes matching entry', () async {
      await repo.save(makeStation('a'));
      await repo.save(makeStation('b'));
      await repo.delete('a');
      expect(repo.getAll().single.id, 'b');
    });

    test('getById returns null for missing id', () async {
      await repo.save(makeStation('a'));
      expect(repo.getById('missing'), isNull);
      expect(repo.getById('a')?.id, 'a');
    });

    test('clear empties the cache', () async {
      await repo.save(makeStation('a'));
      await repo.clear();
      expect(repo.getAll(), isEmpty);
    });

    test('malformed entries are skipped gracefully', () async {
      storage._data['ev_stations_cache'] = [
        makeStation('ok').toJson(),
        'not a map',
        {'id': 'broken'}, // missing required fields
      ];
      final all = repo.getAll();
      expect(all, hasLength(1));
      expect(all.first.id, 'ok');
    });
  });
}

class _FakeSettings implements SettingsStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
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
