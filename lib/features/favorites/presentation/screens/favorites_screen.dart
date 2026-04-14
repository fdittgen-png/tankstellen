import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/service_result.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../search/domain/entities/station.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/ev_favorites_provider.dart';
import '../../providers/favorites_provider.dart';
import '../widgets/alerts_tab.dart';
import '../widgets/ev_favorite_card.dart';
import '../widgets/ev_favorites_list_view.dart';
import '../widgets/favorite_station_dismissible.dart';
import '../widgets/favorites_loading_view.dart';
import '../widgets/favorites_section_header.dart';
import '../widgets/swipe_tutorial_banner.dart';

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
    final evStations = ref.watch(evFavoriteStationsProvider);
    final hasEvFavorites = evStations.isNotEmpty;

    if (favoriteIds.isEmpty && !hasEvFavorites) {
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

    // If only EV favorites (no fuel), show them directly
    if (favoriteIds.isEmpty && hasEvFavorites) {
      return EvFavoritesListView(evStations: evStations);
    }

    return stationsState.when(
      data: (result) {
        if (result.data.isEmpty && !hasEvFavorites) {
          return const FavoritesLoadingView();
        }
        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(favoriteStationsProvider.notifier).loadAndRefresh();
          },
          child: Column(
            children: [
              if (result.data.isNotEmpty)
                ServiceStatusBanner(result: result),
              const SwipeTutorialBanner(),
              Expanded(
                child: ListView(
                  children: [
                    // EV favorites section
                    if (hasEvFavorites) ...[
                      FavoritesSectionHeader(
                        icon: Icons.ev_station,
                        label: l10n?.evChargingSection ?? 'EV Charging',
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      ),
                      ...evStations.map((ev) => EvFavoriteCard(
                            key: ValueKey('ev-${ev.id}'),
                            station: ev,
                            onTap: () => context.push('/ev-station', extra: ev),
                            onFavoriteTap: () {
                              ref.read(evFavoritesProvider.notifier).remove(ev.id);
                              SnackBarHelper.show(
                                context,
                                l10n?.removedFromFavorites ?? 'Removed from favorites',
                              );
                            },
                          )),
                      if (result.data.isNotEmpty)
                        FavoritesSectionHeader(
                          icon: Icons.local_gas_station,
                          label: l10n?.fuelStationsSection ?? 'Fuel Stations',
                        ),
                    ],
                    // Fuel favorites
                    ...result.data.map(
                      (station) =>
                          FavoriteStationDismissible(station: station),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => hasEvFavorites
          ? EvFavoritesListView(evStations: evStations)
          : const FavoritesLoadingView(),
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
