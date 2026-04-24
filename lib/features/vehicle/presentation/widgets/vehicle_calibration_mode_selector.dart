import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vehicle_profile.dart';
import '../../providers/calibration_mode_providers.dart';
import '../../providers/vehicle_providers.dart';

/// Rule / Fuzzy toggle for the vehicle baseline calibration (#894).
///
/// Shown on the edit-vehicle screen directly under the existing
/// baseline progress section. Defaults to [VehicleCalibrationMode.rule]
/// so any profile created before #894 looks unchanged. On change, we
/// re-save the profile with the new `calibrationMode` field — the
/// next trip's samples are classified accordingly. Existing learned
/// baselines are preserved (Welford counts don't reset on mode flip).
class VehicleCalibrationModeSelector extends ConsumerWidget {
  final String vehicleId;

  const VehicleCalibrationModeSelector({
    super.key,
    required this.vehicleId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // The vehicle-list provider can throw when its storage dependency
    // is not wired (e.g. isolated widget tests that pump this section
    // without a full app scope). Fall back to an empty card in that
    // case rather than crashing the whole screen.
    VehicleProfile profile;
    try {
      profile = ref.watch(vehicleProfileListProvider).firstWhere(
            (v) => v.id == vehicleId,
            orElse: () => const VehicleProfile(id: '', name: ''),
          );
    } catch (e) {
      debugPrint('VehicleCalibrationModeSelector: profile lookup failed: $e');
      return const SizedBox.shrink();
    }

    if (profile.id.isEmpty) {
      // Profile not yet saved — segmented button isn't wired.
      return const SizedBox.shrink();
    }

    final tooltip =
        l?.calibrationModeTooltip ??
            'Rule-based assigns each driving sample to exactly one '
                'situation. Fuzzy spreads it across all of them by how well '
                'each fits.';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.blur_on, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l?.calibrationModeLabel ?? 'Calibration mode',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Tooltip(
                  message: tooltip,
                  triggerMode: TooltipTriggerMode.tap,
                  showDuration: const Duration(seconds: 6),
                  child: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                    semanticLabel: tooltip,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<VehicleCalibrationMode>(
              key: const Key('calibrationModeSegmentedButton'),
              segments: [
                ButtonSegment(
                  value: VehicleCalibrationMode.rule,
                  label: Text(l?.calibrationModeRule ?? 'Rule-based'),
                  icon: const Icon(Icons.rule),
                ),
                ButtonSegment(
                  value: VehicleCalibrationMode.fuzzy,
                  label: Text(l?.calibrationModeFuzzy ?? 'Fuzzy'),
                  icon: const Icon(Icons.blur_circular),
                ),
              ],
              selected: {profile.calibrationMode},
              onSelectionChanged: (set) async {
                final next = set.first;
                if (next == profile.calibrationMode) return;
                await ref
                    .read(vehicleProfileListProvider.notifier)
                    .save(profile.copyWith(calibrationMode: next));
                // #894 — flipping mode schedules a replay so the last
                // trip's votes re-flow through the new classifier.
                ref
                    .read(calibrationReplayQueueProvider.notifier)
                    .requestReplay(vehicleId);
              },
            ),
          ],
        ),
      ),
    );
  }
}
