// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/consumption_stats.dart';
import '../../providers/consumption_providers.dart';
import '../../providers/monthly_fuel_stats_provider.dart';
import '../widgets/monthly_fuel_charts.dart';
import '../widgets/monthly_fuel_comparison_card.dart';

/// Full consumption-statistics detail page (#2698), opened from the Fuel
/// tab's summary card. Composes:
///   * a header row of all-time stat tiles (litres, spend, price/L,
///     L/100km, cost/km, fill-ups),
///   * the month-over-month [MonthlyFuelComparisonCard],
///   * the per-metric [MonthlyFuelCharts] evolution section.
///
/// Every figure is derived from the existing fill-up list — no new
/// storage. Renders an empty state when the user has logged nothing yet.
class ConsumptionStatisticsPage extends ConsumerWidget {
  const ConsumptionStatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final stats = ref.watch(consumptionStatsProvider);
    final months = ref.watch(monthlyFuelStatsProvider);
    final hasData = stats.fillUpCount > 0;

    final Widget body = hasData
        ? ListView(
            padding: EdgeInsets.only(
              top: 8,
              bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
            ),
            children: [
              _HeaderTiles(stats: stats),
              MonthlyFuelComparisonCard(months: months),
              const SizedBox(height: 4),
              SectionHeader(
                title: l?.consumptionStatsTrendsTitle ?? 'Evolution over time',
                leadingIcon: Icons.show_chart,
              ),
              MonthlyFuelCharts(months: months),
            ],
          )
        : EmptyState(
            icon: Icons.show_chart_outlined,
            title: l?.noFillUpsTitle ?? 'No fill-ups yet',
            subtitle:
                l?.noFillUpsSubtitle ??
                'Log your first fill-up to start tracking consumption.',
          );

    return PageScaffold(
      title: l?.consumptionStatsPageTitle ?? 'Consumption statistics',
      bannerIcon: Icons.insights_outlined,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l?.tooltipBack ?? 'Back',
        onPressed: () => context.pop(),
      ),
      bodyPadding: EdgeInsets.zero,
      body: body,
    );
  }
}

/// Header row of all-time stat tiles (#2698). Reuses the same six
/// fill-up-derived metrics the summary card surfaces, formatted via
/// [PriceFormatter].
class _HeaderTiles extends StatelessWidget {
  final ConsumptionStats stats;

  const _HeaderTiles({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tiles = <_TileData>[
      _TileData(
        icon: Icons.local_gas_station,
        label: l?.statTotalLiters ?? 'Total liters',
        value: stats.totalLiters.toStringAsFixed(1),
      ),
      _TileData(
        icon: Icons.payments_outlined,
        label: l?.statTotalSpent ?? 'Total spent',
        value: PriceFormatter.formatTotal(stats.totalSpent),
      ),
      _TileData(
        icon: Icons.local_offer_outlined,
        label: l?.consumptionStatsPricePerLiter ?? 'Avg price/L',
        value: PriceFormatter.formatPriceCompact(stats.avgPricePerLiter),
      ),
      _TileData(
        icon: Icons.speed,
        label: l?.statAvgConsumption ?? 'Avg L/100km',
        value: stats.avgConsumptionL100km != null
            ? stats.avgConsumptionL100km!.toStringAsFixed(2)
            : '—',
      ),
      _TileData(
        icon: Icons.euro,
        label: l?.statAvgCostPerKm ?? 'Avg cost/km',
        value: stats.avgCostPerKm != null
            ? PriceFormatter.formatPerKm(stats.avgCostPerKm)
            : '—',
      ),
      _TileData(
        icon: Icons.format_list_numbered,
        label: l?.statFillUpCount ?? 'Fill-ups',
        value: stats.fillUpCount.toString(),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SectionCard(
        child: Column(
          children: [
            for (var i = 0; i < tiles.length; i += 2)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                child: Row(
                  children: [
                    Expanded(child: _StatTile(data: tiles[i])),
                    if (i + 1 < tiles.length)
                      Expanded(child: _StatTile(data: tiles[i + 1]))
                    else
                      const Expanded(child: SizedBox.shrink()),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TileData {
  final IconData icon;
  final String label;
  final String value;

  const _TileData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

/// One header stat tile — icon, label, bold value. Mirrors the summary
/// card's `_StatTile` recipe.
class _StatTile extends StatelessWidget {
  final _TileData data;

  const _StatTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(data.icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: theme.textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                data.value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
