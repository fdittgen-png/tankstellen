// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/domain/refuel_profile_provider.dart';
import '../../../../../core/domain/search_result_item.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/utils/unit_formatter.dart';
import '../../../../../core/widgets/primary_card.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../vehicle/api.dart';
import '../../../providers/refuel_decision_provider.dart';
import 'decision_pick_row.dart';
import 'refuel_quantity_sheet.dart';
import '../../../providers/search_filters_provider.dart';

/// The three meaningful choices, above the list (#4090, epic #4087).
///
/// The results screen used to be a sorted database dump: the user read
/// twenty rows and did the economics in their head. This names the three
/// questions a refuel actually has — best value, cheapest, closest —
/// answers each, and says WHY, so the answer can be disagreed with.
///
/// ## Rules it keeps
///
///  * **Three answers, never one verdict.** `docs/specs/refuel-
///    economics.md` §3: the app does not tell the user which station is
///    best, it tells them what each choice costs.
///  * **A station that wins twice appears once**, its titles joined —
///    repeating the same station three times would read as three
///    options.
///  * **No consumption, no Best Value row.** It is replaced by the
///    one-line reason it is missing (§4.1). A fabricated recommendation
///    is worse than an absent one.
///  * **Both halves of every trade.** A cheaper-but-further row states
///    what the pump saves AND the driving it adds; where the detour eats
///    the saving outright it states the break-even volume instead.
///  * **The assumptions are visible**, because the arithmetic is only as
///    honest as the numbers under it.
///
/// It is the list's first scrolling item, not a band above it: on a
/// screen whose purpose is comparing stations, a header must move out of
/// the way on the first flick (the #3937 rule).
class DecisionHeader extends ConsumerWidget {
  const DecisionHeader({super.key, required this.items});

  /// The filtered, sorted result set the header speaks for.
  final List<SearchResultItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decision = ref.watch(refuelDecisionProvider(items));
    final picks = decision.distinctPicks;
    // Nothing to recommend between: one priced station is the answer by
    // itself, and zero is the empty state's business.
    if (picks.length < 2 && decision.valueRankingAvailable) {
      return const SizedBox.shrink();
    }
    if (picks.isEmpty) return const SizedBox.shrink();

    final stations = {
      for (final item in items.whereType<FuelStationResult>())
        item.station.id: item,
    };
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final fuelType = ref.watch(selectedFuelTypeProvider);
    final profile = ref.watch(refuelProfileProvider);

    return PrimaryCard(
      margin: const EdgeInsets.fromLTRB(
          Spacing.lg, Spacing.sm, Spacing.lg, Spacing.sm),
      // The rows own their own padding — a pick is a full-width tap
      // target and its divider has to reach both edges.
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final quote in picks) ...[
            if (quote != picks.first)
              Divider(
                height: 1,
                thickness: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            DecisionPickRow(
              decision: decision,
              quote: quote,
              result: stations[quote.candidate.stationId],
              fuelType: fuelType,
            ),
          ],
          // §4.1 — the missing ranking is stated, not hidden.
          if (!decision.valueRankingAvailable)
            _ValueUnavailableRow(text: l10n.decisionValueUnavailable),
          _Footer(
            count: items.length,
            assumption: decision.valueRankingAvailable
                ? l10n.decisionAssumption(
                    UnitFormatter.formatConsumption(
                        profile.consumptionLPer100km ?? 0,
                        isEv: false),
                    UnitFormatter.formatVolume(profile.litresIntended),
                  )
                : null,
            // #4095 — the assumption is not just visible, it is
            // changeable. The sheet leads with the measured median, so
            // the default stays the default.
            // #4095 — the active vehicle's capacity, when it has one on
            // file, so the sheet can offer "a full tank". Null simply
            // means that shortcut is absent: the app never requires a
            // capacity, and it never enters the arithmetic (spec §2).
            onEditAssumption: () => unawaited(RefuelQuantitySheet.show(
              context,
              tankCapacityL:
                  ref.watch(activeVehicleProfileProvider)?.tankCapacityL,
            )),
          ),
        ],
      ),
    );
  }
}

/// The Best Value row's stand-in when the vehicle side is unknown.
class _ValueUnavailableRow extends StatelessWidget {
  const _ValueUnavailableRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md, vertical: Spacing.sm),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The assumptions, and the way on to the full list.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.count,
    this.assumption,
    this.onEditAssumption,
  });

  final int count;
  final String? assumption;

  /// #4095 — opens the refill-quantity sheet.
  final VoidCallback? onEditAssumption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Spacing.md, Spacing.xs, Spacing.sm, Spacing.xs),
      child: Row(
        children: [
          if (assumption != null)
            Expanded(
              // Tappable, with the affordance spelled out: an assumption
              // the user cannot reach is only half honest.
              child: InkWell(
                onTap: onEditAssumption,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                  child: Text(
                    onEditAssumption == null
                        ? assumption!
                        : '${assumption!} · ${l10n.refuelQuantityChange}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: Spacing.sm),
          Flexible(
            child: Text(
              l10n.decisionShowAll(count),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
