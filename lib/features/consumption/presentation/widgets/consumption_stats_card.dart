import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/consumption_stats.dart';

/// Card summarising aggregated consumption statistics.
///
/// Since #1362 the card grows two optional decorations on top of the
/// existing stat tiles:
///
///   * a grey **open-window banner** when partial fills sit after the
///     most recent plein-complet — those fills are excluded from the
///     average and the user is told why.
///   * an orange-tinted **correction-share hint** when more than 5 %
///     of the totalled fuel volume came from auto-generated corrections,
///     nudging the user to review the orange entries in the list.
///
/// When neither condition fires, the card renders exactly as before so
/// the all-plein, no-corrections case keeps its calm UX.
class ConsumptionStatsCard extends StatelessWidget {
  final ConsumptionStats stats;

  const ConsumptionStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final avgConsumption = stats.avgConsumptionL100km;
    final avgCostKm = stats.avgCostPerKm;

    final showOpenWindowBanner = stats.openWindowFillCount > 0;
    final showCorrectionHint = stats.correctionShare > 0.05;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showOpenWindowBanner) ...[
              _OpenWindowBanner(
                text: l?.consumptionStatsOpenWindowBanner(
                      stats.openWindowFillCount,
                    ) ??
                    '${stats.openWindowFillCount} partial fill(s) pending '
                        'plein complet — not in average',
              ),
              const SizedBox(height: 8),
            ],
            if (showCorrectionHint) ...[
              _CorrectionShareHint(
                text: l?.consumptionStatsCorrectionShareHint(
                      (stats.correctionShare * 100).round(),
                    ) ??
                    '${(stats.correctionShare * 100).round()}% of fuel from '
                        'auto-corrections — review entries',
              ),
              const SizedBox(height: 8),
            ],
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

/// Grey informational banner — partials are pending a plein-complet
/// close. Non-tappable v1; tap-to-jump to fill-up list is a follow-up.
class _OpenWindowBanner extends StatelessWidget {
  final String text;

  const _OpenWindowBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hourglass_bottom,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Orange-tinted hint — too much of the average comes from auto-
/// corrections. Encourages the user to review the orange entries.
class _CorrectionShareHint extends StatelessWidget {
  final String text;

  const _CorrectionShareHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Reuse the orange palette established by the correction fill-up
    // card (#1361) so the visual language stays consistent.
    final orange = Colors.orange.shade700;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: orange.withValues(alpha: 0.40)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, size: 18, color: orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
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
