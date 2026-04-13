import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/widgets/wizard_create_new.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('WizardCreateNew', () {
    Widget buildWidget({
      int currentStep = 0,
      VoidCallback? onBack,
      VoidCallback? onNext,
      VoidCallback? onContinue,
    }) {
      return WizardCreateNew(
        currentStep: currentStep,
        urlController: TextEditingController(),
        keyController: TextEditingController(),
        keyField: const SizedBox.shrink(),
        onBack: onBack ?? () {},
        onNext: onNext ?? () {},
        onContinue: onContinue,
      );
    }

    testWidgets('step 1 shows Create Supabase title, Next button, no Back',
        (tester) async {
      await pumpApp(tester, buildWidget());

      expect(find.text('Create a Supabase project'), findsOneWidget);
      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Next'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Back'), findsNothing);
    });

    testWidgets('step 2 shows Enable Anonymous title + Back button',
        (tester) async {
      await pumpApp(tester, buildWidget(currentStep: 1));

      expect(find.text('Enable Anonymous Sign-ins'), findsOneWidget);
      expect(find.text('Step 2 of 4'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Back'), findsOneWidget);
    });

    testWidgets('final step shows Continue button and URL field',
        (tester) async {
      await pumpApp(
        tester,
        buildWidget(currentStep: 2, onContinue: () {}),
      );

      expect(find.text('Copy your credentials'), findsOneWidget);
      expect(find.text('Step 3 of 4'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
      expect(find.text('Supabase URL'), findsOneWidget);
    });

    testWidgets('Next tap invokes onNext callback', (tester) async {
      var nexted = false;
      await pumpApp(tester, buildWidget(onNext: () => nexted = true));

      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      expect(nexted, isTrue);
    });
  });
}
