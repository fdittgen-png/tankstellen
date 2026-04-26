import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/loyalty_card.dart';

/// Single row in the loyalty settings list: brand badge + label +
/// per-litre discount, with a `Switch` for enable/disable and a
/// trash-can `IconButton` (the screen also wraps the tile in a
/// [Dismissible] with end-to-start swipe-to-delete that calls back
/// into [onDeleteRequested]).
///
/// Extracted from `loyalty_settings_screen.dart` (#563). Pure
/// presentation: the parent owns the confirm dialog so a dismissed
/// card visually snaps back if the user cancels.
class LoyaltyCardTile extends StatelessWidget {
  final LoyaltyCard card;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDeleteRequested;

  const LoyaltyCardTile({
    super.key,
    required this.card,
    required this.onToggle,
    required this.onDeleteRequested,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final discountText = '${card.discountPerLiter.toStringAsFixed(2)} /L';
    return Dismissible(
      key: ValueKey('loyalty-dismiss-${card.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (_) async {
        // Confirmation dialog lives on the screen so a dismissed
        // card is restored to the list visually if the user cancels.
        onDeleteRequested();
        return false;
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(
            Icons.card_membership,
            color: card.enabled
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(
            card.label.isEmpty ? card.brand.canonicalBrand : card.label,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${card.brand.canonicalBrand} · −$discountText',
            style: theme.textTheme.bodySmall,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: card.enabled,
                onChanged: onToggle,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l?.delete ?? 'Delete',
                onPressed: onDeleteRequested,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
