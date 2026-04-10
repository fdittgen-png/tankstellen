import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

void main() {
  group('VehicleProfileList provider', () {
    late ProviderContainer container;

    setUp(() {
      final repo = VehicleProfileRepository(_FakeSettings());
      container = ProviderContainer(
        overrides: [
          vehicleProfileRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
    });

    test('starts empty when no stored vehicles', () {
      expect(container.read(vehicleProfileListProvider), isEmpty);
      expect(container.read(activeVehicleProfileProvider), isNull);
    });

    test('save adds vehicle and auto-activates', () async {
      const v = VehicleProfile(
        id: 'v1',
        name: 'Model 3',
        type: VehicleType.ev,
        batteryKwh: 60,
      );
      await container.read(vehicleProfileListProvider.notifier).save(v);

      expect(container.read(vehicleProfileListProvider), hasLength(1));
      expect(container.read(activeVehicleProfileProvider)?.id, 'v1');
    });

    test('remove deletes and updates state', () async {
      const v = VehicleProfile(id: 'v1', name: 'Car');
      await container.read(vehicleProfileListProvider.notifier).save(v);
      await container.read(vehicleProfileListProvider.notifier).remove('v1');

      expect(container.read(vehicleProfileListProvider), isEmpty);
      expect(container.read(activeVehicleProfileProvider), isNull);
    });

    test('setActive switches the active vehicle', () async {
      await container.read(vehicleProfileListProvider.notifier).save(
            const VehicleProfile(id: 'v1', name: 'A'),
          );
      await container.read(vehicleProfileListProvider.notifier).save(
            const VehicleProfile(id: 'v2', name: 'B'),
          );
      await container
          .read(activeVehicleProfileProvider.notifier)
          .setActive('v2');

      expect(container.read(activeVehicleProfileProvider)?.id, 'v2');
    });

    test('clearAll removes everything', () async {
      await container.read(vehicleProfileListProvider.notifier).save(
            const VehicleProfile(id: 'v1', name: 'A'),
          );
      await container.read(vehicleProfileListProvider.notifier).clearAll();
      expect(container.read(vehicleProfileListProvider), isEmpty);
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
