// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/navigation/app_routes.dart';

/// Parses a home-widget launch URI into the router path it should push.
///
/// URI contract (set natively by `StationWidgetRenderer.buildActivity`):
/// `tankstellenwidget://station?id=<stationId>`. EV stations use the
/// OpenChargeMap `ocm-` prefix; those route to the EV detail screen so
/// the user sees connectors/power rather than the fuel-price UI.
///
/// Returns `null` for any URI that isn't a valid widget launch — the
/// caller must treat that as a no-op.
///
/// #2600 — the only widget launch URI is now the station deep-link. The
/// refresh button no longer launches the app at all: it is a broadcast
/// (`StationWidgetRenderer.ACTION_REFRESH`) the provider handles in place
/// by enqueuing the on-device price scan, so the old
/// `tankstellenwidget://refresh` marker URI (#1801 / #1961) and its
/// `isWidgetRefreshUri` discriminator were removed.
///
/// Lives in its own file (rather than next to the listener) so the
/// router's redirect chain can call it without the listener's
/// `routerProvider` import re-importing router.dart and creating a
/// circular dependency graph that partially-initialises one side at
/// runtime.
String? widgetUriToPath(Uri? uri) {
  if (uri == null) return null;
  if (uri.scheme != 'tankstellenwidget') return null;
  if (uri.host != 'station') return null;
  final id = uri.queryParameters['id'];
  if (id == null || id.isEmpty) return null;
  return id.startsWith('ocm-')
      ? RoutePaths.evStationById(id)
      : RoutePaths.station(id);
}
