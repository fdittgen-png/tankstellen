import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/route_search/domain/route_search_strategy.dart';

void main() {
  group('RouteSearchStrategyType', () {
    test('four strategies are defined: uniform, cheapest, balanced, eco', () {
      // Guards against a silent new strategy being added without
      // updating the strategy-factory + l10n keys elsewhere.
      expect(
        RouteSearchStrategyType.values.map((s) => s.key).toSet(),
        {'uniform', 'cheapest', 'balanced', 'eco'},
      );
    });

    test('keys are stable (used as persistence tokens)', () {
      // The `key` is what gets stored in the profile; renaming it
      // would orphan existing user data, so pin the exact strings.
      expect(RouteSearchStrategyType.uniform.key, 'uniform');
      expect(RouteSearchStrategyType.cheapest.key, 'cheapest');
      expect(RouteSearchStrategyType.balanced.key, 'balanced');
      expect(RouteSearchStrategyType.eco.key, 'eco');
    });

    test('every strategy has a non-empty distinct l10nKey', () {
      final l10nKeys =
          RouteSearchStrategyType.values.map((s) => s.l10nKey).toSet();
      expect(l10nKeys.length, RouteSearchStrategyType.values.length);
      for (final k in l10nKeys) {
        expect(k, isNotEmpty);
      }
    });

    test('l10nKeys follow the *Search naming convention', () {
      // Pinned so ARB lookups continue working — the UI looks up
      // this exact key.
      for (final s in RouteSearchStrategyType.values) {
        expect(s.l10nKey, endsWith('Search'),
            reason: '${s.name} l10nKey should end with "Search"');
      }
    });
  });
}
