import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/widgets/auth_info_card.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AuthInfoCard', () {
    testWidgets('shows info icon', (tester) async {
      await pumpApp(tester, const AuthInfoCard());
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('shows "Why create an account?" title', (tester) async {
      await pumpApp(tester, const AuthInfoCard());
      expect(find.text('Why create an account?'), findsOneWidget);
    });

    testWidgets('lists sync benefits', (tester) async {
      await pumpApp(tester, const AuthInfoCard());
      expect(find.textContaining('Sync favorites'), findsOneWidget);
      expect(find.textContaining('delete your account'), findsOneWidget);
    });

    testWidgets('is wrapped in a Card', (tester) async {
      await pumpApp(tester, const AuthInfoCard());
      expect(find.byType(Card), findsOneWidget);
    });
  });
}
