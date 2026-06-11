// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/calculator_provider.dart';
import '../widgets/calculator_inputs_card.dart';
import '../widgets/calculator_result_card.dart';

/// Fuel-cost calculator — result-led redesign (#2543).
///
/// The answer leads: a [CalculatorResultCard] hero sits first (with
/// `--` placeholders until inputs are ready), followed by the inputs +
/// options card and a reset button.
///
/// [initialPrice] is the per-litre price the user navigated in with
/// from the search-results launch — pre-applied to the price field and
/// surfaced as an "Applied" chip. Null when the screen is opened cold.
class CalculatorScreen extends ConsumerStatefulWidget {
  final double? initialPrice;

  const CalculatorScreen({super.key, this.initialPrice});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  late final TextEditingController _distanceController;
  late final TextEditingController _consumptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _tripsPerMonthController;

  bool _priceApplied = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(calculatorProvider);

    _distanceController = TextEditingController(
      text: state.distanceKm > 0 ? state.distanceKm.toString() : '',
    );
    _consumptionController = TextEditingController(
      text: state.consumptionPer100Km.toString(),
    );

    final routePrice = widget.initialPrice;
    final hasRoutePrice = routePrice != null && routePrice > 0;
    final price = hasRoutePrice ? routePrice : state.pricePerLiter;
    _priceController = TextEditingController(
      text: price > 0 ? price.toStringAsFixed(3) : '',
    );
    _tripsPerMonthController = TextEditingController();

    if (hasRoutePrice) {
      _priceApplied = true;
      unawaited(Future.microtask(() {
        ref.read(calculatorProvider.notifier).setPrice(routePrice);
      }));
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _consumptionController.dispose();
    _priceController.dispose();
    _tripsPerMonthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calculatorProvider);
    final notifier = ref.read(calculatorProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return PageScaffold(
      title: l10n?.fuelCostCalculator ?? 'Fuel Cost Calculator',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n?.tooltipBack ?? 'Back',
        onPressed: () => context.go('/'),
      ),
      bodyPadding: EdgeInsets.zero,
      body: ListView(
        padding: const EdgeInsets.all(Spacing.xl),
        children: [
          // Answer leads — the result hero is always first; it shows
          // `--` placeholders until all inputs are entered.
          CalculatorResultCard(state: state),
          const SizedBox(height: Spacing.xl),
          CalculatorInputsCard(
            distanceController: _distanceController,
            consumptionController: _consumptionController,
            priceController: _priceController,
            tripsPerMonthController: _tripsPerMonthController,
            priceApplied: _priceApplied,
          ),
          const SizedBox(height: Spacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(l10n?.calculatorReset ?? 'Reset'),
              onPressed: () {
                notifier.reset();
                _distanceController.clear();
                _consumptionController.text =
                    ref.read(calculatorProvider).consumptionPer100Km.toString();
                _priceController.clear();
                _tripsPerMonthController.clear();
                setState(() => _priceApplied = false);
              },
            ),
          ),
        ],
      ),
    );
  }
}
