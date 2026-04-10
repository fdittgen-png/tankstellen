import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;
import 'opening_hours.dart';

part 'charging_station.freezed.dart';
part 'charging_station.g.dart';

/// Real-time status of an individual [EvConnector].
enum ConnectorStatus {
  available('available'),
  occupied('occupied'),
  outOfOrder('out_of_order'),
  unknown('unknown');

  final String key;
  const ConnectorStatus(this.key);

  static ConnectorStatus fromKey(String? value) {
    if (value == null) return ConnectorStatus.unknown;
    for (final v in ConnectorStatus.values) {
      if (v.key == value) return v;
    }
    return ConnectorStatus.unknown;
  }
}

/// A single physical connector attached to a [ChargingStation].
@freezed
abstract class EvConnector with _$EvConnector {
  const factory EvConnector({
    required String id,
    @ConnectorTypeJsonConverter() required ConnectorType type,
    @Default(0) double maxPowerKw,
    @ConnectorStatusJsonConverter()
    @Default(ConnectorStatus.unknown)
    ConnectorStatus status,
    String? tariffId,
  }) = _EvConnector;

  factory EvConnector.fromJson(Map<String, dynamic> json) =>
      _$EvConnectorFromJson(json);
}

/// An EV charging station, typically sourced from OCPI / DATEX II /
/// OpenChargeMap / Bundesnetzagentur.
///
/// The tariff data itself lives in separate [charging_tariff.dart] models;
/// a station holds only `tariffId` references on each connector so that
/// multiple connectors can share the same tariff description.
@freezed
abstract class ChargingStation with _$ChargingStation {
  const ChargingStation._();

  const factory ChargingStation({
    required String id,
    required String name,
    String? operator,
    required double latitude,
    required double longitude,
    String? address,
    @Default(<EvConnector>[])
    @EvConnectorListConverter()
    List<EvConnector> connectors,
    @Default(<String>[]) List<String> amenities,
    @OpeningHoursNullableConverter() OpeningHours? openingHours,
    DateTime? lastUpdate,
  }) = _ChargingStation;

  factory ChargingStation.fromJson(Map<String, dynamic> json) =>
      _$ChargingStationFromJson(json);

  /// Whether any connector is currently reported as `available`.
  bool get hasAvailableConnector => connectors
      .any((c) => c.status == ConnectorStatus.available);

  /// Highest advertised max power across all connectors.
  double get maxPowerKw => connectors.isEmpty
      ? 0
      : connectors
          .map((c) => c.maxPowerKw)
          .reduce((a, b) => a > b ? a : b);
}

// ---------------------------------------------------------------------------
// JSON converters
// ---------------------------------------------------------------------------

/// Serializes [ConnectorType] from `vehicle_profile.dart` as its string key.
class ConnectorTypeJsonConverter
    implements JsonConverter<ConnectorType, String> {
  const ConnectorTypeJsonConverter();

  @override
  ConnectorType fromJson(String json) =>
      ConnectorType.fromKey(json) ?? ConnectorType.type2;

  @override
  String toJson(ConnectorType object) => object.key;
}

/// Serializes [ConnectorStatus] as its string key.
class ConnectorStatusJsonConverter
    implements JsonConverter<ConnectorStatus, String> {
  const ConnectorStatusJsonConverter();

  @override
  ConnectorStatus fromJson(String json) => ConnectorStatus.fromKey(json);

  @override
  String toJson(ConnectorStatus object) => object.key;
}

/// Serializes a list of [EvConnector] as plain JSON maps.
class EvConnectorListConverter
    implements JsonConverter<List<EvConnector>, List<dynamic>> {
  const EvConnectorListConverter();

  @override
  List<EvConnector> fromJson(List<dynamic> json) => json
      .whereType<Map<dynamic, dynamic>>()
      .map((e) => EvConnector.fromJson(Map<String, dynamic>.from(e)))
      .toList();

  @override
  List<Map<String, dynamic>> toJson(List<EvConnector> object) =>
      object.map((c) => c.toJson()).toList();
}

/// Serializes a nullable [OpeningHours] as a plain JSON map.
class OpeningHoursNullableConverter
    implements JsonConverter<OpeningHours?, Map<String, dynamic>?> {
  const OpeningHoursNullableConverter();

  @override
  OpeningHours? fromJson(Map<String, dynamic>? json) =>
      json == null ? null : OpeningHours.fromJson(json);

  @override
  Map<String, dynamic>? toJson(OpeningHours? object) => object?.toJson();
}
