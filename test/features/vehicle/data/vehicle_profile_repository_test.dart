import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

void main() {
  group('VehicleProfileRepository', () {
    late _FakeSettings storage;
    late VehicleProfileRepository repo;

    setUp(() {
      storage = _FakeSettings();
      repo = VehicleProfileRepository(storage);
    });

    const sample = VehicleProfile(
      id: 'v1',
      name: 'Model 3',
      type: VehicleType.ev,
      batteryKwh: 60.0,
      supportedConnectors: {ConnectorType.ccs},
    );

    test('getAll returns empty when no data stored', () {
      expect(repo.getAll(), isEmpty);
    });

    test('save then getAll returns the profile', () async {
      await repo.save(sample);
      final all = repo.getAll();
      expect(all, hasLength(1));
      expect(all.first.name, 'Model 3');
      expect(all.first.supportedConnectors, {ConnectorType.ccs});
    });

    test('save activates first vehicle automatically', () async {
      expect(repo.getActive(), isNull);
      await repo.save(sample);
      expect(repo.getActive()?.id, 'v1');
    });

    test('save does not change active when adding a second vehicle',
        () async {
      await repo.save(sample);
      await repo.save(
        const VehicleProfile(
          id: 'v2',
          name: 'Zoe',
          type: VehicleType.ev,
        ),
      );
      expect(repo.getActive()?.id, 'v1');
    });

    test('save updates existing entry matched by id', () async {
      await repo.save(sample);
      await repo.save(sample.copyWith(name: 'Model 3 Long Range'));
      final all = repo.getAll();
      expect(all, hasLength(1));
      expect(all.first.name, 'Model 3 Long Range');
    });

    test('delete removes entry and switches active to remaining', () async {
      await repo.save(sample);
      await repo.save(
        const VehicleProfile(
          id: 'v2',
          name: 'Zoe',
          type: VehicleType.ev,
        ),
      );
      await repo.delete('v1');

      final all = repo.getAll();
      expect(all, hasLength(1));
      expect(all.first.id, 'v2');
      expect(repo.getActive()?.id, 'v2');
    });

    test('delete last vehicle clears active', () async {
      await repo.save(sample);
      await repo.delete('v1');
      expect(repo.getAll(), isEmpty);
      expect(repo.getActive(), isNull);
    });

    test('setActive changes the active profile', () async {
      await repo.save(sample);
      await repo.save(
        const VehicleProfile(id: 'v2', name: 'Zoe', type: VehicleType.ev),
      );
      await repo.setActive('v2');
      expect(repo.getActive()?.id, 'v2');
    });

    test('clear removes everything', () async {
      await repo.save(sample);
      await repo.clear();
      expect(repo.getAll(), isEmpty);
      expect(repo.getActive(), isNull);
    });

    test('getById returns null when id does not exist', () async {
      await repo.save(sample);
      expect(repo.getById('missing'), isNull);
      expect(repo.getById('v1')?.name, 'Model 3');
    });

    test('malformed JSON entries are skipped without crashing', () async {
      storage._data[_listKey] = [
        sample.toJson(),
        'not a map',
        {'id': 'bad'}, // missing name — VehicleProfile.fromJson will throw
      ];
      final all = repo.getAll();
      expect(all, hasLength(1));
      expect(all.first.id, 'v1');
    });
  });
}

const _listKey = 'vehicle_profiles';

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
