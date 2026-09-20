// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/fleet_kpis.dart';
import '../../providers/fleet_manager_providers.dart';
import '../widgets/fleet_attention_list.dart';
import '../widgets/fleet_figure.dart';
import '../widgets/fleet_kpi_tile.dart';

/// The fleet manager's landing surface (#4216).
///
/// Exceptions first. #4216 asks for a decision-oriented dashboard
/// rather than a data dump, so "Needs attention" is the top card and
/// the totals follow it: a manager who opens this screen should see
/// what to DO before they see how much was spent.
///
/// Three states this screen keeps apart, because collapsing any two
/// tells the manager something untrue:
///
///  * **no fleet on this device** — nothing has been pulled;
///  * **could not ask** — there is a fleet and the server did not
///    answer. Never rendered as an empty fleet;
///  * **nothing in this period** — the server answered, and the answer
///    is that no confirmed expense falls in the window.
class FleetOverviewScreen extends ConsumerWidget {
  const FleetOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final directory = ref.watch(fleetManagerDirectoryProvider);
    return PageScaffold(
      title: l.fleetManagerOverviewTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.receipt_long_outlined),
          tooltip: l.fleetManagerOpenQueue,
          onPressed: () =>
              const FleetExpenseQueueRoute().push<void>(context),
        ),
        IconButton(
          icon: const Icon(Icons.assessment_outlined),
          tooltip: l.fleetManagerOpenReports,
          onPressed: () => const FleetReportsRoute().push<void>(context),
        ),
      ],
      bodyPadding: EdgeInsets.zero,
      body: directory == null
          ? EmptyState(
              icon: Icons.business_outlined,
              title: l.fleetManagerNoFleetTitle,
              subtitle: l.fleetManagerNoFleetBody,
            )
          : ref.watch(fleetPeriodKpisProvider).when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: l.fleetManagerUnavailableTitle,
                  subtitle: l.fleetManagerUnavailableBody,
                ),
                data: (kpis) => kpis == null
                    ? EmptyState(
                        icon: Icons.cloud_off_outlined,
                        title: l.fleetManagerUnavailableTitle,
                        subtitle: l.fleetManagerUnavailableBody,
                      )
                    : _Body(kpis: kpis),
              ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.kpis});

  final FleetKpis kpis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (kpis.vehicles.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        title: l.fleetManagerEmptyPeriodTitle,
        subtitle: l.fleetManagerEmptyPeriodBody,
      );
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.lg,
        Spacing.lg,
        shellScrollClearance(context),
      ),
      children: [
        SectionCard(
          title: l.fleetManagerAttentionTitle,
          leadingIcon: Icons.priority_high_outlined,
          child: FleetAttentionList(
            items: ref.watch(fleetAttentionItemsProvider),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        _KpiGrid(kpis: kpis),
        const SizedBox(height: Spacing.lg),
        SectionCard(
          title: l.fleetManagerVehiclesTitle,
          leadingIcon: Icons.directions_car_outlined,
          child: _VehicleBars(kpis: kpis),
        ),
      ],
    );
  }
}

/// The period's headline figures. Each tile carries its claim class,
/// its caveat and the sample count it rests on (#4216).
class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis});

  final FleetKpis kpis;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final spend = kpis.spend;
    final currency = kpis.currency;
    final tiles = <Widget>[
      // A period that mixes currencies gets no total — the breakdown
      // card below says so in as many words.
      FleetKpiTile(
        label: l.fleetManagerKpiSpend,
        value: spend == null
            ? l.fleetManagerNotCalculated
            : fleetFigure(l, spend, (v) => FleetFormats.money(v, currency)),
        claim: spend?.claim ?? kpis.litres.claim,
        caveat: spend == null ? null : fleetCaveat(l, spend),
        samples: kpis.sampleCount,
      ),
      FleetKpiTile(
        label: l.fleetManagerKpiCostPerKm,
        value: fleetFigure(l, kpis.costPerKm,
            (v) => FleetFormats.costPerKm(v, currency)),
        claim: kpis.costPerKm.claim,
        caveat: fleetCaveat(l, kpis.costPerKm),
      ),
      FleetKpiTile(
        label: l.fleetManagerKpiConsumption,
        value: fleetFigure(l, kpis.lPer100Km, FleetFormats.consumption),
        claim: kpis.lPer100Km.claim,
        caveat: fleetCaveat(l, kpis.lPer100Km),
      ),
      FleetKpiTile(
        label: l.fleetManagerKpiMeasuredCoverage,
        value: fleetFigure(l, kpis.measuredShare, FleetFormats.share),
        claim: kpis.measuredShare.claim,
        caveat: fleetCaveat(l, kpis.measuredShare),
      ),
    ];
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            // IntrinsicHeight, not `CrossAxisAlignment.stretch`: a Row
            // inside a ListView has unbounded height, and stretching
            // into it is an infinite-constraint crash. The pair still
            // reads as one band because they share the taller height.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tiles[i]),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: i + 1 < tiles.length
                        ? tiles[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        if (!kpis.isSingleCurrency) _CurrencyBreakdown(kpis: kpis),
      ],
    );
  }
}

/// What a fleet sees instead of a total when the period crossed a
/// border: one honest number per currency (#4216).
class _CurrencyBreakdown extends StatelessWidget {
  const _CurrencyBreakdown({required this.kpis});

  final FleetKpis kpis;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      title: l.fleetManagerMultiCurrencyTotals,
      subtitle: l.fleetManagerAttentionMixedCurrency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in kpis.spendByCurrency.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.xs),
              child: Text(fleetFigure(l, entry.value,
                  (v) => FleetFormats.money(v, entry.key))),
            ),
        ],
      ),
    );
  }
}

/// Cost per km, vehicle by vehicle (#4216).
///
/// One measure and one axis. Bars are scaled against the largest
/// figure in the group, and a vehicle with no figure gets an empty
/// track plus the reason — never a zero-length bar, which would read
/// as "cheapest".
class _VehicleBars extends ConsumerWidget {
  const _VehicleBars({required this.kpis});

  final FleetKpis kpis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final threshold = ref.watch(fleetAggregationMinSamplesProvider);
    var max = 0.0;
    for (final v in kpis.reported) {
      final cost = v.costPerKm.valueOrNull;
      if (cost != null && cost > max) max = cost;
    }
    return Column(
      children: [
        for (final v in kpis.vehicles)
          Builder(builder: (context) {
            final row = ref.watch(fleetVehicleRowByIdProvider(v.fleetVehicleId));
            final name = row?.displayName ??
                l.fleetManagerVehicleUnnamed(v.fleetVehicleId);
            final cost = v.suppressed ? null : v.costPerKm.valueOrNull;
            return FleetComparisonBar(
              name: name,
              value: v.suppressed
                  ? l.fleetManagerNotCalculated
                  : fleetFigure(l, v.costPerKm,
                      (x) => FleetFormats.costPerKm(x, v.currency)),
              fraction: cost == null || max <= 0 ? null : cost / max,
              subtitle: v.suppressed
                  ? l.fleetManagerVehicleSuppressed(threshold)
                  : l.fleetManagerSamples(v.sampleCount),
              onTap: v.suppressed
                  ? null
                  : () => FleetVehicleDetailRoute(v.fleetVehicleId)
                      .push<void>(context),
            );
          }),
      ],
    );
  }
}
