import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/page_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/loyalty_card.dart';
import '../providers/loyalty_provider.dart';

/// Settings sub-screen that lists every registered fuel-club card and
/// lets the user add, toggle, and delete one (#1120 pilot).
///
/// Visual contract: a `PageScaffold` with a primary-tinted banner that
/// names the feature, a `ListView` of cards, swipe-to-delete with a
/// confirmation dialog, an inline `Switch` to disable a card without
/// deleting it, and a `FloatingActionButton` that opens the add-card
/// bottom sheet. When the list is empty an explanatory empty state
/// stands in for the cards so first-time users know what to do.
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
          ? _LoyaltyEmptyState(onAdd: () => _openAddSheet(context, ref))
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final card = cards[index];
                return _LoyaltyCardTile(
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
      builder: (sheetContext) => const _AddLoyaltyCardSheet(),
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

class _LoyaltyEmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _LoyaltyEmptyState({required this.onAdd});

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

class _LoyaltyCardTile extends StatelessWidget {
  final LoyaltyCard card;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDeleteRequested;

  const _LoyaltyCardTile({
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

class _AddLoyaltyCardSheet extends StatefulWidget {
  const _AddLoyaltyCardSheet();

  @override
  State<_AddLoyaltyCardSheet> createState() => _AddLoyaltyCardSheetState();
}

class _AddLoyaltyCardSheetState extends State<_AddLoyaltyCardSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _discountController = TextEditingController();
  LoyaltyBrand _brand = LoyaltyBrand.totalEnergies;

  @override
  void dispose() {
    _labelController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + viewInsets),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l?.loyaltyAddCardSheetTitle ?? 'Add fuel club card',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LoyaltyBrand>(
              initialValue: _brand,
              decoration: InputDecoration(
                labelText: l?.loyaltyBrandLabel ?? 'Brand',
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final brand in LoyaltyBrand.values)
                  DropdownMenuItem(
                    value: brand,
                    child: Text(brand.canonicalBrand),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _brand = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: l?.loyaltyCardLabelLabel ?? 'Label (optional)',
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _discountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                // Accept either '.' or ',' so a French keyboard works.
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l?.loyaltyDiscountLabel ?? 'Discount (per litre)',
                hintText: '0.05',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                final parsed = _parseDecimal(value);
                if (parsed == null || parsed <= 0) {
                  return l?.loyaltyDiscountInvalid ??
                      'Enter a positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l?.cancel ?? 'Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _onSave,
                    child: Text(l?.save ?? 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onSave() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final discount = _parseDecimal(_discountController.text);
    if (discount == null) return;
    final card = LoyaltyCard(
      id: 'loyalty-${DateTime.now().microsecondsSinceEpoch}',
      brand: _brand,
      discountPerLiter: discount,
      label: _labelController.text.trim(),
      addedAt: DateTime.now(),
    );
    Navigator.of(context).pop(card);
  }

  /// Parse the user's discount input. Accepts both '.' and ',' as the
  /// decimal separator so a German/French keyboard layout works without
  /// nagging the user about the "right" character.
  static double? _parseDecimal(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }
}
