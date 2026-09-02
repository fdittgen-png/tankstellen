// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'edit_vehicle_screen.dart';

/// #3900 — the topic navigation of the Edit-vehicle editor, split out of
/// `_VehicleEditActions` as its own `part` mixin. Constrained `on
/// _VehicleEditActions` so it hands the topic screens the SAME private
/// action closures the long page used to wire inline (`_onAdapterChanged`,
/// `_saveCalibrationOverride`, the resets) — the editor stays the single
/// owner of the form state and every sub-screen persists through it.
///
/// Save model: nothing on a topic screen waits for the top-level Save.
/// The adapter card persists in place (#2960, building from the live
/// controllers so unsaved identity edits ride along), and every other
/// control (baseline reset, calibration mode, overrides, reminders,
/// auto-record) writes through its own provider on change. The pinned
/// Save therefore stays on the top level and only covers the inline
/// identity & engine fields — no save-on-pop is needed.
mixin _VehicleEditTopics on _VehicleCatalogResetAction {
  /// Push the topic screen for [topic]. Plain [Navigator.push] (no
  /// GoRoute): the screen needs the editor's private closures, which a
  /// route table cannot carry. No-op for an unsaved vehicle.
  Future<void> _openTopic(VehicleEditTopic topic) async {
    final id = _existingId;
    if (id == null) return;
    final Widget screen = switch (topic) {
      VehicleEditTopic.adapter => VehicleAdapterTopicScreen(
          vehicleId: id,
          onPaired: _onAdapterChanged,
          onForget: () => _onAdapterChanged(null, null),
        ),
      VehicleEditTopic.calibration => VehicleCalibrationTopicScreen(
          vehicleId: id,
          onDisplacementChanged: (v) =>
              _saveCalibrationOverride(manualEngineDisplacementCcOverride: v),
          onVolumetricEfficiencyChanged: (v) =>
              _saveCalibrationOverride(manualVolumetricEfficiencyOverride: v),
          onAfrChanged: (v) => _saveCalibrationOverride(manualAfrOverride: v),
          onFuelDensityChanged: (v) =>
              _saveCalibrationOverride(manualFuelDensityGPerLOverride: v),
          onResetVolumetricEfficiency: _resetVolumetricEfficiency,
          onResetFromCatalog: _resetFromCatalog,
        ),
      VehicleEditTopic.reminders =>
        VehicleServiceRemindersTopicScreen(vehicleId: id),
      VehicleEditTopic.autoRecord => VehicleAutoRecordTopicScreen(
          vehicleId: id,
          onOpenAdapterTopic: () => _openTopic(VehicleEditTopic.adapter),
        ),
    };
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }
}
