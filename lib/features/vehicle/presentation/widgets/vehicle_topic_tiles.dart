// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/vehicle_profile.dart';
import '../../../../core/error/guarded.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/settings_menu_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../trips/api.dart';
import '../../providers/service_reminder_providers.dart';
import '../../providers/vehicle_providers.dart';
import '../screens/topics/vehicle_edit_topic.dart';

/// The topic tiles of the Edit-vehicle editor (#3900, Epic #3897) —
/// one scannable row per sub-screen, each with a one-line status so the
/// user knows what is inside before opening it:
///
///   * OBD2 adapter — the paired adapter's name, or "None";
///   * Calibration (Advanced) — baseline coverage % + calibration mode;
///   * Service reminders — the reminder count;
///   * Auto-record — on / off.
///
/// Only rendered for a saved vehicle: every topic hangs off a stable id.
class VehicleTopicTiles extends ConsumerWidget {
  final String vehicleId;

  /// Live adapter name from the editor's form state (the adapter card
  /// persists in place, so this tracks the persisted profile too).
  final String? adapterName;
  final String? adapterMac;
  final ValueChanged<VehicleEditTopic> onOpenTopic;

  const VehicleTopicTiles({
    super.key,
    required this.vehicleId,
    required this.adapterName,
    required this.adapterMac,
    required this.onOpenTopic,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // The vehicle-list provider can throw when its storage dependency is
    // not wired (isolated widget tests); every status line then falls
    // back to its "nothing yet" reading rather than crashing the form.
    final profile = guard(
      () => ref
          .watch(vehicleProfileListProvider)
          .where((v) => v.id == vehicleId)
          .firstOrNull,
      where: 'VehicleTopicTiles: profile lookup failed',
      fallback: null as VehicleProfile?,
    );
    final paired = adapterMac != null && adapterMac!.isNotEmpty;
    final adapterStatus = !paired
        ? l.vehicleTopicAdapterNone
        : (adapterName == null || adapterName!.isEmpty
            ? l.vehicleAdapterUnnamed
            : adapterName!);
    final coverage = ref.baselineCoveragePercent(vehicleId);
    final mode = profile?.calibrationMode == VehicleCalibrationMode.fuzzy
        ? l.calibrationModeFuzzy
        : l.calibrationModeRule;
    final reminderCount = guard(
      () => ref.watch(serviceRemindersForVehicleProvider(vehicleId)).length,
      where: 'VehicleTopicTiles: reminder lookup failed',
      fallback: 0,
    );
    final autoRecord = profile?.autoRecord ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsMenuTile(
          key: const Key('vehicleTopic_adapter'),
          icon: Icons.bluetooth,
          title: l.vehicleAdapterSectionTitle,
          subtitle: adapterStatus,
          onTap: () => onOpenTopic(VehicleEditTopic.adapter),
        ),
        const SizedBox(height: 8),
        SettingsMenuTile(
          key: const Key('vehicleTopic_calibration'),
          icon: Icons.tune,
          title: l.vehicleTopicCalibrationTitle,
          subtitle: l.vehicleTopicCalibrationStatus(coverage, mode),
          badge: _AdvancedBadge(label: l.vehicleTopicAdvancedBadge),
          onTap: () => onOpenTopic(VehicleEditTopic.calibration),
        ),
        const SizedBox(height: 8),
        SettingsMenuTile(
          key: const Key('vehicleTopic_reminders'),
          icon: Icons.build_outlined,
          title: l.serviceRemindersSection,
          subtitle: l.vehicleTopicRemindersCount(reminderCount),
          onTap: () => onOpenTopic(VehicleEditTopic.reminders),
        ),
        const SizedBox(height: 8),
        SettingsMenuTile(
          key: const Key('vehicleTopic_autoRecord'),
          icon: Icons.fiber_manual_record_outlined,
          title: l.autoRecordSectionTitle,
          subtitle: autoRecord
              ? l.vehicleTopicAutoRecordOn
              : l.vehicleTopicAutoRecordOff,
          onTap: () => onOpenTopic(VehicleEditTopic.autoRecord),
        ),
      ],
    );
  }
}

/// Small outlined "Advanced" marker on the Calibration tile — the topic
/// is for users who want to tune the estimator, not a daily stop.
class _AdvancedBadge extends StatelessWidget {
  final String label;

  const _AdvancedBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: AppRadius.sm,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
