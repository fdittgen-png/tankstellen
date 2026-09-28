// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/station.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../route_search/api.dart'
    show RouteStopMetrics, routeStopAlongText, routeStopOffRouteText;
import '../../providers/road_distance_provider.dart';

/// The distance segment of a NEARBY station row: road distance when the
/// radar's OSRM table answered (#3634, [Icons.route]), else the
/// crow-flies baseline — the only readings that have ever meant "from
/// me".
///
/// A route row does not come here: it shows [StationCardRouteMetrics]
/// instead (#4432). In a route context the radar side channel is
/// deliberately NOT consulted: `roadDistancesProvider` is keyed by
/// station id alone, from an origin that belongs to a different (nearby)
/// search, so a matching id there proves nothing about this route.
class StationCardDistanceSegment extends ConsumerWidget {
  const StationCardDistanceSegment({
    super.key,
    required this.station,
    required this.style,
  });

  final Station station;
  final TextStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roadKm = ref.watch(
      roadDistancesProvider.select((m) => m[station.id]),
    );
    if (roadKm == null) {
      return Text(
        PriceFormatter.formatDistance(station.dist),
        key: const Key('station_card_distance'),
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return StationCardIconValue(
      key: const Key('station_card_road_distance'),
      icon: Icons.route,
      style: style,
      text: PriceFormatter.formatDistance(roadKm),
    );
  }
}

/// One of the two geometric route readings of a station row (#4432,
/// checkpoint 3's distance-provenance table), each named and each with
/// its own glyph so they cannot be mistaken for each other or for a
/// distance from the driver:
///
///  * **along-route progress** ([Icons.linear_scale]) — `About 62 km
///    along this route`: where the route meets the station, counted from
///    the route start; the quantity the list is ordered by.
///  * **corridor offset** ([Icons.alt_route], [offRoute]) — `4.4 km from
///    the route · geometric estimate`: the straight-line distance from
///    the route line, qualified because it is flown, not driven.
///
/// The routed quantities (road distance to the station, the stop's extra
/// driving and their evidence status) are `StationTravelEstimate`'s
/// (#4359) and are shown where the planner uses them; nothing here
/// stands in for them.
class StationCardRouteMetric extends StatelessWidget {
  const StationCardRouteMetric({
    super.key,
    required this.metrics,
    required this.style,
  }) : offRoute = false;

  const StationCardRouteMetric.offRoute({
    super.key,
    required this.metrics,
    required this.style,
  }) : offRoute = true;

  final RouteStopMetrics metrics;
  final TextStyle style;

  /// The corridor offset rather than the along-route progress.
  final bool offRoute;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (offRoute) {
      return StationCardIconValue(
        key: const Key('station_card_off_route'),
        icon: Icons.alt_route,
        style: style,
        text: routeStopOffRouteText(l10n, metrics),
        tooltip: l10n.routeStopOffRouteTooltip,
      );
    }
    return StationCardIconValue(
      key: const Key('station_card_route_progress'),
      icon: Icons.linear_scale,
      style: style,
      text: routeStopAlongText(l10n, metrics),
      tooltip: l10n.routeStopAlongRouteTooltip,
    );
  }
}

/// A small leading glyph plus an ellipsising value, the shape the meta
/// line's other qualified segments already use.
class StationCardIconValue extends StatelessWidget {
  const StationCardIconValue({
    super.key,
    required this.icon,
    required this.style,
    required this.text,
    this.tooltip,
  });

  final IconData icon;
  final TextStyle style;
  final String text;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: style.color),
        const SizedBox(width: Spacing.xs),
        Flexible(
          child: Text(
            text,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    final message = tooltip;
    if (message == null) return row;
    return Tooltip(
      message: message,
      child: Semantics(label: '$text. $message', child: row),
    );
  }
}
