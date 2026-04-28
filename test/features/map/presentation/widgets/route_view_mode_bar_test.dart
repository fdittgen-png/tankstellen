import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/map/presentation/widgets/route_view_mode_bar.dart';
import 'package:tankstellen/features/map/presentation/widgets/route_view_mode_chip.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  RouteViewModeBar buildBar({
    bool allStationsSelected = true,
    bool bestStopsSelected = false,
    int selectedCount = 0,
    VoidCallback? onTapAllStations,
    VoidCallback? onTapBestStops,
    VoidCallback? onOpenSelectedInMaps,
  }) {
    return RouteViewModeBar(
      allStationsSelected: allStationsSelected,
      bestStopsSelected: bestStopsSelected,
      selectedCount: selectedCount,
      onTapAllStations: onTapAllStations ?? () {},
      onTapBestStops: onTapBestStops ?? () {},
      onOpenSelectedInMaps: onOpenSelectedInMaps ?? () {},
    );
  }

  group('RouteViewModeBar', () {
    testWidgets('renders both chips with localized labels and icons',
        (tester) async {
      await tester.pumpWidget(wrap(buildBar()));
      await tester.pumpAndSettle();

      expect(find.byType(RouteViewModeChip), findsNWidgets(2));
      expect(find.text('All stations'), findsOneWidget);
      expect(find.text('Best stops'), findsOneWidget);
      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('forwards allStationsSelected to the first chip',
        (tester) async {
      await tester.pumpWidget(wrap(buildBar(
        allStationsSelected: true,
        bestStopsSelected: false,
      )));
      await tester.pumpAndSettle();

      final firstChip = tester.widget<RouteViewModeChip>(
        find.byType(RouteViewModeChip).first,
      );
      expect(firstChip.selected, isTrue);
    });

    testWidgets('forwards bestStopsSelected to the second chip',
        (tester) async {
      await tester.pumpWidget(wrap(buildBar(
        allStationsSelected: false,
        bestStopsSelected: true,
      )));
      await tester.pumpAndSettle();

      final secondChip = tester.widget<RouteViewModeChip>(
        find.byType(RouteViewModeChip).at(1),
      );
      expect(secondChip.selected, isTrue);
    });

    testWidgets('first chip unselected when allStationsSelected is false',
        (tester) async {
      await tester.pumpWidget(wrap(buildBar(
        allStationsSelected: false,
        bestStopsSelected: true,
      )));
      await tester.pumpAndSettle();

      final firstChip = tester.widget<RouteViewModeChip>(
        find.byType(RouteViewModeChip).first,
      );
      expect(firstChip.selected, isFalse);
    });

    testWidgets('tapping the All-Stations chip invokes onTapAllStations',
        (tester) async {
      var allTaps = 0;
      var bestTaps = 0;
      await tester.pumpWidget(wrap(buildBar(
        onTapAllStations: () => allTaps++,
        onTapBestStops: () => bestTaps++,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('All stations'));
      await tester.pump();

      expect(allTaps, 1);
      expect(bestTaps, 0);
    });

    testWidgets('tapping the Best-Stops chip invokes onTapBestStops',
        (tester) async {
      var allTaps = 0;
      var bestTaps = 0;
      await tester.pumpWidget(wrap(buildBar(
        onTapAllStations: () => allTaps++,
        onTapBestStops: () => bestTaps++,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Best stops'));
      await tester.pump();

      expect(bestTaps, 1);
      expect(allTaps, 0);
    });

    testWidgets('selectedCount == 0 hides count text and IconButton',
        (tester) async {
      await tester.pumpWidget(wrap(buildBar(selectedCount: 0)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.navigation), findsNothing);
      expect(find.byType(IconButton), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('selectedCount > 0 renders count text and navigation icon',
        (tester) async {
      await tester.pumpWidget(wrap(buildBar(selectedCount: 3)));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.navigation), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('tapping the navigation IconButton invokes onOpenSelectedInMaps',
        (tester) async {
      var openTaps = 0;
      await tester.pumpWidget(wrap(buildBar(
        selectedCount: 2,
        onOpenSelectedInMaps: () => openTaps++,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.navigation));
      await tester.pump();

      expect(openTaps, 1);
    });

    testWidgets('IconButton tooltip is the localized openInMaps string',
        (tester) async {
      await tester.pumpWidget(wrap(buildBar(selectedCount: 1)));
      await tester.pumpAndSettle();

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, 'Open in Maps');
    });

    testWidgets('selectedCount renders the exact integer value',
        (tester) async {
      await tester.pumpWidget(wrap(buildBar(selectedCount: 12)));
      await tester.pumpAndSettle();

      expect(find.text('12'), findsOneWidget);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('both chips can be unselected simultaneously', (tester) async {
      await tester.pumpWidget(wrap(buildBar(
        allStationsSelected: false,
        bestStopsSelected: false,
      )));
      await tester.pumpAndSettle();

      final chips = tester
          .widgetList<RouteViewModeChip>(find.byType(RouteViewModeChip))
          .toList();
      expect(chips, hasLength(2));
      expect(chips[0].selected, isFalse);
      expect(chips[1].selected, isFalse);
    });
  });
}
