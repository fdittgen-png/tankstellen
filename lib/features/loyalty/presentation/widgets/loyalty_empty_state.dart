import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Explanatory placeholder shown on the loyalty settings screen when
/// the user has not registered any fuel-club card yet.
///
/// Renders the brand-membership icon and a short explanation of what
/// a card buys the user. The actual "Add card" action lives on the
/// parent screen's bottom-right `FloatingActionButton` — duplicating
/// it inside the empty state was redundant (#1329). Extracted from
/// `loyalty_settings_screen.dart` (#563) to keep the screen file
/// under the 300-LOC guideline.
class LoyaltyEmptyState extends StatelessWidget {
  const LoyaltyEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_membership,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              l?.loyaltyEmptyTitle ?? 'No fuel club cards yet',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l?.loyaltyEmptyBody ??
                  'Add a card to apply your per-litre discount to '
                      'matching stations automatically.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
