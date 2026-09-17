// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/domain/fuel/next_fill_decision.dart';
import '../../../../../core/domain/fuel/next_fill_request.dart';
import '../../../../../core/providers/consumption_display_provider.dart';
import '../../../../../core/theme/app_text.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../core/utils/unit_formatter.dart';
import '../../../../../core/widgets/panel_card.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/services/fuel_and_tank_view.dart';
import '../../../providers/fuel_and_tank_provider.dart';
import 'fuel_and_tank_labels.dart';
import 'fuel_metric_tile.dart';
import 'next_fill_candidates_panel.dart';

/// Next-fill guidance (#4278): the objective selector, the decision's
/// outcome and every reason behind it, the trade-off with break-even,
/// and the resulting mix. Formats [NextFillView]; decides nothing.
class NextFillSection extends ConsumerWidget {
  const NextFillSection({super.key, required this.view});

  final NextFillView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final decision = view.decision;
    return PanelCard(
      key: const Key('fuel_and_tank_next_fill'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.fuelAndTankNextFillTitle, style: AppText.label(context)),
          const SizedBox(height: Spacing.sm),
          _ObjectiveSelector(selected: view.objective),
          const SizedBox(height: Spacing.lg),
          if (!view.showsDecision)
            const _NoPrices(key: Key('fuel_and_tank_no_prices'))
          else ...[
            Text(
              FuelAndTankLabels.outcome(l, decision),
              key: ValueKey('fuel_and_tank_outcome_${decision.outcome.name}'),
              style: AppText.title(context),
            ),
            if (decision.candidates.isNotEmpty)
              Text(
                l.fuelAndTankDecisionConfidence(
                    FuelAndTankLabels.confidence(l, decision.confidence)),
                style: AppText.label(context),
              ),
            if (view.offerCount > 0)
              Text(l.fuelAndTankPricesSource(view.offerCount),
                  style: AppText.label(context)),
            for (final r in decision.reasons.toSet())
              Padding(
                padding: const EdgeInsets.only(top: Spacing.sm),
                child: Text(FuelAndTankLabels.reason(l, r),
                    key: ValueKey('fuel_and_tank_reason_${r.name}'),
                    style: AppText.body(context)),
              ),
            if (_recommended(decision) case final CandidateView c) ...[
              const SizedBox(height: Spacing.md),
              Text(
                l.fuelAndTankCandidateResultingMix(
                    FuelAndTankLabels.mixLine(l, c.resultingMix)),
                key: const Key('fuel_and_tank_resulting_mix'),
                style: AppText.body(context),
              ),
            ],
            for (final t in decision.tradeOffs) _TradeOffLines(tradeOff: t),
            if (view.convergence case final ConvergenceView c)
              _ConvergenceLine(convergence: c),
            if (view.candidates.isNotEmpty || decision.excluded.isNotEmpty)
              NextFillCandidatesPanel(view: view),
          ],
        ],
      ),
    );
  }

  CandidateView? _recommended(NextFillDecision d) =>
      d.outcome == NextFillOutcome.recommend && view.candidates.isNotEmpty
          ? view.candidates.first
          : null;
}

class _ObjectiveSelector extends ConsumerWidget {
  const _ObjectiveSelector({required this.selected});

  final FillObjective selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.fuelAndTankObjectiveTitle, style: AppText.title(context)),
        const SizedBox(height: Spacing.sm),
        // Radio rows, not chips: a chip label cannot wrap, and these
        // clip at 320 dp under a 1.3× font or a longer translation.
        RadioGroup<FillObjective>(
          groupValue: selected,
          onChanged: (o) {
            if (o == null) return;
            unawaited(ref.read(fillObjectiveSettingProvider.notifier).set(o));
          },
          child: Column(
            children: [
              for (final o in FillObjective.values)
                RadioListTile<FillObjective>(
                  key: ValueKey('fuel_and_tank_objective_${o.name}'),
                  value: o,
                  contentPadding: EdgeInsets.zero,
                  title: Text(FuelAndTankLabels.objective(l, o),
                      style: AppText.body(context)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoPrices extends StatelessWidget {
  const _NoPrices({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.fuelAndTankNoPricesTitle, style: AppText.title(context)),
        const SizedBox(height: Spacing.xs),
        Text(l.fuelAndTankNoPricesBody, style: AppText.body(context)),
      ],
    );
  }
}

/// The leading fuel against one alternative: the per-km deltas and where
/// the decision would flip.
class _TradeOffLines extends ConsumerWidget {
  const _TradeOffLines({required this.tradeOff});

  final FillTradeOff tradeOff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final display = ref.watch(consumptionDisplaySettingProvider);
    final t = tradeOff;
    final chosen = FuelAndTankLabels.grade(l, t.chosen);
    final other = FuelAndTankLabels.grade(l, t.alternative);
    final currency = PriceFormatter.currency;
    final lines = [
      if (t.costPerKmDelta case final double d when d != 0)
        d < 0
            ? l.fuelAndTankTradeOffCheaper(
                PriceFormatter.formatPerKm(-d), currency, other)
            : l.fuelAndTankTradeOffDearer(
                PriceFormatter.formatPerKm(d), currency, other),
      if (t.co2eKgPerKmDelta case final double d when d != 0)
        d < 0
            ? l.fuelAndTankTradeOffCo2eLess(
                FuelAndTankFormat.gramsFigure(-d), other)
            : l.fuelAndTankTradeOffCo2eMore(
                FuelAndTankFormat.gramsFigure(d), other),
      if (t.breakEvenPricePerLitre case final double p)
        l.fuelAndTankBreakEvenPrice(
            chosen, UnitFormatter.formatPricePerUnit(p), other),
      if (t.breakEvenLPer100Km case final double b)
        l.fuelAndTankBreakEvenConsumption(other,
            FuelAndTankFormat.value(l, FuelMetricKind.consumption, b, display)),
      // The cleaner of the two is the one that "avoids" the CO2e.
      if ((t.costPerKgCo2e, t.co2eKgPerKmDelta)
          case (final double c, final double e) when c > 0)
        l.fuelAndTankCostPerKgCo2e(
            e < 0 ? chosen : other, PriceFormatter.formatTotal(c)),
    ];
    if (lines.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: ValueKey('fuel_and_tank_tradeoff_${t.alternative.key}'),
      padding: const EdgeInsets.only(top: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines) Text(line, style: AppText.body(context)),
        ],
      ),
    );
  }
}

class _ConvergenceLine extends StatelessWidget {
  const _ConvergenceLine({required this.convergence});

  final ConvergenceView convergence;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = convergence;
    final fuel = FuelAndTankLabels.grade(l, c.plan.target.grade);
    final percent = c.percent.toString();
    final text = switch (c.plan.status) {
      ConvergenceStatus.alreadyAtTarget =>
        l.fuelAndTankConvergenceAlready(percent, fuel),
      ConvergenceStatus.reachable =>
        l.fuelAndTankConvergenceReachable(c.fills, fuel, percent),
      ConvergenceStatus.unreachableWithinHorizon =>
        l.fuelAndTankConvergenceUnreachable(fuel, percent, c.fills.toString()),
      ConvergenceStatus.notComputable => l.fuelAndTankConvergenceNotComputable,
    };
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.md),
      child: Text(text,
          key: ValueKey('fuel_and_tank_convergence_${c.plan.status.name}'),
          style: AppText.body(context)),
    );
  }
}
