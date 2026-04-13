import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'wizard_option_card.dart';

/// The initial mode selection step of the sync wizard.
///
/// Lets the user choose between creating a new database or joining an existing one.
class WizardChooseMode extends StatelessWidget {
  final VoidCallback onCreateNew;
  final VoidCallback onJoinExisting;

  const WizardChooseMode({
    super.key,
    required this.onCreateNew,
    required this.onJoinExisting,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info card
        Card(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n?.syncOptionalTitle ?? 'TankSync is optional',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(
                  l10n?.syncOptionalDescription ??
                      'Your app works fully without cloud sync. TankSync lets you sync '
                          'favorites, alerts, and ratings across devices using Supabase (free tier available).',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          l10n?.syncHowToConnectQuestion ?? 'How would you like to connect?',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),

        // Option 1: Create new
        WizardOptionCard(
          icon: Icons.add_circle_outline,
          title: l10n?.syncCreateOwnTitle ?? 'Create my own database',
          subtitle: l10n?.syncCreateOwnSubtitle ??
              'Free Supabase project — we\'ll guide you step by step',
          onTap: onCreateNew,
        ),
        const SizedBox(height: 12),

        // Option 2: Join existing
        WizardOptionCard(
          icon: Icons.qr_code_scanner,
          title: l10n?.syncJoinExistingTitle ?? 'Join an existing database',
          subtitle: l10n?.syncJoinExistingSubtitle ??
              'Scan QR code from the database owner or paste credentials',
          onTap: onJoinExisting,
        ),
      ],
    );
  }
}
