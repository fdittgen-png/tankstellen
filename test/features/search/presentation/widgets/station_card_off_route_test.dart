// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/route_search/api.dart'
    show RouteStopMetrics;
import 'package:tankstellen/features/search/presentation/widgets/station_card.dart';
import 'package:tankstellen/features/search/providers/road_distance_provider.dart';
import 'package:tankstellen/features/search/providers/station_off_route_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/pump_app.dart';

/// #4432 — a route row's kilometres are not a distance-from-me, and the
/// two used to look identical.
///
/// The field report's row read `Auchan · 4,4 km` for a forecourt ~60 km
/// ahead of the driver, in the same typography a proximity row uses for
/// "4.4 km from you". Price without a trustworthy distance is not a
/// choice, which is exactly what the reporter said.
///
/// Checkpoint 3's provenance table then asks for the along-route
/// progress and the geometric corridor offset to be two DISTINCT,
/// labelled readings — this file pins both.
void main() {
  const metrics = RouteStopMetrics(
    routeRevision: 7,
    alongKm: 62.3,
    offRouteKm: 4.4,
  );

  Future<void> pumpRouteRow(
    WidgetTester tester, {
    Map<String, RouteStopMetrics>? routeMetrics,
    Locale locale = const Locale('en'),
    double textScale = 1,
    Size? size,
    List<Object> extra = const [],
  }) async {
    if (size != null) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    await pumpApp(
      tester,
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: const SingleChildScrollView(
          child: StationCard(
            station: testStation,
            selectedFuelType: FuelType.e10,
          ),
        ),
      ),
      overrides: [
        stationRouteMetricsProvider
            .overrideWithValue(routeMetrics ?? {testStation.id: metrics}),
        ...extra,
      ],
      locale: locale,
    );
  }

  group('route rows name the quantity (#4432)', () {
    testWidgets('a proximity row still shows the bare distance from me',
        (tester) async {
      await pumpApp(
        tester,
        const StationCard(station: testStation, selectedFuelType: FuelType.e10),
      );

      expect(find.byKey(const Key('station_card_distance')), findsOneWidget);
      expect(find.byKey(const Key('station_card_off_route')), findsNothing);
      expect(
          find.byKey(const Key('station_card_route_progress')), findsNothing);
      expect(find.text('1,5 km'), findsOneWidget);
    });

    testWidgets('a route row names and qualifies its corridor offset',
        (tester) async {
      await pumpRouteRow(tester);

      expect(find.byKey(const Key('station_card_off_route')), findsOneWidget);
      expect(find.byKey(const Key('station_card_distance')), findsNothing);
      // Named ("from the route") AND qualified ("geometric estimate"):
      // it is neither the distance from the driver nor a road detour.
      expect(
        find.text('4,4 km from the route · geometric estimate'),
        findsOneWidget,
      );
      // The unstable first-seen `Station.dist` is not presented at all.
      expect(find.text('1,5 km'), findsNothing);
    });

    testWidgets('a route row shows its along-route progress as its own, '
        'differently named reading', (tester) async {
      await pumpRouteRow(tester);

      final along = find.byKey(const Key('station_card_route_progress'));
      expect(along, findsOneWidget);
      // Whole units: "about", because it is a position on the route line,
      // not a measured drive.
      expect(find.text('About 62 km along this route'), findsOneWidget);
      // Its own glyph — the offset's glyph is a different one — so the
      // two figures are visually distinguishable, not just worded.
      expect(
        find.descendant(of: along, matching: find.byIcon(Icons.linear_scale)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: along, matching: find.byIcon(Icons.alt_route)),
        findsNothing,
      );
      expect(
        tester.widget<Tooltip>(
          find.descendant(of: along, matching: find.byType(Tooltip)),
        ).message,
        allOf(
          contains("route's start"),
          contains('Not the distance from you'),
        ),
      );
    });

    testWidgets('a route row ignores a radar distance for the same id',
        (tester) async {
      // `roadDistancesProvider` is keyed by station id from the NEARBY
      // search's origin. A matching id proves nothing about this route,
      // so the route surface must not borrow the number.
      await pumpRouteRow(tester, extra: [
        roadDistancesProvider.overrideWith(() => _FixedRoadDistances(
              {testStation.id: 9.9},
            )),
      ]);

      expect(find.byKey(const Key('station_card_off_route')), findsOneWidget);
      expect(find.byKey(const Key('station_card_road_distance')), findsNothing);
      expect(find.textContaining('9,9 km'), findsNothing);
    });

    testWidgets('the offset segment is visually distinct, not just worded',
        (tester) async {
      await pumpRouteRow(tester);

      final segment = find.byKey(const Key('station_card_off_route'));
      expect(
        find.descendant(of: segment, matching: find.byIcon(Icons.alt_route)),
        findsOneWidget,
      );
      expect(
        tester.widget<Tooltip>(
          find.descendant(of: segment, matching: find.byType(Tooltip)),
        ).message,
        allOf(
          contains('Not the distance from you'),
          contains('not the extra driving'),
        ),
      );
    });

    testWidgets('a station absent from the route map keeps the plain reading',
        (tester) async {
      await pumpRouteRow(tester, routeMetrics: const {
        'some-other-id': RouteStopMetrics(
          routeRevision: 1,
          alongKm: 9.9,
          offRouteKm: 9.9,
        ),
      });

      expect(find.byKey(const Key('station_card_distance')), findsOneWidget);
      expect(find.byKey(const Key('station_card_off_route')), findsNothing);
      expect(
          find.byKey(const Key('station_card_route_progress')), findsNothing);
    });
  });

  group('route readings across locales and text scale (#4432)', () {
    testWidgets('French names both readings in French', (tester) async {
      await pumpRouteRow(tester, locale: const Locale('fr'));

      final l = await AppLocalizations.delegate.load(const Locale('fr'));
      // The French strings, not the English fallback.
      expect(find.textContaining(l.routeStopOffRouteQualifier), findsOneWidget);
      expect(find.textContaining('le long de cet itinéraire'), findsOneWidget);
      expect(find.textContaining('along this route'), findsNothing);
      expect(find.textContaining('geometric estimate'), findsNothing);
    });

    testWidgets('the en_XA expansion pseudo-locale lays out without '
        'overflow at 320 dp', (tester) async {
      await pumpRouteRow(
        tester,
        locale: const Locale('en', 'XA'),
        size: const Size(320, 1200),
      );

      expect(tester.takeException(), isNull);
      expect(
          find.byKey(const Key('station_card_route_progress')), findsOneWidget);
      expect(find.byKey(const Key('station_card_off_route')), findsOneWidget);
    });

    testWidgets('a narrow screen at double text scale does not overflow',
        (tester) async {
      await pumpRouteRow(
        tester,
        textScale: 2,
        size: const Size(320, 2400),
      );

      expect(tester.takeException(), isNull);
      expect(
          find.byKey(const Key('station_card_route_progress')), findsOneWidget);
      expect(find.byKey(const Key('station_card_off_route')), findsOneWidget);
    });

    testWidgets('a screen reader hears each reading with what it is NOT',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpRouteRow(tester);

      expect(
        find.bySemanticsLabel(RegExp(
            r'About 62 km along this route\. .*Not the distance from you')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'4,4 km from the route')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}

class _FixedRoadDistances extends RoadDistances {
  _FixedRoadDistances(this._values);
  final Map<String, double> _values;

  @override
  Map<String, double> build() => _values;
}
