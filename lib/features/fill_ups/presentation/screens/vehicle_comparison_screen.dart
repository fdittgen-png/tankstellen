// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The #4365 personal-vehicle comparison surface.
///
/// Everything here reads an already-computed
/// [VehicleHistoryComparison]: the history walk lives in
/// `selectedVehicleComparisonProvider`, never in a `build`.
///
/// Two invariants the screen must not break:
///
///  * **the active vehicle never changes.** The chips drive
///    `vehicleComparisonSelectorProvider` and nothing else; there is no
///    call to `activeVehicleProfileProvider.notifier` on this screen.
///  * **an honest frame around the numbers.** The standing note says
///    what a historical observation is — what was recorded, at the
///    prices paid — and what it is not: a measure of built-in
///    efficiency, a forecast, or a saving against a price never seen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/comparison_eligibility.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/time/app_clock.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/api.dart';
import '../../domain/services/vehicle_history_comparison.dart';
import '../../providers/vehicle_comparison_provider.dart';
import '../widgets/vehicle_comparison_column_card.dart';
import '../../../../core/utils/comparison_labels.dart';
import '../widgets/vehicle_comparison_sources_sheet.dart';

/// Side-by-side observed consumption and refuelling for two or more of
/// the driver's own vehicles.
class VehicleComparisonScreen extends ConsumerWidget {
  const VehicleComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final vehicles = ref.watch(vehicleProfileListProvider);
    final selection = ref.watch(vehicleComparisonSelectorProvider);
    final selector = ref.read(vehicleComparisonSelectorProvider.notifier);

    // Only a driver who has never had two vehicles sees the empty
    // state. Deleting one of a pair must NOT wipe the screen: the
    // selection survives so it can be recovered (#4365).
    if (vehicles.length < 2 && !selection.isComparable) {
      return PageScaffold(
        title: l.vehCompareTitle,
        body: EmptyState(
          icon: Icons.compare_arrows,
          title: l.vehCompareTitle,
          subtitle: l.vehCompareNotEnoughVehicles,
        ),
      );
    }

    final comparison = ref.watch(selectedVehicleComparisonProvider);
    final names = {for (final v in vehicles) v.id: v.name};

    return PageScaffold(
      title: l.vehCompareTitle,
      // #4367 — the forecast sibling of this screen. It reuses THIS
      // selection, so the driver crosses from "what did each car cost"
      // to "what would each cost on the trip I am planning" without
      // picking the cars again — and without the active vehicle moving.
      actions: [
        IconButton(
          key: const Key('veh_compare_open_trip'),
          tooltip: l.vehTripOpenTooltip,
          icon: const Icon(Icons.route_outlined),
          onPressed: () =>
              const CompareVehicleTripRoute().push<void>(context),
        ),
      ],
      body: ListView(
        children: [
          _Selector(
            vehicles: [for (final v in vehicles) (v.id, v.name)],
            selected: selection.vehicleIds,
            onToggle: selector.toggle,
          ),
          Spacing.cardGap,
          _PeriodControls(
            selection: selection,
            now: ref.watch(appClockProvider).now(),
            onPeriod: selector.setPeriod,
          ),
          Spacing.cardGap,
          _HonestyNote(),
          if (!selection.isComparable) ...[
            Spacing.cardGap,
            SectionCard(child: Text(l.vehCompareSelectHint)),
          ],
          if (selection.isComparable) ...[
            Spacing.cardGap,
            _Verdicts(comparison: comparison, names: names),
            Spacing.cardGap,
            _Exclusions(comparison: comparison),
            for (var i = 0; i < selection.vehicleIds.length; i++)
              ..._column(context, comparison, selection, names, i, selector),
          ],
        ],
      ),
    );
  }

  List<Widget> _column(
    BuildContext context,
    VehicleHistoryComparison comparison,
    VehicleComparisonSelection selection,
    Map<String, String> names,
    int index,
    VehicleComparisonSelector selector,
  ) {
    final id = selection.vehicleIds[index];
    final column = comparison.columnFor(id);
    if (column == null) return const [];
    final name = names[id] ?? id;
    return [
      Spacing.cardGap,
      VehicleComparisonColumnCard(
        key: Key('veh_compare_column_$id'),
        column: column,
        vehicleName: name,
        index: index,
        total: selection.vehicleIds.length,
        isReference: selection.effectiveReferenceId == id,
        isMissing: comparison.missingVehicleIds.contains(id),
        onShowSources: (figure) => showVehicleComparisonSources(
          context,
          vehicleName: name,
          sources: column.sourcesFor(figure),
        ),
        onUseAsReference: () => selector.setReference(id),
        onRemove: () => selector.drop(id),
      ),
    ];
  }
}

/// The vehicle chips. Toggling one changes the COMPARISON selection and
/// nothing else — the active vehicle is a different piece of state and
/// stays where the driver put it.
class _Selector extends StatelessWidget {
  const _Selector({
    required this.vehicles,
    required this.selected,
    required this.onToggle,
  });

