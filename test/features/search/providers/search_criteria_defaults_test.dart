// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/search/domain/entities/station_amenity.dart';
import 'package:tankstellen/features/search/providers/brand_filter_provider.dart';
import 'package:tankstellen/features/search/providers/search_screen_ui_provider.dart';

import '../../../mocks/mocks.dart';

/// #1792 — the search-criteria providers restore the device-local
/// "Save as default values" set on build, so the whole default set
/// round-trips across an app restart (not just the profile subset).
void main() {
  ProviderContainer containerWith(void Function(MockHiveStorage) stub) {
    final mock = MockHiveStorage();
    when(() => mock.getSetting(any())).thenReturn(null);
    stub(mock);
    final c = ProviderContainer(
      overrides: [hiveStorageProvider.overrideWithValue(mock)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('no saved defaults → providers fall back to empty / false', () {
    final c = containerWith((_) {});
    expect(c.read(openOnlyFilterProvider), isFalse);
    expect(c.read(excludeHighwayStationsProvider), isFalse);
    expect(c.read(selectedAmenitiesProvider), isEmpty);
    expect(c.read(selectedBrandsProvider), isEmpty);
  });

  test('saved open-only filter restores', () {
    final c = containerWith((m) => when(
            () => m.getSetting(StorageKeys.defaultOpenOnly))
        .thenReturn(true));
    expect(c.read(openOnlyFilterProvider), isTrue);
  });

  test('saved exclude-highway filter restores', () {
    final c = containerWith((m) => when(
            () => m.getSetting(StorageKeys.defaultExcludeHighway))
        .thenReturn(true));
    expect(c.read(excludeHighwayStationsProvider), isTrue);
  });

  test('saved brand selection restores', () {
    final c = containerWith((m) => when(
            () => m.getSetting(StorageKeys.defaultBrands))
        .thenReturn(['TotalEnergies', 'Shell']));
    expect(c.read(selectedBrandsProvider), {'TotalEnergies', 'Shell'});
  });

  test('saved amenities restore from their enum names', () {
    final c = containerWith((m) => when(
            () => m.getSetting(StorageKeys.defaultAmenities))
        .thenReturn([StationAmenity.wifi.name, StationAmenity.shop.name]));
    expect(
      c.read(selectedAmenitiesProvider),
      {StationAmenity.wifi, StationAmenity.shop},
    );
  });

  test('an unknown amenity name (downgrade) is skipped, not crashed', () {
    final c = containerWith((m) => when(
            () => m.getSetting(StorageKeys.defaultAmenities))
        .thenReturn([StationAmenity.wifi.name, 'amenity_from_the_future']));
    expect(c.read(selectedAmenitiesProvider), {StationAmenity.wifi});
  });
}
