import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../route_search/data/strategies/eco_route_search_strategy.dart';
import '../../../route_search/presentation/widgets/route_input.dart';
import '../../../route_search/domain/entities/route_info.dart';
import '../../../route_search/domain/route_search_strategy.dart';
import '../../../route_search/providers/route_input_provider.dart';
import '../../providers/search_screen_ui_provider.dart';
import 'fuel_type_selector.dart';

/// Controls for "Route" search mode: route input, fuel type selector,
/// strategy selector chips, and a link to saved routes.
class RouteSearchControls extends ConsumerWidget {
  const RouteSearchControls({
    super.key,
    required this.onSearch,
  });

  /// Callback when the user triggers a route search with waypoints.
  final ValueChanged<List<RouteWaypoint>> onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedStrategy = ref.watch(selectedRouteStrategyProvider);
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
                  onSelected: (_) => ref
                      .read(selectedRouteStrategyProvider.notifier)
                      .set(strategy),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        // Eco strategy savings preview + hint (#1123). Wheel-lens
        // 10/10: when the user picks Eco, surface what they're
        // about to save *before* they commit to the search.
        if (selectedStrategy == RouteSearchStrategyType.eco)
          const _EcoSavingsPreview(),
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
      case RouteSearchStrategyType.eco:
        return l10n?.ecoRouteOption ?? 'Eco';
    }
  }
}

/// Predicted-savings preview shown beneath the strategy chips when
/// Eco is selected (#1123). Watches the resolved start/end coords
/// from [routeInputControllerProvider] and computes a rough
/// litres-saved estimate based on straight-line distance × a typical
/// road-factor × the eco efficiency uplift.
///
/// Before the user has both endpoints resolved we render only the
/// hint caption — without coords there is nothing honest to estimate.
class _EcoSavingsPreview extends ConsumerWidget {
  const _EcoSavingsPreview();

  /// Multiplier from straight-line Haversine to expected driving
  /// distance. 1.3 is a defensible average for European motorway +
  /// B-road mixes; OSRM-resolved distances on common test routes
  /// (Berlin↔Hamburg, Lyon↔Marseille) sit between 1.20 and 1.35.
  static const double _roadFactor = 1.3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final input = ref.watch(routeInputControllerProvider);

    final start = input.startCoords;
    final end = input.endCoords;

    String? savingsLine;
    if (start != null && end != null) {
      final straight = distanceKm(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );
      final est = straight * _roadFactor;
      final litersSaved = EcoSavingsEstimator.estimateLitersSaved(
        fastestDistanceKm: est,
        ecoDistanceKm: est,
        consumptionLPer100km:
            EcoSavingsEstimator.defaultConsumptionLPer100km,
      );
      if (litersSaved > 0) {
        final formatted = litersSaved.toStringAsFixed(1);
        savingsLine = (l10n?.ecoRouteSavings(formatted)) ??
            '≈ $formatted L saved';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4, right: 4, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (savingsLine != null)
            Row(
              key: const ValueKey('ecoSavingsLine'),
              children: [
                Icon(
                  Icons.eco,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  savingsLine,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          Text(
            l10n?.ecoRouteHint ??
                'Smarter drive — favours steady highway over zigzag shortcuts.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
