// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return PageScaffold(
      title: l10n.savedRoutes,
      bodyPadding: EdgeInsets.zero,
      body: itineraries.isEmpty
          ? EmptyState(
              icon: Icons.route,
              title: l10n.noSavedRoutes,
              subtitle: l10n.noSavedRoutesHint,
            )
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
                      unawaited(
                        ref.read(itineraryProvider.notifier).delete(it.id),
                      );
                      SnackBarHelper.show(
                        context,
                        AppLocalizations.of(context).itineraryDeleted(it.name),
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
                        '${it.distanceKm.round()} km · ${it.durationMinutes.round()} min'
                        '$highwaysSuffix',
                      ),
                      trailing: Text(
                        _formatDate(it.updatedAt),
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

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }
}
