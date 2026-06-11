// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/widgets/password_strength_indicator.dart';
import '../../../../l10n/app_localizations.dart';
import 'wizard_option_card.dart';

/// Authentication step of the sync wizard: anonymous vs email.
class WizardAuthStep extends StatelessWidget {
  final bool useEmail;
  final bool isSignUp;
  final bool testing;
  final bool connecting;
  final String? testResult;
  final bool testSuccess;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final ValueChanged<bool> onUseEmailChanged;
  final VoidCallback onToggleSignUp;
  final VoidCallback onTestConnection;
  final VoidCallback onConnect;
  final VoidCallback? onPasswordChanged;

  const WizardAuthStep({
    super.key,
    required this.useEmail,
    required this.isSignUp,
    required this.testing,
    required this.connecting,
    required this.testResult,
    required this.testSuccess,
    required this.emailController,
    required this.passwordController,
    required this.onUseEmailChanged,
    required this.onToggleSignUp,
    required this.onTestConnection,
    required this.onConnect,
    this.onPasswordChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.syncChooseAccountType, style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),

        // Anonymous
        WizardOptionCard(
          icon: Icons.person_outline,
          title: l10n.syncAccountTypeAnonymous,
          subtitle: l10n.syncAccountTypeAnonymousDesc,
          selected: !useEmail,
          onTap: () => onUseEmailChanged(false),
        ),
        const SizedBox(height: 12),

        // Email
        WizardOptionCard(
          icon: Icons.email_outlined,
          title: l10n.syncAccountTypeEmail,
          subtitle: l10n.syncAccountTypeEmailDesc,
          selected: useEmail,
          onTap: () => onUseEmailChanged(true),
        ),

        if (useEmail) ...[
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: l10n.authEmailLabel,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: l10n.authPasswordLabel,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock),
            ),
            obscureText: true,
            onChanged: (_) => onPasswordChanged?.call(),
          ),
          if (isSignUp)
            PasswordStrengthIndicator(password: passwordController.text),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onToggleSignUp,
              child: Text(
                isSignUp
                    ? (l10n.syncHaveAccountSignIn)
                    : (l10n.syncCreateNewAccount),
              ),
            ),
          ),
        ],

        // Test + error display
        if (testResult != null) ...[
          const SizedBox(height: 12),
          Card(
            color: testSuccess
                ? DarkModeColors.success(context).withValues(alpha: 0.1)
                : DarkModeColors.error(context).withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    testSuccess ? Icons.check_circle : Icons.error,
                    color: testSuccess
                        ? DarkModeColors.success(context)
                        : DarkModeColors.error(context),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(testResult!, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: !testing ? onTestConnection : null,
                child: Text(
                  testing
                      ? (l10n.syncTestingConnection)
                      : (l10n.syncTestConnection),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: !connecting ? onConnect : null,
                child: Text(
                  connecting
                      ? (l10n.syncConnectingButton)
                      : (l10n.syncConnectButton),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
