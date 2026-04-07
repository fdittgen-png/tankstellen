import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/route_search/domain/route_search_strategy.dart';
import 'package:tankstellen/features/search/providers/search_screen_ui_provider.dart';

void main() {
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
