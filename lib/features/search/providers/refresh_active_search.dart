// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/search_mode.dart';
import '../../route_search/api.dart';
import 'search_mode_provider.dart';
import 'search_provider.dart';

/// Refresh whatever the driver is actually looking at (#4432).
///
/// The results list, the map's app-bar action and the map's
/// return-after-a-long-gap resume all called the NEARBY
/// `repeatLastSearch()`, unconditionally. With route results on screen
/// that re-fixed the separately stored user position and re-ran a
/// proximity search: the prices moved, the corridor did not, and an
/// origin captured before the driver set off stayed exactly as stale as
/// it was. Refresh has to mean "refresh THIS".
///
/// A route refresh re-runs the stored route request — re-resolving the
/// origin when it is the vehicle's own position, leaving a named origin
/// alone. It returns false when there is no route to refresh (nothing
/// searched yet, or the results were cleared), and the nearby replay
/// then runs as before, so the action is never a no-op.
Future<void> refreshActiveSearch(WidgetRef ref) async {
  // Read every notifier BEFORE the first await (#3159): a post-await
  // ref.read throws once the screen behind it has gone.
  final nearby = ref.read(searchStateProvider.notifier);
  final route = ref.read(routeSearchStateProvider.notifier);
  final inRouteMode = ref.read(activeSearchModeProvider) == SearchMode.route;

  if (inRouteMode && await route.refresh()) return;
  await nearby.repeatLastSearch();
}
