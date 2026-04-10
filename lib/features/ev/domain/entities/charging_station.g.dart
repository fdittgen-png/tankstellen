// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charging_station.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EvConnector _$EvConnectorFromJson(Map<String, dynamic> json) => _EvConnector(
  id: json['id'] as String,
  type: const ConnectorTypeJsonConverter().fromJson(json['type'] as String),
  maxPowerKw: (json['maxPowerKw'] as num?)?.toDouble() ?? 0,
  status: json['status'] == null
      ? ConnectorStatus.unknown
      : const ConnectorStatusJsonConverter().fromJson(json['status'] as String),
  tariffId: json['tariffId'] as String?,
);

Map<String, dynamic> _$EvConnectorToJson(_EvConnector instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': const ConnectorTypeJsonConverter().toJson(instance.type),
      'maxPowerKw': instance.maxPowerKw,
      'status': const ConnectorStatusJsonConverter().toJson(instance.status),
      'tariffId': instance.tariffId,
    };

_ChargingStation _$ChargingStationFromJson(
  Map<String, dynamic> json,
) => _ChargingStation(
  id: json['id'] as String,
  name: json['name'] as String,
  operator: json['operator'] as String?,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  address: json['address'] as String?,
  connectors: json['connectors'] == null
      ? const <EvConnector>[]
      : const EvConnectorListConverter().fromJson(json['connectors'] as List),
  amenities:
      (json['amenities'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  openingHours: const OpeningHoursNullableConverter().fromJson(
    json['openingHours'] as Map<String, dynamic>?,
  ),
  lastUpdate: json['lastUpdate'] == null
      ? null
      : DateTime.parse(json['lastUpdate'] as String),
);

Map<String, dynamic> _$ChargingStationToJson(
  _ChargingStation instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'operator': instance.operator,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'address': instance.address,
  'connectors': const EvConnectorListConverter().toJson(instance.connectors),
  'amenities': instance.amenities,
  'openingHours': const OpeningHoursNullableConverter().toJson(
    instance.openingHours,
  ),
  'lastUpdate': instance.lastUpdate?.toIso8601String(),
};
