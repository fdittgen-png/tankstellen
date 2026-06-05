// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import '../../../search/domain/entities/fuel_type.dart';
import '../../data/vehicle_profile_catalog_matcher.dart';
import '../../domain/entities/reference_vehicle.dart';
import '../../domain/entities/vehicle_profile.dart';

/// Bundles the text controllers, focus node, and scalar form state
/// used by [EditVehicleScreen]. Keeps the screen class focused on
/// build-method composition and async actions while centralising
/// controller lifetime and profile round-tripping in one place.
///
/// All fields are plain instance state — the owner is still a
/// StatefulWidget's `State`, which must call [load] from
/// [widget.vehicleId] lookup logic and [dispose] from its own
/// `dispose`. The form-state flags ([type], [connectors], adapter
/// ids, decoded engine ids) live on the screen since they drive
/// `setState` rebuilds.
class VehicleFormControllers {
  static const _uuid = Uuid();

  final nameController = TextEditingController();
  final batteryController = TextEditingController();
  final maxChargingKwController = TextEditingController();
  final tankController = TextEditingController();
  // #710 — pre-fill E10 so the Preferred-fuel dropdown isn't "Not set".
  final fuelTypeController = TextEditingController(text: 'e10');
  final minSocController = TextEditingController(text: '20');
  final maxSocController = TextEditingController(text: '80');
  final vinController = TextEditingController();
  final vinFocusNode = FocusNode();

  /// Copy the saved [profile] fields into the text controllers.
  /// Non-controller fields (type, connectors, engine ids, adapter
  /// ids) are returned as a snapshot for the caller to copy into
  /// its own state fields.
  VehicleFormSnapshot load(VehicleProfile profile) {
    nameController.text = profile.name;
    batteryController.text = profile.batteryKwh?.toString() ?? '';
    maxChargingKwController.text = profile.maxChargingKw?.toString() ?? '';
    tankController.text = profile.tankCapacityL?.toString() ?? '';
    fuelTypeController.text = profile.preferredFuelType ?? '';
    minSocController.text =
        profile.chargingPreferences.minSocPercent.toString();
    maxSocController.text =
        profile.chargingPreferences.maxSocPercent.toString();
    vinController.text = profile.vin ?? '';
    return VehicleFormSnapshot(
      id: profile.id,
      type: profile.type,
      connectors: {...profile.supportedConnectors},
      adapterMac: profile.obd2AdapterMac,
      adapterName: profile.obd2AdapterName,
      engineDisplacementCc: profile.engineDisplacementCc,
      engineCylinders: profile.engineCylinders,
      curbWeightKg: profile.curbWeightKg,
      multiFuelCapable: profile.multiFuelCapable,
    );
  }

  /// Pre-fill the controllers from a [ReferenceVehicle] catalog entry
  /// (#1372 phase 3). Called after the user picks a row in the
  /// [ReferenceVehiclePicker] modal sheet.
  ///
  /// Sets:
  ///   * [nameController] to `<make> <model>` so the brand-tinted
  ///     header on the edit screen lights up immediately.
  ///   * [fuelTypeController] to a sensible
  ///     [VehicleProfile.preferredFuelType] derived from the catalog's
  ///     coarse `petrol`/`diesel`/`hybrid`/`electric` enum:
  ///       * `petrol` → `e10`   (the default for unleaded blends)
  ///       * `diesel` → `diesel`
  ///       * `hybrid` → `e10`   (most EU PHEVs are petrol-burning)
  ///       * `electric` → `''`  (the EV section owns the connector
  ///                            picker; no preferred fuel applies)
  ///
  /// All other catalog-derived fields (engine displacement, volumetric
  /// efficiency, slug, make/model/year metadata) are owned by the
  /// screen's scalar state since they aren't text-controller-backed —
  /// the screen reads the picked entry directly.
  void applyReferenceVehicle(ReferenceVehicle ref) {
    nameController.text = '${ref.make} ${ref.model}'.trim();
    fuelTypeController.text = _preferredFuelTypeFor(ref.fuelType);
  }

  /// Map the catalog's coarse fuel-type string onto a
  /// [VehicleProfile.preferredFuelType] code (the same string the
  /// `NullableFuelTypeDropdown` consumes). `electric` returns the
  /// empty string so the EV path doesn't surface a meaningless
  /// preferred-petrol selection.
  /// #2885 — the flex-fuel petrol grades (E10 / E85) the multi-fuel
  /// comparison targets. Mirrors `VehicleCombustionSection._offersMultiFuel`
  /// so the persisted flag can never disagree with the rendered switch.
  static bool _offersMultiFuel(FuelType fuel) =>
      fuelCompatibilityFamily(fuel) == FuelCompatibilityFamily.petrol &&
      (fuel == FuelType.e10 || fuel == FuelType.e85);

