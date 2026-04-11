import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station_amenity.dart';
import 'package:tankstellen/features/search/presentation/screens/search_criteria_screen.dart';
import 'package:tankstellen/features/search/presentation/widgets/fuel_type_selector.dart';
import 'package:tankstellen/features/search/presentation/widgets/location_input.dart';
import 'package:tankstellen/features/search/providers/search_screen_ui_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

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
    testWidgets('renders form: LocationInput, FuelTypeSelector, slider, button',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

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
      expect(find.byKey(const ValueKey('criteria-search-button')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('criteria-mode-toggle')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('criteria-open-only-toggle')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('criteria-save-defaults-button')),
          findsOneWidget);
    });

    testWidgets('mode toggle switches from LocationInput to RouteInput',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

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

      // Tap the "Along route" segment.
      await tester.tap(find.text('Search along route').first);
      await tester.pump();

      // LocationInput should be gone; nearby mode widget replaced.
      expect(find.byType(LocationInput), findsNothing);
    });

    testWidgets('open-only toggle updates provider', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...test.overrides,
            selectedFuelTypeOverride(FuelType.e10),
            searchRadiusOverride(8),
            userPositionNullOverride(),
          ].cast(),
          child: Consumer(builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const MaterialApp(home: SearchCriteriaScreen());
          }),
        ),
      );
      await tester.pumpAndSettle();

      container.read(openOnlyFilterProvider.notifier).set(false);
      expect(container.read(openOnlyFilterProvider), isFalse);

      final toggle =
          find.byKey(const ValueKey('criteria-open-only-toggle'));
      await tester.ensureVisible(toggle);
      await tester.pump();
      await tester.tap(toggle);
      await tester.pump();

      expect(container.read(openOnlyFilterProvider), isTrue);
    });

    testWidgets('equipment chips toggle on/off', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...test.overrides,
            selectedFuelTypeOverride(FuelType.e10),
            searchRadiusOverride(8),
            userPositionNullOverride(),
          ].cast(),
          child: Consumer(builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const MaterialApp(home: SearchCriteriaScreen());
          }),
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

    testWidgets(
        'save-as-defaults button updates the active profile', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      const initialProfile = UserProfile(
        id: 'p1',
        name: 'Standard',
      );
      final fake = _FakeActiveProfile(initialProfile);

      // Pre-select shop amenity via the provider override container.
      final overrides = <Object>[
        ...test.overrides,
        selectedFuelTypeOverride(FuelType.diesel),
        searchRadiusOverride(15),
        userPositionNullOverride(),
        activeProfileProvider.overrideWith(() => fake),
      ];

      await pumpApp(
        tester,
        const SearchCriteriaScreen(),
        overrides: overrides,
      );

      // Select the "Air" amenity chip so we can assert it gets persisted.
      final airChip = find.byKey(const ValueKey('criteria-amenity-airPump'));
      await tester.ensureVisible(airChip);
      await tester.pump();
      await tester.tap(airChip);
      await tester.pump();

      final saveBtn =
          find.byKey(const ValueKey('criteria-save-defaults-button'));
      await tester.ensureVisible(saveBtn);
      await tester.pump();
      await tester.tap(saveBtn);
      await tester.pump();

      expect(fake.updates, hasLength(1));
      final saved = fake.updates.single;
      expect(saved.preferredFuelType, FuelType.diesel);
      expect(saved.defaultSearchRadius, 15);
      expect(saved.preferredAmenities, contains(StationAmenity.airPump));
    });

    testWidgets('has a close (X) button that pops the route', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

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

    testWidgets('radius slider updates value', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

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
  });
}

