import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/setup/presentation/widgets/completion_step.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('CompletionStep', () {
    testWidgets('renders completion icon and text', (tester) async {
      await pumpApp(tester, const CompletionStep());

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.text('All set!'), findsOneWidget);
      expect(
        find.text('You can change these settings anytime in your profile.'),
        findsOneWidget,
      );
    });

    testWidgets('renders German text with de locale', (tester) async {
      await pumpApp(
        tester,
        const CompletionStep(),
        locale: const Locale('de'),
      );

      expect(find.text('Alles bereit!'), findsOneWidget);
    });
  });
}
