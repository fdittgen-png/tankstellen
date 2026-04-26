import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Explanatory placeholder shown on the loyalty settings screen when
/// the user has not registered any fuel-club card yet.
///
/// Renders the brand-membership icon, a short explanation of what a
/// card buys the user, and a primary "Add card" CTA that delegates to
/// [onAdd] (the parent screen typically opens the add-card bottom
/// sheet). Extracted from `loyalty_settings_screen.dart` (#563) to keep
/// the screen file under the 300-LOC guideline; behaviour and visual
/// contract are unchanged.
class LoyaltyEmptyState extends StatelessWidget {
  /// Invoked when the user taps the empty-state CTA. The parent screen
  /// is expected to open the add-card sheet (or any equivalent flow).
  final VoidCallback onAdd;

  const LoyaltyEmptyState({super.key, required this.onAdd});

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
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l?.loyaltyAddCard ?? 'Add card'),
            ),
          ],
        ),
      ),
    );
  }
}
