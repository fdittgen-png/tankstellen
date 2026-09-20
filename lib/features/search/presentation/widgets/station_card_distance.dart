// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/station.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/road_distance_provider.dart';
import '../../providers/station_off_route_provider.dart';

/// The distance segment of a station row — and, since #4432, the one
/// place that says WHICH distance it is.
///
/// Three readings share the slot and they are not interchangeable:
///
///  * **off-route offset** (`4.4 km from the route · geometric
///    estimate`, [Icons.alt_route]) — in a route search. It is the
///    straight-line distance from the route line to the station,
///    measured against THIS route (`stationOffRouteKmProvider`). It is not
///    how far the station is from the driver, and it is not the extra
///    driving a stop costs; it is labelled and qualified so it cannot be
///    read as either.
///  * **road distance** ([Icons.route]) — #3634, when the OSRM table has
///    answered for this station on the radar surface.
///  * **crow-flies distance** — the haversine baseline, and the only
///    reading that has ever meant "from me".
///
/// In a route context the radar side channel is deliberately NOT
/// consulted: `roadDistancesProvider` is keyed by station id alone, from
/// an origin that belongs to a different (nearby) search, so a matching
/// id there proves nothing about this route. Wearing a route label it
/// would be a second wrong number rather than the first one fixed.
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
    final offRouteKm = ref.watch(
      stationOffRouteKmProvider.select((m) => m[station.id]),
    );
    if (offRouteKm != null) {
      final l10n = AppLocalizations.of(context);
      return _IconValue(
        key: const Key('station_card_off_route'),
        icon: Icons.alt_route,
        style: style,
        text: '${l10n.routeStopOffRoute(
          PriceFormatter.formatDistance(offRouteKm),
        )} · ${l10n.routeStopOffRouteQualifier}',
        tooltip: l10n.routeStopOffRouteTooltip,
      );
    }
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
    return _IconValue(
      key: const Key('station_card_road_distance'),
      icon: Icons.route,
      style: style,
      text: PriceFormatter.formatDistance(roadKm),
    );
  }
}

/// A small leading glyph plus an ellipsising value, the shape the meta
/// line's other qualified segments already use.
class _IconValue extends StatelessWidget {
  const _IconValue({
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
