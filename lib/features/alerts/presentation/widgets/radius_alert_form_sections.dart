import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';

/// Section widgets for [RadiusAlertCreateSheet] (#563 phase:
/// radius_alert_create_sheet extract).
///
/// Each section is a self-contained `StatelessWidget` so the sheet's
/// `build()` reads top-to-bottom as a list of named fields. The
/// sheet still owns the controllers and the mutable state — these
/// widgets are pure presentation, fed by parameters and callbacks.

/// Label text field at the top of the create sheet. Calls
/// [onChanged] on every keystroke so the parent can re-evaluate
/// [canSave] and toggle the Save button.
class RadiusAlertLabelField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const RadiusAlertLabelField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: l10n?.alertsRadiusLabelHint ?? 'Label',
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

/// Fuel-type dropdown. Hides [FuelType.all] because an alert with
/// "all fuels" wouldn't have a single threshold to compare against.
class RadiusAlertFuelTypeField extends StatelessWidget {
  final FuelType value;
  final ValueChanged<FuelType> onChanged;

  const RadiusAlertFuelTypeField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<FuelType>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: l10n?.alertsRadiusFuelType ?? 'Fuel type',
        border: const OutlineInputBorder(),
      ),
      items: FuelType.values
          .where((t) => t != FuelType.all)
          .map((t) => DropdownMenuItem(
                value: t,
                child: Text(t.displayName),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

/// Threshold price field. Accepts decimal input (German/French
/// keyboards send a comma; the parser normalises that downstream).
class RadiusAlertThresholdField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const RadiusAlertThresholdField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: l10n?.alertsRadiusThreshold ?? 'Threshold (€/L)',
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

/// Radius slider (1-50 km) with the live value on the right.
class RadiusAlertRadiusSlider extends StatelessWidget {
  final double radiusKm;
  final ValueChanged<double> onChanged;

  const RadiusAlertRadiusSlider({
    super.key,
    required this.radiusKm,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              l10n?.alertsRadiusKm ?? 'Radius (km)',
              style: theme.textTheme.titleSmall,
            ),
            const Spacer(),
            Text(
              '${radiusKm.round()} km',
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
        Slider(
          value: radiusKm.clamp(1, 50),
          min: 1,
          max: 50,
          divisions: 49,
          label: '${radiusKm.round()} km',
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Daily-frequency dropdown (1×, 2×, 3×, 4× per day).
class RadiusAlertFrequencyField extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const RadiusAlertFrequencyField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: l10n?.alertsRadiusFrequencyLabel ?? 'Check frequency',
        border: const OutlineInputBorder(),
      ),
      items: <DropdownMenuItem<int>>[
        DropdownMenuItem(
          value: 1,
          child: Text(l10n?.alertsRadiusFrequencyDaily ?? 'Once a day'),
        ),
        DropdownMenuItem(
          value: 2,
          child: Text(
              l10n?.alertsRadiusFrequencyTwiceDaily ?? 'Twice a day'),
        ),
        DropdownMenuItem(
          value: 3,
          child: Text(
              l10n?.alertsRadiusFrequencyThriceDaily ?? 'Three times a day'),
        ),
        DropdownMenuItem(
          value: 4,
          child: Text(l10n?.alertsRadiusFrequencyFourTimesDaily ??
              'Four times a day'),
        ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

/// "Use my location" + "Pick on map" button row, plus the optional
/// caption underneath that names the bound center source.
class RadiusAlertCenterButtons extends StatelessWidget {
  final VoidCallback onUseGps;
  final VoidCallback onPickOnMap;
  final String? centerSource;

  const RadiusAlertCenterButtons({
    super.key,
    required this.onUseGps,
    required this.onPickOnMap,
    required this.centerSource,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.my_location),
                onPressed: onUseGps,
                label: Text(
                  l10n?.alertsRadiusCenterGps ?? 'Use my location',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.map_outlined),
                onPressed: onPickOnMap,
                label: Text(
                  l10n?.radiusAlertPickOnMap ?? 'Pick on map',
                ),
              ),
            ),
          ],
        ),
        if (centerSource != null) ...[
          const SizedBox(height: 8),
          Text(
            centerSource!,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// Postal-code fallback field. The phase-3 worker geocodes this when
/// no GPS center is bound.
class RadiusAlertPostalCodeField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const RadiusAlertPostalCodeField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: l10n?.alertsRadiusCenterPostalCode ?? 'Postal code',
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

/// Cancel + Save action row at the bottom of the sheet. [onSave] is
/// `null` until [canSaveRadiusAlertForm] is satisfied — the
/// `FilledButton` greys out automatically in that state.
class RadiusAlertActionRow extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback? onSave;

  const RadiusAlertActionRow({
    super.key,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            child: Text(l10n?.alertsRadiusCancel ?? 'Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: onSave,
            child: Text(l10n?.alertsRadiusSave ?? 'Save'),
          ),
        ),
      ],
    );
  }
}
