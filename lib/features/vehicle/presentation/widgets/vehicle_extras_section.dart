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
    final theme = Theme.of(context);
    return [
      // Card 3: OBD2 adapter pairing (#779). Stable vehicle id only.
      const SizedBox(height: 16),
      VehicleAdapterSection(
        adapterMac: adapterMac,
        adapterName: adapterName,
        onPaired: onAdapterPaired,
        onForget: onAdapterForget,
      ),
      // Calibration group (#1219) — wraps both reset actions in a single
      // visually-grouped card with one-line captions. The two resets
      // clear different state (Welford samples vs η_v constant) so they
      // need distinct labels and icons; the grouping makes the relation
      // obvious without putting them on the same row.
      const SizedBox(height: 16),
      Card(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                l?.calibrationGroupTitle ?? 'Calibration',
                style: theme.textTheme.titleMedium,
              ),
            ),
            // Driving-situation baseline (#779) — its own progress bars
            // and reset button + caption live inside this section.
            VehicleBaselineSection(vehicleId: vehicleId),
            const Divider(height: 1),
            // η_v calibration reset (#815). Distinct label + caption +
            // icon disambiguate it from the baseline reset above.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: onResetVolumetricEfficiency,
                    icon: const Icon(Icons.tune),
                    label: Text(
                      l?.veResetAction ?? 'Reset volumetric efficiency',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l?.veResetCaption ??
                        'Drops the learned η_v constant back to default '
                            '0.85 — needs new OBD2 trips to re-converge.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Calibration mode toggle (#894) — rule vs fuzzy. Lives directly
      // under the calibration card so users see what they're opting
      // into without jumping sections.
      const SizedBox(height: 12),
      VehicleCalibrationModeSelector(vehicleId: vehicleId),
      // Service reminders (#584). Keyed by vehicle id; hidden on Add.
      const SizedBox(height: 16),
      ServiceReminderSection(
        vehicleId: vehicleId,
        currentOdometerKm: currentOdometerKm,
      ),
    ];
  }
}
