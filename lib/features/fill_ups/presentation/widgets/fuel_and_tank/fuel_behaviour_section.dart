// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/domain/fuel/fuel_behaviour_profile.dart';
import '../../../../../core/providers/consumption_display_provider.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_text.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/widgets/panel_card.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/services/fuel_and_tank_view.dart';
import 'fuel_and_tank_labels.dart';
import 'fuel_metric_tile.dart';

/// How THIS vehicle behaved per fuel (#4278): consumption, cost/km, range
/// and CO2e only where evidence exists, each labelled with its provenance,
/// sample count and confidence. Marked "Your car" so it never blends into
/// the general facts; technical detail sits behind one disclosure.
class FuelBehaviourSection extends StatelessWidget {
  const FuelBehaviourSection({super.key, required this.view});

  final FuelAndTankView view;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final learned = view.rows.where((r) => r.hasAnyFigure).toList();
    return PanelCard(
      key: const Key('fuel_and_tank_behaviour'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Spacing.md,
            runSpacing: Spacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l.fuelAndTankBehaviourTitle, style: AppText.title(context)),
              const _ObservedBadge(),
            ],
          ),
          const SizedBox(height: Spacing.md),
          for (final c in view.comparisons) _ComparisonLine(comparison: c),
          if (view.comparisons.isEmpty)
            Text(l.fuelAndTankCompareNeedsTwo, style: AppText.label(context)),
          for (final row in view.rows) ...[
            const Divider(height: Spacing.xxl),
            _ContextRow(row: row),
          ],
          if (learned.isNotEmpty)
            _Details(rows: learned, view: view),
        ],
      ),
    );
  }
}

class _ObservedBadge extends StatelessWidget {
  const _ObservedBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('fuel_and_tank_observed_badge'),
      padding: Spacing.pillPadding,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: AppRadius.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_car_outlined,
              size: 14, color: scheme.onPrimaryContainer),
          const SizedBox(width: Spacing.sm),
          Flexible(
            child: Text(
              AppLocalizations.of(context).fuelAndTankObservedBadge,
              style: AppText.label(context)
                  .copyWith(color: scheme.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonLine extends StatelessWidget {
  const _ComparisonLine({required this.comparison});

  final GradeComparisonView comparison;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = comparison;
    final a = FuelAndTankLabels.grade(l, c.a);
    final b = FuelAndTankLabels.grade(l, c.b);
    final pct = c.percentDifference;
    final sentence = pct == null
        ? l.fuelAndTankCompareInsufficient(a, b)
        : pct > 0
            ? l.fuelAndTankCompareMore(a, pct.toString(), b)
            : pct < 0
                ? l.fuelAndTankCompareLess(a, (-pct).toString(), b)
                : l.fuelAndTankCompareSame(a, b);
    final caption = [
      if (c.basis == ComparisonBasis.residuals) l.fuelAndTankCompareAdjusted,
      if (c.basis == ComparisonBasis.uncontrolled) l.fuelAndTankUncontrolled,
      if (c.isMaterial == false) l.fuelAndTankCompareWithinUncertainty,
      if (pct != null) l.fuelAndTankSampleCount(c.sampleCount),
    ].join(' ');
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sentence,
              key: ValueKey('fuel_and_tank_compare_${c.a.key}_${c.b.key}'),
              style: AppText.body(context)),
          if (caption.isNotEmpty)
            Text(caption, style: AppText.label(context)),
        ],
      ),
    );
  }
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({required this.row});

  final ContextBehaviourView row;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final name = Text(
      FuelAndTankLabels.context(l, row.context),
      key: ValueKey('fuel_and_tank_row_${row.context.key}'),
      style: AppText.body(context).copyWith(fontWeight: FontWeight.w600),
    );
    if (!row.hasAnyFigure) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          name,
          Text(
            row.evidenceCount == 0
                ? l.fuelAndTankNoEvidenceRow
                : '${l.fuelAndTankNotEnoughEvidence} · '
                    '${l.fuelAndTankSampleCount(row.evidenceCount)}',
            style: AppText.label(context),
          ),
        ],
      );
    }
    final tiles = [
      FuelMetricTile(
          label: l.fuelAndTankMetricConsumption,
          kind: FuelMetricKind.consumption,
          metric: row.lPer100Km),
      FuelMetricTile(
          label: l.fuelAndTankMetricCostPerKm,
          kind: FuelMetricKind.costPerKm,
          metric: row.costPerKm),
      FuelMetricTile(
          label: l.fuelAndTankMetricRange,
          kind: FuelMetricKind.range,
          metric: row.rangeKm),
      FuelMetricTile(
          label: l.fuelAndTankMetricCo2e,
          kind: FuelMetricKind.co2e,
          metric: row.co2eKgPerKm),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        name,
        if (row.confounderControl == ConfounderControl.uncontrolled)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.xs),
            child: Text(l.fuelAndTankUncontrolled,
                key: ValueKey('fuel_and_tank_uncontrolled_${row.context.key}'),
                style: AppText.label(context)),
          ),
        const SizedBox(height: Spacing.md),
        LayoutBuilder(builder: (context, constraints) {
          final twoUp = constraints.maxWidth >= 360;
          final width = twoUp
              ? (constraints.maxWidth - Spacing.lg) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: Spacing.lg,
            runSpacing: Spacing.lg,
            children: [
              for (final t in tiles) SizedBox(width: width, child: t),
            ],
          );
        }),
      ],
    );
  }
}

/// Progressive disclosure: where each figure comes from, its interval,
/// and the model versions — for the reader who wants to check.
class _Details extends ConsumerWidget {
  const _Details({required this.rows, required this.view});

  final List<ContextBehaviourView> rows;
  final FuelAndTankView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final display = ref.watch(consumptionDisplaySettingProvider);
    String? detail(FuelMetricKind kind, String label, MetricView m) {
      final basis = m.basis;
      if (!m.isKnown || basis == null) return null;
      return [
        label,
        FuelAndTankLabels.basis(l, basis),
        ?FuelAndTankFormat.interval(l, kind, m, display),
      ].join(' · ');
    }

    return ExpansionTile(
      key: const Key('fuel_and_tank_behaviour_details'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: Spacing.md),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      title: Text(l.fuelAndTankDetailsToggle, style: AppText.body(context)),
      children: [
        for (final r in rows) ...[
          const SizedBox(height: Spacing.sm),
          Text(FuelAndTankLabels.context(l, r.context),
              style: AppText.label(context)),
          for (final line in [
            detail(FuelMetricKind.consumption, l.fuelAndTankMetricConsumption,
                r.lPer100Km),
            detail(FuelMetricKind.costPerKm, l.fuelAndTankMetricCostPerKm,
                r.costPerKm),
            detail(FuelMetricKind.range, l.fuelAndTankMetricRange, r.rangeKm),
            detail(FuelMetricKind.co2e, l.fuelAndTankMetricCo2e, r.co2eKgPerKm),
          ].nonNulls)
            Text(line, style: AppText.body(context)),
        ],
        const SizedBox(height: Spacing.md),
        Text(
          l.fuelAndTankModelVersions(view.profileModelVersion.toString(),
              view.blendModelVersion.toString()),
          style: AppText.label(context),
        ),
      ],
    );
  }
}
