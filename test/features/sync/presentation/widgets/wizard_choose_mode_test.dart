import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/widgets/wizard_choose_mode.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('WizardChooseMode', () {
    testWidgets('renders both options and info card', (tester) async {
      await pumpApp(
        tester,
        WizardChooseMode(
          onCreateNew: () {},
          onJoinExisting: () {},
        ),
      );

      expect(find.text('TankSync is optional'), findsOneWidget);
      expect(find.text('Create my own database'), findsOneWidget);
      expect(find.text('Join an existing database'), findsOneWidget);
    });

    testWidgets('calls onCreateNew when first option tapped', (tester) async {
      var called = false;
      await pumpApp(
        tester,
        WizardChooseMode(
          onCreateNew: () => called = true,
          onJoinExisting: () {},
        ),
      );

      await tester.tap(find.text('Create my own database'));
      expect(called, isTrue);
    });

    testWidgets('calls onJoinExisting when second option tapped', (tester) async {
      var called = false;
      await pumpApp(
        tester,
        WizardChooseMode(
          onCreateNew: () {},
          onJoinExisting: () => called = true,
        ),
      );

      await tester.tap(find.text('Join an existing database'));
      expect(called, isTrue);
    });
  });
}
