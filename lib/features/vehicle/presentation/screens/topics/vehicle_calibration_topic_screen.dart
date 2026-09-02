// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/domain/vehicle_profile.dart';
import '../../../../../core/error/guarded.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../trips/api.dart';
import '../../../data/reference_vehicle_catalog_provider.dart';
import '../../../data/vehicle_profile_catalog_matcher.dart';
import '../../../domain/entities/reference_vehicle.dart';
import '../../../providers/vehicle_providers.dart';
import '../../widgets/calibration_section.dart';
import '../../widgets/vehicle_calibration_mode_selector.dart';
import 'vehicle_topic_scaffold.dart';

/// Edit vehicle → "Calibration" topic (#3900, the Advanced topic): the
/// baseline coverage (#779), the rule / fuzzy calibration mode (#894),
/// the collapsed advanced-override card (#1397), the broken-MAP
/// diagnostics (#1622) and the reset actions.
///
/// Every control here persists on its own (through its provider or the
/// editor's `_saveCalibrationOverride` / reset actions) — nothing waits
/// for the top-level Save, so leaving the screen never loses a change.
class VehicleCalibrationTopicScreen extends ConsumerWidget {
  final String vehicleId;
  final ValueChanged<double?> onDisplacementChanged;
  final ValueChanged<double?> onVolumetricEfficiencyChanged;
  final ValueChanged<double?> onAfrChanged;
  final ValueChanged<double?> onFuelDensityChanged;

  /// #3901 — discard the learned pump-anchored fuel gain (Epic #3886).
  final VoidCallback onResetPumpGain;

  /// #3651 — re-initialize the catalog-backed spec fields from the
  /// reference vehicle database (confirm dialog owned by the editor).
  final VoidCallback onResetFromCatalog;

  const VehicleCalibrationTopicScreen({
    super.key,
    required this.vehicleId,
    required this.onDisplacementChanged,
    required this.onVolumetricEfficiencyChanged,
    required this.onAfrChanged,
    required this.onFuelDensityChanged,
    required this.onResetPumpGain,
    required this.onResetFromCatalog,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return VehicleTopicScaffold(
      title: l.vehicleTopicCalibrationTitle,
      children: [
        // Baseline calibration section (#779).
        VehicleBaselineSection(vehicleId: vehicleId),
        // Calibration mode toggle (#894) — rule vs fuzzy. Lives directly
        // under the baseline progress so users see what they're opting
        // into without jumping sections.
        const SizedBox(height: 12),
        VehicleCalibrationModeSelector(vehicleId: vehicleId),
        const SizedBox(height: 16),
        // #1397 — collapsed-by-default override tile for the four physics
        // constants the OBD2 estimator uses. Each row labels its source.
        _AdvancedCalibrationCard(
          vehicleId: vehicleId,
          onDisplacementChanged: onDisplacementChanged,
          onVolumetricEfficiencyChanged: onVolumetricEfficiencyChanged,
          onAfrChanged: onAfrChanged,
          onFuelDensityChanged: onFuelDensityChanged,
        ),
        // #1622 — broken-MAP + adapter-blocklist diagnostics (collapses
        // when there's nothing to show).
        const SizedBox(height: 16),
        BrokenMapDiagnosticsCard(vehicleId: vehicleId),
        // Pump-calibration reset (#3901). Distinct icon + label per #1219
        // so users can tell at a glance which side of the calibration
        // pipeline they're nuking — fuel-pump glyph for the pump gain.
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('pumpGainResetButton'),
          onPressed: onResetPumpGain,
          icon: const Icon(Icons.local_gas_station_outlined),
          label: Text(l.pumpGainResetAction),
        ),
        // #3651 — re-initialize the catalog-backed spec fields (tank
        // capacity, rated power, displacement) from the reference
        // vehicle database. Distinct restore glyph so it can't be
        // mistaken for the calibration reset above.
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onResetFromCatalog,
          icon: const Icon(Icons.settings_backup_restore),
          label: Text(l.catalogResetAction),
        ),
      ],
    );
  }
}

/// Resolves the profile + its reference-catalog row for the
/// [CalibrationSection] (#1422 phase 2 origin tag) and the direct-fuel-
/// rate flag (#2837). Hidden while the profile is not loaded yet.
class _AdvancedCalibrationCard extends ConsumerWidget {
  final String vehicleId;
  final ValueChanged<double?> onDisplacementChanged;
  final ValueChanged<double?> onVolumetricEfficiencyChanged;
  final ValueChanged<double?> onAfrChanged;
  final ValueChanged<double?> onFuelDensityChanged;

  const _AdvancedCalibrationCard({
    required this.vehicleId,
    required this.onDisplacementChanged,
    required this.onVolumetricEfficiencyChanged,
    required this.onAfrChanged,
    required this.onFuelDensityChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = guard(
      () => ref
          .watch(vehicleProfileListProvider)
          .where((v) => v.id == vehicleId)
          .firstOrNull,
      where: 'VehicleCalibrationTopicScreen: profile lookup failed',
      fallback: null as VehicleProfile?,
    );
    if (profile == null) return const SizedBox.shrink();
    // #1422 phase 2 — resolve the matching ReferenceVehicle (by slug,
    // else via the matcher) for the η_v origin tag. Catalog provider
    // is keep-alive, so this watch is cheap.
    final catalog = ref.watch(referenceVehicleCatalogProvider).value ??
        const <ReferenceVehicle>[];
    ReferenceVehicle? referenceVehicle;
    if (profile.referenceVehicleId != null) {
      for (final entry in catalog) {
        if (VehicleProfileCatalogMatcher.slugFor(entry) ==
            profile.referenceVehicleId) {
          referenceVehicle = entry;
          break;
        }
      }
    }
    referenceVehicle ??= VehicleProfileCatalogMatcher.bestMatch(
      profile: profile,
      catalog: catalog,
    );
    // #2837 — when this vehicle reports fuel rate directly (PID 5E /
    // MAF), the η_v calibration is irrelevant; de-emphasise it.
    final directFuelRate = vehicleReportsDirectFuelRate(
      // #3613 — the detector reads vehicleId + summary only.
      ref.watch(tripHistoryRepositoryProvider)?.loadSummaries() ?? const [],
      vehicleId: profile.id,
    );
    return CalibrationSection(
      profile: profile,
      referenceVehicle: referenceVehicle,
      directFuelRateSupported: directFuelRate,
      onDisplacementChanged: onDisplacementChanged,
      onVolumetricEfficiencyChanged: onVolumetricEfficiencyChanged,
      onAfrChanged: onAfrChanged,
      onFuelDensityChanged: onFuelDensityChanged,
    );
  }
}
