import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/widgets/auth_form_error_box.dart';

void main() {
  group('AuthFormErrorBox', () {
    Future<void> pumpBox(WidgetTester tester, String message) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthFormErrorBox(message: message),
          ),
        ),
      );
    }

    testWidgets('renders the supplied message', (tester) async {
      await pumpBox(tester, 'Network unreachable');
      expect(find.text('Network unreachable'), findsOneWidget);
    });

    testWidgets('renders the leading error_outline icon', (tester) async {
      await pumpBox(tester, 'Boom');
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('uses the theme error color for the icon and text',
        (tester) async {
      await pumpBox(tester, 'Boom');
      final ctx = tester.element(find.byType(AuthFormErrorBox));
      final errorColor = Theme.of(ctx).colorScheme.error;
      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.color, errorColor);
      final text = tester.widget<Text>(find.text('Boom'));
      expect(text.style?.color, errorColor);
    });

    testWidgets('paints a tinted background container behind the row',
        (tester) async {
      await pumpBox(tester, 'Boom');
      // Find the Container that AuthFormErrorBox builds (the only one
      // inside the widget) and confirm it has a BoxDecoration.
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AuthFormErrorBox),
          matching: find.byType(Container),
        ),
      );
      expect(container.decoration, isA<BoxDecoration>());
    });
  });
}
