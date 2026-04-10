import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/consumption_stats.dart';

/// Card summarising aggregated consumption statistics.
class ConsumptionStatsCard extends StatelessWidget {
  final ConsumptionStats stats;

  const ConsumptionStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final avgConsumption = stats.avgConsumptionL100km;
    final avgCostKm = stats.avgCostPerKm;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l?.consumptionStatsTitle ?? 'Consumption stats',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.speed,
                    label: l?.statAvgConsumption ?? 'Avg L/100km',
                    value: avgConsumption != null
                        ? avgConsumption.toStringAsFixed(2)
                        : '—',
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    icon: Icons.euro,
                    label: l?.statAvgCostPerKm ?? 'Avg /km',
                    value: avgCostKm != null
                        ? avgCostKm.toStringAsFixed(3)
                        : '—',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.local_gas_station,
                    label: l?.statTotalLiters ?? 'Total L',
                    value: stats.totalLiters.toStringAsFixed(1),
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    icon: Icons.payments_outlined,
                    label: l?.statTotalSpent ?? 'Total spent',
                    value: stats.totalSpent.toStringAsFixed(2),
                  ),
                ),
              ],
            ),
            if (stats.fillUpCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${l?.statFillUpCount ?? 'Fill-ups'}: ${stats.fillUpCount}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