  static String _preferredFuelTypeFor(String catalogFuelType) {
    switch (catalogFuelType.toLowerCase()) {
      case 'diesel':
        return 'diesel';
      case 'electric':
        return '';
      case 'hybrid':
      case 'petrol':
      default:
        return 'e10';
    }
  }

  /// Construct a [VehicleProfile] from the current controller values
  /// combined with the non-controller state passed in by the caller.
  ///
  /// When [existing] is non-null, the result is `existing.copyWith(...)` —
  /// every field NOT managed by this form (calibration mode, paired
  /// adapter MAC, autoRecord and friends, runtime-calibrated η_v,
  /// driving-stats aggregates, VIN-decode metadata, ...) is preserved
  /// verbatim. This closes the architectural bug class behind #1226 /
  /// #1217: the previous `buildProfile` returned a fresh
  /// `VehicleProfile(...)` and silently overwrote any field that wasn't
  /// in its parameter list with the freezed `@Default`. Threading every
  /// new field through the form (the #1221 minimum-scope fix for
  /// `calibrationMode`) doesn't scale; copyWith is silently-correct for
  /// every existing AND future field.
  ///
  /// When [existing] is null, the new-vehicle path mints a fresh uuid
  /// and constructs from defaults — no `VehicleProfile` to preserve.
  ///
  /// [referenceVehicle] is the catalog entry the user picked from the
  /// new-vehicle picker (#1372 phase 3), or `null` when the user typed
  /// every field by hand. When non-null, it threads the catalog-only
  /// metadata (`make`, `model`, `year`, `referenceVehicleId`,
  /// `volumetricEfficiency`) into the new profile so the OBD2 layer can
  /// resolve the engine quirks without the user having to wait for the
  /// VIN-driven backfill to land later.
  VehicleProfile buildProfile({
    required VehicleProfile? existing,
    required VehicleType type,
    required Set<ConnectorType> connectors,
    required String? adapterMac,
    required String? adapterName,
    required int? engineDisplacementCc,
    required int? engineCylinders,
    required int? curbWeightKg,
    bool multiFuelCapable = false,
    ReferenceVehicle? referenceVehicle,
  }) {
    final batteryKwh = type == VehicleType.combustion
        ? null
        : _parseDouble(batteryController.text);
    final maxChargingKw = type == VehicleType.combustion
        ? null
        : _parseDouble(maxChargingKwController.text);
    final supportedConnectors =
        type == VehicleType.combustion ? <ConnectorType>{} : {...connectors};
    final tankCapacityL =
        type == VehicleType.ev ? null : _parseDouble(tankController.text);
    final preferredFuelType = type == VehicleType.ev
        ? null
        : (fuelTypeController.text.trim().isEmpty
            ? null
            : fuelTypeController.text.trim());
    // #2885 — only persist the multi-fuel flag for an E10 / E85 petrol
    // vehicle (the grades the per-fuel comparison serves). A diesel / EV /
    // LPG vehicle, or a petrol car flipped to E5 / E98, always saves
    // `false` so a stale flag from a prior fuel can never linger.
    final effectiveMultiFuel = type != VehicleType.ev &&
        preferredFuelType != null &&
        _offersMultiFuel(FuelType.fromString(preferredFuelType)) &&
        multiFuelCapable;
    final chargingPreferences = ChargingPreferences(
      minSocPercent: _parseIntOr(minSocController.text, 20).clamp(0, 100),
      maxSocPercent: _parseIntOr(maxSocController.text, 80).clamp(0, 100),
    );
    final vin = vinController.text.trim().isEmpty
        ? null
        : vinController.text.trim();

    if (existing == null) {
      // `referenceVehicle` is only ever non-null on the new-vehicle
      // path (the picker is hidden in edit mode to avoid silently
      // overwriting user tweaks). When set, prefer the catalog values
      // for the engine + catalog-metadata fields the user can't
      // possibly have edited yet — they pre-populated the form by
      // tapping a row.
      final pickedDisplacement =
          referenceVehicle?.displacementCc ?? engineDisplacementCc;
      final pickedVe = referenceVehicle?.volumetricEfficiency ?? 0.85;
      final pickedMake = referenceVehicle?.make;
      final pickedModel = referenceVehicle?.model;
      final pickedYear = referenceVehicle?.yearStart;
      final pickedSlug = referenceVehicle == null
          ? null
          : VehicleProfileCatalogMatcher.slugFor(referenceVehicle);

      return VehicleProfile(
        id: _uuid.v4(),
        name: nameController.text.trim(),
        type: type,
        batteryKwh: batteryKwh,
        maxChargingKw: maxChargingKw,
        supportedConnectors: supportedConnectors,
        tankCapacityL: tankCapacityL,
        preferredFuelType: preferredFuelType,
        multiFuelCapable: effectiveMultiFuel,
        chargingPreferences: chargingPreferences,
        obd2AdapterMac: adapterMac,
        obd2AdapterName: adapterName,
        vin: vin,
        engineDisplacementCc: pickedDisplacement,
        engineCylinders: engineCylinders,
        curbWeightKg: curbWeightKg,
        volumetricEfficiency: pickedVe,
        make: pickedMake,
        model: pickedModel,
        year: pickedYear,
        referenceVehicleId: pickedSlug,
      );
    }

    // Edit path — copyWith preserves every non-form field on the
    // loaded profile: calibrationMode, pairedAdapterMac,
    // volumetricEfficiency / volumetricEfficiencySamples, autoRecord
    // and friends, the *_aggregates pack, referenceVehicleId, etc.
    return existing.copyWith(
      name: nameController.text.trim(),
      type: type,
      batteryKwh: batteryKwh,
      maxChargingKw: maxChargingKw,
      supportedConnectors: supportedConnectors,
      tankCapacityL: tankCapacityL,
      preferredFuelType: preferredFuelType,
      multiFuelCapable: effectiveMultiFuel,
      chargingPreferences: chargingPreferences,
      obd2AdapterMac: adapterMac,
      obd2AdapterName: adapterName,
      vin: vin,
      engineDisplacementCc: engineDisplacementCc,
      engineCylinders: engineCylinders,
      curbWeightKg: curbWeightKg,
    );
  }

