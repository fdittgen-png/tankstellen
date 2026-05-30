// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/search_result_item.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/merged_favorites_provider.dart';
import 'ev_favorite_dismissible.dart';
import 'favorite_station_dismissible.dart';
import 'favorites_loading_view.dart';
import 'swipe_tutorial_banner.dart';

/// Body of the "Favorites" tab inside `FavoritesScreen`.
///
/// Renders fuel and EV favorites in **one interleaved list** (#1787),
/// ordered by distance via [mergedFavoritesProvider] (#1786) — no
/// labelled sections. The loading / error / freshness lifecycle still
/// comes from [favoriteStationsProvider]; the merged provider only
/// supplies the row content.
class FavoritesTab extends ConsumerWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favoriteIds = ref.watch(favoritesProvider);
    final stationsState = ref.watch(favoriteStationsProvider);
    final favorites = ref.watch(mergedFavoritesProvider);

    if (favoriteIds.isEmpty) {
      return Semantics(
        label: l10n?.noFavoritesSemanticLabel ??
            'No favorites yet. Tap the star on a station to save it as a favorite.',
        child: EmptyState(
          icon: Icons.star_outline,
          iconSize: 80,
          title: l10n?.noFavorites ?? 'No favorites yet',
          subtitle: l10n?.noFavoritesHint ??
              'Tap the star on a station to save it here',
          actionLabel: l10n?.search ?? 'Search Stations',
          onAction: () => context.go('/'),
          topBiased: true,
        ),
      );
    }

    return stationsState.when(
      data: (result) {
        // Only spin while the initial fuel fetch is still pending AND
        // there is nothing to show yet. An all-EV favorites set, or
        // orphan ids without data, falls through to the list — showing
        // what we have (and any banner) beats a spinner forever (#690).
        final hasFuelIds = favoriteIds.any((id) => !id.startsWith('ocm-'));
        if (favorites.isEmpty && hasFuelIds) {
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
                child: ListView.builder(
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final item = favorites[index];
                    return switch (item) {
                      FuelStationResult(:final station) =>
                        FavoriteStationDismissible(station: station),
                      // #1958 — EV favorites now swipe just like
                      // fuel-station favorites (navigate / remove).
                      EVStationResult(:final station) =>
                        EvFavoriteDismissible(station: station),
                    };
                  },
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
