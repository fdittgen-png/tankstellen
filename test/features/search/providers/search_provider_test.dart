import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

import '../../../mocks/mocks.dart';

void main() {
  late MockHiveStorage mockStorage;

  setUp(() {
    mockStorage = MockHiveStorage();
    // Stub storage methods used by profile repository during build
    when(() => mockStorage.getSetting(any())).thenReturn(null);
  });

  ProviderContainer createContainer() {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(mockStorage),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('SelectedFuelType', () {
    test('defaults to FuelType.all when no profile', () {
      final container = createContainer();
      final fuelType = container.read(selectedFuelTypeProvider);

      expect(fuelType, FuelType.all);
    });

    test('select() updates the fuel type', () {
      final container = createContainer();
      container.read(selectedFuelTypeProvider.notifier).select(FuelType.e10);

      expect(container.read(selectedFuelTypeProvider), FuelType.e10);
    });
  });

  group('SearchRadius', () {
    test('defaults to 10.0 when no profile', () {
      final container = createContainer();
      final radius = container.read(searchRadiusProvider);

      expect(radius, 10.0);
    });

    test('set() updates the radius', () {
      final container = createContainer();
      container.read(searchRadiusProvider.notifier).set(5.0);

      expect(container.read(searchRadiusProvider), 5.0);
    });

    test('set() clamps radius to min 1.0', () {
      final container = createContainer();
      container.read(searchRadiusProvider.notifier).set(0.5);

      expect(container.read(searchRadiusProvider), 1.0);
    });

    test('set() clamps radius to max 25.0', () {
      final container = createContainer();
      container.read(searchRadiusProvider.notifier).set(50.0);

      expect(container.read(searchRadiusProvider), 25.0);
    });
  });

  group('SearchLocation', () {
    test('defaults to empty string', () {
      final container = createContainer();
      final location = container.read(searchLocationProvider);

      expect(location, '');
    });

    test('set() updates the location string', () {
      final container = createContainer();
      container.read(searchLocationProvider.notifier).set('10115 Berlin');

      expect(container.read(searchLocationProvider), '10115 Berlin');
    });
  });
}
