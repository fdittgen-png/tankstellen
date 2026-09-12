// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/domain/fuel_type.dart';
import '../../../../../core/domain/refuel_economics.dart';
import '../../../../../core/domain/refuel_profile_provider.dart';
import '../../../../../core/domain/search_result_item.dart';
import '../../../../../core/navigation/app_routes.dart';
import '../../../../../core/theme/app_text.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../core/utils/unit_formatter.dart';
import '../../../../../core/widgets/primary_card.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../providers/refuel_decision_provider.dart';
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
            _PickRow(
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
          ),
        ],
      ),
    );
  }
}

/// One answer: its title(s), its numbers, and the reason it is here.
class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.decision,
    required this.quote,
    required this.result,
    required this.fuelType,
  });

  final RefuelDecision decision;
  final RefuelQuote quote;
  final FuelStationResult? result;
  final FuelType fuelType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final rankings = decision.rankingsFor(quote.candidate.stationId);
    final isValue = rankings.contains(RefuelRanking.bestValue);
    final station = result?.station;

    // Titles in the spec's order, joined — one station, one row.
    final titles = [
      if (rankings.contains(RefuelRanking.bestValue)) l10n.decisionBestValue,
      if (rankings.contains(RefuelRanking.cheapest)) l10n.decisionCheapest,
      if (rankings.contains(RefuelRanking.closest)) l10n.decisionClosest,
    ].join(' · ');

    final accent =
        isValue ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: station == null
          ? null
          : () => unawaited(StationDetailRoute(station.id).push<void>(context)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md, vertical: Spacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titles.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _Numbers(quote: quote, fuelType: fuelType),
                  if (station != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      station.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  ..._reason(context, l10n, theme),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  /// Why this row is worth reading — at most one line, and only when
  /// there is something true to say.
  List<Widget> _reason(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    final text = _reasonText(l10n);
    if (text == null) return const [];
    return [
      const SizedBox(height: 3),
      Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ];
  }

  String? _reasonText(AppLocalizations l10n) {
    final rankings = decision.rankingsFor(quote.candidate.stationId);
    if (rankings.contains(RefuelRanking.bestValue)) {
      return l10n.decisionReasonBestValue;
    }
    // Everything else is stated RELATIVE to the recommendation, which is
    // the only way "cheaper" means anything.
    final reference = decision.bestValue ?? decision.closest;
    if (reference == null || reference == quote) return null;

    // The detour eats the saving at this quantity: say from what volume
    // it stops doing so, rather than implying a win.
    final breakEven = decision.breakEvenLitres(quote, reference);
    if (breakEven != null && breakEven > decision.profile.litresIntended) {
      return l10n.decisionReasonBreakEven(
          UnitFormatter.formatVolume(breakEven));
    }

    final price = quote.candidate.pricePerLitre;
    final refPrice = reference.candidate.pricePerLitre;
    if (price == null || refPrice == null || refPrice <= price) return null;
    final litres = decision.profile.litresIntended;
    final extraKm = decision.extraTravelKm(quote, reference);
    return l10n.decisionReasonSaves(
      PriceFormatter.formatTotal((refPrice - price) * litres),
      UnitFormatter.formatVolume(litres),
      PriceFormatter.formatDistance(extraKm),
    );
  }
}

/// Price and distance, the two numbers every answer is measured in.
class _Numbers extends StatelessWidget {
  const _Numbers({required this.quote, required this.fuelType});

  final RefuelQuote quote;
  final FuelType fuelType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Flexible(
          child: Text(
            UnitFormatter.formatPricePerUnit(
              quote.candidate.pricePerLitre,
              fuelType: fuelType,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.title(context).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '  ·  ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        Flexible(
          child: Text(
            PriceFormatter.formatDistance(quote.candidate.oneWayKm),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
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
  const _Footer({required this.count, this.assumption});

  final int count;
  final String? assumption;

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
              child: Text(
                assumption!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
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
