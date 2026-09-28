// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/map/presentation/widgets/route_station_chip.dart';
import 'package:tankstellen/core/utils/station_extensions.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/route_search/api.dart'
    show RouteStopMetrics, RouteStopMetricsScope;
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../fixtures/stations.dart';

void main() {
  // Now that RouteStationChip is a public widget we can test it directly.

  Widget buildChip({
    Station? station,
    int stopNumber = 1,
    bool isSelected = false,
    double? price,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: RouteStationChip(
          station: station ?? testStation,
          stopNumber: stopNumber,
          isSelected: isSelected,
          price: price,
          onTap: onTap ?? () {},
        ),
      ),
    );
  }

  group('RouteStationChip', () {
    testWidgets('displays stop number', (tester) async {
      await tester.pumpWidget(buildChip(stopNumber: 3));
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('displays station name', (tester) async {
      await tester.pumpWidget(buildChip());
      expect(find.text(testStation.displayName), findsOneWidget);
    });

    testWidgets('displays formatted price when available', (tester) async {
      await tester.pumpWidget(buildChip(price: 1.965));
      // Price now routes through PriceFormatter — comma decimal in
      // the default FR locale plus a space before the currency.
      expect(find.text('1,965 \u20ac'), findsOneWidget);
    });

    testWidgets('displays dash when price is null', (tester) async {
      await tester.pumpWidget(buildChip(price: null));
      expect(find.text('--'), findsOneWidget);
    });

    // #4432 — the chip used to print `Station.dist`: the distance from
    // whichever route sample point's query first returned the station,
    // neither from the driver nor along the route.
    Station withFirstSeenDist() => Station(
          id: testStation.id,
          name: testStation.name,
          brand: testStation.brand,
          street: testStation.street,
          houseNumber: testStation.houseNumber,
          postCode: testStation.postCode,
          place: testStation.place,
          lat: testStation.lat,
          lng: testStation.lng,
          dist: 9.87,
          isOpen: testStation.isOpen,
        );

    testWidgets('never shows the first-seen sample distance', (tester) async {
      await tester.pumpWidget(buildChip(station: withFirstSeenDist()));
      expect(find.textContaining('9,9 km'), findsNothing);
      // Outside a route scope there is no route figure to show, and no
      // stand-in either.
      expect(find.byKey(const Key('route_chip_route_progress')), findsNothing);
    });

    testWidgets('inside a route scope shows the along-route progress, named',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RouteStopMetricsScope(
            metrics: {
              testStation.id: const RouteStopMetrics(
                routeRevision: 3,
                alongKm: 61.6,
                offRouteKm: 4.4,
              ),
            },
            child: RouteStationChip(
              station: withFirstSeenDist(),
              stopNumber: 1,
              isSelected: false,
              price: 1.9,
              onTap: () {},
            ),
          ),
        ),
      ));

      final figure = find.byKey(const Key('route_chip_route_progress'));
      expect(figure, findsOneWidget);
      // Whole units, with the along-route glyph naming it.
      expect(find.text('62 km'), findsOneWidget);
      expect(
        find.descendant(of: figure, matching: find.byIcon(Icons.linear_scale)),
        findsOneWidget,
      );
      // The chip is too small for the words; the tooltip and the spoken
      // label carry them.
      expect(
        tester.widget<Semantics>(figure).properties.label,
        'About 62 km along this route',
      );
      expect(
        tester.widget<Tooltip>(find.ancestor(
          of: figure,
          matching: find.byType(Tooltip),
        )).message,
        contains('Not the distance from you'),
      );
      expect(find.textContaining('9,9 km'), findsNothing);
    });

    testWidgets('selected chip uses primary background color', (tester) async {
      await tester.pumpWidget(buildChip(isSelected: true));
      await tester.pump(const Duration(milliseconds: 250));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(decoration.color, theme.colorScheme.primary);
    });

    testWidgets('unselected chip uses surface background color',
        (tester) async {
      await tester.pumpWidget(buildChip(isSelected: false));
      await tester.pump(const Duration(milliseconds: 250));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(decoration.color, theme.colorScheme.surface);
    });

    testWidgets('selected chip has box shadow', (tester) async {
      await tester.pumpWidget(buildChip(isSelected: true));
      await tester.pump(const Duration(milliseconds: 250));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('unselected chip has no box shadow', (tester) async {
      await tester.pumpWidget(buildChip(isSelected: false));
      await tester.pump(const Duration(milliseconds: 250));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNull);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildChip(onTap: () => tapped = true));
      await tester.tap(find.text(testStation.displayName));
      expect(tapped, isTrue);
    });

    testWidgets('stop number badge is circular', (tester) async {
      await tester.pumpWidget(buildChip(stopNumber: 3));

      final containers = find.byType(Container);
      bool foundCircle = false;
      for (final element in containers.evaluate()) {
        final widget = element.widget as Container;
        if (widget.decoration is BoxDecoration) {
          final deco = widget.decoration as BoxDecoration;
          if (deco.shape == BoxShape.circle) {
            foundCircle = true;
            break;
          }
        }
      }
      expect(foundCircle, isTrue,
          reason: 'Stop number badge should be circular');
    });
  });
}
