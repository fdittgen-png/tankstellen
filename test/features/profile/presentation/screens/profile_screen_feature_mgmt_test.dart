// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/build_channel.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';
import 'package:tankstellen/features/profile/presentation/screens/profile_screen.dart';
import 'package:tankstellen/features/profile/presentation/widgets/feature_management_section.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

/// Widget tests for the #1373 phase-2 Feature management section on the
/// Settings screen. The engine's `enable` still throws on a missing
/// prerequisite; the UI must pre-check and render the switch disabled +
/// tooltip in that case. As of #1447 phase 1 (cascading-disable),
/// `disable` no longer throws — disabling a parent always succeeds and
/// dependent switches become disabled-with-tooltip via
/// `isEffectivelyEnabled`, with their stored state preserved so
/// re-enabling the parent restores the prior surface.
/// A copy of the default manifest with [f] flipped to a beta-only
/// feature — available and default-on in beta, absent in production.
FeatureManifest _manifestWithBetaOnly(Feature f) {
  final entries = Map<Feature, FeatureManifestEntry>.from(
      FeatureManifest.defaultManifest.entries);
  final orig = entries[f]!;
  entries[f] = FeatureManifestEntry(
    feature: f,
    availableChannels: const {BuildChannel.beta},
    defaultEnabledChannels: const {BuildChannel.beta},
    displayName: orig.displayName,
    description: orig.description,
    requires: orig.requires,
  );
  return FeatureManifest(entries);
}

