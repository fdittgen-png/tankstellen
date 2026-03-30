import 'package:flutter/material.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../data/models/price_alert.dart';

/// Dialog for creating a new price alert from the station detail screen.
///
/// Takes the station's ID, name, and current price to pre-fill the form.
/// Returns a [PriceAlert] on submit, or null if cancelled.
class CreateAlertDialog extends StatefulWidget {
  final String stationId;
  final String stationName;
  final double? currentPrice;

  const CreateAlertDialog({
    super.key,
    required this.stationId,
    required this.stationName,
    this.currentPrice,
  });

  @override
  State<CreateAlertDialog> createState() => _CreateAlertDialogState();
}

class _CreateAlertDialogState extends State<CreateAlertDialog> {
  final _formKey = GlobalKey<FormState>();
  late FuelType _selectedFuelType;
  late TextEditingController _priceController;

  // Fuel types that make sense for alerts (exclude 'all')
  static const _alertFuelTypes = [
    FuelType.e5,
    FuelType.e10,
    FuelType.e98,
    FuelType.diesel,
    FuelType.dieselPremium,
    FuelType.e85,
    FuelType.lpg,
    FuelType.cng,
  ];

  @override
  void initState() {
    super.initState();
    _selectedFuelType = FuelType.diesel;
    final prefilled = widget.currentPrice != null
        ? (widget.currentPrice! - 0.05).toStringAsFixed(3)
        : '';
    _priceController = TextEditingController(text: prefilled);
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n?.createAlert ?? 'Create Price Alert'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.stationName,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.currentPrice != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n?.currentPrice(PriceFormatter.formatPrice(widget.currentPrice)) ?? 'Current price: ${PriceFormatter.formatPrice(widget.currentPrice)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<FuelType>(
              initialValue: _selectedFuelType,
              decoration: InputDecoration(
                labelText: l10n?.fuelType ?? 'Fuel type',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: _alertFuelTypes
                  .map((ft) => DropdownMenuItem(
                        value: ft,
                        child: Text(ft.displayName),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedFuelType = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: l10n?.targetPrice ?? 'Target price (EUR)',
                border: const OutlineInputBorder(),
                hintText: '1.500',
                suffixText: '\u20ac/L',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n?.enterPrice ?? 'Please enter a price';
                }
                final parsed = double.tryParse(value.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) {
                  return l10n?.invalidPrice ?? 'Invalid price';
                }
                if (parsed > 10) {
                  return l10n?.priceTooHigh ?? 'Price too high';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: _onSubmit,
          child: Text(l10n?.create ?? 'Create'),
        ),
      ],
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final price =
        double.parse(_priceController.text.replaceAll(',', '.'));

    final alert = PriceAlert(
      id: '${widget.stationId}_${_selectedFuelType.apiValue}_${DateTime.now().millisecondsSinceEpoch}',
      stationId: widget.stationId,
      stationName: widget.stationName,
      fuelType: _selectedFuelType,
      targetPrice: price,
      createdAt: DateTime.now(),
    );

    Navigator.of(context).pop(alert);
  }
}
