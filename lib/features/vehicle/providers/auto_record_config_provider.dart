import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/entities/vehicle_profile.dart';
import 'vehicle_providers.dart';

part 'auto_record_config_provider.g.dart';

/// Hands-free auto-record configuration projection for a single
/// [VehicleProfile] (#1004 phase 1).
///
/// Surfaces only the five auto-record fields so phase 2+ consumers
/// (BT auto-connect listener, movement detector, disconnect-save
/// timer, badge counter) cannot accidentally read or hold a
/// reference to the larger [VehicleProfile] state — keeps the
/// background-isolate API surface minimal.
///
/// Defaults mirror the [VehicleProfile] field defaults so a missing
/// or unknown profile id is indistinguishable from a freshly-saved,
/// not-yet-opted-in profile from the consumer's perspective.
class AutoRecordConfig {
  /// Master toggle. When `false`, phase 2 must not register a
  /// background BT listener for this vehicle.
  final bool autoRecord;

  /// MAC of the OBD2 adapter the user paired to this vehicle.
  /// Null when no adapter has been paired yet — phase 2 must skip
  /// auto-connect registration in that case.
  final String? pairedAdapterMac;

  /// Speed threshold (km/h) above which phase 3's movement detector
  /// fires `startTrip()`.
  final double movementStartThresholdKmh;

  /// Debounce window (seconds) before a BT disconnect triggers
  /// phase 4's `stopAndSave()`.
  final int disconnectSaveDelaySec;

  /// User's stored consent for `ACCESS_BACKGROUND_LOCATION`. Without
  /// it, phase 3 records BT-only with no GPS metadata.
  final bool backgroundLocationConsent;

  const AutoRecordConfig({
    this.autoRecord = false,
    this.pairedAdapterMac,
    this.movementStartThresholdKmh = 5.0,
    this.disconnectSaveDelaySec = 60,
    this.backgroundLocationConsent = false,
  });

  /// All-default fallback used when [autoRecordConfig] is queried for
  /// a profile id that does not exist (e.g. the active profile was
  /// deleted in another isolate). Equivalent to a freshly-created
  /// [VehicleProfile] that has not opted in.
  static const AutoRecordConfig defaults = AutoRecordConfig();

  /// Project a [VehicleProfile] into its auto-record config slice.
  factory AutoRecordConfig.fromProfile(VehicleProfile profile) {
    return AutoRecordConfig(
      autoRecord: profile.autoRecord,
      pairedAdapterMac: profile.pairedAdapterMac,
      movementStartThresholdKmh: profile.movementStartThresholdKmh,
      disconnectSaveDelaySec: profile.disconnectSaveDelaySec,
      backgroundLocationConsent: profile.backgroundLocationConsent,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AutoRecordConfig &&
        other.autoRecord == autoRecord &&
        other.pairedAdapterMac == pairedAdapterMac &&
        other.movementStartThresholdKmh == movementStartThresholdKmh &&
        other.disconnectSaveDelaySec == disconnectSaveDelaySec &&
        other.backgroundLocationConsent == backgroundLocationConsent;
  }

  @override
  int get hashCode => Object.hash(
        autoRecord,
        pairedAdapterMac,
        movementStartThresholdKmh,
        disconnectSaveDelaySec,
        backgroundLocationConsent,
      );

  @override
  String toString() =>
      'AutoRecordConfig(autoRecord: $autoRecord, '
      'pairedAdapterMac: $pairedAdapterMac, '
      'movementStartThresholdKmh: $movementStartThresholdKmh, '
      'disconnectSaveDelaySec: $disconnectSaveDelaySec, '
      'backgroundLocationConsent: $backgroundLocationConsent)';
}

/// Per-vehicle auto-record configuration (#1004 phase 1).
///
/// Reads the [VehicleProfile] identified by [vehicleProfileId] from
/// [vehicleProfileListProvider] and projects it into a small
/// immutable [AutoRecordConfig] value. Returning a narrow projection
/// (instead of the whole profile) keeps the phase 2+ background-
/// isolate API minimal and prevents accidental coupling to unrelated
/// fields like baselines or aggregates.
///
/// When the profile id is not found in the list, the provider
/// returns [AutoRecordConfig.defaults] — that way callers do not
/// need a separate "is this vehicle known yet?" branch.
@riverpod
AutoRecordConfig autoRecordConfig(Ref ref, String vehicleProfileId) {
  final profile = ref
      .watch(vehicleProfileListProvider)
      .where((v) => v.id == vehicleProfileId)
      .firstOrNull;
  if (profile == null) return AutoRecordConfig.defaults;
  return AutoRecordConfig.fromProfile(profile);
}
