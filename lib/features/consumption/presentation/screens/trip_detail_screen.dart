import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../providers/trip_history_provider.dart';
import '../widgets/trip_history_card.dart';

/// Placeholder trip detail screen (#889).
///
/// Lands the `/trip/:id` route so the Trajets tab's row tap has a
/// destination — the full detail implementation (timeline, per-minute
/// consumption, map) arrives with #890. For now we echo the entry
/// headline metrics so the screen isn't empty when someone opens it.
///
/// Hydrates from [tripHistoryListProvider] keyed by the path id; a
/// missing entry (stale deep link) shows a friendly fallback instead
/// of crashing the route.
class TripDetailScreen extends ConsumerWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final trips = ref.watch(tripHistoryListProvider);
    final entry = trips.where((t) => t.id == tripId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l?.tooltipBack ?? 'Back',
          onPressed: () => context.pop(),
        ),
        title: Text(l?.tripHistoryTitle ?? 'Trip history'),
      ),
      body: entry == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l?.tripHistoryEmptyTitle ?? 'No trips yet',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: EdgeInsets.only(
                top: 8,
                bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
              ),
              children: [
                TripHistoryCard(entry: entry),
              ],
            ),
    );
  }
}
