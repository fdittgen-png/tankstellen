import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../route_search/presentation/widgets/route_input.dart';
import '../../../route_search/domain/entities/route_info.dart';
import '../../../route_search/domain/route_search_strategy.dart';
import 'fuel_type_selector.dart';

/// Controls for "Route" search mode: route input, fuel type selector,
/// strategy selector chips, and a link to saved routes.
class RouteSearchControls extends ConsumerWidget {
  const RouteSearchControls({
    super.key,
    required this.onSearch,
    required this.selectedStrategy,
    required this.onStrategyChanged,
  });

  /// Callback when the user triggers a route search with waypoints.
  final ValueChanged<List<RouteWaypoint>> onSearch;

  /// The currently selected route search strategy.
  final RouteSearchStrategyType selectedStrategy;

  /// Called when the user picks a different strategy chip.
  final ValueChanged<RouteSearchStrategyType> onStrategyChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RouteInput(onSearch: (waypoints) => onSearch(waypoints)),
        const SizedBox(height: 4),
        const FuelTypeSelector(),
        const SizedBox(height: 4),
        // Strategy selector chips
        Row(
          children: [
            Text('Strategy:', style: theme.textTheme.bodySmall),
            const SizedBox(width: 8),
            for (final strategy in RouteSearchStrategyType.values)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ChoiceChip(
                  label: Text(
                    _strategyLabel(strategy, l10n),
                    style: const TextStyle(fontSize: 11),
                  ),
                  selected: selectedStrategy == strategy,
                  onSelected: (_) => onStrategyChanged(strategy),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        // Saved routes link
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.push('/itineraries'),
            icon: const Icon(Icons.bookmark, size: 16),
            label: Text(
              l10n?.savedRoutes ?? 'Saved routes',
              style: theme.textTheme.bodySmall,
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
          ),
        ),
      ],
    );
  }

  String _strategyLabel(RouteSearchStrategyType type, AppLocalizations? l10n) {
    switch (type) {
      case RouteSearchStrategyType.uniform:
        return 'Uniform';
      case RouteSearchStrategyType.cheapest:
        return l10n?.cheapest ?? 'Cheapest';
      case RouteSearchStrategyType.balanced:
        return 'Balanced';
    }
  }
}
