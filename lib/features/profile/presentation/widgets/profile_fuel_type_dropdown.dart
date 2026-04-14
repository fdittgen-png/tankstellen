import 'package:flutter/material.dart';

import '../../../../features/search/domain/entities/fuel_type.dart';
import '../../../../l10n/app_localizations.dart';

/// Dropdown for picking the user's preferred [FuelType] in the profile
/// edit sheet. Filters out [FuelType.all] (a search-time wildcard, not a
/// real preference) and labels options via [FuelType.displayName].
///
/// Pulled out of `profile_edit_sheet.dart` so the sheet's `build` method
/// drops the inline dropdown block and so the filter + display labels
/// can be exercised by widget tests in isolation.
class ProfileFuelTypeDropdown extends StatelessWidget {
  final FuelType value;
  final ValueChanged<FuelType> onChanged;

  const ProfileFuelTypeDropdown({
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
        labelText: l10n?.preferredFuel ?? 'Preferred fuel',
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
