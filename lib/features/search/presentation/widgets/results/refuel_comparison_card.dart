// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The stations the driver picked, costed side by side (#4363, Epic
/// #4358).
///
/// One card, whatever door the stations came in through — a list row, a
/// detail screen, a map pin — because they all write the same selection
/// and this reads the same shared result. Each row is the trip ledger's
/// answer (#4360) in one currency (#4361): the litres the pump delivers
/// for the SAME net refill, the cash, the round trip. The cheapest is a
/// named baseline and every other row says what it costs over it; there
/// is no score.
///
/// What cannot be stated is stated as such: a straight-line distance is
/// labelled estimated, a pending road quote says it is on its way, a
/// reference price keeps its price and has no drive (#4348), and a
/// currency without a rate withholds the cheapest rather than guessing.
///
/// No arithmetic here — every figure is read off the provider.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/domain/refuel_comparison_selection.dart';
import '../../../../../core/domain/refuel_trip_cost.dart';
import '../../../../../core/theme/app_text.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/utils/localized_fuel_name.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../core/utils/station_extensions.dart';
import '../../../../../core/utils/unit_formatter.dart';
import '../../../../../core/widgets/section_card.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../providers/refuel_comparison_provider.dart';
import 'refuel_comparison_context_row.dart';

/// The stations the driver picked, costed side by side and each row
/// named — the shared comparison, whichever door its stations came in
/// through.
class RefuelComparisonCard extends ConsumerWidget {
  const RefuelComparisonCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final comparison = ref.watch(refuelComparisonProvider);
    final muted = AppText.label(context)
        .copyWith(color: theme.colorScheme.onSurfaceVariant);
    if (comparison.isEmpty) {
      // #4396 — picking mode with nothing picked yet. The toggles are
      // already on every row; this says what they are for, once, in the
      // slot the comparison itself will take. Outside picking mode the
      // slot stays the zero-height item `ResultsLeadingItems` documents.
      if (!ref.watch(refuelComparisonPickingProvider)) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            Spacing.lg, Spacing.sm, Spacing.lg, Spacing.sm),
        child: SectionCard(
          child: Text(
            key: const Key('refuel_compare_pick_prompt'),
            l10n.refuelComparePickPrompt,
            style: muted,
          ),
        ),
      );
    }

    final caveats = <String>[
      if (!comparison.originKnown) l10n.refuelCompareOriginMissing,
      if (comparison.moneyWithheld) l10n.refuelCompareCurrencyWithheld,
      if (comparison.coverageIncomplete) l10n.decisionPartialCoverageNote,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Spacing.lg, Spacing.sm, Spacing.lg, Spacing.sm),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // The count sits UNDER the title rather than beside it: at
            // 320 dp and double text the three-across header could not
            // fit, and a truncated count is worse than a second line.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.refuelCompareTitle,
                          style: AppText.title(context)),
                      Text(l10n.refuelCompareCount(comparison.entries.length),
                          style: muted),
                    ],
                  ),
                ),
                TextButton(
                  key: const Key('refuel_compare_clear'),
                  onPressed: () => ref
                      .read(refuelComparisonSelectionProvider.notifier)
                      .clear(),
                  child: Text(l10n.refuelCompareClear),
                ),
              ],
            ),
            RefuelComparisonContextRow(comparison: comparison),
            const SizedBox(height: Spacing.sm),
            for (final entry in comparison.entries)
              _Row(entry: entry, comparison: comparison),
            for (final line in caveats)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.xs),
                child: Text(line, style: muted),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.entry, required this.comparison});

  final RefuelComparisonEntry entry;
  final RefuelComparison comparison;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = AppText.label(context)
        .copyWith(color: theme.colorScheme.onSurfaceVariant);
    final cost = entry.cost;
    final cash = entry.cash;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.station.displayName,
                    style: AppText.body(context)
                        .copyWith(fontWeight: FontWeight.w600)),
                // The pump price is a separate FACT, in its own currency.
                if (entry.candidate.pricePerLitre case final price?)
                  Text(
                    UnitFormatter.formatPricePerUnit(price,
                        countryCode: entry.offer.countryCode,
                        fuelType: entry.fuel),
                    style: muted,
                  ),
                if (cost != null && cash != null) ...[
                  Text(
                    (comparison.isJourneyStop
                            ? l10n.refuelCompareRowStopCost
                            : l10n.refuelCompareRowCost)(
                      UnitFormatter.formatVolume(cost.litresDispensed),
                      PriceFormatter.formatTotal(cash.amount),
                      UnitFormatter.formatDistance(cost.travelKm,
                          fractionDigits: 0),
                    ),
                    style: AppText.body(context),
                  ),
                  if (entry.nativeDiffersFrom(comparison.currency))
                    Text(
                      l10n.refuelPlanStopNativePrice(
                          PriceFormatter.formatTotal(entry.nativeCash!.amount,
                              currencyOverride:
                                  entry.nativeCash!.currencyCode)),
                      style: muted,
                    ),
                  if (entry.isBaseline)
                    Text(l10n.refuelCompareBaseline,
                        key: Key('refuel_compare_baseline_${entry.stationId}'),
                        style: AppText.label(context).copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600))
                  else if (entry.extraVsBaseline case final extra?
                      when comparison.baseline != null)
                    Text(
                      l10n.refuelCompareCostsMore(
                        PriceFormatter.formatTotal(extra.amount),
                        comparison.baseline!.station.displayName,
                      ),
                      style: muted,
                    ),
                  if (_travelNote(l10n, entry) case final note?)
                    Text(note, style: muted),
                ] else
                  Text(_blockerLine(l10n, entry), style: muted),
              ],
            ),
          ),
          IconButton(
            key: Key('refuel_compare_remove_${entry.stationId}'),
            icon: const Icon(Icons.close),
            tooltip: l10n.refuelCompareRemove,
            onPressed: () => ref
                .read(refuelComparisonSelectionProvider.notifier)
                .remove(entry.stationId),
          ),
        ],
      ),
    );
  }

  String? _travelNote(AppLocalizations l10n, RefuelComparisonEntry e) =>
      switch (e.travel) {
        RefuelComparisonTravel.road => null,
        RefuelComparisonTravel.pending => l10n.refuelCompareDistancePending,
        RefuelComparisonTravel.approximate =>
          l10n.refuelCompareDistanceApproximate,
      };

  String _blockerLine(AppLocalizations l10n, RefuelComparisonEntry e) =>
      switch (e.blocker) {
        // #4348 — a real price at a place nobody can drive to.
        RefuelTripBlocker.notAStation => l10n.stationReferencePriceNotice,
        RefuelTripBlocker.noPrice =>
          l10n.refuelCompareNoPrice(localizedFuelName(l10n, e.fuel)),
        RefuelTripBlocker.noConsumption =>
          l10n.refuelCompareConsumptionMissing,
        RefuelTripBlocker.cannotReachStation => l10n.refuelCompareOutOfRange,
        RefuelTripBlocker.exceedsCapacity =>
          l10n.refuelCompareExceedsCapacity,
        // #4361 — costed, but in a currency without a rate.
        null => l10n.refuelCompareCurrencyWithheld,
        _ => l10n.refuelCompareNotCosted,
      };
}
