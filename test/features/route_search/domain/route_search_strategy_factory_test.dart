import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/route_search/data/strategies/balanced_search_strategy.dart';
import 'package:tankstellen/features/route_search/data/strategies/cheapest_search_strategy.dart';
import 'package:tankstellen/features/route_search/data/strategies/eco_route_search_strategy.dart';
import 'package:tankstellen/features/route_search/data/strategies/uniform_search_strategy.dart';
import 'package:tankstellen/features/route_search/domain/route_search_strategy.dart';
import 'package:tankstellen/features/route_search/domain/route_search_strategy_factory.dart';

void main() {
  group('strategyFor', () {
    test('uniform → UniformSearchStrategy (and RouteSearchStrategy)', () {
      final s = strategyFor(RouteSearchStrategyType.uniform);
      expect(s, isA<UniformSearchStrategy>());
      expect(s, isA<RouteSearchStrategy>());
    });

    test('cheapest → CheapestSearchStrategy (and RouteSearchStrategy)', () {
      final s = strategyFor(RouteSearchStrategyType.cheapest);
      expect(s, isA<CheapestSearchStrategy>());
      expect(s, isA<RouteSearchStrategy>());
    });

    test('balanced → BalancedSearchStrategy (and RouteSearchStrategy)', () {
      final s = strategyFor(RouteSearchStrategyType.balanced);
      expect(s, isA<BalancedSearchStrategy>());
      expect(s, isA<RouteSearchStrategy>());
    });

    test('eco → EcoRouteSearchStrategy (and RouteSearchStrategy)', () {
      final s = strategyFor(RouteSearchStrategyType.eco);
      expect(s, isA<EcoRouteSearchStrategy>());
      expect(s, isA<RouteSearchStrategy>());
    });

    test('every produced strategy exposes a non-empty name', () {
      // Smoke check the abstract contract — also exercises the
      // strategies' name getters which would otherwise show as
      // zero-coverage in lcov.
      for (final type in RouteSearchStrategyType.values) {
        final s = strategyFor(type);
        expect(s.name, isNotEmpty,
            reason: '${type.key} strategy should expose a non-empty name');
      }
    });

    test('returns a fresh instance on each call (no hidden singleton)', () {
      // Guards against an accidental cached/singleton refactor — strategies
      // currently hold no shared mutable state, but a future change that
      // memoises them would change semantics for callers expecting
      // independent instances.
      for (final type in RouteSearchStrategyType.values) {
        final a = strategyFor(type);
        final b = strategyFor(type);
        expect(identical(a, b), isFalse,
            reason: '${type.key} should produce distinct instances');
      }
    });
  });
}
