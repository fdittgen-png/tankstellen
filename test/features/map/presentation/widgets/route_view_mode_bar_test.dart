import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/map/presentation/widgets/route_view_mode_bar.dart';
import 'package:tankstellen/features/map/presentation/widgets/route_view_mode_chip.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  Widget buildBar({
    bool allStationsSelected = true,
    bool bestStopsSelected = false,
    int selectedCount = 0,
    VoidCallback? onTapAllStations,
    VoidCallback? onTapBestStops,
    VoidCallback? onOpenSelectedInMaps,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: RouteViewModeBar(
          allStationsSelected: allStationsSelected,
          bestStopsSelected: bestStopsSelected,
          selectedCount: selectedCount,
          onTapAllStations: onTapAllStations ?? () {},
          onTapBestStops: onTapBestStops ?? () {},
          onOpenSelectedInMaps: onOpenSelectedInMaps ?? () {},
        ),
      ),
    );
  }

  group('RouteViewModeBar', () {
    testWidgets('renders both RouteViewModeChip widgets', (tester) async {
      await tester.pumpWidget(buildBar());
      await tester.pumpAndSettle();

      expect(find.byType(RouteViewModeChip), findsNWidgets(2));
    });

    testWidgets(
        'forwards allStationsSelected and bestStopsSelected to the chips',
        (tester) async {
      await tester.pumpWidget(
        buildBar(allStationsSelected: true, bestStopsSelected: false),
      );
      await tester.pumpAndSettle();

      final chips = tester
          .widgetList<RouteViewModeChip>(find.byType(RouteViewModeChip))
          .toList();
      expect(chips, hasLength(2));
      expect(chips[0].selected, isTrue);
      expect(chips[1].selected, isFalse);

      await tester.pumpWidget(
        buildBar(allStationsSelected: false, bestStopsSelected: true),
      );
      await tester.pumpAndSettle();

      final swappedChips = tester
          .widgetList<RouteViewModeChip>(find.byType(RouteViewModeChip))
          .toList();
      expect(swappedChips[0].selected, isFalse);
      expect(swappedChips[1].selected, isTrue);
    });

    testWidgets(
        'hides count text and navigation IconButton when selectedCount == 0',
        (tester) async {
      await tester.pumpWidget(buildBar(selectedCount: 0));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsNothing);
      expect(find.byIcon(Icons.navigation), findsNothing);
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('renders the count number when selectedCount > 0',
        (tester) async {
      await tester.pumpWidget(buildBar(selectedCount: 3));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('renders Icons.navigation IconButton when selectedCount > 0',
        (tester) async {
      await tester.pumpWidget(buildBar(selectedCount: 1));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.navigation), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('tapping the All-Stations chip calls onTapAllStations',
        (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        buildBar(
          allStationsSelected: false,
          bestStopsSelected: true,
          onTapAllStations: () => tapped++,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(RouteViewModeChip).first);
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('tapping the Best-Stops chip calls onTapBestStops',
        (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        buildBar(
          allStationsSelected: true,
          bestStopsSelected: false,
          onTapBestStops: () => tapped++,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(RouteViewModeChip).at(1));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets(
        'tapping the navigation IconButton calls onOpenSelectedInMaps',
        (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        buildBar(
          selectedCount: 2,
          onOpenSelectedInMaps: () => tapped++,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.navigation));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets(
        'container background uses theme.colorScheme.surfaceContainerHighest',
        (tester) async {
      await tester.pumpWidget(buildBar());
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(RouteViewModeBar),
          matching: find.byType(Container),
        ).first,
      );
      final theme = Theme.of(tester.element(find.byType(RouteViewModeBar)));
      expect(container.color, theme.colorScheme.surfaceContainerHighest);
    });
  });
}