void main() {
  group('ProfileScreen — Feature management section (#1373 phase 2)', () {
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
        // and the test never has to drain a microtask queue.
        featureFlagsRepositoryProvider.overrideWithValue(null),
      ];
    });

    /// Expand the Feature management foldable so its child SwitchListTiles
    /// mount in the widget tree. The section sits near the bottom of the
    /// settings ListView; we scroll it into view first.
    Future<void> openSection(WidgetTester tester) async {
      final header = find.text('Feature management');
      await tester.scrollUntilVisible(
        header,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(header);
      await tester.pumpAndSettle();
    }

    testWidgets('section renders one toggle per feature (minus Conso-mode flags)',
        (tester) async {
      await pumpApp(tester, const ProfileScreen(), overrides: baseOverrides);
      await openSection(tester);

      // #1571 — three Conso-surface flags are no longer rendered as
      // per-feature switches: `obd2TripRecording`, `manualConsumption`,
      // and `showConsumptionTab` are now driven by the segmented
      // control inside the Conso card. Every other Feature enum value
      // still surfaces a SwitchListTile keyed `featureToggle_<name>`.
      const consoModeFlags = <Feature>{
        Feature.obd2TripRecording,
        Feature.manualConsumption,
        Feature.showConsumptionTab,
      };
      for (final f in Feature.values) {
        if (consoModeFlags.contains(f)) {
          expect(
            find.byKey(Key('featureToggle_${f.name}')),
            findsNothing,
            reason: '${f.name} is driven by the Conso segmented control '
                '(#1571) — it must not render as a stand-alone switch.',
          );
        } else {
          expect(
            find.byKey(Key('featureToggle_${f.name}')),
            findsOneWidget,
            reason: 'expected a switch for ${f.name}',
          );
        }
      }
      expect(Feature.values.length, 25,
          reason: '#1373 phase 1 shipped 13 features; phase 3d added '
              'autoRecord (14); phase 3c bundled showFuel + showElectric + '
              'showConsumptionTab (17); #1517 added manualConsumption + '
              'loyaltyCards (19); #1543 added tflitePricePrediction (20); '
              '#1613 added fuelCalculator (21) + carbonDashboard (22); '
              '#1615 added experimentalOemPids (23); #1638 added '
              'paymentQrScan + communityPriceReports (25); #1789 removed '
              'unifiedSearchResults (24); #2024 added obd2Optional (25). '
              'Update the test if a new feature was added or removed.');
    });

    testWidgets(
        'toggling an unblocked feature flips its state via the provider',
        (tester) async {
      // Use a probe ProviderScope so we can observe the state change.
      final container = ProviderContainer(
        overrides: baseOverrides.cast(),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: FeatureManagementSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // tankSync defaults to false in the manifest; toggling it on is
      // unblocked because it has no prerequisites.
      expect(
        container.read(enabledFeaturesProvider),
        isNot(contains(Feature.tankSync)),
      );
      // Post-#1440 the section renders grouped cards which can push
      // the tankSync row below the 800x600 default surface. Scroll it
      // into view before tapping so the hit test lands on the switch.
      final tankSyncFinder = find.byKey(const Key('featureToggle_tankSync'));
      await tester.scrollUntilVisible(
        tankSyncFinder,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(tankSyncFinder);
      // Pump the synchronous state update + the in-flight Future. We
      // don't pumpAndSettle because the section has no animations.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        container.read(enabledFeaturesProvider),
        contains(Feature.tankSync),
      );
    });

    testWidgets(
        'enabling gamification while obd2TripRecording is OFF is blocked '
        '(switch disabled + tooltip names the prerequisite)', (tester) async {
      final container = ProviderContainer(
        overrides: baseOverrides.cast(),
      );
      addTearDown(container.dispose);

      // Defaults: gamification is ON, obd2TripRecording is OFF. To set
      // up the blocked-enable scenario we first turn gamification off
      // (which is allowed because no other dependent is enabled).
      await container
          .read(featureFlagsProvider.notifier)
          .disable(Feature.gamification);
      // Sanity: we are now in the state we want to test against.
      expect(
        container.read(enabledFeaturesProvider),
        isNot(contains(Feature.gamification)),
      );
      expect(
        container.read(enabledFeaturesProvider),
        isNot(contains(Feature.obd2TripRecording)),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: FeatureManagementSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch must be disabled — `onChanged: null`.
      final gamificationSwitch = tester.widget<SwitchListTile>(
        find.byKey(const Key('featureToggle_gamification')),
      );
      expect(gamificationSwitch.onChanged, isNull,
          reason: 'gamification switch must be disabled when '
              'obd2TripRecording is OFF');

      // The Tooltip wrapping the disabled switch must name the
      // missing prerequisite. The English message includes "OBD2 trip
      // recording".
      final tooltip = tester.widget<Tooltip>(
        find.ancestor(
          of: find.byKey(const Key('featureToggle_gamification')),
          matching: find.byType(Tooltip),
        ),
      );
      expect(tooltip.message, isNotNull);
      expect(tooltip.message!, contains('OBD2 trip recording'),
          reason: 'tooltip must name the blocking prerequisite');
    });

    testWidgets(
        'disabling obd2TripRecording via the provider while gamification is '
        'ON succeeds — gamification switch then renders disabled-with-'
        'tooltip (#1447 cascading-disable, #1571 segmented control)',
        (tester) async {
      final container = ProviderContainer(
        overrides: baseOverrides.cast(),
      );
      addTearDown(container.dispose);

      await container
          .read(featureFlagsProvider.notifier)
          .enable(Feature.obd2TripRecording);
      expect(
        container.read(enabledFeaturesProvider),
        containsAll(<Feature>[
          Feature.obd2TripRecording,
          Feature.gamification,
        ]),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: FeatureManagementSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // #1571 — `obd2TripRecording` is no longer a stand-alone switch.
      // The user-facing path is the Conso segmented control's "Off"
      // segment; we drive the underlying flag directly here to keep
      // this test focused on the cascading-disable behaviour rather
      // than the segmented control wiring (covered in
      // `feature_management_section_grouping_test.dart`).
      await container
          .read(featureFlagsProvider.notifier)
          .disable(Feature.obd2TripRecording);
      await tester.pumpAndSettle();

      expect(
        container.read(enabledFeaturesProvider),
        isNot(contains(Feature.obd2TripRecording)),
      );
      expect(
        container.read(enabledFeaturesProvider),
        contains(Feature.gamification),
        reason: 'Stored child state must survive parent-disable so the '
            'user does not lose their preference.',
      );

      final gamificationSwitchAfter = tester.widget<SwitchListTile>(
        find.byKey(const Key('featureToggle_gamification')),
      );
      expect(gamificationSwitchAfter.onChanged, isNull,
          reason: 'With parent off, the child switch must be '
              'effectively-disabled (non-interactive) until the user '
              're-enables the parent.');

      final tooltip = tester.widget<Tooltip>(
        find.ancestor(
          of: find.byKey(const Key('featureToggle_gamification')),
          matching: find.byType(Tooltip),
        ),
      );
      expect(tooltip.message, isNotNull);
      expect(tooltip.message!, contains('OBD2 trip recording'),
          reason: 'tooltip must point the user at the parent they need '
              'to flip back on to make the child reachable.');
    });

    testWidgets(
        '#1675 — a beta-only feature is hidden from the list in a '
        'production build', (tester) async {
      await pumpApp(tester, const ProfileScreen(), overrides: [
        ...baseOverrides,
        featureManifestProvider
            .overrideWithValue(_manifestWithBetaOnly(Feature.fuelCalculator)),
        buildChannelProvider.overrideWithValue(BuildChannel.production),
      ]);
      await openSection(tester);

      expect(find.byKey(const Key('featureToggle_fuelCalculator')),
          findsNothing,
          reason: 'a beta-only feature must not render in a production '
              'build');
      // A channel-available feature still renders.
      expect(find.byKey(const Key('featureToggle_priceAlerts')),
          findsOneWidget);
    });

    testWidgets(
        '#1675 — the same feature is visible in a beta build',
        (tester) async {
      await pumpApp(tester, const ProfileScreen(), overrides: [
        ...baseOverrides,
        featureManifestProvider
            .overrideWithValue(_manifestWithBetaOnly(Feature.fuelCalculator)),
        buildChannelProvider.overrideWithValue(BuildChannel.beta),
      ]);
      await openSection(tester);

      expect(find.byKey(const Key('featureToggle_fuelCalculator')),
          findsOneWidget,
          reason: 'a beta-only feature must render in a beta build');
    });
  });
}
