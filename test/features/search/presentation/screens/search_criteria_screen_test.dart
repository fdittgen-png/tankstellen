// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/navigation/search_fab_action_provider.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/search_mode.dart';
import 'package:tankstellen/core/domain/station_amenity.dart';
import 'package:tankstellen/features/search/presentation/screens/search_criteria_screen.dart';
import 'package:tankstellen/features/search/presentation/widgets/fuel_type_selector.dart';
import 'package:tankstellen/features/search/presentation/widgets/location_input.dart';
import 'package:tankstellen/features/search/providers/search_filters_provider.dart';
import 'package:tankstellen/features/search/providers/search_screen_ui_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// ActiveProfile stub that records updates in-memory for test assertions.
class _FakeActiveProfile extends ActiveProfile {
  _FakeActiveProfile(this._initial);
  final UserProfile? _initial;
  final List<UserProfile> updates = [];

  @override
  UserProfile? build() => _initial;

  @override
  Future<void> updateProfile(UserProfile profile) async {
    updates.add(profile);
    state = profile;
  }
}

void main() {
  group('SearchCriteriaScreen', () {
    testWidgets(
      'renders form: LocationInput, FuelTypeSelector, slider, button',
      (tester) async {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

        await pumpApp(
          tester,
          const SearchCriteriaScreen(),
          overrides: [
            ...test.overrides,
            selectedFuelTypeOverride(FuelType.e10),
            searchRadiusOverride(8),
            userPositionNullOverride(),
          ],
        );

        expect(find.byType(LocationInput), findsOneWidget);
        expect(find.byType(FuelTypeSelector), findsOneWidget);
        expect(find.byType(Slider), findsOneWidget);
        // #2131 — the inline "Search" CTA moved to the central FAB in
        // the shell bar; the criteria screen no longer renders its own
        // submit button.
        expect(
          find.byKey(const ValueKey('criteria-search-button')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('criteria-mode-toggle')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('criteria-open-only-toggle')),
          findsOneWidget,
        );
        // #3927 — the sheet owns a labelled primary action again, plus a
        // reset; "Save as my defaults" moved into the app-bar overflow.
        expect(
          find.byKey(const ValueKey('criteria-submit-button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('criteria-reset-button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('criteria-overflow-menu')),
          findsOneWidget,
        );
        // Nearby mode can always search — no reason line.
        expect(
          find.byKey(const ValueKey('criteria-disabled-reason')),
          findsNothing,
        );
      },
    );

    testWidgets('mode toggle switches from LocationInput to RouteInput', (
      tester,
    ) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

      await pumpApp(
        tester,
        const SearchCriteriaScreen(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(8),
          userPositionNullOverride(),
        ],
      );

      expect(find.byType(LocationInput), findsOneWidget);

      // Tap the "Route" segment.
      await tester.tap(find.text('Route').first);
      await tester.pump();

      // LocationInput should be gone; nearby mode widget replaced.
      expect(find.byType(LocationInput), findsNothing);
    });

    testWidgets('open-only toggle updates provider', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...test.overrides,
            selectedFuelTypeOverride(FuelType.e10),
            searchRadiusOverride(8),
            userPositionNullOverride(),
          ].cast(),
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: SearchCriteriaScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      container.read(openOnlyFilterProvider.notifier).set(false);
      expect(container.read(openOnlyFilterProvider), isFalse);

      final toggle = find.byKey(const ValueKey('criteria-open-only-toggle'));
      await tester.ensureVisible(toggle);
      await tester.pump();
      await tester.tap(toggle);
      await tester.pump();

      expect(container.read(openOnlyFilterProvider), isTrue);
    });

    testWidgets('equipment chips toggle on/off', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...test.overrides,
            selectedFuelTypeOverride(FuelType.e10),
            searchRadiusOverride(8),
            userPositionNullOverride(),
          ].cast(),
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: SearchCriteriaScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // keepAlive providers can leak state between tests — start clean.
      container.read(selectedAmenitiesProvider.notifier).clear();
      container.read(openOnlyFilterProvider.notifier).set(false);

      expect(container.read(selectedAmenitiesProvider), isEmpty);

      final shopChip = find.byKey(const ValueKey('criteria-amenity-shop'));
      await tester.ensureVisible(shopChip);
      await tester.pump();

      // Toggle the shop chip on.
      await tester.tap(shopChip);
      await tester.pump();
      expect(
        container.read(selectedAmenitiesProvider),
        contains(StationAmenity.shop),
      );

      // Toggle it off.
      await tester.tap(shopChip);
      await tester.pump();
      expect(container.read(selectedAmenitiesProvider), isEmpty);
    });

    testWidgets('save-as-defaults button updates the active profile', (
      tester,
    ) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
      // #1792 — open-only, amenities and brands have no UserProfile
      // field; they persist device-locally via putSetting.
      when(
        () => test.mockStorage.putSetting(any(), any<dynamic>()),
      ).thenAnswer((_) async {});

      const initialProfile = UserProfile(id: 'p1', name: 'Standard');
      final fake = _FakeActiveProfile(initialProfile);

      // Pre-select shop amenity via the provider override container.
      final overrides = <Object>[
        ...test.overrides,
        selectedFuelTypeOverride(FuelType.diesel),
        searchRadiusOverride(15),
        userPositionNullOverride(),
        activeProfileProvider.overrideWith(() => fake),
      ];

      await pumpApp(tester, const SearchCriteriaScreen(), overrides: overrides);

      // Select the "Air" amenity chip so we can assert it gets persisted.
      final airChip = find.byKey(const ValueKey('criteria-amenity-airPump'));
      await tester.ensureVisible(airChip);
      await tester.pump();
      await tester.tap(airChip);
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('criteria-overflow-menu')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('criteria-save-defaults-button')),
      );
      await tester.pumpAndSettle();

      // Fuel type + radius are profile fields — mirrored into the profile.
      expect(fake.updates, hasLength(1));
      final saved = fake.updates.single;
      expect(saved.preferredFuelType, FuelType.diesel);
      expect(saved.defaultSearchRadius, 15);

      // #1792 — the amenity set has no profile field; it persists
      // device-locally instead of on the profile.
      verify(
        () => test.mockStorage.putSetting(StorageKeys.defaultAmenities, [
          StationAmenity.airPump.name,
        ]),
      ).called(1);
    });

    testWidgets(
      '#2592 — save-as-defaults persists route params in route mode',
      (tester) async {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
        when(
          () => test.mockStorage.putSetting(any(), any<dynamic>()),
        ).thenAnswer((_) async {});

        const initialProfile = UserProfile(id: 'p1', name: 'Standard');
        final fake = _FakeActiveProfile(initialProfile);

        await pumpApp(
          tester,
          const SearchCriteriaScreen(),
          overrides: [
            ...test.overrides,
            selectedFuelTypeOverride(FuelType.diesel),
            searchRadiusOverride(15),
            userPositionNullOverride(),
            activeSearchModeOverride(SearchMode.route),
            routeSegmentSearchParamOverride(250),
            activeProfileProvider.overrideWith(() => fake),
          ],
        );

        await tester.tap(find.byKey(const ValueKey('criteria-overflow-menu')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('criteria-save-defaults-button')),
        );
        await tester.pumpAndSettle();

        expect(fake.updates, hasLength(1));
        // Route mode persists the route-segment override onto the profile.
        expect(fake.updates.single.routeSegmentKm, 250);
      },
    );

    testWidgets('has a close (X) button that pops the route', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

      await pumpApp(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => Navigator.of(ctx).push(
              MaterialPageRoute<void>(
                fullscreenDialog: true,
                builder: (_) => const SearchCriteriaScreen(),
              ),
            ),
            child: const Text('open'),
          ),
        ),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(8),
          userPositionNullOverride(),
        ],
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(SearchCriteriaScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(SearchCriteriaScreen), findsNothing);
    });

    testWidgets('#2131 — registers a SearchFabAction on mount (nearby mode)', (
      tester,
    ) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...test.overrides,
            selectedFuelTypeOverride(FuelType.e10),
            searchRadiusOverride(8),
            userPositionNullOverride(),
          ].cast(),
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: SearchCriteriaScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final action = container.read(searchFabActionControllerProvider);
      expect(
        action,
        isNotNull,
        reason: 'Criteria screen must publish a FAB action on mount.',
      );
      // Nearby mode is the default — FAB enabled, search icon.
      expect(action!.icon, Icons.search);
      expect(action.enabled, isTrue);
    });

    testWidgets('radius slider updates value', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

      await pumpApp(
        tester,
        const SearchCriteriaScreen(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(8),
          userPositionNullOverride(),
        ],
      );

      expect(find.text('8 km'), findsOneWidget);
    });

    group('#522 compaction + l10n', () {
      testWidgets('FR locale shows the localised location placeholder '
          '(not "Location search field")', (tester) async {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

        await pumpApp(
          tester,
          const SearchCriteriaScreen(),
          overrides: [
            ...test.overrides,
            selectedFuelTypeOverride(FuelType.e10),
            searchRadiusOverride(8),
            userPositionNullOverride(),
          ],
          locale: const Locale('fr'),
        );
        await tester.pumpAndSettle();

        // Regression guard: the English literal must never render.
        expect(find.text('Location search field'), findsNothing);
        // The French placeholder must be visible inside the location
        // field.
        expect(find.text('Adresse, code postal ou ville'), findsOneWidget);
      });

      testWidgets('FR locale renders the HelpBanner with the translated '
          '"Compris" dismiss button', (tester) async {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
        // Ensure the banner is shown (not previously dismissed).
        when(() => test.mockStorage.getSetting(any())).thenReturn(null);

        await pumpApp(
          tester,
          const SearchCriteriaScreen(),
          overrides: [
            ...test.overrides,
            selectedFuelTypeOverride(FuelType.e10),
            searchRadiusOverride(8),
            userPositionNullOverride(),
          ],
          locale: const Locale('fr'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Compris'), findsOneWidget);
        expect(find.text('Got it'), findsNothing);
      });

      testWidgets('form renders without a vertical overflow at the S23 Ultra '
          'surface size and 1x text scale', (tester) async {
        // #522 acceptance: every filter control fits above the fold.
        await tester.binding.setSurfaceSize(const Size(412, 915));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

        await pumpApp(
          tester,
          const SearchCriteriaScreen(),
          overrides: [
            ...test.overrides,
            selectedFuelTypeOverride(FuelType.e10),
            searchRadiusOverride(8),
            userPositionNullOverride(),
          ],
          locale: const Locale('fr'),
        );
        await tester.pumpAndSettle();

        // pumpAndSettle would have surfaced any RenderFlex overflow
        // errors via the tester.takeException() bucket. Draining and
        // asserting empty locks in the no-overflow invariant.
        expect(tester.takeException(), isNull);
      });
    });
  });

  // #3927 (Epic #3925) — the sheet's own action bar: a labelled primary
  // Search that explains its disabled state, a Reset that restores the
  // saved defaults, and the radius presets beside the slider.
  group('SearchCriteriaScreen — action bar + presets (#3927)', () {
    testWidgets('route mode without endpoints disables Search and says why', (
      tester,
    ) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

      await pumpApp(
        tester,
        const SearchCriteriaScreen(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(8),
          userPositionNullOverride(),
          activeSearchModeOverride(SearchMode.route),
        ],
      );

      final reason = find.byKey(const ValueKey('criteria-disabled-reason'));
      expect(reason, findsOneWidget);
      expect(
        tester.widget<Text>(reason).data,
        'Enter a start and a destination',
      );
      final submit = tester.widget<FilledButton>(
        find.byKey(const ValueKey('criteria-submit-button')),
      );
      expect(submit.onPressed, isNull);
    });

    testWidgets(
      'a radius preset chip sets the radius; Reset restores the saved default',
      (tester) async {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

        late ProviderContainer container;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...test.overrides,
              selectedFuelTypeOverride(FuelType.e10),
              searchRadiusOverride(8),
              userPositionNullOverride(),
            ].cast(),
            child: Consumer(
              builder: (context, ref, _) {
                container = ProviderScope.containerOf(context);
                return const MaterialApp(
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: SearchCriteriaScreen(),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(container.read(searchRadiusProvider), 8.0);

        final preset = find.byKey(const ValueKey('criteria-radius-preset-25'));
        await tester.ensureVisible(preset);
        await tester.pump();
        await tester.tap(preset);
        await tester.pumpAndSettle();
        expect(container.read(searchRadiusProvider), 25.0);

        await tester.tap(find.byKey(const ValueKey('criteria-reset-button')));
        await tester.pumpAndSettle();

        // Back to the saved default the provider builds from.
        expect(container.read(searchRadiusProvider), 8.0);
        expect(find.text('Criteria reset to your defaults'), findsOneWidget);
      },
    );

    testWidgets('no 50 km preset while the radius provider clamps at 25', (
      tester,
    ) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

      await pumpApp(
        tester,
        const SearchCriteriaScreen(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(8),
          userPositionNullOverride(),
        ],
      );

      expect(
        find.byKey(const ValueKey('criteria-radius-preset-5')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('criteria-radius-preset-50')),
        findsNothing,
        reason: 'SearchRadius.set clamps to 25 km — a 50 km chip would '
            'silently land on 25 and lie about what it did.',
      );
    });
  });
}
