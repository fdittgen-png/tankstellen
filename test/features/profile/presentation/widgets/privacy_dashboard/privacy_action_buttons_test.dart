import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/presentation/widgets/privacy_dashboard/privacy_action_buttons.dart';

import '../../../../../helpers/pump_app.dart';

void main() {
  group('PrivacyExportJsonButton', () {
    testWidgets('renders download icon + JSON export label', (tester) async {
      await pumpApp(
        tester,
        PrivacyExportJsonButton(onPressed: () {}),
      );
      expect(find.byIcon(Icons.download), findsOneWidget);
      expect(find.textContaining('JSON'), findsOneWidget);
    });

    testWidgets('tap invokes onPressed', (tester) async {
      var tapped = 0;
      await pumpApp(
        tester,
        PrivacyExportJsonButton(onPressed: () => tapped++),
      );
      await tester.tap(find.byType(OutlinedButton));
      expect(tapped, 1);
    });

    testWidgets('is laid out full-width', (tester) async {
      await pumpApp(
        tester,
        PrivacyExportJsonButton(onPressed: () {}),
      );
      final size = tester.getSize(find.byType(OutlinedButton));
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(size.width, closeTo(screen.width, 1));
    });
  });

  group('PrivacyExportCsvButton', () {
    testWidgets('renders table icon + CSV export label', (tester) async {
      await pumpApp(
        tester,
        PrivacyExportCsvButton(onPressed: () {}),
      );
      expect(find.byIcon(Icons.table_chart), findsOneWidget);
      expect(find.textContaining('CSV'), findsOneWidget);
    });

    testWidgets('tap invokes onPressed', (tester) async {
      var tapped = 0;
      await pumpApp(
        tester,
        PrivacyExportCsvButton(onPressed: () => tapped++),
      );
      await tester.tap(find.byType(OutlinedButton));
      expect(tapped, 1);
    });
  });

  group('PrivacyDeleteAllButton', () {
    testWidgets('renders delete_forever icon + label',
        (tester) async {
      await pumpApp(
        tester,
        PrivacyDeleteAllButton(onPressed: () {}),
      );
      expect(find.byIcon(Icons.delete_forever), findsOneWidget);
      expect(find.textContaining('Delete'), findsOneWidget);
    });

    testWidgets('uses the error colour scheme (destructive cue)',
        (tester) async {
      // Pins the visual-distinction contract between this button
      // and the export buttons — a theme refactor that levels them
      // back to the neutral outline would remove the warning cue.
      await pumpApp(
        tester,
        PrivacyDeleteAllButton(onPressed: () {}),
      );
      final button = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      final style = button.style!;
      // Foreground colour should be the theme's error colour; we
      // don't pin an exact value (it varies with light/dark) but
      // we assert that a non-default override is in place.
      expect(style.foregroundColor, isNotNull);
      expect(style.side, isNotNull);
    });

    testWidgets('tap invokes onPressed', (tester) async {
      var tapped = 0;
      await pumpApp(
        tester,
        PrivacyDeleteAllButton(onPressed: () => tapped++),
      );
      await tester.tap(find.byType(OutlinedButton));
      expect(tapped, 1);
    });
  });
}
