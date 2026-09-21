// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The Opportunities feed (#4154, epic #4148).
///
/// Everything the background engine found and scored — **including what
/// the attention budget declined to push**. #4151's promise was that a
/// demotion is not a deletion; #4183 made that a stored fact; this is
/// where the user can finally open it.
///
/// ## Why it sits above the configured alerts
///
/// The two lists below it are what the user SET UP. This is what
/// HAPPENED. A screen that leads with configuration asks the user to
/// remember what they asked for; one that leads with findings answers
/// the question they opened it with.
///
/// ## What a row may and may not say
///
/// Every EXPLANATION line comes from the model through
/// [opportunityReasonText] — the #4152 renderer — so an expanded row
/// cannot claim anything the detector did not record. The one-line
/// headline is composed here, from three fields and a language-neutral
/// separator; it states facts and never a comparison, because a
/// comparison is a claim and claims belong to the renderer.
///
/// A row the budget refused shows the refusal in the BUDGET's words ("a
/// better one went out instead"), never as a judgement on the finding:
/// it is in the feed because it was worth finding.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/panel_card.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/opportunity_feed_store.dart';
import '../../domain/opportunity_reasons.dart';
import '../../providers/opportunity_feed_provider.dart';
import '../opportunity_kind_text.dart';
import '../opportunity_reason_text.dart';

/// The feed, or an honest empty state.
class OpportunityFeedSection extends ConsumerWidget {
  const OpportunityFeedSection({super.key, this.hideWhenEmpty = false});

  /// Render NOTHING instead of the empty note.
  ///
  /// True from the Alerts screen, which is still a CONFIGURATION screen:
  /// this section sits above the lists the user came for, and even a
  /// compact note there pushes them down the page for no gain. False —
  /// the default — is what the feed's own screen will use, where the
  /// empty state is the whole point and #4154's "say what the engine is
  /// watching for" is answered on screen rather than by a flag.
  final bool hideWhenEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(opportunityFeedProvider);
    if (entries.isEmpty) {
      return hideWhenEmpty ? const SizedBox.shrink() : const _OpportunitiesEmpty();
    }

    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: _OpportunityTile(entry: entry),
          ),
      ],
    );
  }
}

/// #4154 — says what the engine is watching for and why nothing is here
/// yet. Explicitly NOT a fabricated example row: a feed that invents one
/// to look populated is the shape of claim this whole epic exists to
/// remove.
///
/// Deliberately a compact note rather than a full-panel [EmptyState].
/// This section sits ABOVE the user's configured alerts today, and a
/// panel here pushes the list they came for below the fold — which is
/// also what made three existing screen tests fail, because a `ListView`
/// does not build what it cannot show. The full-panel treatment belongs
/// with the screen restructure, where the feed IS the screen and has the
/// room for it.
class _OpportunitiesEmpty extends StatelessWidget {
  const _OpportunitiesEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.opportunitiesEmptyTitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: Spacing.xs),
        Text(
          l10n.opportunitiesEmptyBody,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// One finding, expandable into the facts behind it.
class _OpportunityTile extends StatelessWidget {
  const _OpportunityTile({required this.entry});

  final FeedEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final o = entry.opportunity;
    final reasons = OpportunityReasons.of(o);

    // #3948's secondary surface, not a raw `Card`: a feed row is
    // supporting information beside the primary surfaces on this
    // screen, and the shared panel keeps the page's one rhythm.
    return PanelCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(opportunityKindText(l10n, o.kind),
              style: theme.textTheme.titleSmall),
          subtitle: Text(_headline(l10n, entry),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          trailing: entry.wasNotified
              ? null
              : Chip(
                  label: Text(l10n.opportunityNotSentLabel),
                  visualDensity: VisualDensity.compact,
                ),
          childrenPadding: const EdgeInsets.fromLTRB(
              Spacing.lg, 0, Spacing.lg, Spacing.md),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final reason in reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.xs),
                child: Text('• ${opportunityReasonText(l10n, reason)}',
                    style: theme.textTheme.bodySmall),
              ),
            // The budget's decision, in the budget's words. Absent when
            // it was sent — there is nothing to explain then.
            if (entry.refusal case final refusal?)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.xs),
                child: Text(
                  opportunityRefusalText(l10n, refusal),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The one-line summary: the station and the price, or — for an
  /// area-wide movement, which is about no station — just the price.
  ///
  /// Never the station ID as a fallback: `de-9f3a1c` in front of a user
  /// is the same defect #4179 removed from the home-screen widget.
  String _headline(AppLocalizations l10n, FeedEntry entry) {
    final o = entry.opportunity;
    final price = PriceFormatter.formatTotal(o.currentPrice);
    final name = o.stationName;
    if (name == null || name.isEmpty) return price;
    if (o.distanceKm <= 0) return '$name · $price';
    return '$name · $price · '
        '${UnitFormatter.formatDistance(o.distanceKm)}';
  }
}
