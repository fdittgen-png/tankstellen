// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/user_position_provider.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/service_result.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/search_mode.dart';
import '../../../../core/domain/search_result_item.dart';
import '../../providers/radar_scope_mode_provider.dart';
import '../../providers/radar_search_provider.dart';
import '../../providers/search_mode_provider.dart';
import '../../providers/search_provider.dart';
import 'radar_scope_view.dart';
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
      return const CustomScrollView(slivers: [RouteResultsView()]);
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
      // #3042 — render the radar's AsyncValue with the SAME data/loading/error
      // branching the regular search uses below. Previously this read
      // `radar.stations.value ?? const []`, which collapsed BOTH loading and
      // error into an empty list — so a permission-denied radar run (no GPS
      // fix, no persisted position) showed "no stations" with no explanation.
      // The error branch now surfaces an actionable banner (with an Open
      // Settings path for denied location permission).
      return radar.stations.when(
        data: (stations) {
          // #3058 — a genuinely-empty radar result is its OWN state, visually
          // distinct from the loading shimmer and the error banner, so the
          // user knows the scan FINISHED and found nothing — not that it's
          // still searching (the old bare "0 stations" + blank was ambiguous).
          // #3267 — but while a fresh fix is still resolving ([locating]) an
          // empty provisional scan is NOT "found nothing", so it must NOT show
          // the empty state yet. #3302 — the centred "Finding your location…"
          // panel was removed (it duplicated the FAB's "Searching…" pill, which
          // is the awareness affordance now); the results area just stays blank
          // until the first fix lands and the list paints.
          if (stations.isEmpty) {
            if (radar.locating) return const SizedBox.shrink();
            return _RadarEmptyState(
              onRetry: () => ref.read(radarSearchProvider.notifier).runRadar(),
            );
          }
          final radarResult = ServiceResult<List<SearchResultItem>>(
            data: [for (final s in stations) FuelStationResult(s)],
            source: ServiceSource.cache,
            fetchedAt: DateTime.now(),
          );
          final list = SearchResultsList(
            result: radarResult,
            onRefresh: () => ref.read(radarSearchProvider.notifier).runRadar(),
          );
          // #3342 — a second visualization of the SAME station set: a green
          // PPI radar scope (rotating sweep + a blip per station by distance
          // and bearing). The toggle only swaps the view, it never re-scans,
          // and is only offered when we have a usable centre to place blips
          // around. Defaults to the list.
          final scopeMode = ref.watch(radarScopeModeProvider);
          final userPos = ref.watch(userPositionProvider);
          final canScope =
              userPos != null && isUsableCoord(userPos.lat, userPos.lng);
          final Widget body;
          if (scopeMode && canScope) {
            body = SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: RadarScopeView(
                stations: stations,
                centerLat: userPos.lat,
                centerLng: userPos.lng,
                rangeKm: ref.watch(searchRadiusProvider),
                fuelType: ref.watch(selectedFuelTypeProvider),
                gpsCourseDeg: radar.heading,
                onStationTap: (s) =>
                    unawaited(StationDetailRoute(s.id).push<void>(context)),
              ),
            );
          } else {
            body = list;
          }
          // #3267 — while painting from the last-known position, a thin banner
          // tells the user the spot is being refreshed (instead of silently
          // showing stale-position distances), and clears once the live fix
          // lands and the list re-ranks.
          return Column(
            children: [
              if (canScope) _RadarViewToggle(scopeMode: scopeMode),
              if (radar.locating)
                _RadarUpdatingBanner(message: l10n.radarUpdatingLocation),
              Expanded(child: body),
            ],
          );
        },
        // #3302 — blank while the first scan loads; the FAB's "Searching…"
        // pill is the progress affordance (no centred panel).
        loading: () => const SizedBox.shrink(),
        error: (error, stackTrace) => ServiceChainErrorWidget(
          error: error,
          onRetry: () => ref.read(radarSearchProvider.notifier).runRadar(),
          stackTrace: stackTrace,
          searchContext:
              'Fuel station radar (${ref.read(selectedFuelTypeProvider).apiValue})',
        ),
      );
    }

    return searchState.when(
      data: (result) {
        if (result.data.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // #2743 — the redundant "Stations les plus proches" CTA
                  // card was removed; it duplicated the always-visible
                  // central search FAB and the Fuel Station Radar button.
                  // #2131 — the empty-state inline "Search" CTA moved to
                  // the central FAB. The shell's FAB is always visible
                  // on this screen, so the empty state is no longer a
                  // dead-end even without an inline button.
                  Text(
                    l10n.startSearch,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return SearchResultsList(result: result, onRefresh: onGpsRetry);
      },
      loading: () => const ShimmerStationList(),
      error: (error, stackTrace) => ServiceChainErrorWidget(
        error: error,
        onRetry: onGpsRetry,
        stackTrace: stackTrace,
        searchContext:
            'Station search (${ref.read(selectedFuelTypeProvider).apiValue})',
      ),
    );
  }
}

/// #3342 — a right-aligned button toggling the radar results between the
/// distance-sorted list and the green PPI radar-scope view. Only shown when a
/// usable centre exists (so the scope can place blips). Reads the toggle so its
/// icon/label reflect the current view.
class _RadarViewToggle extends ConsumerWidget {
  const _RadarViewToggle({required this.scopeMode});

  final bool scopeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final label = scopeMode ? l10n.radarScopeShowList : l10n.radarScopeShowScope;
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: TextButton.icon(
          key: const Key('radar_view_toggle'),
          onPressed: () => ref.read(radarScopeModeProvider.notifier).toggle(),
          icon: Icon(scopeMode ? Icons.list : Icons.radar, size: 20),
          label: Text(label),
        ),
      ),
    );
  }
}

/// #3058 — the radar's "scan finished, found nothing" state. Visually distinct
/// from the loading shimmer (still searching) and the error banner (failed), so
/// the user never has to guess which one they're looking at. Reuses the generic
/// no-results strings — no new ARB keys.
class _RadarEmptyState extends StatelessWidget {
  const _RadarEmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.radar,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noResults,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.errorHintNoStations,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// #3267 — a thin banner above the radar results while a fresh GPS fix is still
/// resolving. The list below is painted from the last-known position (so the
/// user sees results instantly), and this strip signals the spot is being
/// refreshed; it clears once the live fix lands and the list re-ranks.
class _RadarUpdatingBanner extends StatelessWidget {
  const _RadarUpdatingBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
