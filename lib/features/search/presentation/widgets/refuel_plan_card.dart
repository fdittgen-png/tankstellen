// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The trip's refuelling plans (#4146, rebuilt for #4363).
///
/// One block per DISTINCT itinerary, never one verdict — the same rule as
/// `docs/specs/refuel-economics.md` §3, and here it falls out of the
/// problem rather than being imposed on it: cheapest, fastest and least
/// driving are genuinely different trips, and which one a driver wants is
/// not something the app gets to decide. Objectives that agree collapse
/// into one block carrying both titles rather than repeating the same
/// stops twice.
///
/// Everything this card cannot stand behind, it says out loud: a detour
/// time estimated from the route's average speed, a candidate search that
/// hit its documented limit, a candidate set narrowed by an ignored
/// station or a partial-coverage source, and reference prices that are
/// not places anyone can stop at (#4348).
///
/// When no plan can be computed at all it names WHICH input is missing.
/// Range is the entire constraint the feature respects, so a guessed tank
/// capacity or an assumed consumption would invent the answer rather than
/// withhold it (economics spec §4.1).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/refuel_plan.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/refuel_plan_applier.dart';
import '../../providers/refuel_plan_candidates.dart';
import '../../providers/refuel_plan_provider.dart';
import 'refuel_plan_block.dart';

/// The route tab's refuelling plans: one block per distinct itinerary,
/// their caveats, or the named reason there is no plan.
class RefuelPlanCard extends ConsumerWidget {
  const RefuelPlanCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(refuelPlanProvider);

    if (!state.isReady) return _Blocked(blocker: state.blocker!);

    final plans = state.plans!;
    if (!plans.isFeasible) {
      return _Gap(gap: plans.gap!, state: state);
    }

    final cheapest = plans.cheapest;
    final distinct = plans.distinctPlans;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < distinct.length; i++) ...[
          if (i > 0) const SizedBox(height: Spacing.md),
          RefuelPlanBlock(
            titles: [
              for (final objective in plans.objectivesFor(distinct[i]))
                _title(l10n, objective),
            ],
            plan: distinct[i],
            stationNames: state.candidates.stationNames,
            tradeOff: cheapest == null || identical(distinct[i], cheapest)
                ? null
                : plans.tradeOff(distinct[i], cheapest),
            onApply: () => unawaited(_apply(context, ref, distinct[i], state)),
          ),
        ],
        _Caveats(state: state),
      ],
    );
  }

  /// Hand [plan] to navigation through the injected launcher, gated
  /// exactly as every station action is (#4348), and say what happened.
  static Future<void> _apply(
    BuildContext context,
    WidgetRef ref,
    RefuelPlan plan,
    RefuelPlanState state,
  ) async {
    final l10n = AppLocalizations.of(context);
    final applier = ref.read(refuelPlanApplierProvider);
    final result = await applier.apply(plan, state.candidates);
    if (!context.mounted) return;
    switch (result.refusal) {
      case null:
        SnackBarHelper.showSuccess(context,
            l10n.refuelPlanApplyOpened(result.launch!.planStops.length));
      case RefuelPlanApplyRefusal.referenceLocation:
        SnackBarHelper.showError(
            context, l10n.refuelPlanApplyRefusedReference);
      case RefuelPlanApplyRefusal.providerUnavailable:
        SnackBarHelper.showError(
            context, l10n.refuelPlanApplyRefusedUnavailable);
      case RefuelPlanApplyRefusal.noRoute:
      case RefuelPlanApplyRefusal.launchFailed:
        SnackBarHelper.showError(context, l10n.refuelPlanApplyFailed);
    }
  }

  static String _title(AppLocalizations l10n, RefuelObjective objective) =>
      switch (objective) {
        RefuelObjective.lowestCost => l10n.refuelPlanCheapestTitle,
        RefuelObjective.shortestTime => l10n.refuelPlanFastestTitle,
        RefuelObjective.leastExtraDistance => l10n.refuelPlanLeastDrivingTitle,
      };
}

/// What the plans above rest on, and what they do not.
class _Caveats extends StatelessWidget {
  const _Caveats({required this.state});

  final RefuelPlanState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final plans = state.plans;
    final references = state.candidates
        .excludedBy(PlanCandidateExclusion.referencePrice)
        .length;
    final approximate = plans != null &&
        plans.distinctPlans.any((p) => p.detourTimeIsApproximate);

    final lines = <String>[
      if (approximate) l10n.refuelPlanDetourTimeApproximate,
      if (plans?.searchWasBounded ?? false) l10n.refuelPlanSearchBounded,
      if (state.evidenceIncomplete) l10n.refuelPlanEvidenceIncomplete,
      if (references > 0) l10n.refuelPlanReferencePricesSkipped(references),
    ];
    if (lines.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.xs),
              child: Text(line, style: _muted(context)),
            ),
        ],
      ),
    );
  }
}

TextStyle _muted(BuildContext context) => AppText.label(context)
    .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

/// The route cannot be driven on this tank.
///
/// A planner that dressed this up as a best-effort plan would strand
/// someone, so the gap is the answer and it names the stretch — and says
/// when the gap is a fact about the CANDIDATES rather than the road.
class _Gap extends StatelessWidget {
  const _Gap({required this.gap, required this.state});

  final RefuelPlanGap gap;
  final RefuelPlanState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
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
        ),
        _Caveats(state: state),
      ],
    );
  }
}

class _Blocked extends StatelessWidget {
  const _Blocked({required this.blocker});

  final RefuelPlanBlocker blocker;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
      child: Text(message, style: _muted(context)),
    );
  }
}
