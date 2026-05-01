import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/page_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/loyalty_card.dart';
import '../providers/loyalty_provider.dart';
import 'widgets/loyalty_add_card_sheet.dart';
import 'widgets/loyalty_card_tile.dart';
import 'widgets/loyalty_empty_state.dart';

/// Settings sub-screen that lists every registered fuel-club card and
/// lets the user add, toggle, and delete one (#1120 pilot).
///
/// Visual contract: a `PageScaffold` with a primary-tinted banner that
/// names the feature, a `ListView` of cards, swipe-to-delete with a
/// confirmation dialog, an inline `Switch` to disable a card without
/// deleting it, and a `FloatingActionButton` that opens the add-card
/// bottom sheet. When the list is empty an explanatory empty state
/// stands in for the cards so first-time users know what to do.
///
/// The empty state, list tile, and add-card bottom sheet were
/// extracted to `widgets/` (#563) to keep this file under the 300-LOC
/// guideline. Behaviour is unchanged.
class LoyaltySettingsScreen extends ConsumerWidget {
  const LoyaltySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cards = ref.watch(loyaltyCardsProvider);

    return PageScaffold(
      title: l?.loyaltySettingsTitle ?? 'Fuel club cards',
      subtitle: l?.loyaltySettingsSubtitle ??
          'Apply your loyalty discount to displayed prices',
      bannerIcon: Icons.card_membership,
      body: cards.isEmpty
          ? const LoyaltyEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final card = cards[index];
                return LoyaltyCardTile(
                  key: Key('loyalty-card-${card.id}'),
                  card: card,
                  onToggle: (enabled) => ref
                      .read(loyaltyCardsProvider.notifier)
                      .setEnabled(card.id, enabled: enabled),
                  onDeleteRequested: () => _confirmAndDelete(context, ref, card),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l?.loyaltyAddCard ?? 'Add card'),
        tooltip: l?.loyaltyAddCard ?? 'Add card',
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<LoyaltyCard>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => const LoyaltyAddCardSheet(),
    );
    if (result != null) {
      await ref.read(loyaltyCardsProvider.notifier).upsert(result);
    }
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    LoyaltyCard card,
  ) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l?.loyaltyDeleteConfirmTitle ?? 'Delete card?'),
        content: Text(
          l?.loyaltyDeleteConfirmBody ??
              'This card will stop applying its discount.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(loyaltyCardsProvider.notifier).remove(card.id);
    }
  }
}
