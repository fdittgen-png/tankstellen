import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/password_validator.dart';
import '../../../../core/widgets/password_strength_indicator.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/auth_form_widget_provider.dart';

/// Reusable authentication form: anonymous or email with password.
///
/// Designed to be app-agnostic. Any app needing Supabase auth can use this.
/// Provides email sign-up (with confirm password) and sign-in flows.
///
/// Toggle state (useEmail/isSignUp/showPassword/showConfirm) lives in
/// [authFormWidgetControllerProvider]. Text controllers remain local
/// since they must be disposed with the widget.
class AuthFormWidget extends ConsumerStatefulWidget {
  /// Called when authentication succeeds.
  /// [isEmail] is false for anonymous, true for email auth.
  final Future<void> Function({
    required bool isEmail,
    String? email,
    String? password,
    required bool isSignUp,
  }) onSubmit;
  final bool isLoading;
  final String? error;

  const AuthFormWidget({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    this.error,
  });

  @override
  ConsumerState<AuthFormWidget> createState() => _AuthFormWidgetState();
}

class _AuthFormWidgetState extends ConsumerState<AuthFormWidget> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validate(AuthFormWidgetState form) {
    if (!form.useEmail) return null; // Anonymous needs no validation
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty) return 'Please enter your email';
    if (!email.contains('@')) return 'Invalid email address';
    if (form.isSignUp && !PasswordValidator.isValid(password)) {
      return l10n?.passwordTooWeak ??
          'Password does not meet all requirements';
    }
    if (form.isSignUp && password != _confirmController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _submit(AuthFormWidgetState form) {
    final error = _validate(form);
    if (error != null) {
      SnackBarHelper.showError(context, error);
      return;
    }
    widget.onSubmit(
      isEmail: form.useEmail,
      email: form.useEmail ? _emailController.text.trim() : null,
      password: form.useEmail ? _passwordController.text : null,
      isSignUp: form.isSignUp,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final form = ref.watch(authFormWidgetControllerProvider);
    final notifier = ref.read(authFormWidgetControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Choose your account type',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Anonymous / Email toggle
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Anonymous'),
              icon: Icon(Icons.person_outline, size: 18),
            ),
            ButtonSegment(
              value: true,
              label: Text('Email'),
              icon: Icon(Icons.email_outlined, size: 18),
            ),
          ],
          selected: {form.useEmail},
          onSelectionChanged: (s) => notifier.setUseEmail(s.first),
        ),
        const SizedBox(height: 8),

        // Description text
        Text(
          form.useEmail
              ? 'Sign in from any device. Recover your data if your phone is lost.'
              : 'Instant access, no email needed. Data tied to this device.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        // Email fields
        if (form.useEmail) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email, size: 18),
              isDense: true,
            ),
            keyboardType: TextInputType.emailAddress,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock, size: 18),
              isDense: true,
              suffixIcon: IconButton(
                icon: Icon(
                  form.showPassword ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                ),
                onPressed: notifier.togglePassword,
              ),
            ),
            obscureText: !form.showPassword,
            enabled: !widget.isLoading,
          ),
          if (form.isSignUp)
            ListenableBuilder(
              listenable: _passwordController,
              builder: (context, _) => PasswordStrengthIndicator(
                password: _passwordController.text,
              ),
            ),
          if (form.isSignUp) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _confirmController,
              decoration: InputDecoration(
                labelText: 'Confirm password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline, size: 18),
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(
                    form.showConfirm
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 18,
                  ),
                  onPressed: notifier.toggleConfirm,
                ),
              ),
              obscureText: !form.showConfirm,
              enabled: !widget.isLoading,
            ),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.isLoading
                  ? null
                  : () {
                      notifier.toggleSignUp();
                      _confirmController.clear();
                    },
              child: Text(
                form.isSignUp
                    ? 'Already have an account? Sign in'
                    : 'Create new account',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],

        // Error display
        if (widget.error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.error!,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: widget.isLoading ? null : () => _submit(form),
          icon: widget.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  form.useEmail
                      ? (form.isSignUp ? Icons.person_add : Icons.login)
                      : Icons.flash_on,
                ),
          label: Text(
            widget.isLoading
                ? 'Connecting...'
                : form.useEmail
                    ? (form.isSignUp
                        ? 'Create account & connect'
                        : 'Sign in & connect')
                    : 'Connect anonymously',
          ),
        ),
      ],
    );
  }
}
