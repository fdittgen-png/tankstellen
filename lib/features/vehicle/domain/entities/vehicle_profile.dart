import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle_profile.freezed.dart';
part 'vehicle_profile.g.dart';

/// Powertrain type for a stored vehicle.
enum VehicleType {
  combustion('combustion'),
  hybrid('hybrid'),
  ev('ev');

  final String key;
  const VehicleType(this.key);

  static VehicleType fromKey(String? value) {
    if (value == null) return VehicleType.combustion;
    for (final v in VehicleType.values) {
      if (v.key == value) return v;
    }
    return VehicleType.combustion;
  }
}

/// Common EV connector standards used in Europe.
///
/// Stored as part of [VehicleProfile.supportedConnectors] so the app can
/// filter charging stations by compatibility with the user's vehicle.
enum ConnectorType {
  type2('type2', 'Type 2'),
  ccs('ccs', 'CCS'),
  chademo('chademo', 'CHAdeMO'),
  tesla('tesla', 'Tesla'),
  schuko('schuko', 'Schuko'),
  type1('type1', 'Type 1'),
  threePin('three_pin', '3-pin');

  final String key;
  final String label;
  const ConnectorType(this.key, this.label);

  static ConnectorType? fromKey(String? value) {
    if (value == null) return null;
    for (final c in ConnectorType.values) {
      if (c.key == value) return c;
    }
    return null;
  }
}

/// User preferences for how a vehicle should be charged.
///
/// Independent of the [VehicleProfile] model because the values are
/// relevant only for EVs / hybrids and may be edited separately.
@freezed
abstract class ChargingPreferences with _$ChargingPreferences {
  const factory ChargingPreferences({
    @Default(20) int minSocPercent,
    @Default(80) int maxSocPercent,
    @Default(<String>[]) List<String> preferredNetworks,
  }) = _ChargingPreferences;

  factory ChargingPreferences.fromJson(Map<String, dynamic> json) =>
      _$ChargingPreferencesFromJson(json);
}

/// Persistent data for one of the user's vehicles.
///
/// A single profile may describe a combustion car (tank capacity, preferred
/// fuel) or an EV (battery, supported connectors, charging preferences).
/// Hybrids may carry either or both sets of fields.
@freezed
abstract class VehicleProfile with _$VehicleProfile {
  const VehicleProfile._();

  const factory VehicleProfile({
    required String id,
    required String name,
    @Default(VehicleType.combustion)
    @VehicleTypeJsonConverter()
    VehicleType type,

    // EV fields
    double? batteryKwh,
    double? maxChargingKw,
    @Default(<ConnectorType>{})
    @ConnectorTypeSetConverter()
    Set<ConnectorType> supportedConnectors,
    @Default(ChargingPreferences())
    @ChargingPreferencesJsonConverter()
    ChargingPreferences chargingPreferences,

    // Combustion fields
    double? tankCapacityL,
    String? preferredFuelType,

    // OBD2 adapter pairing (#784). Persisted so the app can
    // transparently reconnect on launch without prompting the user
    // again. Both fields are nullable — unpaired vehicles carry
    // null. The MAC is the stable key; the name is the label shown
    // to the user ("vLinker FS").
    String? obd2AdapterMac,
    String? obd2AdapterName,
  }) = _VehicleProfile;

  factory VehicleProfile.fromJson(Map<String, dynamic> json) =>
      _$VehicleProfileFromJson(json);

  bool get isEv => type == VehicleType.ev || type == VehicleType.hybrid;
  bool get isCombustion =>
      type == VehicleType.combustion || type == VehicleType.hybrid;
}

/// Serializes [VehicleType] as its string key.
class VehicleTypeJsonConverter
    implements JsonConverter<VehicleType, String> {
  const VehicleTypeJsonConverter();

  @override
  VehicleType fromJson(String json) => VehicleType.fromKey(json);

  @override
  String toJson(VehicleType object) => object.key;
}

/// Serializes [ChargingPreferences] as a plain map so json_serializable
/// does not store the nested object instance directly in the parent's
/// `toJson` output (which would break round-trips through Hive).
class ChargingPreferencesJsonConverter
    implements JsonConverter<ChargingPreferences, Map<String, dynamic>> {
  const ChargingPreferencesJsonConverter();

  @override
  ChargingPreferences fromJson(Map<String, dynamic> json) =>
      ChargingPreferences.fromJson(json);

  @override
  Map<String, dynamic> toJson(ChargingPreferences object) => object.toJson();
}

/// Serializes a `Set<ConnectorType>` as a list of string keys so it
/// survives Hive's `Map<String, dynamic>` storage.
class ConnectorTypeSetConverter
    implements JsonConverter<Set<ConnectorType>, List<dynamic>> {
  const ConnectorTypeSetConverter();

  @override
  Set<ConnectorType> fromJson(List<dynamic> json) {
    final result = <ConnectorType>{};
    for (final value in json) {
      final c = ConnectorType.fromKey(value?.toString());
      if (c != null) result.add(c);
    }
    return result;
  }

  @override
  List<String> toJson(Set<ConnectorType> object) =>
      object.map((c) => c.key).toList();
}
