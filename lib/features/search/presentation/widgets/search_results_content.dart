// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_result.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../domain/entities/search_mode.dart';
import '../../domain/entities/search_result_item.dart';
import '../../providers/radar_search_provider.dart';
import '../../providers/search_mode_provider.dart';
import '../../providers/search_provider.dart';
import 'nearest_shortcut_card.dart';
import 'route_results_view.dart';
import 'search_results_list.dart';

/// Renders the result panel of `SearchScreen` based on the current
/// [SearchMode] and [FuelType]:
///
///  * Route mode -> [RouteResultsView] inside a `CustomScrollView`
///  * Otherwise -> [SearchResultsList] over the standard
///    `searchStateProvider` `AsyncValue` (shimmer/empty/loaded/error),
///    rendering fuel and EV results in one combined mixed list
///
/// Pulled out of `search_screen.dart` so the screen's `_buildResults`
/// helper drops 50 lines and so the empty/loading/error branches can be
/// exercised by widget tests in isolation. The screen still owns
/// `_performGpsSearch`, so it is passed in as [onGpsRetry].
class SearchResultsContent extends ConsumerWidget {
  final Future<void> Function() onGpsRetry;

  const SearchResultsContent({super.key, required this.onGpsRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final searchMode = ref.watch(activeSearchModeProvider);
    final searchState = ref.watch(searchStateProvider);

    if (searchMode == SearchMode.route) {
      return const CustomScrollView(
        slivers: [RouteResultsView()],
      );
    }

    // #2675 — when the on-search Fuel Station Radar is active it OWNS the
    // results list (mirrors the route early-return above): its
    // distance-sorted, priced stations are wrapped as FuelStationResult into
    // a cache-sourced ServiceResult and handed to the same SearchResultsList,
    // so the polymorphic switch renders them as ordinary fuel cards. The
    // regular searchStateProvider is left untouched — dismissing the radar
    // hands the list straight back to it.
    final radar = ref.watch(radarSearchProvider);
    if (radar.active) {
      final stations = radar.stations.value ?? const [];
      final radarResult = ServiceResult<List<SearchResultItem>>(
        data: [for (final s in stations) FuelStationResult(s)],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );
      return SearchResultsList(
        result: radarResult,
        onRefresh: () => ref.read(radarSearchProvider.notifier).runRadar(),
      );
    }

    // #494 — the nearest-stations shortcut only makes sense for users
    // whose preferred landing screen is "nearest". If they picked
    // favorites / cheapest / map, pushing "Stations les plus proches"
    // at them ignores their explicit preference.
    final profile = ref.watch(activeProfileProvider);
    final showNearestShortcut =
        profile == null || profile.landingScreen == LandingScreen.nearest;

    return searchState.when(
      data: (result) {
        if (result.data.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showNearestShortcut) ...[
                    NearestShortcutCard(onTap: onGpsRetry),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    l10n?.startSearch ?? 'Search to find fuel stations.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  // #2131 — the empty-state inline "Search" CTA moved to
                  // the central FAB. The shell's FAB is always visible
                  // on this screen, so the empty state is no longer a
                  // dead-end even without an inline button.
                ],
              ),
            ),
          );
        }
        return SearchResultsList(result: result, onRefresh: onGpsRetry);
      },
      loading: () => const ShimmerStationList(),
      error: (error, stackTrace) =>
          ServiceChainErrorWidget(
            error: error,
            onRetry: onGpsRetry,
            stackTrace: stackTrace,
            searchContext: 'Station search (${ref.read(selectedFuelTypeProvider).apiValue})',
          ),
    );
  }
}
