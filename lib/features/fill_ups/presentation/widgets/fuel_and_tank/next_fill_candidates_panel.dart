// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_text.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/utils/unit_formatter.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/services/fuel_and_tank_view.dart';
import 'fuel_and_tank_labels.dart';
import 'fuel_metric_tile.dart';

/// The per-fuel figures behind the next-fill decision, behind one
/// disclosure (#4278): price, fill volume, resulting mix, the four
/// expected metrics with their evidence, each candidate's own reasons,
/// and the fuels left out with why.
class NextFillCandidatesPanel extends StatelessWidget {
  const NextFillCandidatesPanel({super.key, required this.view});

  final NextFillView view;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final excluded = view.decision.excluded;
    return ExpansionTile(
      key: const Key('fuel_and_tank_candidates'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: Spacing.md),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      title: Text(l.fuelAndTankCandidatesToggle, style: AppText.body(context)),
      children: [
        for (final c in view.candidates) _Candidate(view: c),
        if (excluded.isNotEmpty) ...[
          const SizedBox(height: Spacing.md),
          Text(l.fuelAndTankExcludedTitle, style: AppText.label(context)),
          for (final e in excluded)
            Text(
              l.fuelAndTankExcludedLine(FuelAndTankLabels.grade(l, e.grade),
                  FuelAndTankLabels.reason(l, e.reason)),
              key: ValueKey('fuel_and_tank_excluded_${e.grade.key}'),
              style: AppText.body(context),
            ),
        ],
      ],
    );
  }
}

class _Candidate extends StatelessWidget {
  const _Candidate({required this.view});

  final CandidateView view;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = view.candidate;
    return Padding(
      key: ValueKey('fuel_and_tank_candidate_${c.grade.key}'),
      padding: const EdgeInsets.only(bottom: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            FuelAndTankLabels.grade(l, c.grade),
            style: AppText.body(context).copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            [
              l.fuelAndTankCandidatePrice(
                  UnitFormatter.formatPricePerUnit(c.pricePerLitre)),
              l.fuelAndTankCandidateFill(
                  UnitFormatter.formatVolume(c.fillLitres)),
            ].join(' · '),
            style: AppText.label(context),
          ),
          Text(
            l.fuelAndTankCandidateResultingMix(
                FuelAndTankLabels.mixLine(l, view.resultingMix)),
            style: AppText.label(context),
          ),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.lg,
            runSpacing: Spacing.md,
            children: [
              FuelMetricTile(
                  label: l.fuelAndTankMetricConsumption,
                  kind: FuelMetricKind.consumption,
                  metric: view.lPer100Km),
              FuelMetricTile(
                  label: l.fuelAndTankMetricCostPerKm,
                  kind: FuelMetricKind.costPerKm,
                  metric: view.costPerKm),
              FuelMetricTile(
                  label: l.fuelAndTankMetricRange,
                  kind: FuelMetricKind.range,
                  metric: view.rangeKm),
              FuelMetricTile(
                  label: l.fuelAndTankMetricCo2e,
                  kind: FuelMetricKind.co2e,
                  metric: view.co2eKgPerKm),
            ],
          ),
          for (final r in c.reasons.toSet())
            Text(FuelAndTankLabels.reason(l, r), style: AppText.label(context)),
        ],
      ),
    );
  }
}
