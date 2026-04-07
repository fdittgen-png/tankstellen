import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Status card shown when the user is signed in with an email account.
///
/// Displays the signed-in email and a button to switch to anonymous.
class EmailUserStatusCard extends StatelessWidget {
  final String? userEmail;
  final bool isLoading;
  final VoidCallback onSwitchToAnonymous;

  const EmailUserStatusCard({
    super.key,
    required this.userEmail,
    required this.isLoading,
    required this.onSwitchToAnonymous,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Card(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Signed in as $userEmail',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
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
            subtitle:
                const Text('Continue without email, new anonymous session'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: isLoading ? null : onSwitchToAnonymous,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Card shown when the user is not connected at all, offering guest sign-in.
class GuestOptionCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onContinueAsGuest;

  const GuestOptionCard({
    super.key,
    required this.isLoading,
    required this.onContinueAsGuest,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n?.continueAsGuest ?? 'Continue as guest'),
            subtitle: const Text('Anonymous, no email needed.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: isLoading ? null : onContinueAsGuest,
          ),
        ),
        const SizedBox(height: 16),
        const Row(children: [
          Expanded(child: Divider()),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('or')),
          Expanded(child: Divider()),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Card shown when the user is connected anonymously, prompting email upgrade.
class AnonymousStatusCard extends StatelessWidget {
  final String? userId;

  const AnonymousStatusCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
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
                    '(${userId?.substring(0, 8) ?? ""}...). '
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
    );
  }
}
