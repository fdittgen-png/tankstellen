import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ev/domain/entities/charging_station.dart';
import '../../../search/domain/entities/station.dart';
import '../../providers/ev_favorites_provider.dart';
import '../../providers/favorites_provider.dart';
import 'ev_favorite_card.dart';
import 'favorite_station_dismissible.dart';
import 'favorites_loading_view.dart';
import 'favorites_section_header.dart';
import 'swipe_tutorial_banner.dart';

/// One row of the favorites list — a section header, a fuel station, or
/// an EV station. Flattening the two sections into a single typed list
/// lets the list render lazily via `ListView.builder` (#1763) instead of
/// constructing every favorite card up front.
sealed class _FavRow {
  const _FavRow();
}

class _HeaderRow extends _FavRow {
  const _HeaderRow(this.icon, this.label, this.padding);
  final IconData icon;
  final String label;
  final EdgeInsets padding;
}

class _FuelRow extends _FavRow {
  const _FuelRow(this.station);
  final Station station;
}

class _EvRow extends _FavRow {
  const _EvRow(this.station);
  final ChargingStation station;
}

/// Body of the "Favorites" tab inside `FavoritesScreen`. Renders both fuel
/// and EV favorites in a single unified list. Uses the merged
/// [favoritesProvider] for IDs and loads data from [favoriteStationsProvider]
/// (fuel) and [evFavoriteStationsProvider] (EV).
class FavoritesTab extends ConsumerWidget {
  const FavoritesTab({super.key});

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
          topBiased: true,
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

        // Flatten both sections into one typed list so `ListView.builder`
        // can build rows lazily (#1763). Building the row descriptors is
        // cheap — the station cards themselves are only constructed by
        // `itemBuilder` for the rows actually on screen.
        final rows = <_FavRow>[
          // Fuel stations first (#692) — the app's primary use-case;
          // EV is a secondary section below.
          if (result.data.isNotEmpty) ...[
            if (hasEvFavorites)
              _HeaderRow(
                Icons.local_gas_station,
                l10n?.fuelStationsSection ?? 'Fuel Stations',
                const EdgeInsets.fromLTRB(16, 8, 16, 4),
              ),
            ...result.data.map(_FuelRow.new),
          ],
          if (hasEvFavorites) ...[
            _HeaderRow(
              Icons.ev_station,
              l10n?.evChargingSection ?? 'EV Charging',
              EdgeInsets.fromLTRB(16, result.data.isNotEmpty ? 12 : 8, 16, 4),
            ),
            ...evStations.map(_EvRow.new),
          ],
        ];

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
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return switch (row) {
                      _HeaderRow(:final icon, :final label, :final padding) =>
                        FavoritesSectionHeader(
                          icon: icon,
                          label: label,
                          padding: padding,
                        ),
                      _FuelRow(:final station) =>
                        FavoriteStationDismissible(station: station),
                      _EvRow(:final station) => EvFavoriteCard(
                          key: ValueKey('ev-${station.id}'),
                          station: station,
                          onTap: () =>
                              context.push('/ev-station', extra: station),
                          onFavoriteTap: () {
                            ref
                                .read(favoritesProvider.notifier)
                                .remove(station.id);
                            SnackBarHelper.show(
                              context,
                              l10n?.removedFromFavorites ??
                                  'Removed from favorites',
                            );
                          },
                        ),
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
