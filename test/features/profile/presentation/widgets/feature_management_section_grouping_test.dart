import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/conso_mode.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/presentation/widgets/feature_management_section.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for #1440 — visual grouping of dependent features under
/// their parent in the Settings → Feature management section, plus the
/// new tap-to-snackbar behaviour on disabled (blocked) toggles.
///
/// These tests pump [FeatureManagementSection] inside a vanilla
/// MaterialApp+Scaffold (no profile screen, no Hive) so the assertions
/// stay focused on the widget tree the section produces.
void main() {
  group('FeatureManagementSection — grouping (#1440)', () {
    /// Pump the section with a freshly-constructed container so we can
    /// preconfigure feature-flag state via the notifier before laying
    /// out the widget tree. Returns the container so the test can
    /// dispose it.
    Future<ProviderContainer> pumpSection(
      WidgetTester tester, {
      List<Object> overrides = const [],
    }) async {
      final container = ProviderContainer(
        overrides: [
          // Skip Hive; the notifier's synchronous initial state will be
          // `manifest.defaultEnabledSet()`.
          featureFlagsRepositoryProvider.overrideWithValue(null),
          ...overrides,
        ].cast(),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(
              body: SingleChildScrollView(child: FeatureManagementSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    /// Asserts that [child]'s `_FeatureToggle` is rendered inside the
    /// group card whose parent is [parent]. Uses the public
    /// `featureGroup_<parent>` and `featureToggle_<child>` keys.
    void expectChildInGroup(Feature parent, Feature child) {
      final groupFinder = find.byKey(Key('featureGroup_${parent.name}'));
      final childFinder = find.byKey(Key('featureToggle_${child.name}'));
      expect(groupFinder, findsOneWidget,
          reason: 'expected a group card for ${parent.name}');
      expect(childFinder, findsOneWidget,
          reason: 'expected a toggle for ${child.name}');
      expect(
        find.descendant(of: groupFinder, matching: childFinder),
        findsOneWidget,
        reason: '${child.name} must be rendered inside the '
            '${parent.name} group card',
      );
    }

    testWidgets('Conso group card contains its Trajets-tier dependents',
        (tester) async {
      await pumpSection(tester);

      // #1571 — `obd2TripRecording` no longer renders as its own group
      // card. The Conso card hosts the 3-way segmented control plus
      // the Trajets-tier dependents (every feature whose `requires`
      // chain includes obd2TripRecording, minus `showConsumptionTab`
      // which is now derived from the segmented control).
      const dependents = <Feature>[
        Feature.consumptionAnalytics,
        Feature.gamification,
        Feature.hapticEcoCoach,
        Feature.glideCoach,
        Feature.gpsTripPath,
        Feature.autoRecord,
      ];
      final consoCard = find.byKey(const Key('featureGroup_conso'));
      expect(consoCard, findsOneWidget,
          reason: 'Conso card must exist at the top of the section');
      for (final child in dependents) {
        expect(
          find.descendant(
            of: consoCard,
            matching: find.byKey(Key('featureToggle_${child.name}')),
          ),
          findsOneWidget,
          reason: '${child.name} must render inside the Conso card',
        );
      }
      // The old obd2TripRecording / showConsumptionTab / manualConsumption
      // standalone toggles must NOT render — they're replaced by the
      // segmented control.
      expect(find.byKey(const Key('featureToggle_obd2TripRecording')),
          findsNothing);
      expect(find.byKey(const Key('featureToggle_showConsumptionTab')),
          findsNothing);
      expect(find.byKey(const Key('featureToggle_manualConsumption')),
          findsNothing);
    });

    testWidgets('tankSync group contains baselineSync', (tester) async {
      await pumpSection(tester);
      expectChildInGroup(Feature.tankSync, Feature.baselineSync);
    });

    testWidgets('segmented control renders above the Trajets-tier dependents',
        (tester) async {
      await pumpSection(tester);

      // Topology check (#1571): the Conso segmented control sits at the
      // top of the Conso card; the Trajets-tier toggles render beneath.
      final segmented = tester.getRect(find.byType(SegmentedButton<ConsoMode>));
      final childRect = tester.getRect(
        find.byKey(const Key('featureToggle_gamification')),
      );
      expect(segmented.top, lessThan(childRect.top),
          reason: 'segmented control must render above its dependent toggles');
    });

    testWidgets('Trajets-tier toggles are indented inside the Conso card',
        (tester) async {
      await pumpSection(tester);

      final segmented = tester.getRect(find.byType(SegmentedButton<ConsoMode>));
      final childRect = tester.getRect(
        find.byKey(const Key('featureToggle_gamification')),
      );
      expect(childRect.left, greaterThan(segmented.left),
          reason: 'dependent rows must be indented right of the segmented '
              'control so the Conso hierarchy is visually obvious');
    });
  });

  group('FeatureManagementSection — snackbar on blocked tap (#1440)', () {
    testWidgets(
        'tapping gamification while obd2TripRecording is OFF surfaces a '
        'snackbar with the localised "Enable OBD2 trip recording first" '
        'message', (tester) async {
      final container = ProviderContainer(
        overrides: [
          featureFlagsRepositoryProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      // Gamification defaults ON; turn it off first so we can simulate
      // a user trying to re-enable it while the prerequisite is missing.
      await container
          .read(featureFlagsProvider.notifier)
          .disable(Feature.gamification);
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
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(
              body: SingleChildScrollView(child: FeatureManagementSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The toggle is disabled — onChanged is null — so tapping the
      // SwitchListTile would normally do nothing. The wrapping
      // GestureDetector must intercept the tap and fire a SnackBar.
      // Scroll the row into view before tapping so the hit test lands
      // on the wrapper.
      final toggleFinder = find.byKey(const Key('featureToggle_gamification'));
      await tester.scrollUntilVisible(
        toggleFinder,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(toggleFinder, warnIfMissed: false);
      // Pump the SnackBar reveal animation to completion.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'a snackbar must surface the blocker when the user '
              'taps a disabled (unmet-requires) toggle');
      // The English message includes "OBD2 trip recording".
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining('OBD2 trip recording'),
        ),
        findsOneWidget,
        reason: 'the snackbar must name the blocking prerequisite so '
            'the user knows which switch to flip first',
      );
    });

    testWidgets(
        'tapping an unblocked toggle does NOT surface a snackbar',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          featureFlagsRepositoryProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(
              body: SingleChildScrollView(child: FeatureManagementSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // tankSync has no prerequisites — its toggle is enabled. Tap it
      // and verify nothing surfaces. The default 800x600 surface clips
      // the bottom of the section so we scroll the toggle into view
      // first; behaviour is independent of viewport size.
      final toggleFinder = find.byKey(const Key('featureToggle_tankSync'));
      await tester.scrollUntilVisible(
        toggleFinder,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(toggleFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(SnackBar), findsNothing,
          reason: 'unblocked toggles must NOT trigger the snackbar — '
              'the snackbar is only the blocked-tap path');
    });
  });

  group('FeatureManagementSection — Conso segmented control (#1571)', () {
    testWidgets(
        'tapping the Fuel segment turns on showConsumptionTab + '
        'manualConsumption and turns off obd2TripRecording', (tester) async {
      final container = ProviderContainer(
        overrides: [
          featureFlagsRepositoryProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      // Start in a state where obd2TripRecording is ON to prove the
      // segment switch actually disables it.
      await container
          .read(featureFlagsProvider.notifier)
          .enable(Feature.obd2TripRecording);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(
              body: SingleChildScrollView(child: FeatureManagementSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the "Fuel" segment.
      await tester.tap(find.text('Fuel'));
      await tester.pumpAndSettle();

      final flags = container.read(enabledFeaturesProvider);
      expect(flags, contains(Feature.showConsumptionTab));
      expect(flags, contains(Feature.manualConsumption));
      expect(flags, isNot(contains(Feature.obd2TripRecording)));
    });

    testWidgets('tapping the Off segment clears all three Conso flags',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          featureFlagsRepositoryProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(featureFlagsProvider.notifier)
          .enable(Feature.obd2TripRecording);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(
              body: SingleChildScrollView(child: FeatureManagementSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Off'));
      await tester.pumpAndSettle();

      final flags = container.read(enabledFeaturesProvider);
      expect(flags, isNot(contains(Feature.showConsumptionTab)));
      expect(flags, isNot(contains(Feature.manualConsumption)));
      expect(flags, isNot(contains(Feature.obd2TripRecording)));
    });
  });
}
