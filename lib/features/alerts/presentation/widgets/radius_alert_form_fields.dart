import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';

/// Form section widgets for [RadiusAlertCreateSheet]
/// (#563 phase: radius_alert_create_sheet). Pure stateless widgets —
/// every piece of state lives in `_RadiusAlertCreateSheetState` and
/// flows in via constructor parameters; user input flows back via
/// callbacks. Keeps the parent sheet under the 300-LOC budget while
/// preserving the test-injection hooks (idGenerator, mapPickerOpener).

/// Single-line label input. Fires [onChanged] on each keystroke so the
/// parent can re-evaluate "Save" enablement.
class RadiusAlertLabelField extends StatelessWidget {
  const RadiusAlertLabelField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;

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

/// Dropdown picking the fuel type the alert watches. Excludes
/// [FuelType.all] — an alert needs a concrete fuel to compare against.
class RadiusAlertFuelTypeField extends StatelessWidget {
  const RadiusAlertFuelTypeField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final FuelType value;
  final ValueChanged<FuelType> onChanged;

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

/// Decimal price-per-litre threshold field. Accepts `,` or `.` as the
/// decimal separator; the parent's parser normalises the input.
class RadiusAlertThresholdField extends StatelessWidget {
  const RadiusAlertThresholdField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;

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

/// 1–50 km slider for the search radius around the alert center.
class RadiusAlertRadiusSlider extends StatelessWidget {
  const RadiusAlertRadiusSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

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
            Text('${value.round()} km', style: theme.textTheme.titleSmall),
          ],
        ),
        Slider(
          value: value.clamp(1, 50),
          min: 1,
          max: 50,
          divisions: 49,
          label: '${value.round()} km',
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// WorkManager check-cadence dropdown (1–4 times per day, default 1).
/// #1012 phase 1 added the 2/3/4 options.
class RadiusAlertFrequencyField extends StatelessWidget {
  const RadiusAlertFrequencyField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

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
          child:
              Text(l10n?.alertsRadiusFrequencyTwiceDaily ?? 'Twice a day'),
        ),
        DropdownMenuItem(
          value: 3,
          child: Text(l10n?.alertsRadiusFrequencyThriceDaily ??
              'Three times a day'),
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

/// Two-button row binding the alert center to GPS or a map-pick.
class RadiusAlertCenterButtons extends StatelessWidget {
  const RadiusAlertCenterButtons({
    super.key,
    required this.onUseMyLocation,
    required this.onPickOnMap,
  });

  final VoidCallback onUseMyLocation;
  final VoidCallback onPickOnMap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.my_location),
            onPressed: onUseMyLocation,
            label: Text(l10n?.alertsRadiusCenterGps ?? 'Use my location'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.map_outlined),
            onPressed: onPickOnMap,
            label: Text(l10n?.radiusAlertPickOnMap ?? 'Pick on map'),
          ),
        ),
      ],
    );
  }
}

/// Postal-code fallback field. Save accepts this alone; the phase-3
/// worker geocodes postal-only entries to coordinates later.
class RadiusAlertPostalCodeField extends StatelessWidget {
  const RadiusAlertPostalCodeField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;

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

/// Cancel + Save action row. `onSave == null` greys out the Save button.
class RadiusAlertActionButtons extends StatelessWidget {
  const RadiusAlertActionButtons({
    super.key,
    required this.onCancel,
    required this.onSave,
  });

  final VoidCallback onCancel;
  final VoidCallback? onSave;

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
