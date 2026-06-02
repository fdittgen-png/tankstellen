// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'search_results_list.dart';

/// Extracts fuel stations from the unified results list.
List<Station> _fuelStationsFrom(List<SearchResultItem> items) =>
    items.whereType<FuelStationResult>().map((r) => r.station).toList();

/// Computes which station has the cheapest price for each fuel type.
Map<String, Map<FuelType, bool>> _computeCheapestFlagsFor(
  List<Station> stations,
) {
  if (stations.isEmpty) return {};

  final cheapest = <FuelType, double>{};
  final cheapestIds = <FuelType, String>{};

  const fuelTypes = [
    FuelType.e5,
    FuelType.e10,
    FuelType.e98,
    FuelType.diesel,
    FuelType.dieselPremium,
    FuelType.e85,
    FuelType.lpg,
    FuelType.cng,
  ];

  for (final ft in fuelTypes) {
    for (final s in stations) {
      final price = s.priceFor(ft);
      if (price != null && price > 0) {
        if (!cheapest.containsKey(ft) || price < cheapest[ft]!) {
          cheapest[ft] = price;
          cheapestIds[ft] = s.id;
        }
      }
    }
  }

  final result = <String, Map<FuelType, bool>>{};
  for (final entry in cheapestIds.entries) {
    result.putIfAbsent(entry.value, () => {});
    result[entry.value]![entry.key] = true;
  }
  return result;
}

/// Get min/max price range for tier classification. Delegates to the
/// shared [priceRange] helper (#2182); the search list excludes
/// zero/sentinel prices from its tiers, hence `requirePositive: true`.
(double, double) _getPriceRangeFor(List<Station> stations, FuelType fuel) =>
    priceRange(stations, fuel, requirePositive: true);

/// Collapsible section that wraps [BrandFilterChips] inside an expandable
/// toggle. When collapsed, only a "Brands" label with a chevron is shown.
class _CollapsibleBrandFilters extends ConsumerWidget {
  final List<Station> stations;

  const _CollapsibleBrandFilters({required this.stations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(brandFiltersExpandedProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selectedBrands = ref.watch(selectedBrandsProvider);
    final excludeHighway = ref.watch(excludeHighwayStationsProvider);
    final hasActiveFilters =
        selectedBrands.isNotEmpty || excludeHighway;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () =>
              ref.read(brandFiltersExpandedProvider.notifier).toggle(),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 16,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  l10n?.brandFilterAll ?? 'Brands',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (hasActiveFilters) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  expanded
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: BrandFilterChips(stations: stations),
          secondChild: const SizedBox.shrink(),
          crossFadeState: expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

/// #2675 — header affordance that runs the on-search Fuel Station Radar: a
/// one-shot, cache-first scan around the user's persisted position whose
/// stations render in this same list (the polymorphic switch builds them as
/// fuel cards). Mirrors the map button's Semantics + Tooltip + InkWell pair.
class _RadarSearchButton extends ConsumerWidget {
  const _RadarSearchButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final label = l10n?.fuelStationRadarButtonTooltip ??
        'Search with Fuel Station Radar';
    return Semantics(
      label: label,
      button: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          key: const Key('radarSearchButton'),
          onTap: () => ref.read(radarSearchProvider.notifier).runRadar(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Icon(Icons.radar,
                size: 18, color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
    );
  }
}

/// Toggle button to switch between compact card view and all-prices detail view.
class _ViewToggleButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPrices = ref.watch(allPricesViewEnabledProvider);
    final l10n = AppLocalizations.of(context);

    final label = allPrices
        ? (l10n?.switchToCompactView ?? 'Switch to compact view')
        : (l10n?.switchToAllPricesView ?? 'Switch to all-prices view');

    return Semantics(
      label: label,
      button: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: () => ref
              .read(allPricesViewEnabledProvider.notifier)
              .toggle(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Icon(
              allPrices ? Icons.view_list : Icons.view_agenda,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
