import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/widgets/link_device_how_it_works_card.dart';

void main() {
  group('LinkDeviceHowItWorksCard', () {
    Future<void> pumpCard(WidgetTester tester) {
      return tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LinkDeviceHowItWorksCard(),
          ),
        ),
      );
    }

    testWidgets('renders the title and the info icon', (tester) async {
      await pumpCard(tester);
      expect(find.text('How it works'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('renders the step-by-step body text', (tester) async {
      await pumpCard(tester);
      expect(
        find.textContaining('On Device A'),
        findsOneWidget,
      );
      expect(
        find.textContaining('On Device B'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Import data'),
        findsOneWidget,
      );
    });

    testWidgets('renders inside a Card', (tester) async {
      await pumpCard(tester);
      expect(find.byType(Card), findsOneWidget);
    });
  });
}
