// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/panel_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/alert_statistics_provider.dart';

/// Header strip showing alert statistics: active count, triggered
/// today / this week.
///
/// #3951 (Epic #3947) — a [PanelCard]: the strip is *supporting figures*
/// (secondary surface level), not the thing the page is about, so it
/// reads as ground under the alert cards. Numbers carry the title role
/// and labels the label role; no ad-hoc sizes. The strip is only
/// rendered once at least one alert exists — the zero state collapses it.
class AlertStatisticsCard extends ConsumerWidget {
  const AlertStatisticsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(alertStatisticsProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return PanelCard(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.xl,
        vertical: Spacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatColumn(
            icon: Icons.notifications_active,
            iconColor: theme.colorScheme.primary,
            value: stats.activeAlerts.toString(),
            label: l10n.alertStatsActive,
          ),
          _StatColumn(
            icon: Icons.today,
            iconColor: stats.triggeredToday > 0
                ? DarkModeColors.success(context)
                : theme.colorScheme.onSurfaceVariant,
            value: stats.triggeredToday.toString(),
            label: l10n.alertStatsToday,
          ),
          _StatColumn(
            icon: Icons.date_range,
            iconColor: theme.colorScheme.onSurfaceVariant,
            value: stats.triggeredThisWeek.toString(),
            label: l10n.alertStatsThisWeek,
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatColumn({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    // #3905 — the strip sits at the top of the Favorites "Price alerts"
    // tab. Each column takes an equal third and its label wraps (2 lines,
    // then ellipsis) so an expanded translation at 320 dp never overflows
    // the row.
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: Spacing.sm),
          Text(value, style: AppText.title(context)),
          const SizedBox(height: Spacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(context),
          ),
        ],
      ),
    );
  }
}
