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

/// Get min/max price range for tier classification.
(double, double) _getPriceRangeFor(List<Station> stations, FuelType fuel) {
  double minP = double.infinity;
  double maxP = 0;
  for (final s in stations) {
    final p = s.priceFor(fuel);
    if (p != null && p > 0) {
      if (p < minP) minP = p;
      if (p > maxP) maxP = p;
    }
  }
  if (minP == double.infinity) return (0.0, 0.0);
  return (minP, maxP);
}

List<SearchResultItem> _sortSearchResults(
  List<SearchResultItem> items,
  SortMode sortMode,
  WidgetRef ref,
) {
  final sorted = List<SearchResultItem>.from(items);
  final fuelType = ref.read(selectedFuelTypeProvider);

  if (sorted.every((item) => item is EVStationResult)) {
    sorted.sort((a, b) => a.dist.compareTo(b.dist));
    return sorted;
  }

  switch (sortMode) {
    case SortMode.distance:
      sorted.sort((a, b) => a.dist.compareTo(b.dist));
    case SortMode.price:
      sorted.sort((a, b) {
        final sa = a is FuelStationResult ? a.station : null;
        final sb = b is FuelStationResult ? b.station : null;
        if (sa != null && sb != null) return compareByPrice(sa, sb, fuelType);
        return a.dist.compareTo(b.dist);
      });
    case SortMode.name:
      sorted.sort((a, b) {
        final sa = a is FuelStationResult ? a.station : null;
        final sb = b is FuelStationResult ? b.station : null;
        if (sa != null && sb != null) return compareByName(sa, sb);
        return a.displayName.compareTo(b.displayName);
      });
    case SortMode.open24h:
      sorted.sort((a, b) {
        final sa = a is FuelStationResult ? a.station : null;
        final sb = b is FuelStationResult ? b.station : null;
        if (sa != null && sb != null) return compareByOpen24h(sa, sb);
        return a.dist.compareTo(b.dist);
      });
    case SortMode.rating:
      final ratings = ref.read(stationRatingsProvider);
      sorted.sort((a, b) {
        final sa = a is FuelStationResult ? a.station : null;
        final sb = b is FuelStationResult ? b.station : null;
        if (sa != null && sb != null) return compareByRating(sa, sb, ratings);
        return a.dist.compareTo(b.dist);
      });
    case SortMode.priceDistance:
      sorted.sort((a, b) {
        final sa = a is FuelStationResult ? a.station : null;
        final sb = b is FuelStationResult ? b.station : null;
        if (sa != null && sb != null) {
          return compareByPriceDistance(sa, sb, fuelType);
        }
        return a.dist.compareTo(b.dist);
      });
  }
  return sorted;
}

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
