// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/swipe_to_delete.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../route_search/domain/entities/route_info.dart';
import '../../../route_search/providers/route_search_provider.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../search/providers/search_mode_provider.dart';
import '../../../../core/domain/search_mode.dart';
import '../../providers/itinerary_provider.dart';
import '../../../profile/providers/profile_provider.dart';

class ItinerariesScreen extends ConsumerStatefulWidget {
  const ItinerariesScreen({super.key});

  @override
  ConsumerState<ItinerariesScreen> createState() => _ItinerariesScreenState();
}

class _ItinerariesScreenState extends ConsumerState<ItinerariesScreen> {
  // initState() intentionally omitted: the keepAlive ItineraryNotifier
  // already kicks off _loadAndMerge() via a microtask in build(). A
  // second unconditional fetch here would cause a redundant Supabase
  // round-trip on every navigation. Use pull-to-refresh for an explicit
  // reload (#2312).

  @override
  Widget build(BuildContext context) {
    final itineraries = ref.watch(itineraryProvider);
    final firstLoad = ref.watch(itineraryFirstLoadProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();

    return PageScaffold(
      title: l10n.savedRoutes,
      bodyPadding: EdgeInsets.zero,
      body: itineraries.isEmpty
          // #3993 — "you have none" is a statement of fact, so it waits
          // until the first server pull has actually answered.
          ? (firstLoad
                ? Center(
                    key: const Key('itineraries_loading'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          l10n.savedRoutesLoading,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : EmptyState(
                    icon: Icons.route,
                    title: l10n.noSavedRoutes,
                    subtitle: l10n.noSavedRoutesHint,
                  ))
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(itineraryProvider.notifier).loadFromServer();
              },
              child: ListView.builder(
                itemCount: itineraries.length,
                itemBuilder: (context, index) {
                  final it = itineraries[index];
                  final highwaysSuffix = it.avoidHighways
                      ? ' · ${l10n.avoidHighways}'
                      : '';
                  return SwipeToDelete(
                    dismissKey: ValueKey(it.id),
                    onDismissed: () {
                      // #3993 — capture-and-restore undo, the idiom the
                      // fill-up and alert lists already use. The notifier
                      // is read HERE: this tile leaves the tree the moment
                      // it is dismissed, so the callback must close over
                      // the notifier, not over a dead `ref`.
                      final notifier = ref.read(itineraryProvider.notifier);
                      unawaited(notifier.delete(it.id));
                      SnackBarHelper.showWithUndo(
                        context,
                        l10n.itineraryDeleted(it.name),
                        onUndo: () => unawaited(notifier.restore(it)),
                      );
                    },
                    child: ListTile(
                      leading: const Icon(Icons.route),
                      title: Text(
                        it.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        // #3993 — the distance follows the country's unit
                        // (a UK user reads miles) and the duration's
                        // abbreviation comes from ARB. The hand-built
                        // "n km · n min" it replaces was English and
                        // metric in all 23 locales.
                        '${UnitFormatter.formatDistance(it.distanceKm, fractionDigits: 0)}'
                        ' · ${formatTravelDuration(l10n, it.durationMinutes)}'
                        '$highwaysSuffix',
                      ),
                      trailing: Text(
                        UnitFormatter.formatShortDate(
                          it.updatedAt,
                          locale: locale,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: () => _loadItinerary(it),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _loadItinerary(dynamic it) {
    // Convert waypoints back to RouteWaypoint
    final waypoints = (it.waypoints as List).map((w) {
      final map = w as Map<String, dynamic>;
      return RouteWaypoint(
        lat: (map['lat'] as num).toDouble(),
        lng: (map['lng'] as num).toDouble(),
        label: map['label'] as String? ?? '',
      );
    }).toList();

    // Set search mode to route
    ref.read(activeSearchModeProvider.notifier).set(SearchMode.route);

    // Trigger route search with saved waypoints. #1602 — the search
    // corridor is the active profile's detour budget.
    final fuelType = FuelType.fromString(it.fuelType as String);
    final detourBudgetKm =
        ref.read(activeProfileProvider)?.routeDetourBudgetKm ?? 5.0;
    unawaited(
      ref
          .read(routeSearchStateProvider.notifier)
          .searchAlongRoute(
            waypoints: waypoints,
            fuelType: fuelType,
            searchRadiusKm: detourBudgetKm,
          ),
    );

    // Navigate to search screen
    context.go(RoutePaths.search);

    SnackBarHelper.show(
      context,
      AppLocalizations.of(context).loadingRoute(it.name as String),
    );
  }

}
