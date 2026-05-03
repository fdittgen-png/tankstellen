import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/detected_from_vin_badge.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  Widget buildHarness({required bool show, Locale locale = const Locale('en')}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(body: DetectedFromVinBadge(show: show)),
    );
  }

  group('DetectedFromVinBadge (#1399)', () {
    testWidgets('renders "(detected)" when show=true and locale=en',
        (tester) async {
      await tester.pumpWidget(buildHarness(show: true));
      await tester.pumpAndSettle();
      expect(find.text('(detected)'), findsOneWidget);
    });

    testWidgets('renders "(détecté)" when locale=fr', (tester) async {
      await tester.pumpWidget(
        buildHarness(show: true, locale: const Locale('fr')),
      );
      await tester.pumpAndSettle();
      expect(find.text('(détecté)'), findsOneWidget);
    });

    testWidgets('collapses to SizedBox.shrink when show=false',
        (tester) async {
      await tester.pumpWidget(buildHarness(show: false));
      await tester.pumpAndSettle();
      expect(find.text('(detected)'), findsNothing);
      // The Text widget should not be in the tree at all.
      expect(find.byType(Text), findsNothing);
    });
  });
}
