// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/calculator_prefill_provider.dart';
import '../../providers/calculator_provider.dart';
import 'calculator_input_field.dart';
import 'use_mine_chip.dart';

/// Inputs + options section of the redesigned calculator (#2543).
///
/// Hosts the three [CalculatorInputField]s (each with its own hidden-
/// when-unavailable "use mine" chip), the round-trip switch, and the
/// collapsible "estimate monthly" expansion. The text controllers are
/// owned by the parent screen and threaded in so applying a prefill
/// updates both the field text and the calculator state.
class CalculatorInputsCard extends ConsumerWidget {
  final TextEditingController distanceController;
  final TextEditingController consumptionController;
  final TextEditingController priceController;
  final TextEditingController tripsPerMonthController;

  /// Whether the price the user navigated in with (route extra) has
  /// been applied — flips the price chip to an "Applied" state.
  final bool priceApplied;

  const CalculatorInputsCard({
    super.key,
    required this.distanceController,
    required this.consumptionController,
    required this.priceController,
    required this.tripsPerMonthController,
    this.priceApplied = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(calculatorProvider);
    final notifier = ref.read(calculatorProvider.notifier);
    final prefill = ref.watch(calculatorPrefillProvider);

    final distanceUnit = PriceFormatter.activeConfig.distanceUnit;
    final priceSuffix = UnitFormatter.pricePerUnitSuffix();
    // i18n-ignore: language-neutral consumption unit mask (#2185)
    final consumptionUnit = prefill.isEv ? 'kWh/100 km' : 'L/100 km';

    return SectionCard(
      title: l10n.tripDetails,
      leadingIcon: Icons.tune,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalculatorInputField(
            controller: distanceController,
            labelText: l10n.calculatorDistanceLabel(distanceUnit),
            hintText: l10n.calculatorDistanceHint,
            icon: Icons.straighten,
            onParsed: notifier.setDistance,
            action: prefill.distanceKm == null
                ? null
                : UseMineChip(
                    prefix: l10n.calculatorUseMine,
                    valueLabel: UnitFormatter.formatDistance(
                      prefill.distanceKm,
                    ),
                    onApply: () => _apply(
                      notifier.setDistance,
                      distanceController,
                      prefill.distanceKm!,
                      decimals: 1,
                    ),
                  ),
          ),
          const SizedBox(height: Spacing.xl),
          CalculatorInputField(
            controller: consumptionController,
            labelText: l10n.calculatorConsumptionLabel(consumptionUnit),
            hintText: l10n.calculatorConsumptionHint,
            icon: Icons.local_gas_station,
            onParsed: notifier.setConsumption,
            action: prefill.consumptionPer100Km == null
                ? null
                : UseMineChip(
                    prefix: l10n.calculatorUseMine,
                    valueLabel: UnitFormatter.formatConsumption(
                      prefill.consumptionPer100Km!,
                      isEv: prefill.isEv,
                    ),
                    onApply: () => _apply(
                      notifier.setConsumption,
                      consumptionController,
                      prefill.consumptionPer100Km!,
                      decimals: 1,
                    ),
                  ),
          ),
          const SizedBox(height: Spacing.xl),
          CalculatorInputField(
            controller: priceController,
            labelText: l10n.calculatorPriceLabel(priceSuffix),
            hintText: l10n.calculatorPriceHint,
            icon: Icons.local_offer,
            onParsed: notifier.setPrice,
            action: prefill.pricePerLiter == null && !priceApplied
                ? null
                : UseMineChip(
                    applied: priceApplied,
                    prefix: priceApplied
                        ? (l10n.calculatorApplied)
                        : (l10n.calculatorUseMine),
                    valueLabel: PriceFormatter.formatPrice(
                      priceApplied
                          ? state.pricePerLiter
                          : prefill.pricePerLiter,
                    ),
                    onApply: () => _apply(
                      notifier.setPrice,
                      priceController,
                      prefill.pricePerLiter!,
                      decimals: 3,
                    ),
                  ),
          ),
          const SizedBox(height: Spacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.calculatorRoundTrip),
            value: state.roundTrip,
            onChanged: notifier.setRoundTrip,
          ),
          _MonthlyEstimate(
            controller: tripsPerMonthController,
            onChanged: notifier.setTripsPerMonth,
          ),
        ],
      ),
    );
  }

  /// Apply a prefill value to both the field text and the calculator
  /// state. [decimals] formats the field text plainly (dot decimal) so
  /// the numeric keyboard can re-parse it.
  void _apply(
    ValueChanged<double> set,
    TextEditingController controller,
    double value, {
    required int decimals,
  }) {
    controller.text = value.toStringAsFixed(decimals);
    set(value);
  }
}

/// Collapsible "estimate monthly" block — a single trips-per-month
/// field, hidden by default behind an [ExpansionTile]. No prefill: the
/// app has no monthly-mileage figure to draw from.
class _MonthlyEstimate extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<double?> onChanged;

  const _MonthlyEstimate({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: Spacing.md),
      title: Text(l10n.calculatorEstimateMonthly),
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.calculatorTripsPerMonth,
            hintText: l10n.calculatorTripsPerMonthHint,
            prefixIcon: const Icon(Icons.event_repeat),
            border: const OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => onChanged(double.tryParse(v)),
        ),
      ],
    );
  }
}
