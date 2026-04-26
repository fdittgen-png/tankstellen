import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/loyalty_card.dart';
import '../../domain/loyalty_card_validators.dart';

/// Bottom-sheet form that creates a new [LoyaltyCard].
///
/// Pops with the freshly-built card on Save, or with `null` on
/// Cancel — the parent screen handles persistence so this widget
/// stays free of provider plumbing and can be unit-tested with a
/// plain `pumpApp`.
///
/// Extracted from `loyalty_settings_screen.dart` (#563). Validation
/// rules live in `domain/loyalty_card_validators.dart` so the form
/// and any future bulk-import path stay consistent.
class LoyaltyAddCardSheet extends StatefulWidget {
  const LoyaltyAddCardSheet({super.key});

  @override
  State<LoyaltyAddCardSheet> createState() => _LoyaltyAddCardSheetState();
}

class _LoyaltyAddCardSheetState extends State<LoyaltyAddCardSheet> {
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
                if (!isValidDiscountInput(value)) {
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
    final discount = parseDiscountInput(_discountController.text);
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
}
