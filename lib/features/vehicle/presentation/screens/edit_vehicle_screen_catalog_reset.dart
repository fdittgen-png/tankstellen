// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'edit_vehicle_screen.dart';

/// #3651 — the reset-from-vehicle-database action, split out of
/// `_VehicleEditActions` as its own `part` mixin to keep the actions
/// file under the #1680 length ratchet. Constrained `on
/// _VehicleEditActions` so it reads the same private form state
/// (`_existingId`, `_ctrl`, `_engineDisplacementCc`) the other actions
/// own; the State applies it after `_VehicleEditActions`.
mixin _VehicleCatalogResetAction on _VehicleEditActions {
  /// #3651 — re-initialize the catalog-backed spec fields (tank
  /// capacity, rated power, displacement) from the reference vehicle
  /// database, after an explicit confirm. The η_v calibration keeps its
  /// own dedicated reset (#815) — this action is about the static
  /// manufacturer spec, not the learned state.
  Future<void> _resetFromCatalog() async {
    final id = _existingId;
    if (id == null) return;
    final l = AppLocalizations.of(context);
    final existing = ref
        .read(vehicleProfileListProvider)
        .where((v) => v.id == id)
        .firstOrNull;
    if (existing == null) return;

    final catalog = ref.read(referenceVehicleCatalogProvider).value ??
        const <ReferenceVehicle>[];
    final match = VehicleProfileCatalogMatcher.confidentMatch(
      profile: existing,
      catalog: catalog,
    );
    if (match == null) {
      SnackBarHelper.show(context, l.catalogResetNoMatchSnackbar);
      return;
    }

    final confirmed = await CatalogResetConfirmDialog.show(
      context,
      '${match.make} ${match.model} ${match.generation}',
    );
    if (confirmed != true || !mounted) return;

    // Only overwrite from fields the catalog actually has — a row
    // without a curated capacity/power leaves the profile value alone.
    final updated = existing.copyWith(
      tankCapacityL: match.tankCapacityL ?? existing.tankCapacityL,
      enginePowerKw: match.powerKw ?? existing.enginePowerKw,
      engineDisplacementCc: match.displacementCc,
      referenceVehicleId: VehicleProfileCatalogMatcher.slugFor(match),
    );
    await ref.read(vehicleProfileListProvider.notifier).save(updated);
    if (!mounted) return;
    setState(() {
      _engineDisplacementCc = updated.engineDisplacementCc;
      _ctrl.load(updated);
    });
    SnackBarHelper.show(context, l.catalogResetDoneSnackbar);
  }

}
