// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// One refuelling plan, rendered as something a driver can act on
/// (#4363, Epic #4358).
///
/// The old card showed "Cheapest trip · 2 stops · €61.40 total" and a
/// list of bare quantities. That is a summary of a plan, not a plan: it
/// never said WHERE to stop. A plan whose stops are anonymous cannot be
/// driven, and the driver cannot check it either.
///
/// So each stop is the real station by name, in order, with the litres
/// to buy, what they cost, and the tank level on arrival — the number
/// that proves the plan never dipped into the reserve. Two objectives
/// that landed on the same itinerary appear as ONE block with both
/// titles, and an alternative states what it costs against the cheapest
/// as three separate figures, never a combined score.
///
/// No arithmetic happens here. Every figure is read off the domain
/// result; the widget's whole job is to name and to qualify.
library;

import 'package:flutter/material.dart';

import '../../../../core/domain/money.dart';
import '../../../../core/domain/refuel_plan.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';

/// One plan and everything needed to present it honestly.
class RefuelPlanBlock extends StatelessWidget {
  const RefuelPlanBlock({
    super.key,
    required this.titles,
    required this.plan,
    required this.stationNames,
    this.tradeOff,
    this.onApply,
  });

  /// Hand this plan's stops to navigation (#4363). Null for a plan with
  /// nothing to add — a no-stop journey has no stops to apply.
  final VoidCallback? onApply;

  /// Every objective this itinerary is the answer to, already localized.
  /// More than one means the objectives agreed.
  final List<String> titles;

  final RefuelPlan plan;

  /// Station id to display name, from the candidate set the plan was
  /// built over.
  final Map<String, String> stationNames;

  /// What this plan costs against the cheapest, or null when it IS the
  /// cheapest.
  final RefuelPlanTradeOff? tradeOff;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final perKm = plan.costPerKm;
    final muted = AppText.label(context)
        .copyWith(color: theme.colorScheme.onSurfaceVariant);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Each objective label is its OWN node rather than one joined
          // string: at a large text scale two titles need two lines, and
          // a screen reader announces two answers rather than one run-on
          // sentence. The second label is not decoration.
          Wrap(
            spacing: Spacing.sm,
            children: [
              for (final title in titles)
                Text(title, style: AppText.title(context)),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(l10n.refuelPlanStopCount(plan.stops.length), style: muted),
          const SizedBox(height: Spacing.xs),
          Text(
            l10n.refuelPlanJourneyTotals(
              UnitFormatter.formatDistance(
                  plan.routeKm + plan.detourKm, fractionDigits: 0),
              _duration(l10n, plan.totalMinutes),
            ),
            style: muted,
          ),
          if (plan.stops.isEmpty) ...[
            const SizedBox(height: Spacing.sm),
            // #4362 — zero pump spend is not zero consumption.
            Text(
              l10n.refuelPlanNoStopSummary(
                  UnitFormatter.formatVolume(plan.consumedLitres)),
              style: AppText.body(context),
            ),
          ] else ...[
            const SizedBox(height: Spacing.sm),
            Text(
              l10n.refuelPlanTotal(
                PriceFormatter.formatTotal(plan.totalCost),
                perKm == null ? _unknown : PriceFormatter.formatPerKm(perKm),
              ),
              style: AppText.unit(context),
            ),
            const SizedBox(height: Spacing.sm),
            for (var i = 0; i < plan.stops.length; i++)
              _Stop(
                position: i + 1,
                stop: plan.stops[i],
                planCurrency: plan.currencyCode,
                name: stationNames[plan.stops[i].candidate.stationId] ??
                    plan.stops[i].candidate.stationId,
              ),
          ],
          if (onApply != null && plan.stops.isNotEmpty) ...[
            const SizedBox(height: Spacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: onApply,
                icon: const Icon(Icons.alt_route),
                label: Text(l10n.refuelPlanApply),
              ),
            ),
          ],
          if (tradeOff case final trade? when trade.isMaterial) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              l10n.refuelPlanTradeOff(
                trade.cost == null
                    ? _unknown
                    : _signed(trade.cost!.amount,
                        PriceFormatter.formatTotal(trade.cost!.amount.abs())),
                _signed(trade.minutes, _duration(l10n, trade.minutes.abs())),
                _signed(
                    trade.km,
                    UnitFormatter.formatDistance(trade.km.abs(),
                        fractionDigits: 0)),
              ),
              style: muted,
            ),
          ],
        ],
      ),
    );
  }

  String _duration(AppLocalizations l10n, double minutes) {
    final total = minutes.round();
    return total < 60
        ? l10n.durationMinutesShort(total)
        : l10n.durationHoursMinutes(total ~/ 60, total % 60);
  }
}

/// A leading sign so a saving and a sacrifice cannot be confused.
///
/// Sign glyphs only — every word around them comes from
/// [AppLocalizations], and the number is already formatted for the
/// active locale.
String _signed(double value, String formatted) =>
    value < 0 ? '\u2212$formatted' : '+$formatted';

/// Placeholder for a figure that is not available; the reason is stated
/// in its own localized caveat line.
const String _unknown = '\u2014';

class _Stop extends StatelessWidget {
  const _Stop({
    required this.position,
    required this.stop,
    required this.name,
    required this.planCurrency,
  });

  final int position;
  final PlannedStop stop;
  final String name;

  /// The currency the plan's totals are in. A stop quoted in another one
  /// shows its own price too; a domestic stop would only repeat itself.
  final String? planCurrency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final native = stop.candidate.nativePrice;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.refuelPlanStopNamed(position, name),
            style: AppText.body(context)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            l10n.refuelPlanStopDetail(
              UnitFormatter.formatVolume(stop.litres),
              PriceFormatter.formatTotal(stop.cost),
              UnitFormatter.formatVolume(stop.arrivalLitres),
            ),
            style: AppText.body(context),
          ),
          // #4361 — a stop abroad keeps the price its country quotes,
          // beside the converted total rather than instead of it.
          if (native case final Money price?
              when price.currencyCode != planCurrency)
            Text(
              // The SELLING country's currency, not the driver's — the
              // whole point of showing it at all (#4361).
              l10n.refuelPlanStopNativePrice(PriceFormatter.formatPrice(
                  price.amount,
                  currencyOverride: price.currencyCode)),
              style: AppText.label(context)
                  .copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
