import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/service_result.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/utils/price_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../domain/entities/station.dart';
import '../../providers/ignored_stations_provider.dart';
import '../../providers/search_provider.dart';
import 'cross_border_banner.dart';
import 'sort_selector.dart';
import 'swipeable_station_card.dart';

/// Station list with sort controls, refresh, count bar, and search location header.
class SearchResultsList extends ConsumerStatefulWidget {
  final ServiceResult<List<Station>> result;
  final VoidCallback onRefresh;

  const SearchResultsList({
    super.key,
    required this.result,
    required this.onRefresh,
  });

  @override
  ConsumerState<SearchResultsList> createState() => _SearchResultsListState();
}

class _SearchResultsListState extends ConsumerState<SearchResultsList> {
  SortMode _sortMode = SortMode.distance;

  void _openStationInMaps(Station station) {
    NavigationUtils.openInMaps(
      station.lat, station.lng,
      label: station.displayName,
    );
  }

  List<Station> _sortStations(List<Station> stations) {
    final sorted = List<Station>.from(stations);
    final fuelType = ref.read(selectedFuelTypeProvider);

    switch (_sortMode) {
      case SortMode.distance:
        sorted.sort((a, b) => a.dist.compareTo(b.dist));
      case SortMode.price:
        sorted.sort((a, b) => compareByPrice(a, b, fuelType));
      case SortMode.name:
        sorted.sort((a, b) => compareByName(a, b));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final l10n = AppLocalizations.of(context);
    final ignoredIds = ref.watch(ignoredStationsProvider);

    return Column(
      children: [
        ServiceStatusBanner(result: result),
        // Compact header: location + count + sort in minimal space
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Builder(builder: (ctx) {
                  final location = ref.watch(searchLocationProvider);
                  return Text(
                    location.isNotEmpty
                        ? '$location · ${result.data.length}'
                        : l10n?.stationsFound(result.data.length) ??
                            '${result.data.length} stations',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  );
                }),
              ),
              Semantics(
                label: 'Show stations on map',
                button: true,
                child: InkWell(
                  onTap: () => context.go('/map'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Icon(Icons.map, size: 18,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                result.freshnessLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const CrossBorderBanner(),
        SortSelector(
          selected: _sortMode,
          onChanged: (mode) => setState(() => _sortMode = mode),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => widget.onRefresh(),
            child: Builder(builder: (context) {
              // Filter out ignored stations
              final filtered = result.data
                  .where((s) => !ignoredIds.contains(s.id))
                  .toList();
              final sorted = _sortStations(filtered);
              return ListView.builder(
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final station = sorted[index];
                  final isFav = ref.watch(isFavoriteProvider(station.id));
                  return SwipeableStationCard(
                    key: ValueKey('station-${station.id}'),
                    station: station,
                    isFavorite: isFav,
                    onNavigate: () => _openStationInMaps(station),
                    onIgnore: () {
                      ref.read(ignoredStationsProvider.notifier).add(station.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${station.displayName} hidden'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () => ref
                                .read(ignoredStationsProvider.notifier)
                                .remove(station.id),
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
                    onTap: () => context.push('/station/${station.id}'),
                    onFavoriteTap: () => ref
                        .read(favoritesProvider.notifier)
                        .toggle(station.id, stationData: station),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }
}
