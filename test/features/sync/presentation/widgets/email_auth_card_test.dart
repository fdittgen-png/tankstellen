import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/password_strength_indicator.dart';
import 'package:tankstellen/features/sync/presentation/widgets/email_auth_card.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required TextEditingController confirmController,
    bool isSignUp = false,
    bool isLoading = false,
    bool showPassword = false,
    bool showConfirm = false,
    String? error,
    VoidCallback? onSubmit,
    VoidCallback? onToggleMode,
    VoidCallback? onTogglePassword,
    VoidCallback? onToggleConfirm,
    VoidCallback? onPasswordChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: EmailAuthCard(
              emailController: emailController,
              passwordController: passwordController,
              confirmController: confirmController,
              isSignUp: isSignUp,
              isLoading: isLoading,
              showPassword: showPassword,
              showConfirm: showConfirm,
              error: error,
              onSubmit: onSubmit ?? () {},
              onToggleMode: onToggleMode ?? () {},
              onTogglePassword: onTogglePassword ?? () {},
              onToggleConfirm: onToggleConfirm ?? () {},
              onPasswordChanged: onPasswordChanged ?? () {},
            ),
          ),
        ),
      ),
    );
    // When isLoading is true the FilledButton hosts a CircularProgressIndicator
    // whose continuous animation prevents pumpAndSettle from completing.
    if (isLoading) {
      await tester.pump();
    } else {
      await tester.pumpAndSettle();
    }
  }

  group('EmailAuthCard', () {
    late TextEditingController emailController;
    late TextEditingController passwordController;
    late TextEditingController confirmController;

    setUp(() {
      emailController = TextEditingController();
      passwordController = TextEditingController();
      confirmController = TextEditingController();
    });

    tearDown(() {
      emailController.dispose();
      passwordController.dispose();
      confirmController.dispose();
    });

    testWidgets('sign-in mode renders email + password fields', (tester) async {
      await pumpCard(
        tester,
        emailController: emailController,
        passwordController: passwordController,
        confirmController: confirmController,
        isSignUp: false,
      );

      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
      // Sign-in title appears in card header AND submit button label
      expect(find.text('Sign in'), findsNWidgets(2));
    });

    testWidgets('sign-in mode hides confirm password and strength indicator',
        (tester) async {
      passwordController.text = 'somepass';
      await pumpCard(
        tester,
        emailController: emailController,
        passwordController: passwordController,
        confirmController: confirmController,
        isSignUp: false,
      );

      expect(find.widgetWithText(TextField, 'Confirm password'), findsNothing);
      expect(find.byType(PasswordStrengthIndicator), findsNothing);
    });

    testWidgets('sign-up mode shows confirm password field', (tester) async {
      await pumpCard(
        tester,
        emailController: emailController,
        passwordController: passwordController,
        confirmController: confirmController,
        isSignUp: true,
      );

      expect(find.widgetWithText(TextField, 'Confirm password'), findsOneWidget);
      // Create account title appears in header AND submit button label
      expect(find.text('Create account'), findsNWidgets(2));
    });

    testWidgets('sign-up mode renders password strength indicator',
        (tester) async {
      await pumpCard(
        tester,
        emailController: emailController,
        passwordController: passwordController,
        confirmController: confirmController,
        isSignUp: true,
      );

      expect(find.byType(PasswordStrengthIndicator), findsOneWidget);
    });

    testWidgets('error != null renders error banner text', (tester) async {
      await pumpCard(
        tester,
        emailController: emailController,
        passwordController: passwordController,
        confirmController: confirmController,
        error: 'Invalid credentials',
      );

      expect(find.text('Invalid credentials'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('error == null renders no error banner', (tester) async {
      await pumpCard(
        tester,
        emailController: emailController,
        passwordController: passwordController,
        confirmController: confirmController,
      );

      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('isLoading disables submit button and shows spinner',
        (tester) async {
      await pumpCard(
        tester,
        emailController: emailController,
        passwordController: passwordController,
        confirmController: confirmController,
        isLoading: true,
      );

      final submitButton =
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(submitButton.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('isLoading disables toggle-mode text button', (tester) async {
      await pumpCard(
        tester,
        emailController: emailController,
        passwordController: passwordController,
        confirmController: confirmController,
        isLoading: true,
      );

      final toggleButton = tester.widget<TextButton>(find.byType(TextButton));
      expect(toggleButton.onPressed, isNull);
    });

    testWidgets('tapping submit invokes onSubmit', (tester) async {
      var submitCalls = 0;
      await pumpCard(
        tester,
        emailController: emailController,
        passwordController: passwordController,
        confirmController: confirmController,
        onSubmit: () => submitCalls++,
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(submitCalls, 1);
    });

    testWidgets('tapping toggle-mode text invokes onToggleMode',
        (tester) async {
      var toggleCalls = 0;
      await pumpCard(
        tester,
        emailController: emailController,
        passwordController: passwordController,
        confirmController: confirmController,
        isSignUp: false,
        onToggleMode: () => toggleCalls++,
      );

      await tester.tap(find.textContaining('New here'));
      await tester.pumpAndSettle();

      expect(toggleCalls, 1);
    });

    testWidgets('sign-up shows "Already have an account" toggle text',
        (tester) async {
      await pumpCard(
        tester,
        emailController: emailController,
        passwordController: passwordController,
        confirmController: confirmController,
        isSignUp: true,
      );

      expect(find.textContaining('Already have an account'), findsOneWidget);
    });

    testWidgets('tapping show-password icon invokes onTogglePassword',
        (tester) async {
      var toggleCalls = 0;
      await pumpCard(
        tester,
        emailController: emailController,
        passwordController: passwordController,
        confirmController: confirmController,
        showPassword: false,
        onTogglePassword: () => toggleCalls++,
      );

      // The visibility icon (eye) lives inside the password field's suffix.
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      expect(toggleCalls, 1);
    });

    testWidgets('tapping show-confirm icon invokes onToggleConfirm',
        (tester) async {
      var toggleCalls = 0;
      await pumpCard(
        tester,
        emailController: emailController,
        passwordController: passwordController,
        confirmController: confirmController,
        isSignUp: true,
        showPassword: true, // show password -> visibility_off icon
        showConfirm: false, // confirm visibility icon stays visibility (eye)
        onToggleConfirm: () => toggleCalls++,
      );

      // Two visibility icons exist by default; flipping showPassword=true
      // makes the password field's icon visibility_off, leaving the
      // confirm field's icon as the only Icons.visibility on screen.
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      expect(toggleCalls, 1);
    });

    testWidgets('typing in password field invokes onPasswordChanged',
        (tester) async {
      var changeCalls = 0;
      await pumpCard(
        tester,
        emailController: emailController,
        passwordController: passwordController,
        confirmController: confirmController,
        onPasswordChanged: () => changeCalls++,
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'abc',
      );
      await tester.pumpAndSettle();

      // enterText fires onChanged once for the whole entered string.
      expect(changeCalls, greaterThanOrEqualTo(1));
    });

    testWidgets(
        'showPassword=false obscures password; showPassword=true reveals it',
        (tester) async {
      await pumpCard(
        tester,
        emailController: emailController,
        passwordController: passwordController,
        confirmController: confirmController,
        showPassword: false,
      );

      var passwordField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Password'),
      );
      expect(passwordField.obscureText, isTrue);

      await pumpCard(
        tester,
        emailController: emailController,
        passwordController: passwordController,
        confirmController: confirmController,
        showPassword: true,
      );

      passwordField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Password'),
      );
      expect(passwordField.obscureText, isFalse);
    });

    testWidgets('isLoading disables email and password text fields',
        (tester) async {
      await pumpCard(
        tester,
        emailController: emailController,
        passwordController: passwordController,
        confirmController: confirmController,
        isLoading: true,
      );

      final emailField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Email'),
      );
      final passwordField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Password'),
      );
      expect(emailField.enabled, isFalse);
      expect(passwordField.enabled, isFalse);
    });
  });
}
