import 'package:flutter/material.dart';

import '../../features/search/domain/entities/fuel_type.dart';
import '../../l10n/app_localizations.dart';

/// Shared dropdown for picking a [FuelType]. Uses [FuelType.displayName]
/// for labels (e.g. "Super E10", "E85 / Bioéthanol", "Electric ⚡") so
/// every surface — profile, vehicle, fill-up — shows the same polished
/// list. Filters out [FuelType.all] (a search wildcard, not a preference).
///
/// Use [FuelTypeDropdown] when the selection is required (profile, fill-up)
/// and [NullableFuelTypeDropdown] when "not set" is a legal value
/// (vehicles, before a fuel is configured).
class FuelTypeDropdown extends StatelessWidget {
  final FuelType value;
  final ValueChanged<FuelType> onChanged;
  final String? labelText;
  final Widget? prefixIcon;

  const FuelTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<FuelType>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: labelText ?? l10n?.preferredFuel ?? 'Preferred fuel',
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon,
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

/// Same labels as [FuelTypeDropdown] but allows a null "not set" entry.
/// Used by the vehicle combustion section where the user may want to
/// leave the fuel blank and let the profile's default take over.
///
/// [options] can restrict which fuels appear (e.g. combustion section
/// hides [FuelType.electric]). Defaults to all non-wildcard fuels.
class NullableFuelTypeDropdown extends StatelessWidget {
  final FuelType? value;
  final ValueChanged<FuelType?> onChanged;
  final String? labelText;
  final String? notSetLabel;
  final Widget? prefixIcon;
  final List<FuelType>? options;

  const NullableFuelTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText,
    this.notSetLabel,
    this.prefixIcon,
    this.options,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = options ??
        FuelType.values.where((t) => t != FuelType.all).toList();
    return DropdownButtonFormField<FuelType?>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: labelText ?? l10n?.preferredFuel ?? 'Preferred fuel',
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon,
      ),
      items: [
        DropdownMenuItem<FuelType?>(
          value: null,
          child: Text(
            notSetLabel ?? l10n?.vehicleFuelNotSet ?? 'Not set',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        ...items.map((t) => DropdownMenuItem<FuelType?>(
              value: t,
              child: Text(t.displayName),
            )),
      ],
      onChanged: onChanged,
    );
  }
}
