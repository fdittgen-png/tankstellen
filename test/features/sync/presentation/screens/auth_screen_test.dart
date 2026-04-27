import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/core/widgets/page_scaffold.dart';
import 'package:tankstellen/features/sync/presentation/screens/auth_screen.dart';
import 'package:tankstellen/features/sync/presentation/widgets/auth_info_card.dart';
import 'package:tankstellen/features/sync/presentation/widgets/auth_status_cards.dart';
import 'package:tankstellen/features/sync/presentation/widgets/email_auth_card.dart';
import 'package:tankstellen/features/sync/providers/auth_form_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Fake [AuthFormController] that lets tests drive the form state
/// directly (sign-up vs sign-in, loading, error) without touching the
/// real Supabase-backed [TankSyncClient]. Records mutator calls so
/// tests can assert that user interactions are forwarded to the
/// notifier (toggleSignUp, togglePassword, reset, etc.).
class _FakeAuthFormController extends AuthFormController {
  _FakeAuthFormController(this._initial);

  final AuthFormState _initial;

  int toggleSignUpCalls = 0;
  int togglePasswordCalls = 0;
  int toggleConfirmCalls = 0;
  int touchCalls = 0;
  int resetCalls = 0;

  @override
  AuthFormState build() => _initial;

  @override
  void toggleSignUp() {
    toggleSignUpCalls++;
    super.toggleSignUp();
  }

  @override
  void togglePassword() {
    togglePasswordCalls++;
    super.togglePassword();
  }

  @override
  void toggleConfirm() {
    toggleConfirmCalls++;
    super.toggleConfirm();
  }

  @override
  void touch() {
    touchCalls++;
    super.touch();
  }

  @override
  void reset() {
    resetCalls++;
    // Don't call super.reset() — it would clobber the initial state we
    // configured for the test (the screen calls reset() once in
    // initState's post-frame callback).
  }
}

/// Fake [SyncState] returning a fixed [SyncConfig]. Lets tests choose
/// between "anonymous user" and "email user" rendering paths without
/// hitting Supabase.
class _FakeSyncState extends SyncState {
  _FakeSyncState(this._config);
  final SyncConfig _config;

  @override
  SyncConfig build() => _config;
}

/// Fake [SyncState] whose [signInWithEmail] always throws the supplied
/// error. Used to verify the catch-block goes through the friendly-error
/// mapper rather than dumping `e.toString()` onto the screen (#1186).
class _ThrowingSyncState extends SyncState {
  _ThrowingSyncState(this._error);
  final Object _error;

  @override
  SyncConfig build() => const SyncConfig();

  @override
  Future<void> signInWithEmail(
    String email,
    String password, {
    bool isSignUp = true,
  }) async {
    throw _error;
  }
}

