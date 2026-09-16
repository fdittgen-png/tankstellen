// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The blocks of the home surface (#4137).
///
/// Home's whole reason to exist is that the app already knows things —
/// the vehicle, the last results, the fill-up history, the savings — and
/// showed none of it until asked. Each block below answers one question
/// the user would otherwise have to start a task to ask.
///
/// ## Empty states are the design, not an afterthought
///
/// #4137 is explicit: "a first-run home that shows four empty cards is
/// worse than the search screen it replaced. Prefer showing fewer blocks
/// to showing empty ones." So every block here returns
/// [SizedBox.shrink] when it has nothing true to say, and the screen
/// composes whatever survives. No invented figures, no placeholder
/// zeroes — the same rule `savings_card.dart` follows.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/search_result_item.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fill_ups/api.dart';
import '../../../search/api.dart';


/// "Your next fuel stop" — the three answers, compactly.
///
/// Reuses the search feature's own decision content rather than ranking
/// again: `docs/specs/refuel-economics.md` §3 forbids naming one station
/// objectively best, and #4139 owns that decision if it is ever
/// revisited. Home may present the three answers MORE COMPACTLY; it may
/// not decide for the user.
///
/// Renders only when a search already produced results. `SearchState`'s
/// `build()` is read-only — watching it never starts a search — so
/// arriving at home does not fire network calls, and a user who has not
/// searched yet simply does not see this block.
class HomeNextStopBlock extends ConsumerWidget {
  const HomeNextStopBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchStateProvider).asData?.value.data;
    final items = results ?? const <SearchResultItem>[];
    if (items.whereType<FuelStationResult>().isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Spacing.lg, Spacing.md, Spacing.lg, Spacing.xs),
          child: Text(l10n.homeNextStopTitle, style: AppText.title(context)),
        ),
        DecisionHeader(items: items),
      ],
    );
  }
}

/// "Your car" — cost per kilometre and consumption, when measured.
///
/// Both figures come from `ConsumptionStats.fromFillUps`, so they exist
/// only once the user has logged enough fill-ups. Below that there is
/// nothing honest to show, and the block disappears rather than
/// rendering a dash.
class HomeVehicleBlock extends ConsumerWidget {
  const HomeVehicleBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(consumptionStatsProvider);
    final costPerKm = stats.avgCostPerKm;
    final lPer100 = stats.avgConsumptionL100km;
    if (costPerKm == null && lPer100 == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.homeVehicleTitle, style: AppText.title(context)),
          const SizedBox(height: Spacing.xs),
          Row(
            children: [
              if (costPerKm != null)
                Expanded(
                  child: _Figure(
                    value: PriceFormatter.formatPerKm(costPerKm),
                    label: l10n.homeVehicleCostPerKm,
                  ),
                ),
              if (lPer100 != null)
                Expanded(
                  child: _Figure(
                    value: UnitFormatter.formatDecimal(lPer100),
                    label: l10n.homeVehicleConsumption,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            l10n.homeVehicleFromFillUps,
            style: AppText.body(context)
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// "You've saved" — the realised savings ledger (#4136).
///
/// Mirrors `savings_card.dart`'s rule exactly: below the minimum sample
/// count there is no baseline to measure against, so the block shows
/// nothing rather than a number that is not true (trust rule 1). A
/// history spanning two currencies has no single total, so it stays
/// silent here too — the full card on the Cost surface is where that
/// nuance belongs.
class HomeSavingsBlock extends ConsumerWidget {
  const HomeSavingsBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(savingsLedgerProvider);
    if (!ledger.isAvailable || ledger.entries.isEmpty) {
      return const SizedBox.shrink();
    }
    final total = ledger.total;
    if (total == null || !ledger.isSingleCurrency) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.homeSavingsTitle, style: AppText.title(context)),
          const SizedBox(height: Spacing.xs),
          Text(PriceFormatter.formatTotal(total),
              style: AppText.display(context)),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppText.display(context)),
        Text(
          label,
          style: AppText.body(context)
              .copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