  // #1693 — unsaved-changes tracking for the discard guard.
  Map<String, String> _baseline = const {};

  Map<String, String> _currentValues() => {
        'name': nameController.text,
        'battery': batteryController.text,
        'maxKw': maxChargingKwController.text,
        'tank': tankController.text,
        'fuel': fuelTypeController.text,
        'minSoc': minSocController.text,
        'maxSoc': maxSocController.text,
        'vin': vinController.text,
      };

  /// Capture the current controller values as the "clean" baseline.
  /// The screen calls this once the form is populated — after [load]
  /// for an existing vehicle, or right after construction for a new
  /// one — so [isDirty] can tell whether the user has edited anything.
  void snapshotBaseline() => _baseline = _currentValues();

  /// True when any text field differs from the captured baseline.
  /// Returns false until [snapshotBaseline] has run, so the guard
  /// never fires spuriously in the pre-load frame.
  bool get isDirty {
    if (_baseline.isEmpty) return false;
    final current = _currentValues();
    for (final entry in current.entries) {
      if (_baseline[entry.key] != entry.value) return true;
    }
    return false;
  }

  void dispose() {
    nameController.dispose();
    batteryController.dispose();
    maxChargingKwController.dispose();
    tankController.dispose();
    fuelTypeController.dispose();
    minSocController.dispose();
    maxSocController.dispose();
    vinController.dispose();
    vinFocusNode.dispose();
  }

  static double? _parseDouble(String text) {
    final trimmed = text.trim().replaceAll(',', '.');
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  static int _parseIntOr(String text, int fallback) =>
      int.tryParse(text.trim()) ?? fallback;
}

/// Snapshot of the non-controller fields on a loaded profile, so the
/// owning state can copy them into its own `setState` locals.
class VehicleFormSnapshot {
  final String id;
  final VehicleType type;
  final Set<ConnectorType> connectors;
  final String? adapterMac;
  final String? adapterName;
  final int? engineDisplacementCc;
  final int? engineCylinders;
  final int? curbWeightKg;
  final bool multiFuelCapable;

  VehicleFormSnapshot({
    required this.id,
    required this.type,
    required this.connectors,
    required this.adapterMac,
    required this.adapterName,
    required this.engineDisplacementCc,
    required this.engineCylinders,
    required this.curbWeightKg,
    required this.multiFuelCapable,
  });
}
