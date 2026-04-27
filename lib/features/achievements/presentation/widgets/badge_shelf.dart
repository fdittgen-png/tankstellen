import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/achievement.dart';
import '../../providers/achievements_provider.dart';

/// Row of earned + unearned badges (#781). Zero-height when nothing
/// is earned yet so the consumption screen doesn't get cluttered for
/// first-run users; a short prompt replaces the shelf in that case.
class BadgeShelf extends ConsumerWidget {
  const BadgeShelf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earned = ref.watch(achievementsProvider);
    final l = AppLocalizations.of(context);
    if (earned.isEmpty) return const SizedBox.shrink();
    final earnedIds = {for (final e in earned) e.id};
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  l?.achievementsTitle ?? 'Achievements',
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                Text(
                  '${earnedIds.length}/${AchievementId.values.length}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 88,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final id in AchievementId.values)
                    _BadgeTile(
                      id: id,
                      isEarned: earnedIds.contains(id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final AchievementId id;
  final bool isEarned;

  const _BadgeTile({required this.id, required this.isEarned});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (icon, label) = _iconAndLabel(id, l);
    return Tooltip(
      message: _description(id, l),
      child: Container(
        width: 88,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isEarned
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: isEarned
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isEarned
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  (IconData, String) _iconAndLabel(AchievementId id, AppLocalizations? l) {
    switch (id) {
      case AchievementId.firstTrip:
        return (Icons.route, l?.achievementFirstTrip ?? 'First trip');
      case AchievementId.firstFillUp:
        return (
          Icons.local_gas_station,
          l?.achievementFirstFillUp ?? 'First fill-up',
        );
      case AchievementId.tenTrips:
        return (Icons.military_tech, l?.achievementTenTrips ?? '10 trips');
      case AchievementId.zeroHarshTrip:
        return (Icons.spa, l?.achievementZeroHarsh ?? 'Smooth driver');
      case AchievementId.ecoWeek:
        return (
          Icons.event_available,
          l?.achievementEcoWeek ?? 'Eco week',
        );
      case AchievementId.priceWin:
        return (
          Icons.savings,
          l?.achievementPriceWin ?? 'Price win',
        );
      case AchievementId.smoothDriver:
        return (
          Icons.timeline,
          l?.achievementSmoothDriver ?? 'Smooth streak',
        );
      case AchievementId.coldStartAware:
        return (
          Icons.ac_unit,
          l?.achievementColdStartAware ?? 'Cold-start aware',
        );
      case AchievementId.highwayMaster:
        return (
          Icons.straight,
          l?.achievementHighwayMaster ?? 'Highway master',
        );
    }
  }

  String _description(AchievementId id, AppLocalizations? l) {
    switch (id) {
      case AchievementId.firstTrip:
        return l?.achievementFirstTripDesc ??
            'Record your first OBD2 trip.';
      case AchievementId.firstFillUp:
        return l?.achievementFirstFillUpDesc ??
            'Log your first fill-up.';
      case AchievementId.tenTrips:
        return l?.achievementTenTripsDesc ??
            'Record 10 OBD2 trips.';
      case AchievementId.zeroHarshTrip:
        return l?.achievementZeroHarshDesc ??
            'Complete a trip of 10 km or more with no harsh braking or acceleration.';
      case AchievementId.ecoWeek:
        return l?.achievementEcoWeekDesc ??
            'Drive 7 consecutive days with at least one smooth trip each day.';
      case AchievementId.priceWin:
        return l?.achievementPriceWinDesc ??
            'Log a fill-up that beats the station\'s 30-day average by 5 % or more.';
      case AchievementId.smoothDriver:
        return l?.achievementSmoothDriverDesc ??
            'Drive 5 trips in a row with a smooth-driving score of 80 or higher.';
      case AchievementId.coldStartAware:
        return l?.achievementColdStartAwareDesc ??
            'Keep a whole month\'s cold-start fuel cost under 2 % of total fuel — combine short trips.';
      case AchievementId.highwayMaster:
        return l?.achievementHighwayMasterDesc ??
            'Complete a 30 km+ trip at consistent speed with a smooth-driving score of 90 or higher.';
    }
  }
}
