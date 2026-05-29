// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import '../../../../core/country/country_config.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../domain/entities/price_alert.dart';

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

  // #2246 — restricted to the fuels the on-device background evaluator
  // can actually resolve. Tankerkönig's prices feed only exposes e5/e10/
  // diesel (the German MTS-K mandate); e98/dieselPremium/e85/lpg/cng are
  // not in the upstream feed, so offering them produced silently-dead
  // alerts that could never fire. Mirrors the radius sheet's #2211 fix.
  static const _alertFuelTypes = [
    FuelType.e5,
    FuelType.e10,
    FuelType.diesel,
  ];

  /// True when the station's id prefix resolves to a non-DE country.
  /// The background evaluator is Tankerkönig-only today, so a non-DE
  /// alert is saved but can't fire — we warn the user at creation
  /// rather than letting it silently never notify (#2246).
  bool get _isNonDeStation {
    final country = Countries.countryCodeForStationId(widget.stationId);
    return country != null && country != 'DE';
  }

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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            // #2246 — honest creation gating: the on-device background
            // evaluator is Tankerkönig-only, so an alert on a non-DE
            // station is saved but can't fire yet. Surface that instead
            // of letting it silently never notify.
            if (_isNonDeStation) ...[
              const SizedBox(height: 16),
              _NonDeStationWarning(
                message: l10n?.alertGatingNonDeStationWarning ??
                    'Background price alerts currently only work for '
                        'stations in Germany.',
              ),
            ],
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

/// Inline amber warning banner shown when the alert's station is outside
/// Germany — the on-device background evaluator can't reach it yet
/// (#2246).
class _NonDeStationWarning extends StatelessWidget {
  const _NonDeStationWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.tertiary;
    return Container(
      key: const Key('alert_non_de_warning'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
