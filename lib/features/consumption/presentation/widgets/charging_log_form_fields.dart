import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../domain/charging_log_readout.dart';
import '../../domain/charging_log_validators.dart';
import 'charging_log_derived_readout_panel.dart';
import 'fill_up_date_row.dart';
import 'fill_up_numeric_field.dart';
import 'fill_up_vehicle_dropdown.dart';

/// All the input rows on the Add-Charging-Log form, composed in the
/// canonical order: date, vehicle, kWh, cost (+derived readout),
/// charge-time, odometer, station name, save button. Pulled out of
/// `add_charging_log_screen.dart` (#582 phase 2 follow-up, #563)
/// so the screen file drops well below 300 LOC and the form layout
/// can be exercised as a single widget in tests.
///
/// All controllers, callbacks, and the form's parent `_formKey` are
/// owned by the screen — this widget is a pure stateless layout.
class ChargingLogFormFields extends StatelessWidget {
  final String dateLabel;
  final VoidCallback onPickDate;

  final String? vehicleId;
  final List<VehicleProfile> vehicles;
  final void Function(String? id, VehicleProfile? selected) onVehicleChanged;

  final TextEditingController kwhCtrl;
  final TextEditingController costCtrl;
  final TextEditingController timeMinCtrl;
  final TextEditingController odoCtrl;
  final TextEditingController stationCtrl;

  final ChargingLogReadout? derived;

  final bool saving;
  final VoidCallback onSave;

  const ChargingLogFormFields({
    super.key,
    required this.dateLabel,
    required this.onPickDate,
    required this.vehicleId,
    required this.vehicles,
    required this.onVehicleChanged,
    required this.kwhCtrl,
    required this.costCtrl,
    required this.timeMinCtrl,
    required this.odoCtrl,
    required this.stationCtrl,
    required this.derived,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FillUpDateRow(dateLabel: dateLabel, onTap: onPickDate),
        const SizedBox(height: 8),
        FillUpVehicleDropdown(
          vehicleId: vehicleId,
          vehicles: vehicles,
          onChanged: onVehicleChanged,
        ),
        const SizedBox(height: 12),
        FillUpNumericField(
          key: const Key('charging_kwh_field'),
          controller: kwhCtrl,
          label: l?.chargingKwh ?? 'Energy (kWh)',
          icon: Icons.bolt_outlined,
          validator: (v) => ChargingLogValidators.positiveNumber(v, l),
        ),
        const SizedBox(height: 12),
        FillUpNumericField(
          key: const Key('charging_cost_field'),
          controller: costCtrl,
          label: l?.chargingCost ?? 'Total cost',
          icon: Icons.euro,
          validator: (v) => ChargingLogValidators.positiveNumber(v, l),
        ),
        ChargingLogDerivedReadoutPanel(readout: derived),
        const SizedBox(height: 12),
        FillUpNumericField(
          key: const Key('charging_time_field'),
          controller: timeMinCtrl,
          label: l?.chargingTimeMin ?? 'Charge time (min)',
          icon: Icons.timer_outlined,
          validator: (v) => ChargingLogValidators.nonNegativeInt(v, l),
        ),
        const SizedBox(height: 12),
        FillUpNumericField(
          key: const Key('charging_odo_field'),
          controller: odoCtrl,
          label: l?.odometerKm ?? 'Odometer (km)',
          icon: Icons.speed,
          validator: (v) => ChargingLogValidators.positiveNumber(v, l),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('charging_station_field'),
          controller: stationCtrl,
          textCapitalization: TextCapitalization.words,
          inputFormatters: [
            LengthLimitingTextInputFormatter(80),
          ],
          decoration: InputDecoration(
            labelText: l?.chargingStationName ?? 'Station (optional)',
            prefixIcon: const Icon(Icons.place_outlined),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const Key('charging_save_button'),
          onPressed: saving ? null : onSave,
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(l?.save ?? 'Save'),
        ),
        SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
      ],
    );
  }
}
