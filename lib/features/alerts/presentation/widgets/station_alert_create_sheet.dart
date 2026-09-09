// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../background/fuel_price_fields.dart';
import '../../../../core/country/country_config.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/sheet_form_actions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../domain/entities/price_alert.dart';
import '../../domain/radius_alert_validators.dart';
import 'radius_alert_form_support.dart';

/// Bottom sheet that creates a price alert for ONE station.
///
/// Takes the station's ID, name, and current price to pre-fill the form.
/// Pops with a [PriceAlert] on submit, or null if cancelled.
///
/// #3993 — this was an `AlertDialog` while its sibling, the zone alert,
/// was a bottom sheet: the same act on the same screen, arriving from
/// two directions. It is now a sheet with the shared
/// [SheetFormActions] row, and it seeds and parses its price through
/// the same locale-aware helpers the zone sheet uses — the old
/// `toStringAsFixed(3)` prefill showed a dot-decimal number to readers
/// whose keyboards type commas.
class StationAlertCreateSheet extends StatefulWidget {
  final String stationId;
  final String stationName;
  final double? currentPrice;

  const StationAlertCreateSheet({
    super.key,
    required this.stationId,
    required this.stationName,
    this.currentPrice,
  });

  /// Open the sheet and return the alert the user built, or null.
  /// Both entry points — the station-detail app bar and the alerts
  /// screen's station picker — go through here, so the two can never
  /// drift into different surfaces again.
  static Future<PriceAlert?> show(
    BuildContext context, {
    required String stationId,
    required String stationName,
    double? currentPrice,
  }) {
    return showModalBottomSheet<PriceAlert>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StationAlertCreateSheet(
          stationId: stationId,
          stationName: stationName,
          currentPrice: currentPrice,
        ),
      ),
    );
  }

  @override
  State<StationAlertCreateSheet> createState() =>
      _StationAlertCreateSheetState();
}

class _StationAlertCreateSheetState extends State<StationAlertCreateSheet> {
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
    // #3993 — seeded the way the zone sheet seeds: 5 % below the
    // current price, floored to the thousandth so the target never
    // lands above it, and formatted in the reader's decimal separator.
    // The flat 5-cent discount this replaces was the same absolute step
    // whether the fuel cost 1.20 or 2.20.
    final prefilled = widget.currentPrice != null
        ? formatThreshold(floorToThreeDecimals(
            widget.currentPrice! * (1 - kRadiusAlertThresholdDiscount)))
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

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.createAlert,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
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
                // #3993 — the example in the reader's decimal format.
                hintText: formatThreshold(1.5),
                suffixText: '$_currencySymbol/L',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.enterPrice;
                }
                // #3993 — the ONE threshold parser both alert forms use,
                // so "1,499" and "1.499" mean the same price here as
                // they do in the zone sheet.
                final parsed = RadiusAlertValidators.parseThreshold(value);
                if (parsed == null || parsed <= 0) {
                  return l10n.invalidPrice;
                }
                if (parsed > 10) {
                  return l10n.priceTooHigh;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SheetFormActions(
              onCancel: () => Navigator.of(context).pop(),
              onConfirm: _onSubmit,
              confirmLabel: l10n.create,
              confirmKey: const Key('station_alert_create'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final price = RadiusAlertValidators.parseThreshold(_priceController.text);
    // The validator has already rejected an unparseable field; this
    // guard keeps `_onSubmit` total rather than trusting that ordering.
    if (price == null) return;

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
