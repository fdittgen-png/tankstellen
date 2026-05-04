import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/presentation/screens/profile_screen.dart';
import 'package:tankstellen/features/profile/presentation/widgets/feature_management_section.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

/// Widget tests for the #1373 phase-2 Feature management section on the
/// Settings screen. The Phase-1 engine ships with `enable` / `disable`
/// throwing `StateError` on illegal transitions; the UI must pre-check
/// and disable + tooltip the switch instead of letting the error reach
/// the user.
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

    testWidgets('section renders with one toggle per feature (17 total)',
        (tester) async {
      await pumpApp(tester, const ProfileScreen(), overrides: baseOverrides);
      await openSection(tester);

      // Every Feature enum value must surface a SwitchListTile keyed
      // `featureToggle_<name>`. The test pins the count at the current
      // enum size so adding a feature without wiring it up fails here.
      for (final f in Feature.values) {
        expect(
          find.byKey(Key('featureToggle_${f.name}')),
          findsOneWidget,
          reason: 'expected a switch for ${f.name}',
        );
      }
      expect(Feature.values.length, 17,
          reason: '#1373 phase 1 shipped 13 features; phase 3d added '
              'autoRecord as a master gate over the per-vehicle bool '
              '(14); phase 3c bundled showFuel + showElectric + '
              'showConsumptionTab (total 17). Update the test if a '
              'new feature was added or removed.');
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
        container.read(featureFlagsProvider),
        isNot(contains(Feature.tankSync)),
      );
      await tester.tap(find.byKey(const Key('featureToggle_tankSync')));
      // Pump the synchronous state update + the in-flight Future. We
      // don't pumpAndSettle because the section has no animations.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        container.read(featureFlagsProvider),
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
        container.read(featureFlagsProvider),
        isNot(contains(Feature.gamification)),
      );
      expect(
        container.read(featureFlagsProvider),
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
        'disabling obd2TripRecording while gamification is ON is blocked '
        '(switch disabled + tooltip names the dependent)', (tester) async {
      final container = ProviderContainer(
        overrides: baseOverrides.cast(),
      );
      addTearDown(container.dispose);

      // Set up the state where obd2TripRecording is ON (so its switch
      // shows ON) and gamification is also ON (depends on it).
      await container
          .read(featureFlagsProvider.notifier)
          .enable(Feature.obd2TripRecording);
      // gamification is on by default; verify the precondition.
      expect(
        container.read(featureFlagsProvider),
        contains(Feature.gamification),
      );
      expect(
        container.read(featureFlagsProvider),
        contains(Feature.obd2TripRecording),
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

      // The obd2TripRecording switch must be disabled (the user must
      // turn dependents off first).
      final obd2Switch = tester.widget<SwitchListTile>(
        find.byKey(const Key('featureToggle_obd2TripRecording')),
      );
      expect(obd2Switch.onChanged, isNull,
          reason: 'obd2TripRecording switch must be disabled while '
              'gamification still depends on it');

      // The wrapping Tooltip must name `gamification` (English label).
      final tooltip = tester.widget<Tooltip>(
        find.ancestor(
          of: find.byKey(const Key('featureToggle_obd2TripRecording')),
          matching: find.byType(Tooltip),
        ),
      );
      expect(tooltip.message, isNotNull);
      expect(tooltip.message!, contains('Gamification'),
          reason: 'tooltip must name the dependent feature so the user '
              'knows which switch to flip first');
    });
  });
}
