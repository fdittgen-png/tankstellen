import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/setup/presentation/widgets/setup_header.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('SetupHeader', () {
    Future<void> pumpHeader(WidgetTester tester,
        {Locale locale = const Locale('en')}) {
      return tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SetupHeader()),
        ),
      );
    }

    testWidgets('renders the gas-pump hero icon', (tester) async {
      await pumpHeader(tester);
      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
    });

    testWidgets('renders the welcome title and subtitle in English',
        (tester) async {
      await pumpHeader(tester);
      // The welcome key resolves to "Fuel Prices" in English; subtitle to
      // "Find the cheapest fuel near you." Both must render.
      expect(find.text('Fuel Prices'), findsOneWidget);
      expect(find.text('Find the cheapest fuel near you.'), findsOneWidget);
    });

    testWidgets('marks the title with header semantics for screen readers',
        (tester) async {
      await pumpHeader(tester);
      // Look for a Semantics node with header: true wrapping the title.
      final headerSemantics = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.header == true &&
            w.child is Text &&
            (w.child as Text).data == 'Fuel Prices',
      );
      expect(headerSemantics, findsOneWidget);
    });

    testWidgets('hides the icon from semantics so screen readers do not '
        'announce a meaningless graphic', (tester) async {
      await pumpHeader(tester);
      // The icon is wrapped in `Semantics(excludeSemantics: true, ...)`,
      // so it produces no semantics label.
      expect(
        find.bySemanticsLabel(RegExp('local_gas_station|gas')),
        findsNothing,
      );
    });
  });
}
