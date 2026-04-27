import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/sync/supabase_client.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/auth_error_mapper.dart';
import '../../providers/auth_form_provider.dart';
import '../widgets/auth_info_card.dart';
import '../widgets/auth_status_cards.dart';
import '../widgets/email_auth_card.dart';

/// Authentication screen for switching between anonymous and email accounts.
///
/// Features:
/// - Switch anonymous -> email (sign up or sign in)
/// - Switch email -> anonymous (with confirmation)
/// - Password visibility toggle
/// - Confirm password on sign-up
/// - Proper error messages
/// - Works for all sync modes (community, private, joinExisting)
///
/// Form state (toggles, loading, error) lives in [authFormControllerProvider];
/// only [TextEditingController]s remain local because they must follow
/// Flutter's widget lifecycle.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reset shared form state for a fresh screen instance.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authFormControllerProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  AuthFormController get _formNotifier =>
      ref.read(authFormControllerProvider.notifier);

  Future<void> _continueAsGuest() async {
    _formNotifier.setLoading(true);
    try {
      final userId = await TankSyncClient.signInAnonymously();
      if (userId != null) {
        final settings = ref.read(settingsStorageProvider);
        await settings.putSetting('sync_user_id', userId);
        ref.invalidate(syncStateProvider);
        if (mounted) {
          SnackBarHelper.showSuccess(
              context,
              AppLocalizations.of(context)?.connectedAsGuest ??
                  'Connected as guest');
          context.pop();
        }
      }
    } catch (e, st) {
      debugPrint('AuthScreen._continueAsGuest failed: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        if (l10n != null) {
          _formNotifier
              .setError(mapAuthErrorToLocalized(e, l10n, stackTrace: st));
        } else {
          _formNotifier.setError('Something went wrong. Please try again.');
        }
      }
    } finally {
      _formNotifier.setLoading(false);
    }
  }

  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final isSignUp = ref.read(authFormControllerProvider).isSignUp;

    if (email.isEmpty || password.isEmpty) {
      _formNotifier.setError('Please enter email and password');
      return;
    }
    if (!email.contains('@')) {
      _formNotifier.setError('Please enter a valid email address');
      return;
    }
    if (isSignUp && !PasswordValidator.isValid(password)) {
      final l10n = AppLocalizations.of(context);
      _formNotifier.setError(
          l10n?.passwordTooWeak ?? 'Password does not meet all requirements');
      return;
    }
    if (isSignUp && password != _confirmController.text) {
      _formNotifier.setError('Passwords do not match');
      return;
    }

    _formNotifier.setLoading(true);
    try {
      await ref.read(syncStateProvider.notifier).signInWithEmail(
            email, password,
            isSignUp: isSignUp,
          );

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarHelper.showSuccess(
            context,
            isSignUp
                ? (l10n?.accountCreated ?? 'Account created!')
                : (l10n?.signedIn ?? 'Signed in!'));
        context.pop();
      }
    } catch (e, st) {
      debugPrint('AuthScreen._submitEmail failed: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        if (l10n != null) {
          _formNotifier
              .setError(mapAuthErrorToLocalized(e, l10n, stackTrace: st));
        } else {
          _formNotifier.setError('Something went wrong. Please try again.');
        }
      }
    } finally {
      _formNotifier.setLoading(false);
    }
  }

  Future<void> _switchToAnonymous() async {
    _formNotifier.setLoading(true);
    try {
      await ref.read(syncStateProvider.notifier).switchToAnonymous();
      if (mounted) {
        SnackBarHelper.show(
            context,
            AppLocalizations.of(context)?.switchedToAnonymous ??
                'Switched to anonymous session');
        context.pop();
      }
    } catch (e, st) {
      debugPrint('AuthScreen._switchToAnonymous failed: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        if (l10n != null) {
          _formNotifier
              .setError(mapAuthErrorToLocalized(e, l10n, stackTrace: st));
        } else {
          _formNotifier.setError('Something went wrong. Please try again.');
        }
      }
    } finally {
      _formNotifier.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final syncConfig = ref.watch(syncStateProvider);
    final form = ref.watch(authFormControllerProvider);
    final isEmailUser = syncConfig.hasEmail;

    return PageScaffold(
      title: l10n?.account ?? 'Account',
      bodyPadding: EdgeInsets.zero,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
        children: [
          if (isEmailUser)
            EmailUserStatusCard(
              userEmail: syncConfig.userEmail,
              isLoading: form.isLoading,
              onSwitchToAnonymous: _switchToAnonymous,
            )
          else if (!TankSyncClient.isConnected)
            GuestOptionCard(
              isLoading: form.isLoading,
              onContinueAsGuest: _continueAsGuest,
            )
          else
            AnonymousStatusCard(userId: syncConfig.userId),

          if (!isEmailUser)
            EmailAuthCard(
              emailController: _emailController,
              passwordController: _passwordController,
              confirmController: _confirmController,
              isSignUp: form.isSignUp,
              isLoading: form.isLoading,
              showPassword: form.showPassword,
              showConfirm: form.showConfirm,
              error: form.error,
              onSubmit: _submitEmail,
              onToggleMode: () {
                _confirmController.clear();
                _formNotifier.toggleSignUp();
              },
              onTogglePassword: _formNotifier.togglePassword,
              onToggleConfirm: _formNotifier.toggleConfirm,
              onPasswordChanged: _formNotifier.touch,
            ),

          if (isEmailUser && form.error != null) ...[
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.error.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        size: 16, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(form.error!,
                            style: TextStyle(
                                color: theme.colorScheme.error, fontSize: 12))),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          if (!isEmailUser) const AuthInfoCard(),
        ],
      ),
    );
  }
}
