// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/search_mode.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/route_search/api.dart';
import 'package:tankstellen/features/search/providers/refresh_active_search.dart';
import 'package:tankstellen/features/search/providers/search_mode_provider.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

/// #4432 — "Refresh" has to refresh what is on screen.
///
/// Both the results app bar and the map called the NEARBY
/// `repeatLastSearch()` unconditionally. With route results showing,
/// that re-ran a proximity search: the prices moved, the corridor did
/// not, and an origin captured before the driver set off stayed exactly
/// as stale as it was.
class _SpyRoute extends RouteSearchState {
  _SpyRoute(this.hasRoute);
  final bool hasRoute;
  int refreshes = 0;

  @override
  AsyncValue<RouteSearchResult?> build() => const AsyncValue.data(null);

  @override
  Future<bool> refresh() async {
    refreshes++;
    return hasRoute;
  }
}

class _SpyNearby extends SearchState {
  int replays = 0;

  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() =>
      AsyncValue.data(ServiceResult(
        data: const <SearchResultItem>[],
        source: ServiceSource.cache,
        fetchedAt: DateTime(2026, 3, 11, 14, 30),
      ));

  @override
  Future<void> repeatLastSearch() async => replays++;
}

class _FixedMode extends ActiveSearchMode {
  _FixedMode(this._mode);
  final SearchMode _mode;

  @override
  SearchMode build() => _mode;
}

void main() {
  Future<({_SpyRoute route, _SpyNearby nearby})> run(
    WidgetTester tester, {
    required SearchMode mode,
    required bool hasRoute,
  }) async {
    final route = _SpyRoute(hasRoute);
    final nearby = _SpyNearby();
    late WidgetRef captured;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routeSearchStateProvider.overrideWith(() => route),
          searchStateProvider.overrideWith(() => nearby),
          activeSearchModeProvider.overrideWith(() => _FixedMode(mode)),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            captured = ref;
            return const SizedBox();
          },
        ),
      ),
    );
    await refreshActiveSearch(captured);
    return (route: route, nearby: nearby);
  }

  testWidgets('in route mode, refresh refreshes the ROUTE', (tester) async {
    final spies = await run(tester, mode: SearchMode.route, hasRoute: true);

    expect(spies.route.refreshes, 1);
    expect(spies.nearby.replays, 0,
        reason: 'the proximity replay would leave the corridor stale');
  });

  testWidgets('in nearby mode, refresh stays the proximity replay',
      (tester) async {
    final spies = await run(tester, mode: SearchMode.nearby, hasRoute: true);

    expect(spies.route.refreshes, 0);
    expect(spies.nearby.replays, 1);
  });

  testWidgets('route mode with nothing searched yet still refreshes prices',
      (tester) async {
    // The action must never become a silent no-op.
    final spies = await run(tester, mode: SearchMode.route, hasRoute: false);

    expect(spies.route.refreshes, 1);
    expect(spies.nearby.replays, 1);
  });
}
