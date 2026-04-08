import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/service_result.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../search/domain/entities/station.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/presentation/widgets/station_card.dart';
import '../../providers/favorites_provider.dart';
import '../widgets/alerts_tab.dart';
import '../widgets/favorites_loading_view.dart';

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

    // Reload favorites when the auth identity changes
    // (anonymous -> email, reconnect, disconnect, etc.)
    ref.listen(
      syncStateProvider.select((s) => s.userId),
      (prev, next) {
        if (prev != next) {
          ref.read(favoriteStationsProvider.notifier).loadAndRefresh();
        }
      },
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Semantics(
            header: true,
            child: Text(l10n?.favorites ?? 'Favorites'),
          ),
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
            const AlertsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesTab(
    BuildContext context,
    AppLocalizations? l10n,
    List<String> favoriteIds,
    AsyncValue<ServiceResult<List<Station>>> stationsState,
  ) {
    if (favoriteIds.isEmpty) {
      return Semantics(
        label:
            'No favorites yet. Tap the star on a station to save it as a favorite.',
        child: EmptyState(
          icon: Icons.star_outline,
          iconSize: 80,
          title: l10n?.noFavorites ?? 'No favorites yet',
          subtitle: l10n?.noFavoritesHint ??
              'Tap the star on a station to save it here',
          actionLabel: l10n?.search ?? 'Search Stations',
          onAction: () => context.go('/'),
        ),
      );
    }

    return stationsState.when(
      data: (result) {
        if (result.data.isEmpty) {
          return const FavoritesLoadingView();
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
                    // Swipe right -> navigate, swipe left -> remove favorite
                    return Dismissible(
                      key: ValueKey('fav-${station.id}'),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          _openStationInMaps(station.lat, station.lng, label);
                          return false;
                        } else {
                          // Remove favorite
                          ref
                              .read(favoritesProvider.notifier)
                              .remove(station.id);
                          final l10nSnack = AppLocalizations.of(context);
                          SnackBarHelper.showWithUndo(
                            context,
                            l10nSnack?.removedFromFavoritesName(label) ??
                                '$label removed from favorites',
                            undoLabel: l10nSnack?.undo ?? 'Undo',
                            onUndo: () => ref
                                .read(favoritesProvider.notifier)
                                .add(station.id, stationData: station),
                          );
                          return true;
                        }
                      },
                      background: Semantics(
                        label: 'Navigate to $label',
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 24),
                          color: Theme.of(context).colorScheme.primary,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.navigation,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Navigate',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      secondaryBackground: Semantics(
                        label: 'Remove $label from favorites',
                        child: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          color: Colors.red,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Remove',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Icon(Icons.delete, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                      child: StationCard(
                        key: ValueKey(station.id),
                        station: station,
                        selectedFuelType: FuelType.all,
                        isFavorite: true,
                        onTap: () => context.push('/station/${station.id}'),
                        onFavoriteTap: () {
                          ref
                              .read(favoritesProvider.notifier)
                              .remove(station.id);
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
      loading: () => const FavoritesLoadingView(),
      error: (error, _) => Semantics(
        label: 'Error loading favorites: ${error.toString()}',
        child: Center(
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
      ),
    );
  }
}
