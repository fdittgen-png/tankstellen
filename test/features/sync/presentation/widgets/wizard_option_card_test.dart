import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/widgets/wizard_option_card.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('WizardOptionCard', () {
    testWidgets('renders title and subtitle', (tester) async {
      await pumpApp(
        tester,
        WizardOptionCard(
          icon: Icons.add,
          title: 'Test Title',
          subtitle: 'Test Subtitle',
          onTap: () {},
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await pumpApp(
        tester,
        WizardOptionCard(
          icon: Icons.add,
          title: 'Tap Me',
          subtitle: 'Subtitle',
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.text('Tap Me'));
      expect(tapped, isTrue);
    });

    testWidgets('shows selected state with primary color', (tester) async {
      await pumpApp(
        tester,
        WizardOptionCard(
          icon: Icons.add,
          title: 'Selected',
          subtitle: 'Sub',
          selected: true,
          onTap: () {},
        ),
      );

      // Selected card has elevation 2
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 2);
    });
  });
}
