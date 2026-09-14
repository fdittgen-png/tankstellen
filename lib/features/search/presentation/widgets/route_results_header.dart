// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/utils/duration_formatter.dart';
import '../../../../core/widgets/selectable_pill.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../route_search/api.dart';
import 'route_results_view.dart';

/// The route summary and the three answers it can show (#2622, #4125,
/// #4146).
///
/// Extracted from `route_results_view.dart` (#4146) when the third mode
/// took that file past the 400-line cap. A real seam: this is the
/// screen's CHROME — what the route is and which question is being asked
/// — while the view below it renders whichever answer was chosen.
class RouteResultsHeader extends StatelessWidget {
  const RouteResultsHeader({
    super.key,
    required this.result,
    required this.shownCount,
    required this.mode,
    required this.onModeChanged,
  });

  final RouteSearchResult result;

  /// Rows the list is showing — #4125: the count describes the screen,
  /// not the raw service result.
  final int shownCount;

  final RouteResultMode mode;
  final ValueChanged<RouteResultMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // #2622 — de-densify: the route summary and the All/Best toggle
          // share ONE row (summary left, pills right) and wrap when narrow.
          // The "Every {km} km" segment row was a verbatim duplicate of the
          // SearchSummaryBar's second chip (same routeSegmentSummaryBadge
          // key); it stays visible there, so it is dropped from the header.
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.route, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    // #4125 — count the rows THIS LIST is showing.
                    // It read `result.stations.length`: the raw service
                    // result, before the swipe-away ignore filter and
                    // before the All/Best toggle. So "108 stations" stood
                    // above whatever the toggle had left — 7 curated stops
                    // under "Meilleurs arrêts" — and the one number on the
                    // screen described neither state of the screen. Three
                    // counts were in play for one route (108 results, 55
                    // fuel stations on the map, 7 best stops); each
                    // surface now counts what it renders.
                    '${result.route.distanceKm.round()} km · '
                    '${formatTravelDuration(l10n, result.route.durationMinutes)} · '
                    '${l10n.routeStationCount(shownCount)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectablePill(
                    label: l10n.allStations,
                    icon: Icons.local_gas_station,
                    selected: mode == RouteResultMode.allStations,
                    onTap: () => onModeChanged(RouteResultMode.allStations),
                  ),
                  const SizedBox(width: 8),
                  SelectablePill(
                    label: l10n.bestStops,
                    icon: Icons.star,
                    selected: mode == RouteResultMode.bestStops,
                    onTap: () =>
                        onModeChanged(RouteResultMode.bestStops),
                  ),
                  const SizedBox(width: 8),
                  // #4146 — the third answer: not which stations exist,
                  // but where this tank must stop and what that costs.
                  SelectablePill(
                    label: l10n.refuelPlanTab,
                    icon: Icons.route_outlined,
                    selected: mode == RouteResultMode.plan,
                    onTap: () =>
                        onModeChanged(RouteResultMode.plan),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
