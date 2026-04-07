import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';
import 'package:tankstellen/features/search/presentation/widgets/route_results_view.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('RouteResultsView', () {
    testWidgets('shows localized empty message when no stations found',
        (tester) async {
      final test = standardTestOverrides();

      const emptyResult = RouteSearchResult(
        route: RouteInfo(
          geometry: [LatLng(48.0, 2.0), LatLng(49.0, 3.0)],
          distanceKm: 100,
          durationMinutes: 60,
          samplePoints: [LatLng(48.5, 2.5)],
        ),
        stations: [],
      );

      await pumpApp(
        tester,
        const CustomScrollView(slivers: [RouteResultsView()]),
        overrides: [
          ...test.overrides,
          routeSearchStateProvider
              .overrideWith(() => _FixedRouteSearch(emptyResult)),
        ],
      );

      expect(
        find.text('No stations found along this route.'),
        findsOneWidget,
      );
    });

    testWidgets('shows localized start search message when no search performed',
        (tester) async {
      final test = standardTestOverrides();

      await pumpApp(
        tester,
        const CustomScrollView(slivers: [RouteResultsView()]),
        overrides: [
          ...test.overrides,
          routeSearchStateProvider
              .overrideWith(() => _FixedRouteSearch(null)),
        ],
      );

      expect(
        find.text('Search to find fuel stations.'),
        findsOneWidget,
      );
    });
  });
}

class _FixedRouteSearch extends RouteSearchState {
  final RouteSearchResult? _result;
  _FixedRouteSearch(this._result);

  @override
  AsyncValue<RouteSearchResult?> build() => AsyncValue.data(_result);
}
