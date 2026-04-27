import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../consumption/presentation/widgets/vehicle_adapter_section.dart';
import '../../../consumption/presentation/widgets/vehicle_baseline_section.dart';
import 'service_reminder_section.dart';
import 'vehicle_calibration_mode_selector.dart';

/// "Extras for a saved vehicle" band on the edit screen — OBD2
/// adapter pairing, learned baselines, volumetric-efficiency reset
/// and service reminders. All four depend on a stable vehicle id
/// and are hidden while a brand-new vehicle is still being created.
///
/// Returns a `List<Widget>` that the caller spreads into its
/// enclosing scrollable's `children`. Wrapping them in a single
/// widget's `Column` would break `tester.scrollUntilVisible` for the
/// reset/reminder rows (see `feedback_ci_column_in_listview.md`).
class VehicleExtrasSection {
  VehicleExtrasSection._();

  static List<Widget> build({
    required BuildContext context,
    required String vehicleId,
    required String? adapterMac,
    required String? adapterName,
    required void Function(String name, String mac) onAdapterPaired,
    required VoidCallback onAdapterForget,
    required VoidCallback onResetVolumetricEfficiency,
    required double? currentOdometerKm,
  }) {
    final l = AppLocalizations.of(context);
    return [
      // Card 3: OBD2 adapter pairing (#779). Stable vehicle id only.
      const SizedBox(height: 16),
      VehicleAdapterSection(
        adapterMac: adapterMac,
        adapterName: adapterName,
        onPaired: onAdapterPaired,
        onForget: onAdapterForget,
      ),
      // Baseline calibration section (#779). Only renders once a
      // vehicle is saved — hidden during the Add flow.
      const SizedBox(height: 16),
      VehicleBaselineSection(vehicleId: vehicleId),
      // Calibration mode toggle (#894) — rule vs fuzzy. Lives directly
      // under the baseline progress so users see what they're opting
      // into without jumping sections.
      const SizedBox(height: 12),
      VehicleCalibrationModeSelector(vehicleId: vehicleId),
      // η_v calibration reset (#815). Pairs visually with baseline
      // above — users who reset one often reset the other. Distinct
      // icon + label per #1219 so users can tell at a glance which
      // side of the calibration pipeline they're nuking — fuel-pump
      // glyph for the volumetric-efficiency constant.
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: onResetVolumetricEfficiency,
        icon: const Icon(Icons.local_gas_station_outlined),
        label: Text(l?.veResetAction ?? 'Reset volumetric efficiency'),
      ),
      // Service reminders (#584). Keyed by vehicle id; hidden on Add.
      const SizedBox(height: 16),
      ServiceReminderSection(
        vehicleId: vehicleId,
        currentOdometerKm: currentOdometerKm,
      ),
    ];
  }
}
