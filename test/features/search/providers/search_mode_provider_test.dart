import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/providers/search_mode_provider.dart';

void main() {
  group('ActiveSearchMode', () {
    test('initial state is SearchMode.nearby', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(activeSearchModeProvider), SearchMode.nearby);
    });

    test('set changes state to route', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(activeSearchModeProvider.notifier).set(SearchMode.route);

      expect(container.read(activeSearchModeProvider), SearchMode.route);
    });

    test('set changes state back to nearby', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(activeSearchModeProvider.notifier).set(SearchMode.route);
      container.read(activeSearchModeProvider.notifier).set(SearchMode.nearby);

      expect(container.read(activeSearchModeProvider), SearchMode.nearby);
    });
  });

  group('SearchMode enum', () {
    test('nearby has correct apiValue', () {
      expect(SearchMode.nearby.apiValue, 'nearby');
    });

    test('route has correct apiValue', () {
      expect(SearchMode.route.apiValue, 'route');
    });

    test('nearby has correct displayName', () {
      expect(SearchMode.nearby.displayName, 'Around me');
    });

    test('route has correct displayName', () {
      expect(SearchMode.route.displayName, 'Along route');
    });

    test('enum has exactly 2 values', () {
      expect(SearchMode.values.length, 2);
    });
  });
}
