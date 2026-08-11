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
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../domain/entities/consumption_stats.dart';
import '../../providers/consumption_providers.dart';
import '../../domain/services/fill_up_monthly_stats_aggregator.dart';
import '../../providers/monthly_fuel_stats_provider.dart';
import '../widgets/fuel_type_efficiency_card.dart';
import '../widgets/localized_fuel_name.dart';
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
class ConsumptionStatisticsPage extends ConsumerStatefulWidget {
  const ConsumptionStatisticsPage({super.key});

  @override
  ConsumerState<ConsumptionStatisticsPage> createState() =>
      _ConsumptionStatisticsPageState();
}

class _ConsumptionStatisticsPageState
    extends ConsumerState<ConsumptionStatisticsPage> {
  /// The fuel-filter selection (#3691): null = all fuels. Every stat
  /// and chart on the page follows it, so "how does E85 perform on the
  /// car" is one tap away.
  FuelType? _fuel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fuels = ref.watch(loggedFuelTypesProvider);
    // A vanished selection (fill-up deleted) falls back to all fuels.
    final fuel = fuels.contains(_fuel) ? _fuel : null;
    final stats = ref.watch(consumptionStatsForFuelProvider(fuel));
    final months = ref.watch(monthlyFuelStatsForFuelProvider(fuel));
    final perFuel = fuel == null && fuels.length >= 2
        ? {
            for (final f in fuels)
              f: ref.watch(monthlyFuelStatsForFuelProvider(f)),
          }
        : const <FuelType, List<MonthlyFuelStats>>{};
    final hasData =
        ref.watch(consumptionStatsProvider).fillUpCount > 0;

    final Widget body = hasData
        ? ListView(
            padding: EdgeInsets.only(
              top: 8,
              bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
            ),
            children: [
              // Per-fuel filter (#3691) — only for multi-fuel logs.
              if (fuels.length >= 2)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        key: const Key('fuel_filter_all'),
                        label: Text(l.allFuels),
                        selected: fuel == null,
                        onSelected: (_) => setState(() => _fuel = null),
                      ),
                      for (final f in fuels)
                        ChoiceChip(
                          key: Key('fuel_filter_${f.runtimeType}'),
                          avatar: Icon(Icons.circle,
                              size: 12, color: FuelColors.forType(f)),
                          label: Text(localizedFuelName(l, f)),
                          selected: fuel == f,
                          onSelected: (_) => setState(() => _fuel = f),
                        ),
                    ],
                  ),
                ),
              _HeaderTiles(stats: stats),
              MonthlyFuelComparisonCard(months: months),
              // #2887 — per-fuel €/km comparison for a multi-fuel
              // vehicle. Self-hides (SizedBox.shrink) when the active
              // vehicle is not multiFuelCapable or fewer than two fuels
              // have been logged, so single-fuel users never see it.
              const FuelTypeEfficiencyCard(),
              const SizedBox(height: 4),
              SectionHeader(
                title: l.consumptionStatsTrendsTitle,
                leadingIcon: Icons.show_chart,
              ),
              MonthlyFuelCharts(months: months, perFuel: perFuel),
            ],
          )
        : EmptyState(
            icon: Icons.show_chart_outlined,
            title: l.noFillUpsTitle,
            subtitle: l.noFillUpsSubtitle,
          );

    return PageScaffold(
      title: l.consumptionStatsPageTitle,
      bannerIcon: Icons.insights_outlined,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l.tooltipBack,
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
        label: l.statTotalLiters,
        value: stats.totalLiters.toStringAsFixed(1),
      ),
      _TileData(
        icon: Icons.payments_outlined,
        label: l.statTotalSpent,
        value: PriceFormatter.formatTotal(stats.totalSpent),
      ),
      _TileData(
        icon: Icons.local_offer_outlined,
        label: l.consumptionStatsPricePerLiter,
        value: PriceFormatter.formatPriceCompact(stats.avgPricePerLiter),
      ),
      _TileData(
        icon: Icons.speed,
        label: l.statAvgConsumption,
        value: stats.avgConsumptionL100km != null
            ? stats.avgConsumptionL100km!.toStringAsFixed(2)
            : '—',
      ),
      _TileData(
        icon: Icons.euro,
        label: l.statAvgCostPerKm,
        value: stats.avgCostPerKm != null
            ? PriceFormatter.formatPerKm(stats.avgCostPerKm)
            : '—',
      ),
      _TileData(
        icon: Icons.format_list_numbered,
        label: l.statFillUpCount,
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