  final List<(String, String)> vehicles;
  final List<String> selected;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) => SectionCard(
        child: Wrap(
          spacing: Spacing.md,
          runSpacing: Spacing.sm,
          children: [
            for (final (id, name) in vehicles)
              FilterChip(
                key: Key('veh_compare_chip_$id'),
                label: Text(name),
                selected: selected.contains(id),
                onSelected: (_) => onToggle(id),
              ),
          ],
        ),
      );
}

/// Period and boundary policy. The boundary note is not decoration: it
/// states the inclusion rule the numbers above were computed under.
class _PeriodControls extends StatelessWidget {
  const _PeriodControls({
    required this.selection,
    required this.now,
    required this.onPeriod,
  });

  final VehicleComparisonSelection selection;
  final DateTime now;
  final void Function(ComparisonPeriod) onPeriod;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final policy = selection.period.boundaryPolicy;
    return SectionCard(
      title: l.vehComparePeriodLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Spacing.md,
            runSpacing: Spacing.sm,
            children: [
              _periodChip(l.vehComparePeriodAll, 'all',
                  ComparisonPeriod(boundaryPolicy: policy)),
              _periodChip(
                  l.vehComparePeriodYear,
                  'year',
                  ComparisonPeriod(
                      start: now.subtract(const Duration(days: 365)),
                      boundaryPolicy: policy)),
              _periodChip(
                  l.vehComparePeriodQuarter,
                  'quarter',
                  ComparisonPeriod(
                      start: now.subtract(const Duration(days: 90)),
                      boundaryPolicy: policy)),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Text(l.vehCompareBoundaryPolicyLabel,
              style: theme.textTheme.bodySmall),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.md,
            runSpacing: Spacing.sm,
            children: [
              _policyChip(l.vehCompareBoundaryClosing,
                  BoundaryWindowPolicy.closingFillInPeriod),
              _policyChip(l.vehCompareBoundaryContained,
                  BoundaryWindowPolicy.whollyContained),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(l.vehCompareBoundaryNote,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _periodChip(String label, String id, ComparisonPeriod period) =>
      ChoiceChip(
        key: Key('veh_compare_period_$id'),
        label: Text(label),
        selected: selection.period.start == period.start &&
            selection.period.end == period.end,
        onSelected: (_) => onPeriod(period),
      );

  Widget _policyChip(String label, BoundaryWindowPolicy policy) => ChoiceChip(
        key: Key('veh_compare_policy_${policy.name}'),
        label: Text(label),
        selected: selection.period.boundaryPolicy == policy,
        onSelected: (_) => onPeriod(ComparisonPeriod(
            start: selection.period.start,
            end: selection.period.end,
            boundaryPolicy: policy)),
      );
}

class _HonestyNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SectionCard(
      leadingIcon: Icons.info_outline,
      child: Text(l.vehCompareHonestyNote,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}

/// The two rankings — each either crowned WITH its caveats, or
/// withheld WITH its reason. Never a silent default.
class _Verdicts extends StatelessWidget {
  const _Verdicts({required this.comparison, required this.names});

  final VehicleHistoryComparison comparison;
  final Map<String, String> names;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _verdict(context, l, comparison.lowestConsumption,
              (name) => l.vehCompareWinnerConsumption(name),
              'veh_compare_winner_consumption'),
          const SizedBox(height: Spacing.md),
          _verdict(context, l, comparison.lowestCostPerKm,
              (name) => l.vehCompareWinnerCost(name), 'veh_compare_winner_cost'),
        ],
      ),
    );
  }

  Widget _verdict(BuildContext context, AppLocalizations l,
      ComparableMetric<String> metric, String Function(String) headline,
      String keyName) {
    final theme = Theme.of(context);
    final id = metric.valueOrNull;
    if (id == null) {
      return Text(
        l.vehCompareNoWinner(comparisonReasonLabel(
            l, metric.reason ?? ComparisonUnavailableReason.noEvidence)),
        key: Key('${keyName}_withheld'),
        style: theme.textTheme.bodySmall,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(headline(names[id] ?? id),
            key: Key(keyName), style: theme.textTheme.titleSmall),
        for (final caveat in comparisonQualificationLabels(l, metric))
          Text(caveat,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

/// Records credited to nobody, reported once.
class _Exclusions extends StatelessWidget {
  const _Exclusions({required this.comparison});

  final VehicleHistoryComparison comparison;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lines = <String>[
      if (comparison.unassignedFillCount > 0)
        l.vehCompareUnassignedFills(comparison.unassignedFillCount),
      if (comparison.ambiguousFillCount > 0)
        l.vehCompareAmbiguousFills(comparison.ambiguousFillCount),
      if (comparison.unassignedTripCount > 0)
        l.vehCompareUnassignedTrips(comparison.unassignedTripCount),
    ];
    if (lines.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      leadingIcon: Icons.help_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Text(line, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
