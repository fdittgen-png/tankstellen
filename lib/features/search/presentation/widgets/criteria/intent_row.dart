// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/domain/refuel_profile_provider.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../favorites/api.dart';
import '../../../domain/search_intent.dart';
import '../../../providers/search_intent_apply.dart';
import 'criteria_chip_group.dart';
import 'criteria_section_header.dart';

/// The intent row at the top of the criteria sheet (#4138).
///
/// The sheet below this asks for fuel type, radius, sort order, mode,
/// strategy and detour budget — the knobs the ENGINE needs. This row
/// asks the question the user actually arrived with, and each answer
/// applies a named preset over those same controls.
///
/// Three rules this widget exists to keep:
///
///  * **The knobs stay authoritative.** Applying an intent writes
///    through the existing setters; nothing here owns state. Touching
///    any control re-derives the selection, so it falls to "Custom"
///    rather than showing a label that no longer matches.
///  * **An unavailable intent says why.** "Best stop" ranks by
///    effective price per litre, which needs the drive cost, which
///    needs a known consumption. Without one it renders disabled with a
///    one-line reason instead of silently falling back to a price sort
///    (trust rule 1).
///  * **No new ranking.** Every intent is a preset; `docs/specs/
///    refuel-economics.md` §3 forbids naming one station objectively
///    best, and #4139 owns that decision if it is ever revisited.
class IntentRow extends ConsumerWidget {
  const IntentRow({super.key, required this.routeMode});

  /// Whether the sheet is in route mode — the discriminator that
  /// separates "Cheapest nearby" from "On my route" (they share a sort
  /// and an open-now filter).
  final bool routeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = detectIntent(readSearchIntentState(ref, routeMode: routeMode));

    final hasConsumption =
        (ref.watch(refuelProfileProvider).consumptionLPer100km ?? 0) > 0;
    final hasFavourites = ref.watch(favoritesProvider).isNotEmpty;

    const intents = SearchIntent.values;
    final blockers = {
      for (final i in intents)
        i: blockerFor(i,
            hasConsumption: hasConsumption,
            hasFavourites: hasFavourites,
            hasRoute: routeMode),
    };

    // The reason line belongs to the one intent that can be blocked by
    // something the user can fix from here; the others are blocked by
    // context (no route, no favourite) that the sheet already shows.
    final showConsumptionReason =
        blockers[SearchIntent.bestStop] == SearchIntentBlocker.consumptionUnknown;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CriteriaSectionHeader(l10n.criteriaIntentHeader),
        const SizedBox(height: Spacing.xs),
        CriteriaChipGroup(
          groupKeyPrefix: 'criteria-intent',
          // +1 for the Custom read-out: six chips must never fold
          // behind "Show more". Hiding Custom would leave the sheet
          // showing NO selection once the user touches a knob — the
          // "label that no longer matches the state" #4138 forbids.
          collapsedCount: intents.length + 1,
          selectedFlags: [
            for (final i in intents) i == selected,
            // The trailing Custom chip, selected when nothing matches.
            selected == null,
          ],
          chips: [
            for (final i in intents)
              _chip(context, ref, i, selected, blockers[i]),
            _customChip(context, l10n, selected == null),
          ],
        ),
        if (showConsumptionReason)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Spacing.lg, Spacing.xs, Spacing.lg, 0),
            child: Text(
              l10n.criteriaIntentNeedsConsumption,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _chip(
    BuildContext context,
    WidgetRef ref,
    SearchIntent intent,
    SearchIntent? selected,
    SearchIntentBlocker? blocker,
  ) {
    final l10n = AppLocalizations.of(context);
    final label = switch (intent) {
      SearchIntent.cheapestNearby => l10n.criteriaIntentCheapestNearby,
      SearchIntent.bestStop => l10n.criteriaIntentBestStop,
      SearchIntent.onMyRoute => l10n.criteriaIntentOnMyRoute,
      SearchIntent.fastest => l10n.criteriaIntentFastest,
      SearchIntent.aFavourite => l10n.criteriaIntentFavourite,
    };
    return ChoiceChip(
      key: ValueKey('criteria-intent-${intent.name}'),
      label: Text(label),
      selected: intent == selected,
      // A blocked intent stays VISIBLE and disabled: removing it would
      // hide a capability the user could unlock, which is the opposite
      // of saying why.
      onSelected:
          blocker != null ? null : (_) => applySearchIntent(ref, intent),
    );
  }

  Widget _customChip(
      BuildContext context, AppLocalizations l10n, bool selected) {
    return ChoiceChip(
      key: const ValueKey('criteria-intent-custom'),
      label: Text(l10n.criteriaIntentCustom),
      selected: selected,
      // Custom is a READ-OUT, never a command: it is what the sheet
      // shows once the parameters stop matching any preset, so there is
      // nothing to apply.
      onSelected: null,
    );
  }
}
