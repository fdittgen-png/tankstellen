import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/screens/sync_wizard_screen.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('SyncWizardScreen', () {
    testWidgets('renders choose mode screen with two options', (tester) async {
      await pumpApp(tester, const SyncWizardScreen());

      expect(find.text('Create my own database'), findsOneWidget);
      expect(find.text('Join an existing database'), findsOneWidget);
    });

    testWidgets('renders TankSync info card', (tester) async {
      await pumpApp(tester, const SyncWizardScreen());

      expect(find.text('TankSync is optional'), findsOneWidget);
    });

    testWidgets('renders Connect TankSync title', (tester) async {
      await pumpApp(tester, const SyncWizardScreen());

      expect(find.text('Connect TankSync'), findsOneWidget);
    });
  });
}