void main() {
  setUp(() {
    // The friendly-error mapper used by AuthScreen logs through
    // errorLogger, which falls through to the Hive-backed spool when
    // no foreground container is bound. Hive is not initialised in
    // pure widget tests, so override the enqueue to a no-op.
    errorLogger.spoolEnqueueOverride = ({
      required String isolateTaskName,
      required Object error,
      StackTrace? stack,
      Map<String, dynamic>? contextMap,
      DateTime? timestamp,
    }) async {};
  });

  tearDown(() {
    errorLogger.resetForTest();
  });

  group('AuthScreen', () {
    Future<_FakeAuthFormController> pumpAuthScreen(
      WidgetTester tester, {
      AuthFormState formState = const AuthFormState(),
      SyncConfig syncConfig = const SyncConfig(),
      bool settle = true,
    }) async {
      final fakeForm = _FakeAuthFormController(formState);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authFormControllerProvider.overrideWith(() => fakeForm),
            syncStateProvider.overrideWith(() => _FakeSyncState(syncConfig)),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: AuthScreen(),
          ),
        ),
      );
      // pumpAndSettle hangs on a continuous CircularProgressIndicator,
      // so callers exercising the isLoading path opt out via settle:false.
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        // Drain the post-frame initState callback without waiting for
        // the spinner animation to finish.
        await tester.pump();
      }
      return fakeForm;
    }

    testWidgets('renders without throwing and shows the localized title',
        (tester) async {
      await pumpAuthScreen(tester);

      expect(find.byType(PageScaffold), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets(
        'anonymous (no Supabase session): shows GuestOptionCard + EmailAuthCard',
        (tester) async {
      await pumpAuthScreen(tester);

      // No email -> EmailUserStatusCard absent.
      expect(find.byType(EmailUserStatusCard), findsNothing);
      // TankSyncClient.isConnected returns false in tests (no init) -> guest CTA.
      expect(find.byType(GuestOptionCard), findsOneWidget);
      // Email auth form is offered alongside the guest option.
      expect(find.byType(EmailAuthCard), findsOneWidget);
      // AuthInfoCard at the bottom for anonymous users — may sit
      // off-screen below the ListView's viewport, so look at the
      // full element tree rather than just the painted set.
      expect(
          find.byType(AuthInfoCard, skipOffstage: false), findsOneWidget);
    });

    testWidgets(
        'sign-up form (default): renders email + password + confirm fields',
        (tester) async {
      await pumpAuthScreen(
        tester,
        formState: const AuthFormState(isSignUp: true),
      );

      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
      expect(
          find.widgetWithText(TextField, 'Confirm password'), findsOneWidget);
    });

    testWidgets('sign-in form: renders email + password (no confirm)',
        (tester) async {
      await pumpAuthScreen(
        tester,
        formState: const AuthFormState(isSignUp: false),
      );

      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Confirm password'), findsNothing);
    });

    testWidgets(
        'tapping the toggle-mode button forwards toggleSignUp to the controller',
        (tester) async {
      // Start in sign-in mode so the visible toggle text is "New here?
      // Create account" — tapping it should fire toggleSignUp().
      final fake = await pumpAuthScreen(
        tester,
        formState: const AuthFormState(isSignUp: false),
      );

      expect(fake.toggleSignUpCalls, 0);
      await tester.tap(find.textContaining('New here'));
      await tester.pumpAndSettle();
      expect(fake.toggleSignUpCalls, 1);
    });

    testWidgets('isLoading: submit FilledButton is disabled and shows spinner',
        (tester) async {
      await pumpAuthScreen(
        tester,
        formState: const AuthFormState(isLoading: true),
        // The spinner animates indefinitely; pumpAndSettle would hang.
        settle: false,
      );

      // The EmailAuthCard's submit button is disabled.
      final submit =
          tester.widget<FilledButton>(find.byType(FilledButton).first);
      expect(submit.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error state renders the error message inside the card',
        (tester) async {
      await pumpAuthScreen(
        tester,
        formState: const AuthFormState(error: 'Invalid email or password'),
      );

      expect(find.text('Invalid email or password'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsWidgets);
    });

    testWidgets(
        'email user: shows EmailUserStatusCard with email and switch-to-anon CTA',
        (tester) async {
      await pumpAuthScreen(
        tester,
        syncConfig: const SyncConfig(userEmail: 'me@example.com'),
      );

      expect(find.byType(EmailUserStatusCard), findsOneWidget);
      expect(find.textContaining('me@example.com'), findsOneWidget);
      // Email-mode hides the email auth form and the anonymous AuthInfoCard.
      expect(find.byType(EmailAuthCard), findsNothing);
      expect(find.byType(AuthInfoCard), findsNothing);
      expect(find.text('Switch to anonymous'), findsOneWidget);
    });

    testWidgets('email user with error renders the screen-level error banner',
        (tester) async {
      await pumpAuthScreen(
        tester,
        formState: const AuthFormState(error: 'Switch failed'),
        syncConfig: const SyncConfig(userEmail: 'me@example.com'),
      );

      expect(find.text('Switch failed'), findsOneWidget);
    });

    testWidgets(
        'initState calls reset() once on the form controller (post-frame)',
        (tester) async {
      final fake = await pumpAuthScreen(tester);
      // pumpApp ends with pumpAndSettle so the post-frame callback has run.
      expect(fake.resetCalls, 1);
    });

    testWidgets(
        'submitting email when sign-in throws a retryable fetch error '
        'renders the localized "no network" string and never leaks the '
        'project URL or exception type name (#1186)',
        (tester) async {
      // Drive _submitEmail by tapping the submit button — the throwing
      // SyncState fakes the worst-case scenario from the bug: the user
      // enters credentials, the server is unreachable, and the catch
      // block previously rendered something like
      // `AuthRetryableFetchException: ...
      // uri=https://klelxnkzrxlpzuddhpfg.supabase.co/...`.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authFormControllerProvider
                .overrideWith(() => _FakeAuthFormController(
                      const AuthFormState(isSignUp: false),
                    )),
            syncStateProvider.overrideWith(
              () => _ThrowingSyncState(
                AuthRetryableFetchException(
                  message:
                      'AuthRetryableFetchException: ClientException with '
                      'SocketException: Failed host lookup '
                      'klelxnkzrxlpzuddhpfg.supabase.co',
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: AuthScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Type credentials so the early-return validators don't short-circuit.
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'someone@example.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Password'), 'Hunter22!');
      await tester.pump();

      // Tap the submit button (FilledButton inside the EmailAuthCard).
      await tester.tap(find.byType(FilledButton).first);
      // The throwing future resolves on the next microtask; pumpAndSettle
      // would loop on the spinner while it's flipped on.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // The friendly localized string is what the user sees.
      expect(find.text('No network connection. Try again later.'),
          findsOneWidget);

      // None of these forbidden strings appear anywhere on the rendered
      // tree. This is the core regression test for #1186.
      final allText = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data ?? '')
          .join(' \n ');
      expect(allText, isNot(contains('AuthRetryableFetchException')),
          reason: 'exception type name must not leak into the UI');
      expect(allText, isNot(contains('klelxnkzrxlpzuddhpfg')),
          reason: 'project URL must not leak into the UI');
      expect(allText, isNot(contains('supabase.co')),
          reason: 'project host must not leak into the UI');
    });
  });
}
