// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/refuel_plan.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/refuel_plan_provider.dart';

/// The trip's refuelling plan (#4146).
///
/// Two plans, never one verdict — the same rule as
/// `docs/specs/refuel-economics.md` §3, and here it falls out of the
/// problem rather than being imposed on it: "cheapest" and "fastest" are
/// genuinely different trips, and which one a driver wants is not
/// something the app gets to decide.
///
/// When the plan cannot be computed this says WHICH input is missing.
/// Range is the entire constraint the feature respects, so a guessed tank
/// capacity or an assumed consumption would invent the answer rather than
/// withhold it (economics spec §4.1).
class RefuelPlanCard extends ConsumerWidget {
  const RefuelPlanCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(refuelPlanProvider);

    if (!state.isReady) {
      return _Blocked(blocker: state.blocker!);
    }
    final plans = state.plans!;
    if (!plans.isFeasible) {
      return _Gap(gap: plans.gap!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (plans.cheapest case final plan?)
          _PlanBlock(title: l10n.refuelPlanCheapestTitle, plan: plan),
        if (plans.fastest case final plan?) ...[
          const SizedBox(height: Spacing.md),
          _PlanBlock(title: l10n.refuelPlanFastestTitle, plan: plan),
        ],
      ],
    );
  }
}

class _PlanBlock extends StatelessWidget {
  const _PlanBlock({required this.title, required this.plan});

  final String title;
  final RefuelPlan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final perKm = plan.costPerKm;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppText.title(context)),
          const SizedBox(height: Spacing.xs),
          Text(
            l10n.refuelPlanStopCount(plan.stops.length),
            style: AppText.label(context)
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (plan.stops.isNotEmpty) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              l10n.refuelPlanTotal(
                PriceFormatter.formatPrice(plan.totalCost),
                perKm == null ? '—' : PriceFormatter.formatPerKm(perKm),
              ),
              style: AppText.unit(context),
            ),
            const SizedBox(height: Spacing.sm),
            // Each stop states the litres to buy, because "just enough to
            // reach a cheaper station" is the instruction — not always a
            // full tank, and that is the whole point of the plan.
            for (final stop in plan.stops)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.xs),
                child: Text(
                  l10n.refuelPlanStopLine(
                    UnitFormatter.formatVolume(stop.litres),
                    PriceFormatter.formatPrice(stop.cost),
                  ),
                  style: AppText.body(context),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// The route cannot be driven on this tank.
///
/// A planner that dressed this up as a best-effort plan would strand
/// someone, so the gap is the answer and it names the stretch.
class _Gap extends StatelessWidget {
  const _Gap({required this.gap});

  final RefuelPlanGap gap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SectionCard(
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              l10n.refuelPlanGap(
                UnitFormatter.formatDistance(gap.fromKm, fractionDigits: 0),
                UnitFormatter.formatDistance(gap.toKm, fractionDigits: 0),
              ),
              style: AppText.body(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blocked extends StatelessWidget {
  const _Blocked({required this.blocker});

  final RefuelPlanBlocker blocker;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final message = switch (blocker) {
      RefuelPlanBlocker.noConsumption => l10n.refuelPlanNeedsConsumption,
      RefuelPlanBlocker.noTankCapacity ||
      RefuelPlanBlocker.noTankLevel =>
        l10n.refuelPlanNeedsTank,
      RefuelPlanBlocker.noPricedStations => l10n.refuelPlanNeedsPrices,
      // #4361 — the prices exist; what is missing is a rate to compare
      // them at, and saying so is the honest answer.
      RefuelPlanBlocker.noComparableCurrency =>
        l10n.refuelPlanNeedsExchangeRate,
      RefuelPlanBlocker.noRoute => l10n.startSearch,
    };

    return SectionCard(
      child: Text(
        message,
        style: AppText.body(context)
            .copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
