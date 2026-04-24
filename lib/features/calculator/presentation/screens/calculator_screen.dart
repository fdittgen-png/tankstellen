import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/calculator_provider.dart';
import '../widgets/calculator_empty_hint.dart';
import '../widgets/calculator_input_field.dart';
import '../widgets/calculator_result_card.dart';

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

    final price = widget.initialPrice ?? state.pricePerLiter;
    _priceController = TextEditingController(
      text: price > 0 ? price.toStringAsFixed(3) : '',
    );

    if (widget.initialPrice != null && widget.initialPrice! > 0) {
      Future.microtask(() {
        ref.read(calculatorProvider.notifier).setPrice(widget.initialPrice!);
      });
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _consumptionController.dispose();
    _priceController.dispose();
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
        padding: const EdgeInsets.all(16),
        children: [
          CalculatorInputField(
            controller: _distanceController,
            labelText: l10n?.distanceKm ?? 'Distance (km)',
            hintText: 'e.g. 150',
            icon: Icons.straighten,
            onParsed: notifier.setDistance,
          ),
          const SizedBox(height: 16),
          CalculatorInputField(
            controller: _consumptionController,
            labelText: l10n?.consumptionL100km ?? 'Consumption (L/100km)',
            hintText: 'e.g. 7.0',
            icon: Icons.local_gas_station,
            onParsed: notifier.setConsumption,
          ),
          const SizedBox(height: 16),
          CalculatorInputField(
            controller: _priceController,
            labelText: l10n?.fuelPriceEurL ?? 'Fuel price (\u20ac/L)',
            hintText: 'e.g. 1.899',
            icon: Icons.euro,
            onParsed: notifier.setPrice,
          ),
          const SizedBox(height: 32),
          if (state.hasInput)
            CalculatorResultCard(state: state)
          else
            const CalculatorEmptyHint(),
        ],
      ),
    );
  }
}
