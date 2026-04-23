import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/setup/presentation/widgets/completion_step.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('CompletionStep', () {
    testWidgets('renders shield illustration and text', (tester) async {
      await pumpApp(tester, const CompletionStep());

      // #593: completion step renders the branded ShieldIllustration
      // (privacy shield + fuel drop) instead of the generic check-mark.
      expect(find.byIcon(Icons.verified_user), findsOneWidget);
      expect(find.byIcon(Icons.water_drop), findsOneWidget);
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
