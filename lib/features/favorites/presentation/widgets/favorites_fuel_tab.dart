import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/ev_favorites_provider.dart';
import '../../providers/favorites_provider.dart';
import 'ev_favorite_card.dart';
import 'favorite_station_dismissible.dart';
import 'favorites_loading_view.dart';
import 'favorites_section_header.dart';
import 'swipe_tutorial_banner.dart';

/// Body of the "Favorites" tab inside `FavoritesScreen`. Renders both fuel
/// and EV favorites in a single unified list. Uses the merged
/// [favoritesProvider] for IDs and loads data from [favoriteStationsProvider]
/// (fuel) and [evFavoriteStationsProvider] (EV).
class FavoritesFuelTab extends ConsumerWidget {
  const FavoritesFuelTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favoriteIds = ref.watch(favoritesProvider);
    final stationsState = ref.watch(favoriteStationsProvider);
    final evStations = ref.watch(evFavoriteStationsProvider);
    final hasEvFavorites = evStations.isNotEmpty;

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
        // Only show the loading view if the initial fuel fetch hasn't
        // returned yet AND there is at least one fuel id to load. If all
        // favorites are EV, or there are orphan ids without data, fall
        // through to the list below — showing the EV section (and any
        // diagnostic banner) is better UX than a spinner forever (#690).
        final hasFuelIds = favoriteIds.any((id) => !id.startsWith('ocm-'));
        if (result.data.isEmpty && !hasEvFavorites && hasFuelIds) {
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
                    // Fuel stations first (#692) — they're the app's primary
                    // use-case; EV is a secondary section below.
                    if (result.data.isNotEmpty) ...[
                      if (hasEvFavorites)
                        FavoritesSectionHeader(
                          icon: Icons.local_gas_station,
                          label: l10n?.fuelStationsSection ?? 'Fuel Stations',
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        ),
                      ...result.data.map(
                        (station) =>
                            FavoriteStationDismissible(station: station),
                      ),
                    ],
                    if (hasEvFavorites) ...[
                      FavoritesSectionHeader(
                        icon: Icons.ev_station,
                        label: l10n?.evChargingSection ?? 'EV Charging',
                        padding: EdgeInsets.fromLTRB(
                          16,
                          result.data.isNotEmpty ? 12 : 8,
                          16,
                          4,
                        ),
                      ),
                      ...evStations.map((ev) => EvFavoriteCard(
                            key: ValueKey('ev-${ev.id}'),
                            station: ev,
                            onTap: () =>
                                context.push('/ev-station', extra: ev),
                            onFavoriteTap: () {
                              ref
                                  .read(favoritesProvider.notifier)
                                  .remove(ev.id);
                              SnackBarHelper.show(
                                context,
                                l10n?.removedFromFavorites ??
                                    'Removed from favorites',
                              );
                            },
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const FavoritesLoadingView(),
      error: (error, stackTrace) => ServiceChainErrorWidget(
        error: error,
        stackTrace: stackTrace,
        searchContext: 'Favorites load',
        onRetry: () =>
            ref.read(favoriteStationsProvider.notifier).loadAndRefresh(),
      ),
    );
  }
}
