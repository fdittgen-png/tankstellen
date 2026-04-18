import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';

import '../../mocks/mocks.dart';

void main() {
  late MockHiveStorage mockStorage;
  final persisted = <String, dynamic>{};

  setUp(() {
    persisted.clear();
    mockStorage = MockHiveStorage();
    when(() => mockStorage.getSetting(any()))
        .thenAnswer((inv) => persisted[inv.positionalArguments.first]);
    when(() => mockStorage.putSetting(any(), any()))
        .thenAnswer((inv) async {
      final key = inv.positionalArguments.first as String;
      persisted[key] = inv.positionalArguments.last;
    });
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(mockStorage),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('UserPosition.build — hydration', () {
    test('returns null when nothing is persisted', () {
      expect(makeContainer().read(userPositionProvider), isNull);
    });

    test('reconstructs UserPositionData from persisted settings', () {
      persisted[StorageKeys.userPositionLat] = 48.85;
      persisted[StorageKeys.userPositionLng] = 2.35;
      persisted[StorageKeys.userPositionTimestamp] =
          DateTime(2026, 4, 10, 9, 30).millisecondsSinceEpoch;
      persisted[StorageKeys.userPositionSource] = 'GPS';

      final pos = makeContainer().read(userPositionProvider);
      expect(pos, isNotNull);
      expect(pos!.lat, 48.85);
      expect(pos.lng, 2.35);
      expect(pos.source, 'GPS');
      expect(pos.updatedAt, DateTime(2026, 4, 10, 9, 30));
    });

    test('missing source defaults to "GPS"', () {
      persisted[StorageKeys.userPositionLat] = 1.0;
      persisted[StorageKeys.userPositionLng] = 2.0;
      persisted[StorageKeys.userPositionTimestamp] = 0;
      final pos = makeContainer().read(userPositionProvider)!;
      expect(pos.source, 'GPS');
    });

    test('partial persistence (missing lat) yields null', () {
      persisted[StorageKeys.userPositionLng] = 2.35;
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
      expect(persisted[StorageKeys.userPositionLat], 43.6);
      expect(persisted[StorageKeys.userPositionSource], 'GPS');
    });

    test('setWithSource uses the supplied label', () {
      final container = makeContainer();
      final notifier = container.read(userPositionProvider.notifier);

      notifier.setWithSource(50.1, 8.7, 'Frankfurt Hbf');

      final pos = container.read(userPositionProvider)!;
      expect(pos.source, 'Frankfurt Hbf');
      expect(persisted[StorageKeys.userPositionSource], 'Frankfurt Hbf');
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
      expect(persisted[StorageKeys.userPositionLat], isNull);
      expect(persisted[StorageKeys.userPositionLng], isNull);
      expect(persisted[StorageKeys.userPositionTimestamp], isNull);
      expect(persisted[StorageKeys.userPositionSource], isNull);
    });
  });
}
