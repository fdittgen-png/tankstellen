import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/sync/supabase_client.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
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
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSignUp = true;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
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
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter email and password');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }
    if (_isSignUp && !PasswordValidator.isValid(password)) {
      final l10n = AppLocalizations.of(context);
      setState(() => _error =
          l10n?.passwordTooWeak ?? 'Password does not meet all requirements');
      return;
    }
    if (_isSignUp && password != _confirmController.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(syncStateProvider.notifier).signInWithEmail(
            email, password,
            isSignUp: _isSignUp,
          );

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarHelper.showSuccess(
            context,
            _isSignUp
                ? (l10n?.accountCreated ?? 'Account created!')
                : (l10n?.signedIn ?? 'Signed in!'));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('invalid_credentials')) {
          errorMsg = 'Invalid email or password. Check your credentials.';
        } else if (errorMsg.contains('user_already_exists') ||
            errorMsg.contains('already registered')) {
          errorMsg =
              'This email is already registered. Try signing in instead.';
        } else if (errorMsg.contains('email_not_confirmed')) {
          errorMsg =
              'Please check your email and confirm your account first.';
        }
        setState(() => _error = errorMsg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _switchToAnonymous() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(syncStateProvider.notifier).switchToAnonymous();
      if (mounted) {
        SnackBarHelper.show(
            context,
            AppLocalizations.of(context)?.switchedToAnonymous ??
                'Switched to anonymous session');
        context.pop();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final syncConfig = ref.watch(syncStateProvider);
    final isEmailUser = syncConfig.hasEmail;

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.account ?? 'Account')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
        children: [
          if (isEmailUser)
            EmailUserStatusCard(
              userEmail: syncConfig.userEmail,
              isLoading: _isLoading,
              onSwitchToAnonymous: _switchToAnonymous,
            )
          else if (!TankSyncClient.isConnected)
            GuestOptionCard(
              isLoading: _isLoading,
              onContinueAsGuest: _continueAsGuest,
            )
          else
            AnonymousStatusCard(userId: syncConfig.userId),

          if (!isEmailUser)
            EmailAuthCard(
              emailController: _emailController,
              passwordController: _passwordController,
              confirmController: _confirmController,
              isSignUp: _isSignUp,
              isLoading: _isLoading,
              showPassword: _showPassword,
              showConfirm: _showConfirm,
              error: _error,
              onSubmit: _submitEmail,
              onToggleMode: () => setState(() {
                _isSignUp = !_isSignUp;
                _confirmController.clear();
                _error = null;
              }),
              onTogglePassword: () =>
                  setState(() => _showPassword = !_showPassword),
              onToggleConfirm: () =>
                  setState(() => _showConfirm = !_showConfirm),
              onPasswordChanged: () => setState(() {}),
            ),

          if (isEmailUser && _error != null) ...[
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
                        child: Text(_error!,
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
