// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// The mocktail Mock* storage doubles are deprecated as a steering hint
// (prefer the stateful fakes) but remain sanctioned for widget tests that
// stub reads exclusively -- see test/helpers/mock_providers.dart (#3742).
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/theme/theme_mode_provider.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';

import '../../../../../helpers/mock_providers.dart';
import '../../../../../mocks/mocks.dart';

/// Shared override set for the Settings root + topic-screen widget tests
/// (#3884): the read-only `MockHiveStorage` stubs the former
/// `profile_screen_test` used, the standard provider overrides, a
/// null feature-flags repository (synchronous manifest defaults) and,
/// when [flags] is given, a pinned feature set.
List<Object> settingsTestOverrides({Set<Feature>? flags}) {
  final mockStorage = MockHiveStorage();
  when(() => mockStorage.hasApiKey(any())).thenReturn(false);
  when(() => mockStorage.getApiKey(any())).thenReturn(null);
  when(() => mockStorage.getActiveProfileId()).thenReturn(null);
  when(() => mockStorage.getAllProfiles()).thenReturn([]);
  when(() => mockStorage.getRatings()).thenReturn({});
  when(() => mockStorage.getIgnoredIds()).thenReturn([]);
  when(() => mockStorage.getSetting(any())).thenReturn(null);
  when(() => mockStorage.storageStats).thenReturn((
    settings: 0,
    profiles: 0,
    favorites: 0,
    cache: 0,
    priceHistory: 0,
    alerts: 0,
    total: 0,
  ));
  when(() => mockStorage.profileCount).thenReturn(0);
  when(() => mockStorage.favoriteCount).thenReturn(0);
  when(() => mockStorage.cacheEntryCount).thenReturn(0);
  when(() => mockStorage.priceHistoryEntryCount).thenReturn(0);
  when(() => mockStorage.alertCount).thenReturn(0);
  when(() => mockStorage.getFavoriteIds()).thenReturn([]);
  when(() => mockStorage.getAlerts()).thenReturn([]);
  when(() => mockStorage.getEvApiKey()).thenReturn(null);
  when(() => mockStorage.hasCustomEvApiKey()).thenReturn(false);
  // #3910 — the device-data inventory behind the Privacy & data entry.
  when(() => mockStorage.getItineraries()).thenReturn([]);
  when(() => mockStorage.getPriceHistoryKeys()).thenReturn([]);

  final test = standardTestOverrides();
  return [
    hiveStorageProvider.overrideWithValue(mockStorage),
    ...test.overrides.skip(1), // skip the default storage override
    // Skip the Hive load path so the synchronous initial state is the
    // manifest default set and no microtask queue needs draining.
    featureFlagsRepositoryProvider.overrideWithValue(null),
    if (flags != null)
      featureFlagsProvider.overrideWith(() => PinnedFeatureFlags(flags)),
    themeModeSettingProvider.overrideWith(
      () => FixedThemeMode(AppThemeChoice.system),
    ),
  ];
}

/// FeatureFlags notifier pinned to a fixed set — no Hive, no async.
class PinnedFeatureFlags extends FeatureFlags {
  PinnedFeatureFlags(this._initial);

  final Set<Feature> _initial;

  @override
  Set<Feature> build() {
    ref.watch(featureManifestProvider);
    return {..._initial};
  }
}

/// ThemeModeSetting with a fixed `build()` value — skips the real
/// provider's SharedPreferences load (no plugin channel in widget tests).
class FixedThemeMode extends ThemeModeSetting {
  FixedThemeMode(this._initial);

  final AppThemeChoice _initial;

  @override
  AppThemeChoice build() => _initial;

  @override
  Future<void> set(AppThemeChoice mode) async {
    state = mode;
  }
}
