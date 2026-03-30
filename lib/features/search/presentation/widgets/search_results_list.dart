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
import 'sort_selector.dart';
import 'station_card.dart';

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
                  return _SwipeableStationCard(
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

/// Station card with bidirectional swipe:
/// - Swipe right → open in maps/navigation
/// - Swipe left → ignore/hide station
class _SwipeableStationCard extends ConsumerWidget {
  final Station station;
  final bool isFavorite;
  final VoidCallback onNavigate;
  final VoidCallback onIgnore;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const _SwipeableStationCard({
    required this.station,
    required this.isFavorite,
    required this.onNavigate,
    required this.onIgnore,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey('swipe-${station.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onNavigate();
          return false; // Don't dismiss — just trigger navigation
        } else {
          onIgnore();
          return true; // Dismiss — remove from list
        }
      },
      // Swipe right background → Navigate
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        color: theme.colorScheme.primary,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.navigation, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(l10n?.navigate ?? 'Navigate',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      // Swipe left background → Ignore
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.orange.shade700,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Hide',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Icon(Icons.visibility_off, color: Colors.white, size: 20),
          ],
        ),
      ),
      child: StationCard(
        station: station,
        selectedFuelType: ref.watch(selectedFuelTypeProvider),
        isFavorite: isFavorite,
        onTap: onTap,
        onFavoriteTap: onFavoriteTap,
      ),
    );
  }
}
