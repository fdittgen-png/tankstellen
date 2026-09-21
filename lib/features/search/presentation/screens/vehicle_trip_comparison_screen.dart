// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The #4367 same-trip comparison surface.
///
/// Everything here reads an already-computed [VehicleTripComparison]:
/// the per-vehicle planning happens in `vehicleTripComparisonProvider`,
/// never in a `build`.
///
/// Three invariants the screen must not break:
///
///  * **the active vehicle never changes.** The columns come from
///    #4365's selection; nothing on this screen writes
///    `activeVehicleProfileProvider`, and nothing here can — the
///    provider is not even reachable from this feature.
///  * **an honest frame around the numbers.** Two standing notes say
///    what a forecast is (an estimate for a drive that has not
///    happened) and what this total is not (a cost of ownership).
///  * **applying is explicit.** A plan is handed to navigation only by
///    the button on its own column, through the #4363 route boundary
///    that preserves the driver's existing waypoints.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/comparison_eligibility.dart';
import '../../../../core/domain/refuel_plan.dart';
import '../../../../core/domain/vehicle_trip_comparison.dart';
import '../../../../core/domain/vehicle_trip_providers.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/refuel_plan_applier.dart';
import '../../providers/vehicle_trip_comparison_provider.dart';
import '../widgets/vehicle_trip_column_card.dart';

/// Side-by-side forecasts of one proposed journey for the selected
/// vehicles.
class VehicleTripComparisonScreen extends ConsumerWidget {
  const VehicleTripComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(vehicleTripComparisonProvider);
    final comparison = state.comparison;

    if (comparison == null) {
      return PageScaffold(
        title: l.vehTripTitle,
        body: EmptyState(
          icon: Icons.route_outlined,
          title: l.vehTripTitle,
          subtitle: switch (state.blocker) {
            VehicleTripComparisonBlocker.noRoute => l.vehTripNoRoute,
            VehicleTripComparisonBlocker.notEnoughVehicles ||
            null =>
              l.vehTripNotEnoughVehicles,
          },
        ),
      );
    }

    return PageScaffold(
      title: l.vehTripTitle,
      body: ListView(
        children: [
          SectionCard(child: Text(l.vehTripForecastNote)),
          Spacing.cardGap,
          SectionCard(child: Text(l.vehTripScopeNote)),
          Spacing.cardGap,
          _ObjectiveSelector(
            objective: ref.watch(vehicleTripObjectiveProvider),
            onSelect: ref.read(vehicleTripObjectiveProvider.notifier).select,
          ),
          Spacing.cardGap,
          _Verdicts(comparison: comparison),
          for (var i = 0; i < comparison.columns.length; i++) ...[
            Spacing.cardGap,
            VehicleTripColumnCard(
              key: Key('veh_trip_column_${comparison.columns[i].vehicleId}'),
              column: comparison.columns[i],
              index: i,
              total: comparison.columns.length,
              stationNames: state.stationNames,
              onApply: comparison.columns[i].plan == null
                  ? null
                  : () => _apply(context, ref, state, comparison.columns[i]),
            ),
          ],
        ],
      ),
    );
  }

  /// Hand ONE vehicle's plan to navigation: the real ordered stations,
  /// through the existing route boundary, with the driver's own
  /// waypoints preserved (#4363).
  Future<void> _apply(
    BuildContext context,
    WidgetRef ref,
    VehicleTripComparisonState state,
    VehicleTripColumn column,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    final candidates = state.candidatesByVehicle[column.vehicleId];
    final plan = column.plan;
    if (candidates == null || plan == null) return;
    final result =
        await ref.read(refuelPlanApplierProvider).apply(plan, candidates);
    messenger.showSnackBar(SnackBar(
      content: Text(result.isLaunched
          ? l.vehTripApplied(column.basis.vehicleName)
          : l.vehTripApplyRefused),
    ));
  }
}

/// Which objective every column is reported on — one choice for the
/// whole comparison, because columns answering different questions are
/// not a comparison.
class _ObjectiveSelector extends StatelessWidget {
  const _ObjectiveSelector({required this.objective, required this.onSelect});

  final RefuelObjective objective;
  final void Function(RefuelObjective) onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      title: l.vehTripObjectiveLabel,
      child: Wrap(
        spacing: Spacing.md,
        runSpacing: Spacing.sm,
        children: [
          for (final (value, label) in <(RefuelObjective, String)>[
            (RefuelObjective.lowestCost, l.vehTripObjectiveCost),
            (RefuelObjective.shortestTime, l.vehTripObjectiveTime),
            (RefuelObjective.leastExtraDistance, l.vehTripObjectiveDistance),
          ])
            ChoiceChip(
              key: Key('veh_trip_objective_${value.name}'),
              label: Text(label),
              selected: objective == value,
              onSelected: (_) => onSelect(value),
            ),
        ],
      ),
    );
  }
}

/// The three verdicts, each named or explicitly withheld. A withheld
/// winner never suppresses the columns beneath it.
class _Verdicts extends StatelessWidget {
  const _Verdicts({required this.comparison});

  final VehicleTripComparison comparison;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(context, comparison.lowestCostToDrive, l.vehTripWinnerCost,
              'cost'),
          _line(context, comparison.lowestCashRequired, l.vehTripWinnerCash,
              'cash'),
          _line(context, comparison.shortestTime, l.vehTripWinnerTime,
              'time'),
        ],
      ),
    );
  }

  Widget _line(
    BuildContext context,
    ComparableMetric<String> winner,
    String Function(String) phrase,
    String slot,
  ) {
    final l = AppLocalizations.of(context);
    final id = winner.valueOrNull;
    final name = id == null
        ? null
        : comparison.columnFor(id)?.basis.vehicleName ?? id;
    return Padding(
      key: Key('veh_trip_verdict_$slot'),
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Text(
        name == null ? l.vehTripWinnerWithheld : phrase(name),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
