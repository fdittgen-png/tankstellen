import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/feedback/auto_record_badge_provider.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/trip_history_provider.dart';
import '../widgets/trip_history_card.dart';

/// Rolling log of finalised OBD2 trips (#726). Opened from the
/// consumption screen. Swipe-to-delete mirrors the fill-up list.
///
/// AppBar exposes a "Mark all as read" action (#1004 phase 6) when
/// the auto-record badge counter is non-zero. Tapping it resets the
/// launcher icon badge without forcing the user to open every trip
/// individually — useful when several auto-trips landed during a
/// commute and the user just wants the dot off their home screen.
class TripHistoryScreen extends ConsumerWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final trips = ref.watch(tripHistoryListProvider);
    final badgeCount = ref.watch(autoRecordBadgeCountProvider);

    return PageScaffold(
      title: l?.tripHistoryTitle ?? 'Trip history',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l?.tooltipBack ?? 'Back',
        onPressed: () => context.pop(),
      ),
      actions: badgeCount > 0
          ? [
              _BadgeClearAction(
                count: badgeCount,
                tooltip: l?.autoRecordBadgeClearTooltip ?? 'Clear counter',
                onPressed: () => ref
                    .read(autoRecordBadgeCountProvider.notifier)
                    .markAllAsRead(),
              ),
            ]
          : null,
      bodyPadding: EdgeInsets.zero,
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

/// Icon-only AppBar action with a small numeric overlay showing the
/// current unseen-trip count. Tapping clears the counter.
class _BadgeClearAction extends StatelessWidget {
  final int count;
  final String tooltip;
  final VoidCallback onPressed;

  const _BadgeClearAction({
    required this.count,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      key: const Key('tripHistoryBadgeClear'),
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_active_outlined),
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onError,
                  fontSize: 10,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
