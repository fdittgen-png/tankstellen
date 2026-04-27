import '../data/strategies/balanced_search_strategy.dart';
import '../data/strategies/cheapest_search_strategy.dart';
import '../data/strategies/eco_route_search_strategy.dart';
import '../data/strategies/uniform_search_strategy.dart';
import 'route_search_strategy.dart';

/// Factory to get the right strategy implementation.
RouteSearchStrategy strategyFor(RouteSearchStrategyType type) {
  switch (type) {
    case RouteSearchStrategyType.uniform:
      return UniformSearchStrategy();
    case RouteSearchStrategyType.cheapest:
      return CheapestSearchStrategy();
    case RouteSearchStrategyType.balanced:
      return BalancedSearchStrategy();
    case RouteSearchStrategyType.eco:
      return EcoRouteSearchStrategy();
  }
}
