// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'auth_form_error_box.dart';

/// "Join an existing account" step (#3080).
///
/// Shown when a scanned share-QR carries an `email` (the first device has an
/// email account). The second device *adopts* that identity: it signs in with
/// the same email + password so both devices share one account's data —
/// crucially via the existing email sign-in (`isSignUp:false`), which never
/// mints a new UUID.
///
/// Presentation-only: the password lives in a [TextEditingController] owned by
/// the screen; loading/error state and the actions are injected.
class SyncAdoptionStep extends StatelessWidget {
  /// The email address read from the scanned QR — the account to join.
  final String email;
  final TextEditingController passwordController;
  final bool isLoading;
  final String? error;
  final bool showPassword;
  final VoidCallback onTogglePassword;

  /// Signs the second device into [email]'s account (the adopt action).
  final VoidCallback onJoin;

  /// Abandons adoption and returns to the normal account-setup flow.
  final VoidCallback onUseDifferentAccount;

  const SyncAdoptionStep({
    super.key,
    required this.email,
    required this.passwordController,
    required this.isLoading,
    required this.showPassword,
    required this.onTogglePassword,
    required this.onJoin,
    required this.onUseDifferentAccount,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.group_add_outlined, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n?.syncAdoptTitle(email) ?? "Join $email's account",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n?.syncAdoptSubtitle ??
              "Sign in with this account's password to share its data "
                  'across both devices.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          decoration: InputDecoration(
            labelText: l10n?.syncAdoptPasswordLabel ?? 'Account password',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock, size: 18),
            isDense: true,
            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility_off : Icons.visibility,
                size: 18,
              ),
              tooltip: showPassword
                  ? (l10n?.tooltipHidePassword ?? 'Hide password')
                  : (l10n?.tooltipShowPassword ?? 'Show password'),
              onPressed: onTogglePassword,
            ),
          ),
          obscureText: !showPassword,
          enabled: !isLoading,
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          AuthFormErrorBox(message: error!),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: isLoading ? null : onJoin,
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.login),
          label: Text(l10n?.syncAdoptJoinButton ?? 'Join account'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: isLoading ? null : onUseDifferentAccount,
            child: Text(
              l10n?.syncAdoptUseDifferentAccount ??
                  'Use a different account instead',
            ),
          ),
        ),
      ],
    );
  }
}
