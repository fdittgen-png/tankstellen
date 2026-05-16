import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/screens/sync_setup_screen.dart';
import 'package:tankstellen/features/sync/presentation/widgets/anon_key_field.dart';
import 'package:tankstellen/features/sync/presentation/widgets/sync_mode_card.dart';
import 'package:tankstellen/features/sync/presentation/widgets/wizard_create_new.dart';
import 'package:tankstellen/features/sync/presentation/widgets/sync_credentials_step.dart';

import '../../../../helpers/pump_app.dart';

/// #1703 — the private ("Base privée") sync mode walks the user through
/// the guided create-database wizard flow; "join a group" keeps the
/// plain credentials form.
void main() {
  group('SyncSetupScreen — credentials step', () {
    testWidgets('private mode renders the guided WizardCreateNew flow',
        (tester) async {
      await pumpApp(tester, const SyncSetupScreen());

      // Pick the "Private Database" mode card.
      await tester.tap(
        find.widgetWithIcon(SyncModeCard, Icons.lock_outline),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WizardCreateNew), findsOneWidget);
      expect(find.byType(SyncCredentialsStep), findsNothing);
      // The guided flow shows a step progress bar — the bare form never
      // does.
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('join-a-group mode keeps the plain credentials form',
        (tester) async {
      await pumpApp(tester, const SyncSetupScreen());

      await tester.tap(
        find.widgetWithIcon(SyncModeCard, Icons.group_outlined),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SyncCredentialsStep), findsOneWidget);
      expect(find.byType(WizardCreateNew), findsNothing);
    });

    testWidgets('the guided flow advances through its sub-steps',
        (tester) async {
      await pumpApp(tester, const SyncSetupScreen());

      await tester.tap(
        find.widgetWithIcon(SyncModeCard, Icons.lock_outline),
      );
      await tester.pumpAndSettle();

      // Step 1 — the create-Supabase-project guide opens with an
      // external-link action button and no credentials fields yet.
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
      expect(find.byType(AnonKeyField), findsNothing);

      // The single FilledButton is the wizard's Next/Continue control;
      // advancing twice reaches the credentials sub-step.
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // The credentials sub-step surfaces the URL field + the anon-key
      // field.
      expect(find.byType(AnonKeyField), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });
  });
}
