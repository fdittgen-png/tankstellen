// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../background/fuel_price_fields.dart';
import '../../../../core/country/country_config.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/fuel_type.dart';
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

  /// The station's origin country (#2865) — derived once from the id
  /// prefix. Background alerts now fire for every supported country, so
  /// the form is country-aware: it offers that country's fuels and shows
  /// its currency. Falls back to the default country when the id carries
  /// no recognised prefix (legacy / demo ids).
  late final String _stationCountry =
      Countries.countryCodeForStationId(widget.stationId) ??
      Countries.germany.code;

  /// The fuels the background evaluator can actually resolve for this
  /// station's country (#2865) — drops the search wildcard and any fuel
  /// the country's provider doesn't price, so a saved alert can always
  /// fire. DE keeps its historical e5/e10/diesel set.
  late final List<FuelType> _alertFuelTypes = alertEvaluableFuelsFor(
    _stationCountry,
  );

  /// Currency symbol of the station's country (#2865), used in the
  /// target-price label + suffix instead of a hardcoded euro.
  late final String _currencySymbol =
      Countries.byCode(_stationCountry)?.currencySymbol ??
      Countries.germany.currencySymbol;

  @override
  void initState() {
    super.initState();
    // Default to diesel when the country offers it (it almost always
    // does); otherwise fall back to the first evaluable fuel so the
    // dropdown's initial value is always a valid item (#2865).
    _selectedFuelType = _alertFuelTypes.contains(FuelType.diesel)
        ? FuelType.diesel
        : (_alertFuelTypes.isNotEmpty
              ? _alertFuelTypes.first
              : FuelType.diesel);
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
      title: Text(l10n.createAlert),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.stationName,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.currentPrice != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.currentPrice(
                  PriceFormatter.formatPrice(widget.currentPrice),
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<FuelType>(
              initialValue: _selectedFuelType,
              decoration: InputDecoration(
                labelText: l10n.fuelType,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items:
                  <FuelType>{
                        ..._alertFuelTypes,
                        // Keep the selected value present even in the unlikely
                        // case it's not in the evaluable set, so the dropdown
                        // never asserts on a missing initial value (#2865).
                        _selectedFuelType,
                      }
                      .map(
                        (ft) => DropdownMenuItem(
                          value: ft,
                          child: Text(ft.displayName),
                        ),
                      )
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
                labelText: l10n.alertTargetPriceWithCurrency(_currencySymbol),
                border: const OutlineInputBorder(),
                hintText: '1.500',
                suffixText: '$_currencySymbol/L',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.enterPrice;
                }
                final parsed = double.tryParse(value.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) {
                  return l10n.invalidPrice;
                }
                if (parsed > 10) {
                  return l10n.priceTooHigh;
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
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _onSubmit, child: Text(l10n.create)),
      ],
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final price = double.parse(_priceController.text.replaceAll(',', '.'));

    final alert = PriceAlert(
      // #3370 — a real UUID so the alert round-trips the Supabase `alerts.id`
      // uuid column. The old `stationId_fuel_ts` composite failed sync with
      // 22P02 (the id is just an identifier — stationId/fuelType live in their
      // own fields — so a uuid is a safe swap).
      id: const Uuid().v4(),
      stationId: widget.stationId,
      stationName: widget.stationName,
      fuelType: _selectedFuelType,
      targetPrice: price,
      createdAt: DateTime.now(),
    );

    Navigator.of(context).pop(alert);
  }
}
