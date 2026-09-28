// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/widgets.dart';

import '../../../../core/utils/unit_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/route_stop_metrics.dart';

export '../../domain/route_stop_metrics.dart';

/// Hands a route surface's [RouteStopMetrics] to every widget below it
/// (#4432).
///
/// The route map's markers, chips and marker sheet are shared with the
/// nearby map, so none of them can decide on its own that it is looking
/// at a route. The route surface says so by wrapping its subtree in this
/// scope; a widget outside one finds no metrics and keeps its nearby
/// reading. A sheet opened from inside the scope reads the value at the
/// tap (`read`) and carries it over the modal route, which is not a
/// descendant.
class RouteStopMetricsScope extends InheritedWidget {
  const RouteStopMetricsScope({
    super.key,
    required this.metrics,
    required super.child,
  });

  /// Station id → metrics of the route on screen.
  final Map<String, RouteStopMetrics> metrics;

  /// The metrics of [stationId] on the enclosing route, rebuilding the
  /// caller when the route changes; null outside a route surface.
  static RouteStopMetrics? of(BuildContext context, String stationId) =>
      context
          .dependOnInheritedWidgetOfExactType<RouteStopMetricsScope>()
          ?.metrics[stationId];

  /// [of] without a rebuild dependency — for event handlers.
  static RouteStopMetrics? read(BuildContext context, String stationId) =>
      context
          .getInheritedWidgetOfExactType<RouteStopMetricsScope>()
          ?.metrics[stationId];

  @override
  bool updateShouldNotify(RouteStopMetricsScope oldWidget) =>
      !identical(metrics, oldWidget.metrics);
}

/// The whole-unit along-route figure, in the user's distance unit.
String routeStopAlongDistance(RouteStopMetrics metrics) =>
    UnitFormatter.formatDistance(metrics.alongKm, fractionDigits: 0);

/// "About 62 km along this route" — the along-route progress, named.
String routeStopAlongText(AppLocalizations l10n, RouteStopMetrics metrics) =>
    l10n.routeStopAlongRoute(routeStopAlongDistance(metrics));

/// "4.4 km from the route · geometric estimate" — the corridor offset,
/// named AND qualified: flown, not driven, and not from the driver.
String routeStopOffRouteText(
  AppLocalizations l10n,
  RouteStopMetrics metrics,
) =>
    '${l10n.routeStopOffRoute(UnitFormatter.formatDistance(metrics.offRouteKm))}'
    ' · ${l10n.routeStopOffRouteQualifier}';
