import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/widgets/auth_status_cards.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('EmailUserStatusCard', () {
    testWidgets('shows signed-in email', (tester) async {
      await pumpApp(
        tester,
        EmailUserStatusCard(
          userEmail: 'test@example.com',
          isLoading: false,
          onSwitchToAnonymous: () {},
        ),
      );

      expect(find.textContaining('test@example.com'), findsOneWidget);
    });

    testWidgets('shows verified user icon', (tester) async {
      await pumpApp(
        tester,
        EmailUserStatusCard(
          userEmail: 'test@example.com',
          isLoading: false,
          onSwitchToAnonymous: () {},
        ),
      );

      expect(find.byIcon(Icons.verified_user), findsOneWidget);
    });

    testWidgets('switch to anonymous triggers callback', (tester) async {
      var switched = false;
      await pumpApp(
        tester,
        EmailUserStatusCard(
          userEmail: 'test@example.com',
          isLoading: false,
          onSwitchToAnonymous: () => switched = true,
        ),
      );

      await tester.tap(find.text('Switch to anonymous'));
      expect(switched, isTrue);
    });

    testWidgets('switch button disabled when loading', (tester) async {
      var switched = false;
      await pumpApp(
        tester,
        EmailUserStatusCard(
          userEmail: 'test@example.com',
          isLoading: true,
          onSwitchToAnonymous: () => switched = true,
        ),
      );

      await tester.tap(find.text('Switch to anonymous'));
      expect(switched, isFalse);
    });
  });

  group('GuestOptionCard', () {
    testWidgets('shows continue as guest option', (tester) async {
      await pumpApp(
        tester,
        GuestOptionCard(
          isLoading: false,
          onContinueAsGuest: () {},
        ),
      );

      expect(find.textContaining('guest'), findsWidgets);
    });

    testWidgets('triggers callback on tap', (tester) async {
      var continued = false;
      await pumpApp(
        tester,
        GuestOptionCard(
          isLoading: false,
          onContinueAsGuest: () => continued = true,
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(continued, isTrue);
    });

    testWidgets('shows divider with "or"', (tester) async {
      await pumpApp(
        tester,
        GuestOptionCard(
          isLoading: false,
          onContinueAsGuest: () {},
        ),
      );

      expect(find.text('or'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(2));
    });
  });

  group('AnonymousStatusCard', () {
    testWidgets('shows truncated user ID', (tester) async {
      await pumpApp(
        tester,
        const AnonymousStatusCard(
          userId: 'abcdef12-3456-7890-abcd-ef1234567890',
        ),
      );

      expect(find.textContaining('abcdef12'), findsOneWidget);
    });

    testWidgets('shows upgrade prompt', (tester) async {
      await pumpApp(
        tester,
        const AnonymousStatusCard(userId: 'abcdef1234567890'),
      );

      expect(find.textContaining('Add an email'), findsOneWidget);
    });

    testWidgets('shows person outline icon', (tester) async {
      await pumpApp(
        tester,
        const AnonymousStatusCard(userId: 'abcdef1234567890'),
      );

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });
  });
}
