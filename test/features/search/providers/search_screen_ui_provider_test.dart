import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/route_search/domain/route_search_strategy.dart';
import 'package:tankstellen/features/search/presentation/widgets/sort_selector.dart';
import 'package:tankstellen/features/search/providers/search_screen_ui_provider.dart';

ProviderContainer _containerWithLanding(LandingScreen? landing) {
  final profile = landing == null
      ? null
      : UserProfile(id: 't', name: 'T', landingScreen: landing);
  final container = ProviderContainer(
    overrides: [
      activeProfileProvider.overrideWith(() => _FakeActive(profile)),
    ],
  );
  return container;
}

class _FakeActive extends ActiveProfile {
  _FakeActive(this._profile);
  final UserProfile? _profile;
  @override
  UserProfile? build() => _profile;
}

void main() {
  group('SelectedSortMode default derived from landing preference', () {
    test('no profile → distance', () {
      final container = _containerWithLanding(null);
      addTearDown(container.dispose);
      expect(container.read(selectedSortModeProvider), SortMode.distance);
    });

    test('cheapest landing → price sort', () {
      final container = _containerWithLanding(LandingScreen.cheapest);
      addTearDown(container.dispose);
      expect(container.read(selectedSortModeProvider), SortMode.price);
    });

    test('nearest landing → distance sort', () {
      final container = _containerWithLanding(LandingScreen.nearest);
      addTearDown(container.dispose);
      expect(container.read(selectedSortModeProvider), SortMode.distance);
    });

    test('favorites landing → distance sort', () {
      final container = _containerWithLanding(LandingScreen.favorites);
      addTearDown(container.dispose);
      expect(container.read(selectedSortModeProvider), SortMode.distance);
    });

    test('map landing → distance sort', () {
      final container = _containerWithLanding(LandingScreen.map);
      addTearDown(container.dispose);
      expect(container.read(selectedSortModeProvider), SortMode.distance);
    });

    test('set() overrides the derived default', () {
      final container = _containerWithLanding(LandingScreen.cheapest);
      addTearDown(container.dispose);
      expect(container.read(selectedSortModeProvider), SortMode.price);
      container.read(selectedSortModeProvider.notifier).set(SortMode.rating);
      expect(container.read(selectedSortModeProvider), SortMode.rating);
    });
  });

  group('FiltersExpanded', () {
    test('defaults to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(filtersExpandedProvider), isTrue);
    });

    test('set(false) collapses filters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(filtersExpandedProvider.notifier).set(false);
      expect(container.read(filtersExpandedProvider), isFalse);
    });

    test('collapse() sets state to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(filtersExpandedProvider), isTrue);
      container.read(filtersExpandedProvider.notifier).collapse();
      expect(container.read(filtersExpandedProvider), isFalse);
    });

    test('toggle() flips state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(filtersExpandedProvider), isTrue);
      container.read(filtersExpandedProvider.notifier).toggle();
      expect(container.read(filtersExpandedProvider), isFalse);
      container.read(filtersExpandedProvider.notifier).toggle();
      expect(container.read(filtersExpandedProvider), isTrue);
    });

    test('set(true) expands filters after collapse', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(filtersExpandedProvider.notifier).collapse();
      expect(container.read(filtersExpandedProvider), isFalse);
      container.read(filtersExpandedProvider.notifier).set(true);
      expect(container.read(filtersExpandedProvider), isTrue);
    });
  });

  group('SelectedRouteStrategy', () {
    test('defaults to uniform', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(selectedRouteStrategyProvider),
        RouteSearchStrategyType.uniform,
      );
    });

    test('set() changes strategy', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(selectedRouteStrategyProvider.notifier)
          .set(RouteSearchStrategyType.cheapest);
      expect(
        container.read(selectedRouteStrategyProvider),
        RouteSearchStrategyType.cheapest,
      );
    });

    test('set() to balanced strategy', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(selectedRouteStrategyProvider.notifier)
          .set(RouteSearchStrategyType.balanced);
      expect(
        container.read(selectedRouteStrategyProvider),
        RouteSearchStrategyType.balanced,
      );
    });

    test('can cycle through all strategies', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      for (final strategy in RouteSearchStrategyType.values) {
        container.read(selectedRouteStrategyProvider.notifier).set(strategy);
        expect(container.read(selectedRouteStrategyProvider), strategy);
      }
    });
  });

  group('BrandFiltersExpanded', () {
    test('defaults to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(brandFiltersExpandedProvider), isFalse);
    });

    test('set(true) expands brand filters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(brandFiltersExpandedProvider.notifier).set(true);
      expect(container.read(brandFiltersExpandedProvider), isTrue);
    });

    test('toggle() flips state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(brandFiltersExpandedProvider), isFalse);
      container.read(brandFiltersExpandedProvider.notifier).toggle();
      expect(container.read(brandFiltersExpandedProvider), isTrue);
      container.read(brandFiltersExpandedProvider.notifier).toggle();
      expect(container.read(brandFiltersExpandedProvider), isFalse);
    });

    test('set(false) collapses after expansion', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(brandFiltersExpandedProvider.notifier).set(true);
      container.read(brandFiltersExpandedProvider.notifier).set(false);
      expect(container.read(brandFiltersExpandedProvider), isFalse);
    });
  });

  group('AllPricesViewEnabled', () {
    test('defaults to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(allPricesViewEnabledProvider), isFalse);
    });

    test('toggle() flips state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(allPricesViewEnabledProvider), isFalse);
      container.read(allPricesViewEnabledProvider.notifier).toggle();
      expect(container.read(allPricesViewEnabledProvider), isTrue);
      container.read(allPricesViewEnabledProvider.notifier).toggle();
      expect(container.read(allPricesViewEnabledProvider), isFalse);
    });

    test('set(true) enables all-prices view', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(allPricesViewEnabledProvider.notifier).set(true);
      expect(container.read(allPricesViewEnabledProvider), isTrue);
    });

    test('set(false) disables all-prices view', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(allPricesViewEnabledProvider.notifier).set(true);
      container.read(allPricesViewEnabledProvider.notifier).set(false);
      expect(container.read(allPricesViewEnabledProvider), isFalse);
    });
  });
}
