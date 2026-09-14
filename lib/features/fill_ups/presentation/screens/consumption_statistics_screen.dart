// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/widgets/panel_card.dart';
import '../../../../core/widgets/staggered_fade_in.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../domain/entities/consumption_stats.dart';
import '../../providers/consumption_providers.dart';
import '../../domain/services/fill_up_monthly_stats_aggregator.dart';
import '../../providers/monthly_fuel_stats_provider.dart';
import '../widgets/consumption_stat_tile.dart';
import '../widgets/fuel_type_efficiency_card.dart';
import '../widgets/localized_fuel_name.dart';
import '../widgets/monthly_fuel_charts.dart';
import '../widgets/monthly_fuel_comparison_card.dart';
import '../../../../core/utils/unit_formatter.dart';

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
    extends ConsumerState<ConsumptionStatisticsPage>
    with SingleTickerProviderStateMixin {
  /// The fuel-filter selection (#3691): null = all fuels. Every stat
  /// and chart on the page follows it, so "how does E85 perform on the
  /// car" is one tap away.
  FuelType? _fuel;

  /// #4175 — ONE controller for the whole page's entrance, sliced per
  /// card by [StaggeredFadeIn]. The cards arrive in reading order
  /// instead of the page appearing whole, which is what makes a report
  /// feel composed rather than dumped.
  ///
  /// Deliberately NOT a count-up on the figures. A number that animates
  /// from zero shows the reader a WRONG total for the length of the
  /// animation, and this is a page about money. Motion belongs to
  /// arrival here, never to the values themselves.
  late final AnimationController _entrance;
  bool _entranceStarted = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: StaggeredFadeIn.timelineDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceStarted) return;
    _entranceStarted = true;
    // #3948's contract: reduced motion renders the END STATE rather
    // than a faster tween.
    if (AppMotion.enabled(context)) {
      unawaited(_entrance.forward());
    } else {
      _entrance.value = 1;
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// One slice of the shared entrance timeline.
  Widget _staggered(int index, Widget child) =>
      StaggeredFadeIn(controller: _entrance, index: index, child: child);

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
        ? Column(
            children: [
              // #4175 — the fuel filter is PINNED under the app bar
              // instead of scrolling away inside the list. It governs
              // every figure below it, and a control that governs the
              // page has no business leaving the page.
              if (fuels.length >= 2)
                _FuelFilterBar(
                  fuels: fuels,
                  selected: fuel,
                  onSelected: (f) => setState(() => _fuel = f),
                ),
              Expanded(
                child: ListView(
                  key: const Key('consumption_stats_list'),
                  padding: EdgeInsets.only(
                    top: Spacing.sm,
                    bottom: Spacing.lg +
                        MediaQuery.of(context).viewPadding.bottom,
                  ),
                  children: [
                    _staggered(0, _HeaderTiles(stats: stats)),
                    _staggered(
                        1, MonthlyFuelComparisonCard(months: months)),
                    // #2887 — per-fuel €/km comparison for a multi-fuel
                    // vehicle. Self-hides when the active vehicle is not
                    // multiFuelCapable or fewer than two fuels have been
                    // logged, so single-fuel users never see it.
                    _staggered(2, const FuelTypeEfficiencyCard()),
                    const SizedBox(height: Spacing.xs),
                    _staggered(
                      3,
                      SectionHeader(
                        title: l.consumptionStatsTrendsTitle,
                        leadingIcon: Icons.show_chart,
                      ),
                    ),
                    _staggered(
                      4,
                      MonthlyFuelCharts(months: months, perFuel: perFuel),
                    ),
                  ],
                ),
              ),
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

/// Header row of all-time stat tiles (#2698, #4175).
///
/// These used to be a private `_StatTile` with a `bodySmall` value — so
/// on the page whose whole purpose is these six numbers, not one of them
/// was the largest text on its own card. #3950 gave the summary card's
/// tiles focal numbers and this page kept its older recipe; it now uses
/// the same [ConsumptionStatTile], which means the grammar test that
/// guards the summary card guards this page too.
///
/// Each metric family carries its own scheme role on the icon disc, so
/// money, volume and efficiency are distinguishable at a glance without
/// reading a single label.
class _HeaderTiles extends StatelessWidget {
  final ConsumptionStats stats;

  const _HeaderTiles({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tiles = <_TileData>[
      _TileData(
        icon: Icons.local_gas_station,
        label: l.statTotalLiters,
        value: UnitFormatter.formatDecimal(stats.totalLiters),
        accent: scheme.primary,
      ),
      _TileData(
        icon: Icons.payments_outlined,
        label: l.statTotalSpent,
        value: PriceFormatter.formatTotal(stats.totalSpent),
        accent: scheme.tertiary,
      ),
      _TileData(
        icon: Icons.local_offer_outlined,
        label: l.consumptionStatsPricePerLiter,
        value: PriceFormatter.formatPriceCompact(stats.avgPricePerLiter),
        accent: scheme.secondary,
      ),
      _TileData(
        icon: Icons.speed,
        label: l.statAvgConsumption,
        value: stats.avgConsumptionL100km != null
            ? UnitFormatter.formatDecimal(stats.avgConsumptionL100km!,
                fractionDigits: 2)
            : '—',
        accent: scheme.primary,
      ),
      _TileData(
        icon: Icons.euro,
        label: l.statAvgCostPerKm,
        value: stats.avgCostPerKm != null
            ? PriceFormatter.formatPerKm(stats.avgCostPerKm)
            : '—',
        accent: scheme.tertiary,
      ),
      _TileData(
        icon: Icons.format_list_numbered,
        label: l.statFillUpCount,
        value: stats.fillUpCount.toString(),
        accent: scheme.secondary,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: PanelCard(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < tiles.length; i += 2)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : Spacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _tile(tiles[i])),
                    const SizedBox(width: Spacing.md),
                    if (i + 1 < tiles.length)
                      Expanded(child: _tile(tiles[i + 1]))
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

  Widget _tile(_TileData d) => ConsumptionStatTile(
        icon: d.icon,
        label: d.label,
        value: d.value,
        accent: d.accent,
      );
}

class _TileData {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _TileData({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });
}

/// The pinned fuel filter (#3691, #4175).
///
/// Horizontally scrollable rather than a `Wrap`: with four or more
/// logged fuels under a long locale the wrap grew to three lines and ate
/// the top of the page it was supposed to sit above.
class _FuelFilterBar extends StatelessWidget {
  const _FuelFilterBar({
    required this.fuels,
    required this.selected,
    required this.onSelected,
  });

  final List<FuelType> fuels;
  final FuelType? selected;
  final ValueChanged<FuelType?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      height: 48,
      child: ListView(
        key: const Key('fuel_filter_bar'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.xs,
        ),
        children: [
          ChoiceChip(
            key: const Key('fuel_filter_all'),
            label: Text(l.allFuels),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          for (final f in fuels) ...[
            const SizedBox(width: Spacing.sm),
            ChoiceChip(
              key: Key('fuel_filter_${f.runtimeType}'),
              avatar: Icon(Icons.circle,
                  size: 12, color: FuelColors.forType(f)),
              label: Text(localizedFuelName(l, f)),
              selected: selected == f,
              onSelected: (_) => onSelected(f),
            ),
          ],
        ],
      ),
    );
  }
}
