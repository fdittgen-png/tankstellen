import 'package:flutter/material.dart';

import '../../../../core/widgets/password_strength_indicator.dart';
import '../../../../l10n/app_localizations.dart';

/// Card containing the email/password sign-in or sign-up form.
///
/// Handles form layout, password visibility toggles, confirm password field,
/// strength indicator, sign-in/sign-up toggle, and inline error display.
class EmailAuthCard extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool isSignUp;
  final bool isLoading;
  final bool showPassword;
  final bool showConfirm;
  final String? error;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onPasswordChanged;

  const EmailAuthCard({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.isSignUp,
    required this.isLoading,
    required this.showPassword,
    required this.showConfirm,
    this.error,
    required this.onSubmit,
    required this.onToggleMode,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onPasswordChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
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
                  isSignUp
                      ? (l10n?.createAccount ?? 'Create account')
                      : (l10n?.signIn ?? 'Sign in'),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Sync data automatically across all your devices.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            // Email field
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email, size: 18),
                isDense: true,
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !isLoading,
            ),
            const SizedBox(height: 12),

            // Password field with visibility toggle
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock, size: 18),
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                  ),
                  onPressed: onTogglePassword,
                ),
              ),
              obscureText: !showPassword,
              enabled: !isLoading,
              onChanged: (_) => onPasswordChanged(),
            ),

            // Password strength indicator (sign-up only)
            if (isSignUp)
              PasswordStrengthIndicator(password: passwordController.text),

            // Confirm password field (sign-up only)
            if (isSignUp) ...[
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline, size: 18),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      showConfirm ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                    onPressed: onToggleConfirm,
                  ),
                ),
                obscureText: !showConfirm,
                enabled: !isLoading,
              ),
            ],

            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isLoading ? null : onSubmit,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(isSignUp ? Icons.person_add : Icons.login),
              label: Text(isSignUp
                  ? (l10n?.createAccount ?? 'Create account')
                  : (l10n?.signIn ?? 'Sign in')),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44)),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: isLoading ? null : onToggleMode,
                child: Text(isSignUp
                    ? 'Already have an account? Sign in'
                    : 'New here? Create account'),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              _ErrorBanner(error: error!, theme: theme),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline error banner used within auth cards.
class _ErrorBanner extends StatelessWidget {
  final String error;
  final ThemeData theme;

  const _ErrorBanner({required this.error, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(error,
                style:
                    TextStyle(color: theme.colorScheme.error, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
