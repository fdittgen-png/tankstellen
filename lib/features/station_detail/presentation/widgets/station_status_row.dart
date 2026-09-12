// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/price_freshness.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/time/app_clock.dart';
import '../../../../core/widgets/price_freshness_words.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/station.dart';
import '../../../search/providers/station_rating_provider.dart';
import 'station_header_metrics.dart';

/// Top row of the station detail screen — availability and price
/// freshness as TWO facts on the left, compact 5-star rating on the
/// right.
///
/// Stateless apart from watching `stationRatingProvider` (which the parent
/// previously did inline via `Consumer`). Pulled out of
/// `station_detail_screen.dart` so the screen's `_buildContent` helper
/// drops the 49-line inline `Row(...)` block and so the row can be
/// covered by widget tests in isolation.
///
/// This row is the ONE place the screen states the open / closed state
/// (#3902): the opening-hours card below renders the schedule only.
///
/// #4092 — it used to state availability and price freshness as a single
/// sentence in a single colour: `stationStatusWithFreshness` produced
/// "Open · updated 3 h ago" painted green, so the green was simultaneously
/// claiming the forecourt is open AND that the price is current. They are
/// orthogonal facts — an open station can publish a week-old price, and a
/// closed one can have published five minutes ago — and a reader had no
/// way to tell which half the colour belonged to. They are now two
/// segments, each with its own glyph, its own colour and its own
/// screen-reader label, on the one line the #3902 height budget allows.
///
/// The freshness fact also changed CLOCK. It used to read
/// `ServiceResult.freshnessLabel` — how long ago the app DOWNLOADED the
/// price list — and render it as "Open · updated < 1 min ago" directly
/// beside a price. A reader takes that to mean the price is a minute
/// old; it meant our copy of the list is. The header now states the
/// operator's own publication age, which is the number a driver is
/// actually asking about, and the exact stamp rides in the tooltip. How
/// fresh our COPY is remains a real but separate fact, and the results
/// band (`PriceFreshnessSegment`) is where it is already stated.
class StationStatusRow extends ConsumerWidget {
  final Station station;

  /// ID used to look up the rating from `stationRatingProvider`. Usually
  /// the `stationId` field on the screen.
  final String stationId;

  const StationStatusRow({
    super.key,
    required this.station,
    required this.stationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final rating = ref.watch(stationRatingProvider(stationId));

    // #3198 — tri-state: an unknown open state renders the neutral muted
    // dot/text and is announced as unknown, never as open or closed.
    final color = switch (station.isOpen) {
      true => DarkModeColors.success(context),
      false => DarkModeColors.error(context),
      null => DarkModeColors.mutedText(context),
    };

    final statusSemantic = l10n.stationOpenStateSemantic('${station.isOpen}');
    final band = priceFreshness(
      station.updatedAt,
      now: ref.watch(appClockProvider).now(),
    );
    final bandWord = priceFreshnessWord(band, l10n);
    final bandColor = band == PriceFreshness.stale
        ? theme.colorScheme.tertiary
        : DarkModeColors.mutedText(context);

    return Row(
      children: [
        Expanded(
          // Flexible children with single-line ellipsis so the facts yield
          // instead of overflowing when the width is narrow — e.g. the
          // flex:2 left pane of the #2531 two-column wide layout, where the
          // row competes with the trailing stars. One line also keeps the
          // row at the height `stationHeaderExpandedHeight` budgets for it
          // (#3902).
          child: Row(
            children: [
              // FACT 1 — availability. The coloured dot belongs to this
              // fact and to nothing else.
              Flexible(
                child: Semantics(
                  label: '${l10n.availabilityLabel}: $statusSemantic',
                  child: ExcludeSemantics(
                    child: Row(
                      children: [
                        Container(
                          width: kStatusDotSize,
                          height: kStatusDotSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _availabilityWord(station, l10n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                headerStatusStyle(theme)?.copyWith(color: color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // A language-neutral separator between two facts.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '·',
                  style: headerStatusStyle(theme)
                      ?.copyWith(color: DarkModeColors.mutedText(context)),
                ),
              ),
              // FACT 2 — how old the PRICE is. Never the availability
              // colour, and never a congratulatory green of its own: only
              // a stale price is an attention state.
              Flexible(
                child: Tooltip(
                  message: l10n.priceFreshnessTooltip(
                    bandWord,
                    l10n.stationUpdatedLabel(station.updatedAt ?? ''),
                  ),
                  child: Semantics(
                    label: '${l10n.priceFreshnessLabel}: $bandWord',
                    child: ExcludeSemantics(
                      child: Row(
                        children: [
                          Icon(
                            band == PriceFreshness.stale
                                ? Icons.history_toggle_off
                                : Icons.schedule,
                            size: kStatusDotSize + 4,
                            color: bandColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              bandWord,
                              key: const Key('station_detail_freshness_word'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: headerStatusStyle(theme)
                                  ?.copyWith(color: bandColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (rating != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (i) => Icon(
                i < rating ? Icons.star : Icons.star_border,
                size: kRatingStarSize,
                color: i < rating ? Colors.amber : Colors.grey.shade400,
              ),
            ),
          ),
      ],
    );
  }
}

/// The availability word on its own.
///
/// #3198 — tri-state: an unknown open state is stated as unreported,
/// never as open and never as closed.
String _availabilityWord(Station station, AppLocalizations l10n) {
  return switch (station.isOpen) {
    true => station.is24h ? l10n.stationCardStatus24h(l10n.open) : l10n.open,
    false => l10n.closed,
    null => l10n.availabilityNotReported,
  };
}
