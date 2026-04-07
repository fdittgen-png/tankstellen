import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/sync/supabase_client.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../../core/widgets/password_strength_indicator.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';

/// Authentication screen for switching between anonymous and email accounts.
///
/// Features:
/// - Switch anonymous → email (sign up or sign in)
/// - Switch email → anonymous (with confirmation)
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
    setState(() { _isLoading = true; _error = null; });
    try {
      final userId = await TankSyncClient.signInAnonymously();
      if (userId != null) {
        final settings = ref.read(settingsStorageProvider);
        await settings.putSetting('sync_user_id', userId);
        ref.invalidate(syncStateProvider);
        if (mounted) {
          SnackBarHelper.showSuccess(context, AppLocalizations.of(context)?.connectedAsGuest ?? 'Connected as guest');
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

    // Validation
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
      setState(() => _error = l10n?.passwordTooWeak ?? 'Password does not meet all requirements');
      return;
    }
    if (_isSignUp && password != _confirmController.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() { _isLoading = true; _error = null; });
    try {
      // Use the SyncProvider to handle email auth properly
      await ref.read(syncStateProvider.notifier).signInWithEmail(
        email, password,
        isSignUp: _isSignUp,
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarHelper.showSuccess(context, _isSignUp ? (l10n?.accountCreated ?? 'Account created!') : (l10n?.signedIn ?? 'Signed in!'));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        // Show user-friendly error messages
        String errorMsg = e.toString();
        if (errorMsg.contains('invalid_credentials')) {
          errorMsg = 'Invalid email or password. Check your credentials.';
        } else if (errorMsg.contains('user_already_exists') || errorMsg.contains('already registered')) {
          errorMsg = 'This email is already registered. Try signing in instead.';
        } else if (errorMsg.contains('email_not_confirmed')) {
          errorMsg = 'Please check your email and confirm your account first.';
        }
        setState(() => _error = errorMsg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _switchToAnonymous() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(syncStateProvider.notifier).switchToAnonymous();
      if (mounted) {
        SnackBarHelper.show(context, AppLocalizations.of(context)?.switchedToAnonymous ?? 'Switched to anonymous session');
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
      appBar: AppBar(
        title: Text(l10n?.account ?? 'Account'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
        children: [
          // Current auth status card
          if (isEmailUser) ...[
            // Connected with email — show status + switch to anonymous
            Card(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_user, size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Signed in as ${syncConfig.userEmail}',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your data syncs across all devices with this email.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Switch to anonymous'),
                subtitle: const Text('Continue without email, new anonymous session'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _isLoading ? null : _switchToAnonymous,
              ),
            ),
            const SizedBox(height: 16),
          ] else if (!TankSyncClient.isConnected) ...[
            // Not connected at all — show guest option
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(l10n?.continueAsGuest ?? 'Continue as guest'),
                subtitle: const Text('Anonymous, no email needed.'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _isLoading ? null : _continueAsGuest,
              ),
            ),
            const SizedBox(height: 16),
            const Row(children: [
              Expanded(child: Divider()),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('or')),
              Expanded(child: Divider()),
            ]),
            const SizedBox(height: 16),
          ] else ...[
            // Connected as anonymous — show upgrade prompt
            Card(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You\'re connected as guest '
                        '(${syncConfig.userId?.substring(0, 8) ?? ""}...). '
                        'Add an email to sign in from other devices.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Email auth card — shown when not already signed in with email
          if (!isEmailUser) Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isSignUp
                            ? (l10n?.createAccount ?? 'Create account')
                            : (l10n?.signIn ?? 'Sign in'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sync data automatically across all your devices.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),

                  // Email field
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email, size: 18),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 12),

                  // Password field with visibility toggle
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock, size: 18),
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    obscureText: !_showPassword,
                    enabled: !_isLoading,
                    onChanged: (_) => setState(() {}),
                  ),

                  // Password strength indicator (sign-up only)
                  if (_isSignUp)
                    PasswordStrengthIndicator(password: _passwordController.text),

                  // Confirm password field (sign-up only)
                  if (_isSignUp) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmController,
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
                        isDense: true,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirm ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _showConfirm = !_showConfirm),
                        ),
                      ),
                      obscureText: !_showConfirm,
                      enabled: !_isLoading,
                    ),
                  ],

                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _submitEmail,
                    icon: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(_isSignUp ? Icons.person_add : Icons.login),
                    label: Text(_isSignUp
                        ? (l10n?.createAccount ?? 'Create account')
                        : (l10n?.signIn ?? 'Sign in')),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => setState(() {
                        _isSignUp = !_isSignUp;
                        _confirmController.clear();
                        _error = null;
                      }),
                      child: Text(_isSignUp
                          ? 'Already have an account? Sign in'
                          : 'New here? Create account'),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Error display (for switch-to-anonymous or guest errors)
          if (isEmailUser && _error != null) ...[
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.error.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12))),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Info card
          if (!isEmailUser)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18),
                        const SizedBox(width: 8),
                        Text('Why create an account?', style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Sync favorites, alerts, and saved routes across devices\n'
                      '• Prepare a route on your phone, use it in your car\n'
                      '• No data is shared with third parties\n'
                      '• You can delete your account at any time',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
