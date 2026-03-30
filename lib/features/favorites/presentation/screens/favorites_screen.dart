import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../alerts/providers/alert_provider.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/presentation/widgets/station_card.dart';
import '../../providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(favoriteStationsProvider.notifier).loadAndRefresh();
    });
  }

  void _openStationInMaps(double lat, double lng, String label) {
    NavigationUtils.openInMaps(lat, lng, label: label);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final favoriteIds = ref.watch(favoritesProvider);
    final stationsState = ref.watch(favoriteStationsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n?.favorites ?? 'Favorites'),
          actions: [
            if (favoriteIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.read(favoriteStationsProvider.notifier).loadAndRefresh();
                },
                tooltip: l10n?.refreshPrices ?? 'Refresh prices',
              ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n?.favorites ?? 'Favorites'),
              Tab(text: l10n?.priceAlerts ?? 'Price Alerts'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFavoritesTab(context, l10n, favoriteIds, stationsState),
            _buildAlertsTab(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesTab(
    BuildContext context,
    AppLocalizations? l10n,
    List<String> favoriteIds,
    AsyncValue stationsState,
  ) {
    if (favoriteIds.isEmpty) {
      return Center(
        child: Semantics(
          label: 'No favorites yet. Tap the star on a station to save it as a favorite.',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_outline, size: 80, color: Colors.grey,
                semanticLabel: 'Empty favorites',
              ),
              const SizedBox(height: 24),
              Text(
                l10n?.noFavorites ?? 'No favorites yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  l10n?.noFavoritesHint ??
                  'Tap the star on a station to save it here',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.search),
                label: Text(l10n?.search ?? 'Search Stations'),
              ),
            ],
          ),
        ),
      );
    }

    return stationsState.when(
      data: (result) {
        if (result.data.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sync, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Loading favorites...',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.noFavoritesHint ?? 'Search for stations first so their data can be cached.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.search),
                    label: Text(l10n?.search ?? 'Search Stations'),
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(favoriteStationsProvider.notifier).loadAndRefresh();
          },
          child: Column(
            children: [
              ServiceStatusBanner(result: result),
              Expanded(
                child: ListView.builder(
                  itemCount: result.data.length,
                  itemBuilder: (context, index) {
                    final station = result.data[index];
                    final label = station.displayName;
                    // Swipe right → navigate, swipe left → remove favorite
                    return Dismissible(
                      key: ValueKey('fav-${station.id}'),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          _openStationInMaps(station.lat, station.lng, label);
                          return false;
                        } else {
                          // Remove favorite
                          ref.read(favoritesProvider.notifier).remove(station.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$label removed from favorites'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () => ref
                                    .read(favoritesProvider.notifier)
                                    .add(station.id, stationData: station),
                              ),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                          return true;
                        }
                      },
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 24),
                        color: Theme.of(context).colorScheme.primary,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.navigation, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Navigate',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        color: Colors.red,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Remove',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.delete, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                      child: StationCard(
                        key: ValueKey(station.id),
                        station: station,
                        selectedFuelType: FuelType.all,
                        isFavorite: true,
                        onTap: () => context.push('/station/${station.id}'),
                        onFavoriteTap: () {
                          ref.read(favoritesProvider.notifier).remove(station.id);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ref.read(favoriteStationsProvider.notifier).loadAndRefresh();
              },
              child: Text(l10n?.retry ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsTab(BuildContext context, AppLocalizations? l10n) {
    return Consumer(builder: (context, ref, _) {
      final alerts = ref.watch(alertProvider);
      if (alerts.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_off_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  l10n?.noPriceAlerts ?? 'No price alerts',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n?.noPriceAlertsHint ?? 'Create an alert from a station\'s detail page.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
      return ListView.builder(
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          // Swipe left to delete alert
          return Dismissible(
            key: ValueKey(alert.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              color: Colors.red,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Delete',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.delete, color: Colors.white, size: 20),
                ],
              ),
            ),
            onDismissed: (_) {
              ref.read(alertProvider.notifier).removeAlert(alert.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n?.alertDeleted(alert.stationName) ?? 'Alert "${alert.stationName}" deleted')),
              );
            },
            child: ListTile(
              leading: Icon(
                alert.isActive ? Icons.notifications_active : Icons.notifications_off,
                color: alert.isActive ? FuelColors.forType(alert.fuelType) : Colors.grey,
              ),
              title: Text(alert.stationName),
              subtitle: Text(
                '${alert.fuelType.displayName} \u2264 ${PriceFormatter.formatPrice(alert.targetPrice)}',
                style: TextStyle(color: alert.isActive ? FuelColors.forType(alert.fuelType) : Colors.grey),
              ),
              trailing: Switch(
                value: alert.isActive,
                onChanged: (_) => ref.read(alertProvider.notifier).toggleAlert(alert.id),
              ),
              // Tap to open station detail (shows price history)
              onTap: () => context.push('/station/${alert.stationId}'),
            ),
          );
        },
      );
    });
  }
}
