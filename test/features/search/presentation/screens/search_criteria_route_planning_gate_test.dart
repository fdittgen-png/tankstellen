// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/search_mode.dart';
import 'package:tankstellen/features/search/presentation/screens/search_criteria_screen.dart';
import 'package:tankstellen/features/search/presentation/widgets/route_planning_controls.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_mode_toggle.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_radius_slider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #1447 phase 4 — when `Feature.routePlanning` is effectively-disabled,
/// the SearchModeToggle disappears and the criteria screen renders only
/// the Nearby branch even if the persisted mode was previously Route.
/// Re-enabling the feature restores the toggle and the prior mode.
void main() {
  group('SearchCriteriaScreen — route-planning gate (#1447 phase 4)', () {
    testWidgets(
      'SearchModeToggle hides when Feature.routePlanning is disabled',
      (tester) async {
        final test = standardTestOverrides();

        await pumpApp(
          tester,
          const SearchCriteriaScreen(),
          overrides: [
            ...test.overrides,
            selectedFuelTypeOverride(FuelType.e10),
            searchRadiusOverride(8),
            userPositionNullOverride(),
            // Feature manifest default is routePlanning=true; pin it
            // off via a featureFlagsProvider override to exercise the
            // gate.
            featureFlagsProvider.overrideWith(
              () => _CriteriaGateFlags(<Feature>{}),
            ),
          ],
        );

        expect(
          find.byType(SearchModeToggle),
          findsNothing,
          reason: 'SearchModeToggle must be absent when '
              'Feature.routePlanning is effectively-disabled (#1447 phase 4).',
        );
        expect(
          find.byKey(const ValueKey('criteria-mode-toggle')),
          findsNothing,
          reason: 'The toggle key must not appear in the tree either.',
        );
      },
    );

    testWidgets(
      'SearchModeToggle renders when Feature.routePlanning is enabled',
      (tester) async {
        final test = standardTestOverrides();

        await pumpApp(
          tester,
          const SearchCriteriaScreen(),
          overrides: [
            ...test.overrides,
            selectedFuelTypeOverride(FuelType.e10),
            searchRadiusOverride(8),
            userPositionNullOverride(),
            featureFlagsProvider.overrideWith(
              () => _CriteriaGateFlags(<Feature>{Feature.routePlanning}),
            ),
          ],
        );

        expect(find.byType(SearchModeToggle), findsOneWidget);
      },
    );
  });

  // #2592 — route mode hides the radius slider and surfaces the
  // route-planning controls; nearby mode is the reverse.
  group('SearchCriteriaScreen — route-mode controls (#2592)', () {
    testWidgets('nearby mode shows the radius slider, not route controls',
        (tester) async {
      final test = standardTestOverrides();

      await pumpApp(
        tester,
        const SearchCriteriaScreen(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(8),
          userPositionNullOverride(),
          activeSearchModeOverride(SearchMode.nearby),
          featureFlagsProvider.overrideWith(
            () => _CriteriaGateFlags(<Feature>{Feature.routePlanning}),
          ),
        ],
      );

      expect(find.byType(SearchRadiusSlider), findsOneWidget);
      expect(find.byType(RoutePlanningControls), findsNothing);
    });

    testWidgets('route mode shows route controls, not the radius slider',
        (tester) async {
      final test = standardTestOverrides();

      await pumpApp(
        tester,
        const SearchCriteriaScreen(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(8),
          userPositionNullOverride(),
          activeSearchModeOverride(SearchMode.route),
          featureFlagsProvider.overrideWith(
            () => _CriteriaGateFlags(<Feature>{Feature.routePlanning}),
          ),
        ],
      );

      expect(find.byType(RoutePlanningControls), findsOneWidget);
      expect(find.byType(SearchRadiusSlider), findsNothing);
    });
  });
}

/// Test-only FeatureFlags notifier with a fixed enabled set. Skips the
/// Hive load path for synchronous reads.
class _CriteriaGateFlags extends FeatureFlags {
  _CriteriaGateFlags(this._initial);

  final Set<Feature> _initial;

  @override
  Set<Feature> build() {
    ref.watch(featureManifestProvider);
    return _initial;
  }
}
