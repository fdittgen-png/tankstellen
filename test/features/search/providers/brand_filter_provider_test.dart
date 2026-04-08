import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/providers/brand_filter_provider.dart';

void main() {
  group('SelectedBrandsProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('initial state is empty set (all brands shown)', () {
      expect(container.read(selectedBrandsProvider), isEmpty);
    });

    test('toggle adds a brand', () {
      container.read(selectedBrandsProvider.notifier).toggle('SHELL');
      expect(container.read(selectedBrandsProvider), {'SHELL'});
    });

    test('toggle removes a brand when already selected', () {
      container.read(selectedBrandsProvider.notifier).toggle('SHELL');
      container.read(selectedBrandsProvider.notifier).toggle('SHELL');
      expect(container.read(selectedBrandsProvider), isEmpty);
    });

    test('multiple brands can be selected', () {
      container.read(selectedBrandsProvider.notifier).toggle('SHELL');
      container.read(selectedBrandsProvider.notifier).toggle('ARAL');
      expect(container.read(selectedBrandsProvider), {'SHELL', 'ARAL'});
    });

    test('clear resets to empty set', () {
      container.read(selectedBrandsProvider.notifier).toggle('SHELL');
      container.read(selectedBrandsProvider.notifier).toggle('ARAL');
      container.read(selectedBrandsProvider.notifier).clear();
      expect(container.read(selectedBrandsProvider), isEmpty);
    });

    test('selectOnly sets exactly one brand', () {
      container.read(selectedBrandsProvider.notifier).toggle('SHELL');
      container.read(selectedBrandsProvider.notifier).toggle('ARAL');
      container.read(selectedBrandsProvider.notifier).selectOnly('JET');
      expect(container.read(selectedBrandsProvider), {'JET'});
    });
  });

  group('ExcludeHighwayStationsProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('initial state is false', () {
      expect(container.read(excludeHighwayStationsProvider), isFalse);
    });

    test('toggle flips to true', () {
      container.read(excludeHighwayStationsProvider.notifier).toggle();
      expect(container.read(excludeHighwayStationsProvider), isTrue);
    });

    test('toggle twice returns to false', () {
      container.read(excludeHighwayStationsProvider.notifier).toggle();
      container.read(excludeHighwayStationsProvider.notifier).toggle();
      expect(container.read(excludeHighwayStationsProvider), isFalse);
    });

    test('set explicitly sets value', () {
      container.read(excludeHighwayStationsProvider.notifier).set(true);
      expect(container.read(excludeHighwayStationsProvider), isTrue);
      container.read(excludeHighwayStationsProvider.notifier).set(false);
      expect(container.read(excludeHighwayStationsProvider), isFalse);
    });
  });
}
