// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/presentation/screens/profile_screen.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

/// #1447 phase 3 — settings sections whose root feature is effectively
/// disabled must vanish entirely from [ProfileScreen]. Re-enabling the
/// root brings them back without the user touching any sub-state.
///
/// This test pins:
///   1. `Feature.tankSync` off → the TankSync foldable is gone.
///   2. `Feature.obd2TripRecording` off → the Consumption foldable is gone.
///   3. Both on → both foldables render.
void main() {
  group('ProfileScreen — section gating (#1447 phase 3)', () {
    late MockHiveStorage mockStorage;
    late List<Object> baseOverrides;

    setUp(() {
      mockStorage = MockHiveStorage();
      when(() => mockStorage.hasApiKey()).thenReturn(false);
      when(() => mockStorage.getApiKey()).thenReturn(null);
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

      final test = standardTestOverrides();
      baseOverrides = [
        hiveStorageProvider.overrideWithValue(mockStorage),
        ...test.overrides.skip(1),
        // Force the FeatureFlags notifier to skip the Hive load path so
        // the synchronous initial state is `manifest.defaultEnabledSet()`
        // — same pattern as the feature-mgmt section test.
        featureFlagsRepositoryProvider.overrideWithValue(null),
      ];
    });

    /// Builds a manifest override that pins the enabled set to [flags].
    /// Done by overriding the repository with an in-memory fake — the
    /// notifier loads the persisted set on first read.
    List<Object> overridesWithFlags(Set<Feature> flags) {
      return [
        ...baseOverrides,
        // Replace the repository override with a manifest pin so the
        // FeatureFlags notifier resolves to exactly [flags]. Easiest
        // path: override the notifier directly.
        featureFlagsProvider.overrideWith(() => _PinnedFeatureFlags(flags)),
      ];
    }

    testWidgets(
      'TankSync foldable hides when Feature.tankSync is disabled',
      (tester) async {
        await pumpApp(
          tester,
          const ProfileScreen(),
          // Default-enabled set has tankSync OFF, obd2TripRecording OFF.
          // Both gated sections should be absent.
          overrides: overridesWithFlags(const <Feature>{}),
        );

        expect(
          find.text('TankSync'),
          findsNothing,
          reason: 'Section title must not appear when Feature.tankSync '
              'is effectively-disabled (#1447 phase 3).',
        );
      },
    );

    testWidgets(
      'Consumption foldable hides when Feature.obd2TripRecording is disabled',
      (tester) async {
        await pumpApp(
          tester,
          const ProfileScreen(),
          overrides: overridesWithFlags(const <Feature>{}),
        );

        expect(
          find.text('Consumption'),
          findsNothing,
          reason: 'Section title must not appear when '
              'Feature.obd2TripRecording is effectively-disabled — the '
              'whole consumption-settings group (vehicles, eco-coach, '
              'fuel club cards) lives behind this gate.',
        );
      },
    );

    testWidgets(
      'both foldables render when both root features are enabled',
      (tester) async {
        // The ListView in ProfileScreen lazy-builds children based on
        // viewport. The default 800×600 surface scrolls the
        // Consumption foldable far off-stage, and the lazy delegate
        // doesn't materialise it until it's near the viewport — so
        // `skipOffstage: false` finds nothing. Set a tall surface so
        // every foldable renders eagerly (#1545 fix).
        await tester.binding.setSurfaceSize(const Size(1200, 3200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await pumpApp(
          tester,
          const ProfileScreen(),
          overrides: overridesWithFlags(<Feature>{
            Feature.tankSync,
            Feature.obd2TripRecording,
            // #1520: Consumption section visibility now requires the
            // `showConsumptionTab` flag in the stored set in addition
            // to a data source (obd2TripRecording OR manualConsumption).
            // Pin it so the foldable renders.
            Feature.showConsumptionTab,
          }),
        );

        expect(find.text('TankSync', skipOffstage: false), findsOneWidget);
        expect(find.text('Consumption', skipOffstage: false), findsOneWidget);
        // #2521 — TankSync is the only child of the "Account & sync"
        // group, so enabling it must also surface that group header.
        expect(
          find.text('Account & sync', skipOffstage: false),
          findsOneWidget,
          reason: '#2521: enabling TankSync must surface its group header',
        );
      },
    );

    testWidgets(
      'TankSync foldable hides without affecting Consumption when only '
      'tankSync is off (independent gates)',
      (tester) async {
        // Same surface-size fix as the 'both foldables render' test
        // above (#1545) — the lazy ListView won't materialise the
        // Consumption row at the default 800×600 viewport.
        await tester.binding.setSurfaceSize(const Size(1200, 3200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await pumpApp(
          tester,
          const ProfileScreen(),
          overrides: overridesWithFlags(<Feature>{
            Feature.obd2TripRecording,
            // #1520: same gate change — pin showConsumptionTab so the
            // foldable renders even when tankSync is off.
            Feature.showConsumptionTab,
          }),
        );

        expect(find.text('TankSync', skipOffstage: false), findsNothing);
        expect(find.text('Consumption', skipOffstage: false), findsOneWidget);
      },
    );

    // #2248 — the Developer tools tile is gated on Feature.debugMode and
    // must never render for a production (default) user.
    testWidgets(
      'Developer tools tile hides when Feature.debugMode is off (default)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 3200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await pumpApp(
          tester,
          const ProfileScreen(),
          overrides: overridesWithFlags(const <Feature>{}),
        );

        expect(
          find.text('Developer tools', skipOffstage: false),
          findsNothing,
          reason: 'debugMode is default-off, so production users must '
              'never see the Developer tools entry (#2248).',
        );
      },
    );

    testWidgets(
      'Developer tools tile renders when Feature.debugMode is on',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 3200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await pumpApp(
          tester,
          const ProfileScreen(),
          overrides: overridesWithFlags(const <Feature>{Feature.debugMode}),
        );

        expect(
          find.text('Developer tools', skipOffstage: false),
          findsOneWidget,
          reason: 'enabling debugMode must surface the Developer tools '
              'entry in Settings (#2248).',
        );
        // #2521 — the Developer tools tile lives under the "Advanced &
        // developer" group, whose header is conditionalised on having a
        // visible child. Enabling debugMode must surface that header.
        expect(
          find.text('Advanced & developer', skipOffstage: false),
          findsOneWidget,
          reason: '#2521: enabling debugMode must surface the Advanced & '
              'developer group header',
        );
      },
    );
  });
}

/// Test-only FeatureFlags notifier that returns a fixed set on `build()`.
/// Skips the Hive-load path entirely so synchronous reads observe the
/// pinned set without a microtask drain.
class _PinnedFeatureFlags extends FeatureFlags {
  _PinnedFeatureFlags(this._initial);

  final Set<Feature> _initial;

  @override
  Set<Feature> build() {
    // Watch the manifest so cycle assertions still run.
    ref.watch(featureManifestProvider);
    return _initial;
  }
}
