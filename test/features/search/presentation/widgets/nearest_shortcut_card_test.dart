import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/presentation/widgets/nearest_shortcut_card.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('NearestShortcutCard', () {
    testWidgets('renders title and hint text', (tester) async {
      await pumpApp(
        tester,
        NearestShortcutCard(onTap: () {}),
      );

      expect(find.text('Nearest stations'), findsOneWidget);
      expect(
        find.text(
            'Find the closest stations using your current location'),
        findsOneWidget,
      );
    });

    testWidgets('renders near_me icon', (tester) async {
      await pumpApp(
        tester,
        NearestShortcutCard(onTap: () {}),
      );

      expect(find.byIcon(Icons.near_me), findsOneWidget);
    });

    testWidgets('renders chevron_right icon', (tester) async {
      await pumpApp(
        tester,
        NearestShortcutCard(onTap: () {}),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await pumpApp(
        tester,
        NearestShortcutCard(onTap: () => tapped = true),
      );

      await tester.tap(find.byType(NearestShortcutCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders German text with de locale', (tester) async {
      await pumpApp(
        tester,
        NearestShortcutCard(onTap: () {}),
        locale: const Locale('de'),
      );

      expect(find.text('Nächste Tankstellen'), findsOneWidget);
      expect(
        find.text(
            'Die nächstgelegenen Tankstellen über Ihren Standort finden'),
        findsOneWidget,
      );
    });

    testWidgets('is wrapped in a Card widget', (tester) async {
      await pumpApp(
        tester,
        NearestShortcutCard(onTap: () {}),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('has InkWell for tap feedback', (tester) async {
      await pumpApp(
        tester,
        NearestShortcutCard(onTap: () {}),
      );

      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
