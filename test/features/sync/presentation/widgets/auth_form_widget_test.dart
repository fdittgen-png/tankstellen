import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/widgets/auth_form_widget.dart';

void main() {
  Future<void> pumpForm(
    WidgetTester tester, {
    bool isLoading = false,
    String? error,
  }) async {
    // Fresh ProviderScope per test so the auth-form toggle state is reset.
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AuthFormWidget(
                onSubmit: ({
                  required bool isEmail,
                  String? email,
                  String? password,
                  required bool isSignUp,
                }) async {},
                isLoading: isLoading,
                error: error,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('AuthFormWidget', () {
    testWidgets('renders Anonymous/Email segmented button', (tester) async {
      await pumpForm(tester);
      expect(find.text('Anonymous'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('default mode is Anonymous — no email fields', (tester) async {
      await pumpForm(tester);
      expect(find.text('Email'), findsOneWidget); // In segmented button
      expect(find.widgetWithText(TextField, 'Email'), findsNothing); // No input field
    });

    testWidgets('tapping Email shows email and password fields', (tester) async {
      await pumpForm(tester);
      await tester.tap(find.text('Email'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    });

    testWidgets('sign-up mode shows confirm password field', (tester) async {
      await pumpForm(tester);
      await tester.tap(find.text('Email'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Confirm password'), findsOneWidget);
    });

    testWidgets('toggle to sign-in hides confirm password', (tester) async {
      await pumpForm(tester);
      await tester.tap(find.text('Email'));
      await tester.pumpAndSettle();
      // Tap "Already have an account? Sign in"
      await tester.tap(find.textContaining('Already have an account'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Confirm password'), findsNothing);
    });

    testWidgets('shows error text when error provided', (tester) async {
      await pumpForm(tester, error: 'Connection failed');
      expect(find.text('Connection failed'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await pumpForm(tester, isLoading: true);
      expect(find.text('Connecting...'), findsOneWidget);
    });

    testWidgets('anonymous connect button text', (tester) async {
      await pumpForm(tester);
      expect(find.text('Connect anonymously'), findsOneWidget);
    });

    testWidgets('email sign-up button text', (tester) async {
      await pumpForm(tester);
      await tester.tap(find.text('Email'));
      await tester.pumpAndSettle();
      expect(find.text('Create account & connect'), findsOneWidget);
    });

    group('password length validation (#198)', () {
      testWidgets('sign-in accepts passwords shorter than 6 characters', (tester) async {
        bool submitCalled = false;
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: AuthFormWidget(
                    onSubmit: ({
                      required bool isEmail,
                      String? email,
                      String? password,
                      required bool isSignUp,
                    }) async {
                      submitCalled = true;
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        // Switch to email mode
        await tester.tap(find.text('Email'));
        await tester.pumpAndSettle();

        // Switch to sign-in mode
        await tester.tap(find.textContaining('Already have an account'));
        await tester.pumpAndSettle();

        // Enter email and short password
        await tester.enterText(find.widgetWithText(TextField, 'Email'), 'test@example.com');
        await tester.enterText(find.widgetWithText(TextField, 'Password'), 'abc');

        // Submit
        await tester.tap(find.text('Sign in & connect'));
        await tester.pumpAndSettle();

        // Should call onSubmit without showing password-too-short error
        expect(submitCalled, isTrue);
      });

      testWidgets('sign-up rejects passwords shorter than 6 characters', (tester) async {
        bool submitCalled = false;
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: AuthFormWidget(
                    onSubmit: ({
                      required bool isEmail,
                      String? email,
                      String? password,
                      required bool isSignUp,
                    }) async {
                      submitCalled = true;
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        // Switch to email mode (already in sign-up mode by default)
        await tester.tap(find.text('Email'));
        await tester.pumpAndSettle();

        // Enter email and short password
        await tester.enterText(find.widgetWithText(TextField, 'Email'), 'test@example.com');
        await tester.enterText(find.widgetWithText(TextField, 'Password'), 'abc');
        await tester.enterText(find.widgetWithText(TextField, 'Confirm password'), 'abc');

        // Submit
        await tester.tap(find.text('Create account & connect'));
        await tester.pumpAndSettle();

        // Should NOT call onSubmit — validation should block it
        expect(submitCalled, isFalse);
      });
    });
  });
}
