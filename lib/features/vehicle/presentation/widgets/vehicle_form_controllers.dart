import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

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
      pairedAdapterMac: profile.pairedAdapterMac,
      engineDisplacementCc: profile.engineDisplacementCc,
      engineCylinders: profile.engineCylinders,
      curbWeightKg: profile.curbWeightKg,
    );
  }

  /// Construct a [VehicleProfile] from the current controller values
  /// combined with the non-controller state passed in by the caller.
  ///
  /// When [existing] is non-null, the result starts from
  /// `existing.copyWith(...)` and only overwrites the fields the form
  /// actually edits — everything else (e.g. the long-lived
  /// `pairedAdapterMac`, the auto-record toggle, learned volumetric
  /// efficiency, the driving aggregates, the reference-catalog ids)
  /// is preserved automatically. This is the architectural fix for
  /// #1217: previously, every Save constructed a brand-new profile
  /// from a fixed parameter list, silently wiping any field that
  /// wasn't on that list back to its `@Default(...)`.
  ///
  /// When [existing] is null (the "Add vehicle" path), the new profile
  /// is built from defaults with a freshly minted uuid.
  VehicleProfile buildProfile({
    required VehicleProfile? existing,
    required VehicleType type,
    required Set<ConnectorType> connectors,
    required String? adapterMac,
    required String? adapterName,
    required int? engineDisplacementCc,
    required int? engineCylinders,
    required int? curbWeightKg,
  }) {
    // Compute the form-derived values once — they're the same whether
    // we're creating a new profile or copying an existing one.
    final name = nameController.text.trim();
    final isCombustion = type == VehicleType.combustion;
    final isEv = type == VehicleType.ev;
    final batteryKwh =
        isCombustion ? null : _parseDouble(batteryController.text);
    final maxChargingKw =
        isCombustion ? null : _parseDouble(maxChargingKwController.text);
    final supportedConnectors =
        isCombustion ? <ConnectorType>{} : {...connectors};
    final tankCapacityL =
        isEv ? null : _parseDouble(tankController.text);
    final preferredFuelType = isEv
        ? null
        : (fuelTypeController.text.trim().isEmpty
            ? null
            : fuelTypeController.text.trim());
    final chargingPreferences = ChargingPreferences(
      minSocPercent: _parseIntOr(minSocController.text, 20).clamp(0, 100),
      maxSocPercent: _parseIntOr(maxSocController.text, 80).clamp(0, 100),
    );
    final vin = vinController.text.trim().isEmpty
        ? null
        : vinController.text.trim();

    if (existing != null) {
      // Preserve every non-form field by starting from the saved
      // profile and only overwriting what the form actually edits.
      // The EV/combustion type-flip rules (null out battery/tank/etc.
      // when switching across types) are still applied above and
      // flow through copyWith here.
      return existing.copyWith(
        name: name,
        type: type,
        batteryKwh: batteryKwh,
        maxChargingKw: maxChargingKw,
        supportedConnectors: supportedConnectors,
        chargingPreferences: chargingPreferences,
        tankCapacityL: tankCapacityL,
        preferredFuelType: preferredFuelType,
        obd2AdapterMac: adapterMac,
        obd2AdapterName: adapterName,
        vin: vin,
        engineDisplacementCc: engineDisplacementCc,
        engineCylinders: engineCylinders,
        curbWeightKg: curbWeightKg,
      );
    }

    return VehicleProfile(
      id: _uuid.v4(),
      name: name,
      type: type,
      batteryKwh: batteryKwh,
      maxChargingKw: maxChargingKw,
      supportedConnectors: supportedConnectors,
      tankCapacityL: tankCapacityL,
      preferredFuelType: preferredFuelType,
      chargingPreferences: chargingPreferences,
      obd2AdapterMac: adapterMac,
      obd2AdapterName: adapterName,
      vin: vin,
      engineDisplacementCc: engineDisplacementCc,
      engineCylinders: engineCylinders,
      curbWeightKg: curbWeightKg,
    );
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

  /// Long-lived "this adapter belongs to this car" marker (#1004).
  /// Distinct from [adapterMac] — that field holds the currently-
  /// connected adapter from the OBD2 picker. The read-VIN-from-car
  /// button (#1162) gates on this field.
  final String? pairedAdapterMac;

  final int? engineDisplacementCc;
  final int? engineCylinders;
  final int? curbWeightKg;

  VehicleFormSnapshot({
    required this.id,
    required this.type,
    required this.connectors,
    required this.adapterMac,
    required this.adapterName,
    required this.pairedAdapterMac,
    required this.engineDisplacementCc,
    required this.engineCylinders,
    required this.curbWeightKg,
  });
}
