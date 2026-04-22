import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';

/// Mandatory vehicle picker on the Add-Fill-Up form (#713).
///
/// Renders a `DropdownButtonFormField` over [vehicles], enforces a
/// non-null selection via the form validator, and calls [onChanged]
/// with BOTH the id and the resolved [VehicleProfile]. Handing the
/// profile back lets the caller derive the default fuel type in
/// the same setState (the fuel picker below the dropdown reacts on
/// vehicle-switch per #698 — fuel is always the vehicle's fuel).
///
/// Pulled out of `add_fill_up_screen.dart` (#727) so the screen's
/// `build` method drops a 25-line inline block and the dropdown can
/// be rendered and tapped in isolation by widget tests.
class FillUpVehicleDropdown extends StatelessWidget {
  final String? vehicleId;
  final List<VehicleProfile> vehicles;
  final void Function(String id, VehicleProfile selected) onChanged;

  const FillUpVehicleDropdown({
    super.key,
    required this.vehicleId,
    required this.vehicles,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DropdownButtonFormField<String>(
      initialValue: vehicleId,
      decoration: InputDecoration(
        labelText: l?.fillUpVehicleLabel ?? 'Vehicle',
        prefixIcon: const Icon(Icons.directions_car_outlined),
      ),
      items: vehicles
          .map(
            (v) => DropdownMenuItem<String>(
              value: v.id,
              child: Text(v.name),
            ),
          )
          .toList(),
      validator: (v) =>
          v == null ? (l?.fillUpVehicleRequired ?? 'Required') : null,
      onChanged: (v) {
        if (v == null) return;
        final selected = vehicles.firstWhere((x) => x.id == v);
        onChanged(v, selected);
      },
    );
  }
}
