import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../providers/charging_stats_provider.dart';

/// EV-side counterpart to [ConsumptionStatsCard] (#582 phase 2).
///
/// Three tiles: EUR/100 km (the wheel-lens savings metric), total
/// kWh, total spend. The EUR/100 km value collapses to "—" when the
/// active vehicle has fewer than two logged sessions — we need a
/// paired odometer window before the weighted mean is meaningful.
///
/// Uses [AsyncValue.when] so the card degrades gracefully while
/// Riverpod hydrates the derived providers on first paint — the
/// consumption screen must never show a spinner just because a lazy
/// future hasn't resolved.
class ChargingStatsCard extends ConsumerWidget {
  const ChargingStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final eurPer100Km = ref.watch(chargingEurPer100KmProvider);
    final totalKwh = ref.watch(chargingTotalKwhProvider);
    final totalCost = ref.watch(chargingTotalCostEurProvider);

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
                    icon: Icons.euro,
                    label: l?.chargingLogStatsEurPer100Km ?? 'EUR / 100 km',
                    value: eurPer100Km.when(
                      data: (v) => v != null ? v.toStringAsFixed(2) : '—',
                      loading: () => '—',
                      error: (_, _) => '—',
                    ),
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    icon: Icons.bolt,
                    label: l?.chargingLogStatsTotalKwh ?? 'Total kWh',
                    value: totalKwh.when(
                      data: (v) => v.toStringAsFixed(1),
                      loading: () => '—',
                      error: (_, _) => '—',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.payments_outlined,
                    label: l?.chargingLogStatsTotalCost ?? 'Total cost',
                    value: totalCost.when(
                      data: (v) => v.toStringAsFixed(2),
                      loading: () => '—',
                      error: (_, _) => '—',
                    ),
                  ),
                ),
              ],
            ),
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
