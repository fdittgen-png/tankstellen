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
      calibrationMode: profile.calibrationMode,
    );
  }

  /// Construct a [VehicleProfile] from the current controller values
  /// combined with the non-controller state passed in by the caller.
  ///
  /// [calibrationMode] is threaded through verbatim so the screen-
  /// level Save path doesn't clobber a value the
  /// [VehicleCalibrationModeSelector] persisted moments earlier
  /// (#1217). Defaults to [VehicleCalibrationMode.rule] to match the
  /// freezed default for new profiles where the caller has no live
  /// value to pass in.
  VehicleProfile buildProfile({
    required String? existingId,
    required VehicleType type,
    required Set<ConnectorType> connectors,
    required String? adapterMac,
    required String? adapterName,
    required int? engineDisplacementCc,
    required int? engineCylinders,
    required int? curbWeightKg,
    VehicleCalibrationMode calibrationMode = VehicleCalibrationMode.rule,
  }) {
    return VehicleProfile(
      id: existingId ?? _uuid.v4(),
      name: nameController.text.trim(),
      type: type,
      batteryKwh: type == VehicleType.combustion
          ? null
          : _parseDouble(batteryController.text),
      maxChargingKw: type == VehicleType.combustion
          ? null
          : _parseDouble(maxChargingKwController.text),
      supportedConnectors:
          type == VehicleType.combustion ? <ConnectorType>{} : {...connectors},
      tankCapacityL:
          type == VehicleType.ev ? null : _parseDouble(tankController.text),
      preferredFuelType: type == VehicleType.ev
          ? null
          : (fuelTypeController.text.trim().isEmpty
              ? null
              : fuelTypeController.text.trim()),
      chargingPreferences: ChargingPreferences(
        minSocPercent: _parseIntOr(minSocController.text, 20).clamp(0, 100),
        maxSocPercent: _parseIntOr(maxSocController.text, 80).clamp(0, 100),
      ),
      obd2AdapterMac: adapterMac,
      obd2AdapterName: adapterName,
      vin: vinController.text.trim().isEmpty
          ? null
          : vinController.text.trim(),
      engineDisplacementCc: engineDisplacementCc,
      engineCylinders: engineCylinders,
      curbWeightKg: curbWeightKg,
      calibrationMode: calibrationMode,
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

  /// Calibration mode (#894) carried out of [VehicleFormControllers.load]
  /// so the screen can seed its live state and pass the value back
  /// through [VehicleFormControllers.buildProfile] on save (#1217).
  final VehicleCalibrationMode calibrationMode;

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
    this.calibrationMode = VehicleCalibrationMode.rule,
  });
}
