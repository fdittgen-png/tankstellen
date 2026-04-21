import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/trip_history_provider.dart';
import '../widgets/trip_history_card.dart';

/// Rolling log of finalised OBD2 trips (#726). Opened from the
/// consumption screen. Swipe-to-delete mirrors the fill-up list.
class TripHistoryScreen extends ConsumerWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final trips = ref.watch(tripHistoryListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l?.tooltipBack ?? 'Back',
          onPressed: () => context.pop(),
        ),
        title: Text(l?.tripHistoryTitle ?? 'Trip history'),
      ),
      body: trips.isEmpty
          ? EmptyState(
              icon: Icons.route_outlined,
              title: l?.tripHistoryEmptyTitle ?? 'No trips yet',
              subtitle: l?.tripHistoryEmptySubtitle ??
                  'Connect an OBD2 adapter and record a trip to '
                      'start building your driving history.',
            )
          : ListView.builder(
              padding: EdgeInsets.only(
                top: 8,
                bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
              ),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return Dismissible(
                  key: ValueKey(trip.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref
                        .read(tripHistoryListProvider.notifier)
                        .delete(trip.id);
                  },
                  child: TripHistoryCard(entry: trip),
                );
              },
            ),
    );
  }
}
