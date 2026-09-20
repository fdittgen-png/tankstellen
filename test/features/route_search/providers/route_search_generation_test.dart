// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/route_search/api.dart';

/// #4432 — every publication belongs to one request generation.
///
/// The corridor sweep streams partials for seconds. Without a fence a
/// superseded search's late partial, final result or error could
/// overwrite the search the driver ran after it, and `clear()` could not
/// retire work already in flight — the list would repopulate itself
/// after the user emptied it.
void main() {
  const route = RouteInfo(
    geometry: [LatLng(45.7594, 5.6842), LatLng(46.2044, 6.1432)],
    distanceKm: 80,
    durationMinutes: 62,
    samplePoints: [LatLng(45.7594, 5.6842)],
  );

  RouteSearchResult resultWith(String? cheapestId) => RouteSearchResult(
        route: route,
        stations: const [],
        cheapestId: cheapestId,
        cheapestPerSegment: null,
        strategyType: RouteSearchStrategyType.uniform,
      );

  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    // Hold a subscription: the provider is auto-dispose and these tests
    // read its notifier across several steps.
    addTearDown(c.listen(routeSearchStateProvider, (_, _) {}).close);
    return c;
  }

  test('a publication carrying the active generation is accepted', () {
    final c = makeContainer();
    final notifier = c.read(routeSearchStateProvider.notifier);

    notifier.publish(
      notifier.activeRevision,
      AsyncValue.data(resultWith('first')),
    );

    expect(c.read(routeSearchStateProvider).value?.cheapestId, 'first');
  });

  test('clear() retires the generation, so a late answer cannot land', () {
    final c = makeContainer();
    final notifier = c.read(routeSearchStateProvider.notifier);
    final inFlight = notifier.activeRevision;

    notifier.publish(inFlight, AsyncValue.data(resultWith('first')));
    notifier.clear();
    // The sweep that was already streaming finally answers.
    notifier.publish(inFlight, AsyncValue.data(resultWith('late partial')));

    expect(c.read(routeSearchStateProvider).value, isNull);
  });

  test('an obsolete ERROR cannot replace the current results either', () {
    final c = makeContainer();
    final notifier = c.read(routeSearchStateProvider.notifier);
    final obsolete = notifier.activeRevision;

    notifier.clear(); // a newer submission would bump it the same way
    final current = notifier.activeRevision;
    notifier.publish(current, AsyncValue.data(resultWith('current')));

    notifier.publish(
      obsolete,
      const AsyncValue.error('OSRM down', StackTrace.empty),
    );

    expect(c.read(routeSearchStateProvider).hasError, isFalse);
    expect(c.read(routeSearchStateProvider).value?.cheapestId, 'current');
  });

  test('refresh() with nothing searched yet declines, it does not throw',
      () async {
    final c = makeContainer();
    final notifier = c.read(routeSearchStateProvider.notifier);

    // False lets the caller fall through to the nearby replay, so the
    // refresh action is never a silent no-op.
    expect(await notifier.refresh(), isFalse);
  });
}
