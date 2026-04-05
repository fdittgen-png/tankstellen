import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/swipe_to_delete.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../route_search/domain/entities/route_info.dart';
import '../../../route_search/providers/route_search_provider.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/providers/search_mode_provider.dart';
import '../../../search/domain/entities/search_mode.dart';
import '../../providers/itinerary_provider.dart';

class ItinerariesScreen extends ConsumerStatefulWidget {
  const ItinerariesScreen({super.key});

  @override
  ConsumerState<ItinerariesScreen> createState() => _ItinerariesScreenState();
}

class _ItinerariesScreenState extends ConsumerState<ItinerariesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(itineraryProvider.notifier).loadFromServer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final itineraries = ref.watch(itineraryProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.savedRoutes ?? 'Saved Routes'),
      ),
      body: itineraries.isEmpty
          ? EmptyState(
              icon: Icons.route,
              title: l10n?.noSavedRoutes ?? 'No saved routes',
              subtitle: l10n?.noSavedRoutesHint ?? 'Search along a route and save it for quick access later.',
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(itineraryProvider.notifier).loadFromServer();
              },
              child: ListView.builder(
                itemCount: itineraries.length,
                itemBuilder: (context, index) {
                  final it = itineraries[index];
                  return SwipeToDelete(
                    dismissKey: ValueKey(it.id),
                    onDismissed: () {
                      ref.read(itineraryProvider.notifier).delete(it.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)?.itineraryDeleted(it.name) ?? '${it.name} deleted')),
                      );
                    },
                    child: ListTile(
                      leading: const Icon(Icons.route),
                      title: Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${it.distanceKm.round()} km · ${it.durationMinutes.round()} min'
                        '${it.avoidHighways ? ' · no highways' : ''}',
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

    // Trigger route search with saved waypoints
    final fuelType = FuelType.fromString(it.fuelType);
    ref.read(routeSearchStateProvider.notifier).searchAlongRoute(
      waypoints: waypoints,
      fuelType: fuelType,
    );

    // Navigate to search screen
    context.go('/');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)?.loadingRoute(it.name) ?? 'Loading route: ${it.name}')),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }
}
