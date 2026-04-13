import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vehicle_profile.dart';

/// EV-specific portion of the [EditVehicleScreen] form. Owns the battery,
/// max-charge-power, supported connectors, and SoC range fields. Statelessly
/// surfaces every input through callbacks so the parent screen keeps a
/// single source of truth for form state.
class VehicleEvSection extends StatelessWidget {
  final TextEditingController batteryController;
  final TextEditingController maxChargingKwController;
  final TextEditingController minSocController;
  final TextEditingController maxSocController;
  final Set<ConnectorType> connectors;
  final ValueChanged<ConnectorType> onToggleConnector;
  final String? Function(String?) numberValidator;

  const VehicleEvSection({
    super.key,
    required this.batteryController,
    required this.maxChargingKwController,
    required this.minSocController,
    required this.maxSocController,
    required this.connectors,
    required this.onToggleConnector,
    required this.numberValidator,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l?.vehicleEvSectionTitle ?? 'Electric',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: batteryController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l?.vehicleBatteryLabel ?? 'Battery capacity (kWh)',
          ),
          validator: numberValidator,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: maxChargingKwController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText:
                l?.vehicleMaxChargeLabel ?? 'Max charging power (kW)',
          ),
          validator: numberValidator,
        ),
        const SizedBox(height: 16),
        Text(
          l?.vehicleConnectorsLabel ?? 'Supported connectors',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ConnectorType.values.map((c) {
            final selected = connectors.contains(c);
            return FilterChip(
              label: Text(c.label),
              selected: selected,
              onSelected: (_) => onToggleConnector(c),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: minSocController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l?.vehicleMinSocLabel ?? 'Min SoC %',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: maxSocController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l?.vehicleMaxSocLabel ?? 'Max SoC %',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
