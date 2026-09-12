// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/domain/fuel_type.dart';
import '../../../../../core/domain/refuel_economics.dart';
import '../../../../../core/domain/search_result_item.dart';
import '../../../../../core/navigation/app_routes.dart';
import '../../../../../core/theme/app_text.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../core/utils/unit_formatter.dart';
import '../../../../../l10n/app_localizations.dart';

/// One answer in the decision header: its title(s), its numbers, and the
/// reason it is here (#4090).
///
/// Its own library because `decision_header.dart` reached the 400-line
/// cap, and because the reason-picking logic below is the part of the
/// header most likely to keep growing: every new way of saying "here is
/// what this choice costs you" lands in [_reasonText].
class DecisionPickRow extends StatelessWidget {
  const DecisionPickRow({
    super.key,
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
