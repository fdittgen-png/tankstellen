// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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
    // Wide-screen / landscape compact mode (#2018 follow-up). The
    // portrait tile is 88×88 with an icon + label; landscape compresses
    // to 48×48 icon-only with the label moving to the tooltip so the
    // shelf doesn't eat ~120 dp of left-panel real-estate in a wide
    // layout.
    final compact = MediaQuery.of(context).size.width >= 600;
    final shelfHeight = compact ? 48.0 : 88.0;
    final cardMargin = compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    final cardPadding = compact
        ? const EdgeInsets.all(8)
        : const EdgeInsets.all(12);

    return Card(
      margin: cardMargin,
      child: Padding(
        padding: cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined, size: 20),
                const SizedBox(width: 8),
                Text(l.achievementsTitle, style: theme.textTheme.titleSmall),
                const Spacer(),
                Text(
                  '${earnedIds.length}/${AchievementId.values.length}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            SizedBox(height: compact ? 4 : 8),
            SizedBox(
              height: shelfHeight,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final id in AchievementId.values)
                    _BadgeTile(
                      id: id,
                      isEarned: earnedIds.contains(id),
                      compact: compact,
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
  final bool compact;

  const _BadgeTile({
    required this.id,
    required this.isEarned,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (icon, label) = _iconAndLabel(id, l);
    return Tooltip(
      message: _description(id, l),
      child: Container(
        width: compact ? 72 : 88,
        margin: const EdgeInsets.only(right: 8),
        padding: EdgeInsets.all(compact ? 4 : 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 8 : 12),
          color: isEarned
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: compact ? 20 : 28,
              color: isEarned
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            SizedBox(height: compact ? 2 : 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isEarned
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
                fontSize: compact ? 10 : null,
              ),
              textAlign: TextAlign.center,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  (IconData, String) _iconAndLabel(AchievementId id, AppLocalizations l) {
    switch (id) {
      case AchievementId.firstTrip:
        return (Icons.route, l.achievementFirstTrip);
      case AchievementId.firstFillUp:
        return (Icons.local_gas_station, l.achievementFirstFillUp);
      case AchievementId.tenTrips:
        return (Icons.military_tech, l.achievementTenTrips);
      case AchievementId.zeroHarshTrip:
        return (Icons.spa, l.achievementZeroHarsh);
      case AchievementId.ecoWeek:
        return (Icons.event_available, l.achievementEcoWeek);
      case AchievementId.priceWin:
        return (Icons.savings, l.achievementPriceWin);
      case AchievementId.smoothDriver:
        return (Icons.timeline, l.achievementSmoothDriver);
      case AchievementId.coldStartAware:
        return (Icons.ac_unit, l.achievementColdStartAware);
      case AchievementId.highwayMaster:
        return (Icons.straight, l.achievementHighwayMaster);
    }
  }

  String _description(AchievementId id, AppLocalizations l) {
    switch (id) {
      case AchievementId.firstTrip:
        return l.achievementFirstTripDesc;
      case AchievementId.firstFillUp:
        return l.achievementFirstFillUpDesc;
      case AchievementId.tenTrips:
        return l.achievementTenTripsDesc;
      case AchievementId.zeroHarshTrip:
        return l.achievementZeroHarshDesc;
      case AchievementId.ecoWeek:
        return l.achievementEcoWeekDesc;
      case AchievementId.priceWin:
        return l.achievementPriceWinDesc;
      case AchievementId.smoothDriver:
        return l.achievementSmoothDriverDesc;
      case AchievementId.coldStartAware:
        return l.achievementColdStartAwareDesc;
      case AchievementId.highwayMaster:
        return l.achievementHighwayMasterDesc;
    }
  }
}
