import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';

import '../../fakes/fake_hive_storage.dart';

void main() {
  late FakeHiveStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeHiveStorage();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('UserPosition.build — hydration', () {
    test('returns null when nothing is persisted', () {
      expect(makeContainer().read(userPositionProvider), isNull);
    });

    test('reconstructs UserPositionData from persisted settings', () async {
      await fakeStorage.putSetting(StorageKeys.userPositionLat, 48.85);
      await fakeStorage.putSetting(StorageKeys.userPositionLng, 2.35);
      await fakeStorage.putSetting(StorageKeys.userPositionTimestamp,
          DateTime(2026, 4, 10, 9, 30).millisecondsSinceEpoch);
      await fakeStorage.putSetting(StorageKeys.userPositionSource, 'GPS');

      final pos = makeContainer().read(userPositionProvider);
      expect(pos, isNotNull);
      expect(pos!.lat, 48.85);
      expect(pos.lng, 2.35);
      expect(pos.source, 'GPS');
      expect(pos.updatedAt, DateTime(2026, 4, 10, 9, 30));
    });

    test('missing source defaults to "GPS"', () async {
      await fakeStorage.putSetting(StorageKeys.userPositionLat, 1.0);
      await fakeStorage.putSetting(StorageKeys.userPositionLng, 2.0);
      await fakeStorage.putSetting(StorageKeys.userPositionTimestamp, 0);
      final pos = makeContainer().read(userPositionProvider)!;
      expect(pos.source, 'GPS');
    });

    test('partial persistence (missing lat) yields null', () async {
      await fakeStorage.putSetting(StorageKeys.userPositionLng, 2.35);
      expect(makeContainer().read(userPositionProvider), isNull);
    });
  });

  group('UserPosition — mutations', () {
    test('setFromGps persists coords + source + timestamp', () {
      final container = makeContainer();
      final notifier = container.read(userPositionProvider.notifier);

      notifier.setFromGps(43.6, 1.4);

      final pos = container.read(userPositionProvider)!;
      expect(pos.lat, 43.6);
      expect(pos.lng, 1.4);
      expect(pos.source, 'GPS');
      expect(pos.updatedAt.isAfter(DateTime(2024)), isTrue);
      expect(fakeStorage.getSetting(StorageKeys.userPositionLat), 43.6);
      expect(fakeStorage.getSetting(StorageKeys.userPositionSource), 'GPS');
    });

    test('setWithSource uses the supplied label', () {
      final container = makeContainer();
      final notifier = container.read(userPositionProvider.notifier);

      notifier.setWithSource(50.1, 8.7, 'Frankfurt Hbf');

      final pos = container.read(userPositionProvider)!;
      expect(pos.source, 'Frankfurt Hbf');
      expect(fakeStorage.getSetting(StorageKeys.userPositionSource),
          'Frankfurt Hbf');
    });

    test('subsequent setFromGps overwrites the earlier position', () {
      final container = makeContainer();
      final notifier = container.read(userPositionProvider.notifier);
      notifier.setFromGps(1.0, 2.0);
      notifier.setFromGps(3.0, 4.0);
      final pos = container.read(userPositionProvider)!;
      expect(pos.lat, 3.0);
      expect(pos.lng, 4.0);
    });

    test('clear() wipes state and every persisted key', () {
      final container = makeContainer();
      final notifier = container.read(userPositionProvider.notifier);
      notifier.setFromGps(1.0, 2.0);
      expect(container.read(userPositionProvider), isNotNull);

      notifier.clear();

      expect(container.read(userPositionProvider), isNull);
      expect(fakeStorage.getSetting(StorageKeys.userPositionLat), isNull);
      expect(fakeStorage.getSetting(StorageKeys.userPositionLng), isNull);
      expect(
          fakeStorage.getSetting(StorageKeys.userPositionTimestamp), isNull);
      expect(fakeStorage.getSetting(StorageKeys.userPositionSource), isNull);
    });
  });
}
