// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/route_search/providers/route_search_params_provider.dart';
import 'package:tankstellen/features/search/presentation/widgets/route_planning_controls.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #2592 — the route-planning controls render three sliders defaulted from
/// the active profile and write the per-search override providers on drag.
class _FixedProfile extends ActiveProfile {
  _FixedProfile(this._profile);
  final UserProfile? _profile;

  @override
  UserProfile? build() => _profile;
}

/// Detour override that starts away from the profile default, so the
/// "Route options" section must open pre-expanded (#3927).
class _FixedDetour extends RouteDetourSearchParam {
  _FixedDetour(this._km);
  final double _km;

  @override
  double build() => _km;
}

void main() {
  group('RoutePlanningControls (#2592)', () {
    testWidgets('renders three sliders defaulted from the profile', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeProfileProvider.overrideWith(
              () => _FixedProfile(
                const UserProfile(
                  id: 'p',
                  name: 'P',
                  routeSegmentKm: 200,
                  routeDetourBudgetKm: 8,
                  minRouteSavingPerLiter: 0.05,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: RoutePlanningControls()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // #3927 — the options are collapsed while every value still equals
      // the profile default; the one-line summary carries all three.
      expect(find.byType(Slider), findsNothing);
      expect(
        find.text('Every 200 km · 8 km detour · 0,05 €/L'),
        findsOneWidget,
      );

      await tester.tap(find.text('Route options'));
      await tester.pumpAndSettle();

      // Two sliders now — the minimum saving became preset chips.
      expect(find.byType(Slider), findsNWidgets(2));
      expect(find.text('200 km'), findsOneWidget);
      expect(find.text('8 km'), findsOneWidget);
      expect(find.text('0,05 €/L'), findsWidgets);
      // The 0.05 preset chip is the selected one.
      final chip = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('criteria-min-saving-5')),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('#3927 — a minimum-saving chip writes the same provider '
        'value the slider wrote', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeProfileProvider.overrideWith(
              () => _FixedProfile(
                const UserProfile(id: 'p', name: 'P', routeSegmentKm: 50),
              ),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(body: RoutePlanningControls()),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Route options'));
      await tester.pumpAndSettle();

      expect(container.read(minRouteSavingSearchParamProvider), 0.0);
      await tester.tap(find.byKey(const ValueKey('criteria-min-saving-10')));
      await tester.pumpAndSettle();
      expect(container.read(minRouteSavingSearchParamProvider), 0.10);
    });

    testWidgets('#3927 — the section opens pre-expanded when a value '
        'differs from its default', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeProfileProvider.overrideWith(
              () => _FixedProfile(
                const UserProfile(id: 'p', name: 'P', routeSegmentKm: 50),
              ),
            ),
            routeDetourSearchParamProvider.overrideWith(
              () => _FixedDetour(12),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: RoutePlanningControls()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsNWidgets(2));
    });

    testWidgets('dragging the segment slider updates the provider', (
      tester,
    ) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeProfileProvider.overrideWith(
              () => _FixedProfile(
                const UserProfile(id: 'p', name: 'P', routeSegmentKm: 50),
              ),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(body: RoutePlanningControls()),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Route options'));
      await tester.pumpAndSettle();

      expect(container.read(routeSegmentSearchParamProvider), 50.0);

      // Drag the first (segment) slider rightwards to raise the value.
      await tester.drag(find.byType(Slider).first, const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(
        container.read(routeSegmentSearchParamProvider),
        greaterThan(50.0),
      );
    });
  });
}
