import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/password_strength_indicator.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('PasswordStrengthIndicator', () {
    testWidgets('shows nothing for empty password', (tester) async {
      await pumpApp(tester, const PasswordStrengthIndicator(password: ''));
      // SizedBox.shrink is rendered, no progress indicator
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('shows strength bar for non-empty password', (tester) async {
      await pumpApp(
        tester,
        const PasswordStrengthIndicator(password: 'abc'),
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows Weak label for simple password', (tester) async {
      await pumpApp(
        tester,
        const PasswordStrengthIndicator(password: 'abc'),
      );
      expect(find.text('Weak'), findsOneWidget);
    });

    testWidgets('shows Strong label for complex password', (tester) async {
      await pumpApp(
        tester,
        const PasswordStrengthIndicator(password: 'Abcdefg1!'),
      );
      expect(find.text('Strong'), findsOneWidget);
    });

    testWidgets('shows requirement checklist items', (tester) async {
      await pumpApp(
        tester,
        const PasswordStrengthIndicator(password: 'abc'),
      );
      // Should show all 5 requirement labels
      expect(find.textContaining('8 characters'), findsOneWidget);
      expect(find.textContaining('uppercase'), findsOneWidget);
      expect(find.textContaining('lowercase'), findsOneWidget);
      expect(find.textContaining('number'), findsOneWidget);
      expect(find.textContaining('special'), findsOneWidget);
    });

    testWidgets('shows check icons for met requirements', (tester) async {
      await pumpApp(
        tester,
        const PasswordStrengthIndicator(password: 'abcdefgh'),
      );
      // minLength and lowercase are met -> 2 check_circle icons
      final checkIcons = find.byIcon(Icons.check_circle);
      final circleIcons = find.byIcon(Icons.circle_outlined);
      expect(checkIcons, findsNWidgets(2)); // minLength + lowercase
      expect(circleIcons, findsNWidgets(3)); // uppercase + digit + special
    });

    testWidgets('shows all checks for fully valid password', (tester) async {
      await pumpApp(
        tester,
        const PasswordStrengthIndicator(password: 'Abcdefg1!'),
      );
      expect(find.byIcon(Icons.check_circle), findsNWidgets(5));
      expect(find.byIcon(Icons.circle_outlined), findsNothing);
    });

    testWidgets('shows Fair label for medium-strength password', (tester) async {
      await pumpApp(
        tester,
        // Meets minLength, lowercase, uppercase (3/5 = 0.48 score)
        const PasswordStrengthIndicator(password: 'Abcdefgh'),
      );
      expect(find.text('Fair'), findsOneWidget);
    });

    testWidgets('shows German labels when locale is de', (tester) async {
      await pumpApp(
        tester,
        const PasswordStrengthIndicator(password: 'abc'),
        locale: const Locale('de'),
      );
      expect(find.text('Schwach'), findsOneWidget);
      expect(find.textContaining('Zeichen'), findsOneWidget);
    });
  });
}
