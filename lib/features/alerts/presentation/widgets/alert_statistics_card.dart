import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/alert_statistics_provider.dart';

/// Header card showing alert statistics: active count, triggered today/week.
class AlertStatisticsCard extends ConsumerWidget {
  const AlertStatisticsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(alertStatisticsProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatColumn(
              icon: Icons.notifications_active,
              iconColor: theme.colorScheme.primary,
              value: stats.activeAlerts.toString(),
              label: l10n?.alertStatsActive ?? 'Active',
            ),
            _StatColumn(
              icon: Icons.today,
              iconColor: stats.triggeredToday > 0
                  ? Colors.green
                  : theme.colorScheme.onSurfaceVariant,
              value: stats.triggeredToday.toString(),
              label: l10n?.alertStatsToday ?? 'Today',
            ),
            _StatColumn(
              icon: Icons.date_range,
              iconColor: theme.colorScheme.onSurfaceVariant,
              value: stats.triggeredThisWeek.toString(),
              label: l10n?.alertStatsThisWeek ?? 'This week',
            ),
          ],
        ),
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
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
