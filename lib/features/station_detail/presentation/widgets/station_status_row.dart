// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_result.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/station.dart';
import '../../../search/providers/station_rating_provider.dart';
import 'station_header_metrics.dart';

/// Top row of the station detail screen — open/closed dot + freshness
/// text on the left, compact 5-star rating on the right.
///
/// Stateless apart from watching `stationRatingProvider` (which the parent
/// previously did inline via `Consumer`). Pulled out of
/// `station_detail_screen.dart` so the screen's `_buildContent` helper
/// drops the 49-line inline `Row(...)` block and so the row can be
/// covered by widget tests in isolation.
///
/// This row is the ONE place the screen states the open / closed state
/// (#3902): the opening-hours card below renders the schedule only.
class StationStatusRow extends ConsumerWidget {
  final Station station;
  final ServiceResult<dynamic> serviceResult;

  /// ID used to look up the rating from `stationRatingProvider`. Usually
  /// the `stationId` field on the screen.
  final String stationId;

  const StationStatusRow({
    super.key,
    required this.station,
    required this.serviceResult,
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

    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: statusSemantic,
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: kStatusDotSize,
                    height: kStatusDotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Flexible + single-line ellipsis so the status text yields
                // instead of overflowing the row when the available width is
                // narrow — e.g. the flex:2 left pane of the #2531 two-column
                // wide layout, where the row competes with the trailing
                // stars. One line also keeps the row at the height
                // `stationHeaderExpandedHeight` budgets for it (#3902).
                Flexible(
                  child: ExcludeSemantics(
                    child: Text(
                      buildStationStatusText(station, serviceResult, l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: headerStatusStyle(theme)?.copyWith(color: color),
                    ),
                  ),
                ),
              ],
            ),
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

/// The open-state + freshness phrase, e.g. "Open · updated < 1 min ago".
///
/// #3902 — used to be composed from word fragments
/// (`'$status — $freshness $agoSuffix'`), which produced "Ouvert — < 1 min
/// il y a" in French: the `ago` word is a prefix there, not a suffix. One
/// parameterised ARB key per locale owns the word order instead.
String buildStationStatusText(
  Station station,
  ServiceResult<dynamic> result,
  AppLocalizations l10n,
) {
  final status = switch (station.isOpen) {
    true => l10n.open,
    false => l10n.closed,
    null => l10n.openStateUnknown,
  };
  return l10n.stationStatusWithFreshness(status, result.freshnessLabel);
}
