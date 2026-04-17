import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/stores/profiles_hive_store.dart';

void main() {
  late ProfilesHiveStore store;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('profiles_store_test_');
    Hive.init(tempDir.path);
    await HiveStorage.initForTest();
    store = ProfilesHiveStore();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  final profileA = {
    'id': 'p-a',
    'name': 'Daily',
    'countryCode': 'FR',
    'fuelType': 'diesel',
    'radiusKm': 10,
  };
  final profileB = {
    'id': 'p-b',
    'name': 'Travel',
    'countryCode': 'DE',
    'fuelType': 'e10',
    'radiusKm': 25,
  };

  group('ProfilesHiveStore.activeProfileId', () {
    test('returns null when no active profile set', () {
      expect(store.getActiveProfileId(), isNull);
    });

    test('setActiveProfileId persists the selection', () async {
      await store.setActiveProfileId('p-a');
      expect(store.getActiveProfileId(), 'p-a');
    });

    test('setActiveProfileId overwrites a prior selection', () async {
      await store.setActiveProfileId('p-a');
      await store.setActiveProfileId('p-b');
      expect(store.getActiveProfileId(), 'p-b');
    });
  });

  group('ProfilesHiveStore profile CRUD', () {
    test('empty store: getProfile returns null, getAll returns []',
        () {
      expect(store.getProfile('p-a'), isNull);
      expect(store.getAllProfiles(), isEmpty);
      expect(store.profileCount, 0);
    });

    test('saveProfile + getProfile round-trip', () async {
      await store.saveProfile('p-a', profileA);
      final round = store.getProfile('p-a');
      expect(round, isNotNull);
      expect(round!['name'], 'Daily');
      expect(round['countryCode'], 'FR');
      expect(round['radiusKm'], 10);
    });

    test('getAllProfiles enumerates every saved profile', () async {
      await store.saveProfile('p-a', profileA);
      await store.saveProfile('p-b', profileB);
      final all = store.getAllProfiles();
      expect(all, hasLength(2));
      final names = all.map((p) => p['name']).toSet();
      expect(names, {'Daily', 'Travel'});
    });

    test('saveProfile with the same id overwrites the existing one',
        () async {
      await store.saveProfile('p-a', profileA);
      await store.saveProfile('p-a', {
        ...profileA,
        'name': 'Daily (updated)',
        'radiusKm': 15,
      });
      final round = store.getProfile('p-a')!;
      expect(round['name'], 'Daily (updated)');
      expect(round['radiusKm'], 15);
      expect(store.profileCount, 1);
    });

    test('deleteProfile removes only the target profile', () async {
      await store.saveProfile('p-a', profileA);
      await store.saveProfile('p-b', profileB);
      await store.deleteProfile('p-a');

      expect(store.getProfile('p-a'), isNull);
      expect(store.getProfile('p-b'), isNotNull);
      expect(store.profileCount, 1);
    });

    test('deleteProfile on an unknown id is a no-op', () async {
      await store.saveProfile('p-a', profileA);
      await store.deleteProfile('unknown');
      expect(store.getProfile('p-a'), isNotNull);
      expect(store.profileCount, 1);
    });

    test('profileCount tracks add + delete cycles', () async {
      expect(store.profileCount, 0);
      await store.saveProfile('p-a', profileA);
      expect(store.profileCount, 1);
      await store.saveProfile('p-b', profileB);
      expect(store.profileCount, 2);
      await store.deleteProfile('p-a');
      expect(store.profileCount, 1);
    });
  });
}
