// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charging_station.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EvConnector _$EvConnectorFromJson(Map<String, dynamic> json) => _EvConnector(
  id: json['id'] as String? ?? '',
  type: const ConnectorTypeJsonConverter().fromJson(json['type'] as String),
  maxPowerKw: (json['maxPowerKw'] as num?)?.toDouble() ?? 0,
  status: json['status'] == null
      ? ConnectorStatus.unknown
      : const ConnectorStatusJsonConverter().fromJson(json['status'] as String),
  tariffId: json['tariffId'] as String?,
  rawType: json['rawType'] as String?,
  currentType: json['currentType'] as String?,
  quantity: (json['quantity'] as num?)?.toInt() ?? 0,
  statusLabel: json['statusLabel'] as String?,
);

Map<String, dynamic> _$EvConnectorToJson(_EvConnector instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': const ConnectorTypeJsonConverter().toJson(instance.type),
      'maxPowerKw': instance.maxPowerKw,
      'status': const ConnectorStatusJsonConverter().toJson(instance.status),
      'tariffId': instance.tariffId,
      'rawType': instance.rawType,
      'currentType': instance.currentType,
      'quantity': instance.quantity,
      'statusLabel': instance.statusLabel,
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
  dist: (json['dist'] as num?)?.toDouble() ?? 0,
  postCode: json['postCode'] as String?,
  place: json['place'] as String?,
  totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
  isOperational: json['isOperational'] as bool?,
  usageCost: json['usageCost'] as String?,
  updatedAt: json['updatedAt'] as String?,
  countryCode: json['countryCode'] as String?,
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
  'dist': instance.dist,
  'postCode': instance.postCode,
  'place': instance.place,
  'totalPoints': instance.totalPoints,
  'isOperational': instance.isOperational,
  'usageCost': instance.usageCost,
  'updatedAt': instance.updatedAt,
  'countryCode': instance.countryCode,
};
