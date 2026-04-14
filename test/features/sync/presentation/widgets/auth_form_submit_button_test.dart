import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/widgets/auth_form_submit_button.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('AuthFormSubmitButton', () {
    Future<void> pumpButton(
      WidgetTester tester, {
      bool isLoading = false,
      required bool useEmail,
      required bool isSignUp,
      VoidCallback? onPressed,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AuthFormSubmitButton(
              isLoading: isLoading,
              useEmail: useEmail,
              isSignUp: isSignUp,
              onPressed: onPressed ?? () {},
            ),
          ),
        ),
      );
    }

    testWidgets('reads "Connect anonymously" when useEmail is false',
        (tester) async {
      await pumpButton(tester, useEmail: false, isSignUp: false);
      expect(find.text('Connect anonymously'), findsOneWidget);
      expect(find.byIcon(Icons.flash_on), findsOneWidget);
    });

    testWidgets('reads "Sign in & connect" for email + sign-in mode',
        (tester) async {
      await pumpButton(tester, useEmail: true, isSignUp: false);
      expect(find.text('Sign in & connect'), findsOneWidget);
      expect(find.byIcon(Icons.login), findsOneWidget);
    });

    testWidgets('reads "Create account & connect" for email + sign-up mode',
        (tester) async {
      await pumpButton(tester, useEmail: true, isSignUp: true);
      expect(find.text('Create account & connect'), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('shows the "Connecting..." label and a spinner while loading',
        (tester) async {
      await pumpButton(
        tester,
        isLoading: true,
        useEmail: true,
        isSignUp: false,
      );
      expect(find.text('Connecting...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disables the button while loading and forwards taps when not',
        (tester) async {
      var taps = 0;
      await pumpButton(
        tester,
        isLoading: true,
        useEmail: true,
        isSignUp: false,
        onPressed: () => taps++,
      );
      await tester.tap(find.byType(FilledButton));
      expect(taps, 0);

      await pumpButton(
        tester,
        useEmail: true,
        isSignUp: false,
        onPressed: () => taps++,
      );
      await tester.tap(find.byType(FilledButton));
      expect(taps, 1);
    });
  });
}
