// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/app_profile.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_category.dart';
import 'package:tankstellen/features/profile/presentation/widgets/feature_management_section.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget + unit tests for the #2681 ordered-category reorganization of
/// the Settings → Feature management screen.
///
/// The screen now renders seven category section headers in
/// [categoryOrder], each followed by the feature group cards bucketed
/// under it. The reorg is presentation-only and behaviour-preserving:
/// the [Feature] enum, the manifest, and the [appProfileBundles] presets
/// are unchanged.
void main() {
  Future<ProviderContainer> pumpSection(
    WidgetTester tester, {
    List<Object> overrides = const [],
  }) async {
    final container = ProviderContainer(
      overrides: [
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

  group('FeatureManagementSection — ordered category sections (#2681)', () {
    testWidgets('renders all 7 section headers in categoryOrder', (tester) async {
      await pumpSection(tester);

      // Every category header renders exactly once.
      for (final c in categoryOrder) {
        expect(
          find.byKey(Key('featureSectionHeader_${c.name}')),
          findsOneWidget,
          reason: 'expected a section header for ${c.name}',
        );
      }
      expect(categoryOrder.length, 7,
          reason: '#2681 ships 7 ordered category sections');

      // Header rects must be ordered top-to-bottom in categoryOrder.
      double topOf(FeatureCategory c) =>
          tester.getRect(find.byKey(Key('featureSectionHeader_${c.name}'))).top;
      for (var i = 0; i < categoryOrder.length - 1; i++) {
        expect(
          topOf(categoryOrder[i]),
          lessThan(topOf(categoryOrder[i + 1])),
          reason: '${categoryOrder[i].name} header must render above '
              '${categoryOrder[i + 1].name}',
        );
      }
    });

    testWidgets('a sample feature sits under its section header for each '
        'category', (tester) async {
      await pumpSection(tester);

      // One representative feature per category; assert its toggle/card
      // renders below the matching header and above the next header.
      const samples = <FeatureCategory, Feature>{
        FeatureCategory.finding: Feature.showFuel,
        FeatureCategory.prices: Feature.priceAlerts,
        FeatureCategory.radar: Feature.approachOverlay,
        FeatureCategory.consumption: Feature.gamification,
        FeatureCategory.sync: Feature.tankSync,
        FeatureCategory.input: Feature.addFillUpOcrReceipt,
        FeatureCategory.developer: Feature.debugMode,
      };
      for (final entry in samples.entries) {
        final category = entry.key;
        final feature = entry.value;
        final headerTop = tester
            .getRect(find.byKey(Key('featureSectionHeader_${category.name}')))
            .top;
        final toggleTop = tester
            .getRect(find.byKey(Key('featureToggle_${feature.name}')))
            .top;
        expect(toggleTop, greaterThan(headerTop),
            reason: '${feature.name} must render below its '
                '${category.name} section header');

        // Below the *next* header too (when there is one).
        final idx = categoryOrder.indexOf(category);
        if (idx < categoryOrder.length - 1) {
          final nextHeaderTop = tester
              .getRect(find.byKey(
                  Key('featureSectionHeader_${categoryOrder[idx + 1].name}')))
              .top;
          expect(toggleTop, lessThan(nextHeaderTop),
              reason: '${feature.name} must render above the next section '
                  '(${categoryOrder[idx + 1].name}) header');
        }
      }
    });

    testWidgets('nesting is preserved — dependents render inside their '
        'parent group/card', (tester) async {
      await pumpSection(tester);

      // baselineSync under tankSync.
      expect(
        find.descendant(
          of: find.byKey(const Key('featureGroup_tankSync')),
          matching: find.byKey(const Key('featureToggle_baselineSync')),
        ),
        findsOneWidget,
        reason: 'baselineSync must nest under the tankSync group',
      );
      // tflitePricePrediction under priceHistory.
      expect(
        find.descendant(
          of: find.byKey(const Key('featureGroup_priceHistory')),
          matching: find.byKey(const Key('featureToggle_tflitePricePrediction')),
        ),
        findsOneWidget,
        reason: 'Best time to fill up must nest under priceHistory',
      );
      // voiceAnnouncements under approachOverlay.
      expect(
        find.descendant(
          of: find.byKey(const Key('featureGroup_approachOverlay')),
          matching: find.byKey(const Key('featureToggle_voiceAnnouncements')),
        ),
        findsOneWidget,
        reason: 'voiceAnnouncements must nest under the Fuel Station Radar '
            '(approachOverlay) group',
      );
    });

    testWidgets('renames applied — Fuel Station Radar + Consumption headers, '
        'no "Approach overlay" / "Conso"', (tester) async {
      await pumpSection(tester);

      // The renamed radar label appears (section header + toggle label).
      expect(find.text('Fuel Station Radar'), findsWidgets,
          reason: 'the approach overlay was renamed to Fuel Station Radar');
      expect(find.text('Approach overlay'), findsNothing,
          reason: 'the old "Approach overlay" label must be gone');
      // The renamed Conso group title.
      expect(find.text('Consumption'), findsWidgets,
          reason: 'the Conso card header was renamed to Consumption');
      expect(find.text('Conso'), findsNothing,
          reason: 'the old "Conso" title must be gone');
    });
  });

  group('FeatureManagementSection — gating preserved (#2681)', () {
    testWidgets(
        'tapping gamification while obd2TripRecording is OFF still surfaces '
        'the blocked snackbar', (tester) async {
      final container = await pumpSection(tester);

      // Defaults: gamification ON, obd2TripRecording OFF. Disable
      // gamification first so the re-enable path is the blocked one.
      await container
          .read(featureFlagsProvider.notifier)
          .disable(Feature.gamification);
      await tester.pumpAndSettle();

      final toggleFinder = find.byKey(const Key('featureToggle_gamification'));
      await tester.scrollUntilVisible(
        toggleFinder,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(toggleFinder, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'gating must survive the reorg — a blocked tap still '
              'surfaces the prerequisite snackbar');
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining('OBD2 trip recording'),
        ),
        findsOneWidget,
      );
    });
  });

  group('AppProfile presets are byte-for-byte unchanged (#2681)', () {
    test('basic / medium / full bundles match the pinned canonical sets', () {
      // Regression guard: the IA reorg is presentation-only — the preset
      // bundles must not have drifted. Pin the exact sets here.
      expect(appProfileBundles[AppProfile.basic], <Feature>{
        Feature.showFuel,
        Feature.showElectric,
        Feature.priceAlerts,
        Feature.priceHistory,
        Feature.routePlanning,
        Feature.evCharging,
        Feature.tankSync,
        Feature.baselineSync,
      });
      expect(appProfileBundles[AppProfile.medium], <Feature>{
        Feature.showFuel,
        Feature.showElectric,
        Feature.priceAlerts,
        Feature.priceHistory,
        Feature.routePlanning,
        Feature.evCharging,
        Feature.tankSync,
        Feature.baselineSync,
        Feature.manualConsumption,
        Feature.showConsumptionTab,
        Feature.obd2TripRecording,
        Feature.consumptionAnalytics,
        Feature.gpsTripPath,
        Feature.approachOverlay,
      });
      expect(appProfileBundles[AppProfile.full], <Feature>{
        Feature.showFuel,
        Feature.showElectric,
        Feature.priceAlerts,
        Feature.priceHistory,
        Feature.routePlanning,
        Feature.evCharging,
        Feature.tankSync,
        Feature.baselineSync,
        Feature.manualConsumption,
        Feature.loyaltyCards,
        Feature.obd2TripRecording,
        Feature.autoRecord,
        Feature.consumptionAnalytics,
        Feature.gamification,
        Feature.showConsumptionTab,
        Feature.hapticEcoCoach,
        Feature.glideCoach,
        Feature.gpsTripPath,
        Feature.obd2Optional,
        Feature.approachOverlay,
      });
      expect(appProfileBundles[AppProfile.custom], isEmpty);
    });

    test('detectProfileFromFlags round-trips every preset bundle', () {
      for (final preset in AppProfile.values) {
        if (preset == AppProfile.custom) continue;
        final bundle = appProfileBundles[preset]!;
        expect(detectProfileFromFlags(Set<Feature>.from(bundle)), preset,
            reason: 'detectProfileFromFlags must map the $preset bundle '
                'back to $preset');
      }
    });
  });

  group('featureCategory map (#2681)', () {
    test('every Feature is placed in exactly one category', () {
      for (final f in Feature.values) {
        expect(featureCategory.containsKey(f), isTrue,
            reason: '$f must have a FeatureCategory mapping');
        // categoryOf asserts presence and returns the mapped value.
        expect(categoryOf(f), featureCategory[f]);
      }
      // No stray keys (every mapped feature is a real enum value — trivially
      // true) and the map covers all 31.
      expect(featureCategory.length, Feature.values.length,
          reason: 'the category map must cover every Feature exactly once');
    });
  });
}
