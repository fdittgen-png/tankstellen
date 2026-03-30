import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/calculator_provider.dart';

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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.fuelCostCalculator ?? 'Fuel Cost Calculator'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Distance input
          TextField(
            controller: _distanceController,
            decoration: InputDecoration(
              labelText: l10n?.distanceKm ?? 'Distance (km)',
              hintText: 'e.g. 150',
              prefixIcon: const Icon(Icons.straighten),
              border: const OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final parsed = double.tryParse(value) ?? 0;
              ref.read(calculatorProvider.notifier).setDistance(parsed);
            },
          ),
          const SizedBox(height: 16),

          // Consumption input
          TextField(
            controller: _consumptionController,
            decoration: InputDecoration(
              labelText: l10n?.consumptionL100km ?? 'Consumption (L/100km)',
              hintText: 'e.g. 7.0',
              prefixIcon: const Icon(Icons.local_gas_station),
              border: const OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final parsed = double.tryParse(value) ?? 0;
              ref.read(calculatorProvider.notifier).setConsumption(parsed);
            },
          ),
          const SizedBox(height: 16),

          // Price input
          TextField(
            controller: _priceController,
            decoration: InputDecoration(
              labelText: l10n?.fuelPriceEurL ?? 'Fuel price (\u20ac/L)',
              hintText: 'e.g. 1.899',
              prefixIcon: const Icon(Icons.euro),
              border: const OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final parsed = double.tryParse(value) ?? 0;
              ref.read(calculatorProvider.notifier).setPrice(parsed);
            },
          ),
          const SizedBox(height: 32),

          // Result card
          if (state.hasInput)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.calculate_outlined,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.tripCost ?? 'Trip Cost',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ResultItem(
                          label: l10n?.fuelNeeded ?? 'Fuel needed',
                          value: '${state.calculation.totalLiters.toStringAsFixed(1)} L',
                        ),
                        _ResultItem(
                          label: l10n?.totalCost ?? 'Total cost',
                          value: '${state.calculation.totalCost.toStringAsFixed(2)} \u20ac',
                          highlight: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.calculate_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.enterCalcValues ?? 'Enter distance, consumption, and price to calculate trip cost',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _ResultItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: highlight
              ? theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                )
              : theme.textTheme.titleLarge,
        ),
      ],
    );
  }
}
