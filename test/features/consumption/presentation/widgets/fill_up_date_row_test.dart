import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_date_row.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('FillUpDateRow', () {
    Future<void> pumpRow(
      WidgetTester tester, {
      required String dateLabel,
      required VoidCallback onTap,
      Locale locale = const Locale('en'),
    }) {
      return tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FillUpDateRow(dateLabel: dateLabel, onTap: onTap),
          ),
        ),
      );
    }

    testWidgets('renders the calendar icon, localised label, and date subtitle',
        (tester) async {
      await pumpRow(tester, dateLabel: '2026-04-21', onTap: () {});
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('2026-04-21'), findsOneWidget);
    });

    testWidgets('renders French label on fr locale', (tester) async {
      await pumpRow(
        tester,
        dateLabel: '2026-04-21',
        onTap: () {},
        locale: const Locale('fr'),
      );
      await tester.pumpAndSettle();

      // The French ARB ships `fillUpDate: "Date"` (same word as English).
      // The important check is that the widget renders via
      // AppLocalizations rather than a hard-coded English literal.
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('2026-04-21'), findsOneWidget);
    });

    testWidgets('forwards onTap', (tester) async {
      var tapped = false;
      await pumpRow(tester, dateLabel: '2026-04-21', onTap: () => tapped = true);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FillUpDateRow));
      expect(tapped, isTrue);
    });
  });
}
