// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../providers/calibration_mode_providers.dart';
import '../../providers/vehicle_providers.dart';
import '../../../../core/error/guarded.dart';

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

  const VehicleCalibrationModeSelector({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // The vehicle-list provider can throw when its storage dependency
    // is not wired (e.g. isolated widget tests that pump this section
    // without a full app scope). Fall back to an empty profile in that
    // case rather than crashing the whole screen — the `id.isEmpty`
    // branch below then hides the selector.
    final profile = guard(
      () => ref
          .watch(vehicleProfileListProvider)
          .firstWhere(
            (v) => v.id == vehicleId,
            orElse: () => const VehicleProfile(id: '', name: ''),
          ),
      where: 'VehicleCalibrationModeSelector: profile lookup failed',
      fallback: const VehicleProfile(id: '', name: ''),
    );

    if (profile.id.isEmpty) {
      // Profile not yet saved — segmented button isn't wired.
      return const SizedBox.shrink();
    }

    final tooltip = l.calibrationModeTooltip;

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
                    l.calibrationModeLabel,
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
                  label: Text(l.calibrationModeRule),
                  icon: const Icon(Icons.rule),
                ),
                ButtonSegment(
                  value: VehicleCalibrationMode.fuzzy,
                  label: Text(l.calibrationModeFuzzy),
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
            // #3900 — one plain-language line per mode, so "Rule-based"
            // vs "Fuzzy" is a choice the user can make without opening
            // the tooltip. Rule = winner-take-all single bucket via fixed
            // thresholds; fuzzy = one weighted vote per neighbouring
            // bucket (trip_baseline_recorder → fuzzy_classifier).
            const SizedBox(height: 12),
            _ModeDescription(
              icon: Icons.rule,
              body: l.calibrationModeRuleDescription,
            ),
            const SizedBox(height: 6),
            _ModeDescription(
              icon: Icons.blur_circular,
              body: l.calibrationModeFuzzyDescription,
            ),
          ],
        ),
      ),
    );
  }
}

/// One "what this mode does" line under the segmented control (#3900),
/// led by the same glyph as its segment so the pairing reads at a glance.
class _ModeDescription extends StatelessWidget {
  final IconData icon;
  final String body;

  const _ModeDescription({required this.icon, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
