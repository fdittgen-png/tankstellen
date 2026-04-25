import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/driving/presentation/widgets/driving_bottom_bar.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('DrivingBottomBar', () {
    testWidgets('fires onRecenter exactly once when the location button taps',
        (tester) async {
      var recenter = 0;
      var nearest = 0;
      var exit = 0;

      await pumpApp(
        tester,
        DrivingBottomBar(
          onRecenter: () => recenter++,
          onNearestStation: () => nearest++,
          onExit: () => exit++,
        ),
      );

      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pumpAndSettle();

      expect(recenter, 1);
      expect(nearest, 0);
      expect(exit, 0);
    });

    testWidgets(
        'fires onNearestStation exactly once when the gas-station button taps',
        (tester) async {
      var recenter = 0;
      var nearest = 0;
      var exit = 0;

      await pumpApp(
        tester,
        DrivingBottomBar(
          onRecenter: () => recenter++,
          onNearestStation: () => nearest++,
          onExit: () => exit++,
        ),
      );

      await tester.tap(find.byIcon(Icons.local_gas_station));
      await tester.pumpAndSettle();

      expect(nearest, 1);
      expect(recenter, 0);
      expect(exit, 0);
    });

    testWidgets('fires onExit exactly once when the close button taps',
        (tester) async {
      var recenter = 0;
      var nearest = 0;
      var exit = 0;

      await pumpApp(
        tester,
        DrivingBottomBar(
          onRecenter: () => recenter++,
          onNearestStation: () => nearest++,
          onExit: () => exit++,
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(exit, 1);
      expect(recenter, 0);
      expect(nearest, 0);
    });

    testWidgets('renders English fallback labels when no l10n delegate wired',
        (tester) async {
      // Builds the bar with a bare MaterialApp that has no
      // AppLocalizations delegate, forcing the `?? 'fallback'` arms.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrivingBottomBar(
              onRecenter: () {},
              onNearestStation: () {},
              onExit: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Nearest'), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);
    });

    testWidgets('renders the localized labels when AppLocalizations is wired',
        (tester) async {
      await pumpApp(
        tester,
        DrivingBottomBar(
          onRecenter: () {},
          onNearestStation: () {},
          onExit: () {},
        ),
      );

      // English ARB: currentLocation = "Current location",
      // drivingNearestStation = "Nearest", drivingExit = "Exit".
      expect(find.text('Current location'), findsOneWidget);
      expect(find.text('Nearest'), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);
    });

    testWidgets('all three buttons meet the Android tap-target guideline (>=48dp)',
        (tester) async {
      final handle = tester.ensureSemantics();

      await pumpApp(
        tester,
        DrivingBottomBar(
          onRecenter: () {},
          onNearestStation: () {},
          onExit: () {},
        ),
      );

      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
      );

      handle.dispose();
    });

    testWidgets('bottom padding includes MediaQuery viewPadding.bottom',
        (tester) async {
      const inset = 34.0;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MediaQuery(
            data: const MediaQueryData(
              viewPadding: EdgeInsets.only(bottom: inset),
            ),
            child: Scaffold(
              body: DrivingBottomBar(
                onRecenter: () {},
                onNearestStation: () {},
                onExit: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The Container is the root of DrivingBottomBar; its bottom padding
      // must be the base 12dp + the system inset (34dp) = 46dp.
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(DrivingBottomBar),
              matching: find.byType(Container),
            )
            .first,
      );
      final padding = container.padding as EdgeInsets;
      expect(padding.bottom, 12 + inset);
      expect(padding.top, 12);
      expect(padding.left, 16);
      expect(padding.right, 16);

      // No overflow at the inset.
      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out the three buttons in a single Row',
        (tester) async {
      await pumpApp(
        tester,
        DrivingBottomBar(
          onRecenter: () {},
          onNearestStation: () {},
          onExit: () {},
        ),
      );

      // One Row with all three icons — confirms the spaceEvenly layout
      // contract the driving cockpit relies on.
      final row = find.descendant(
        of: find.byType(DrivingBottomBar),
        matching: find.byType(Row),
      );
      expect(row, findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
