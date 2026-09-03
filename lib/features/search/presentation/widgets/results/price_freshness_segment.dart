// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/time/app_clock.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../providers/search_provider.dart';
import 'summary_chip.dart';

/// The worded freshness segment of the results summary bar (row A, #3926).
///
/// ## What the number actually measures
///
/// The age is `now - ServiceResult.fetchedAt`: how long ago **the app
/// downloaded this price list** from the country's open-data service. A
/// list served from the station cache keeps the download time of the
/// original fetch (`station_service_chain.dart` stamps `entry.storedAt`),
/// so "2 h ago" means "this list was pulled from the provider two hours
/// ago" — NOT "the operator changed the price two hours ago". The
/// per-station "Updated …" line on each card is the operator-side
/// timestamp; the two are different clocks and are deliberately worded
/// differently.
///
/// This replaces the wordless amber "⚠ 2 h ago" pill, which never said
/// what was two hours old.
///
/// ## Amber
///
/// Amber is reserved for the pre-existing staleness threshold the
/// `FreshnessBadge` used: the chain's own `ServiceResult.isStale` flag, or
/// an age past 15 minutes. Below that the segment is a neutral pill — a
/// six-minute-old price list is not an attention state.
class PriceFreshnessSegment extends ConsumerWidget {
  const PriceFreshnessSegment({super.key});

  /// Age past which the segment turns amber — the `FreshnessBadge`
  /// "warning_amber_rounded" branch (#2492), preserved verbatim.
  static const Duration staleAfter = Duration(minutes: 15);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(searchStateProvider.select((s) => s.value));
    if (result == null || result.data.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final age = ref.watch(appClockProvider).now().difference(result.fetchedAt);
    final stale = result.isStale || age > staleAfter;

    // #3939 — the clock glyph already says "age", so the pill carries the
    // bare figure ("1 min") and the sentence that names WHAT is that old
    // moves into the tooltip / screen-reader label. Both come from the
    // same branch, so they can never disagree.
    final String label;
    final String tooltip;
    if (age.inMinutes < 1) {
      label = l10n.searchSummaryAgeJustNow;
      tooltip = l10n.searchSummaryPricesJustNow;
    } else if (age.inHours < 1) {
      label = l10n.searchSummaryAgeMinutes(age.inMinutes);
      tooltip = l10n.searchSummaryPricesMinutes(age.inMinutes);
    } else if (age.inDays < 1) {
      label = l10n.searchSummaryAgeHours(age.inHours);
      tooltip = l10n.searchSummaryPricesHours(age.inHours);
    } else {
      label = l10n.searchSummaryAgeDays(age.inDays);
      tooltip = l10n.searchSummaryPricesDays(age.inDays);
    }

    return SummaryChip(
      key: const Key('search_freshness_segment'),
      icon: Icon(
        stale ? Icons.warning_amber_rounded : Icons.schedule,
        size: 14,
        color: stale
            ? Theme.of(context).colorScheme.onTertiaryContainer
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      label: label,
      tooltip: tooltip,
      emphasized: stale,
    );
  }
}
