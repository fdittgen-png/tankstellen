// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charging_station.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChargingStation _$ChargingStationFromJson(Map<String, dynamic> json) =>
    _ChargingStation(
      id: json['id'] as String,
      name: json['name'] as String,
      operator: json['operator'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      dist: (json['dist'] as num?)?.toDouble() ?? 0,
      address: json['address'] as String,
      postCode: json['postCode'] as String? ?? '',
      place: json['place'] as String? ?? '',
      connectors: (json['connectors'] as List<dynamic>)
          .map((e) => Connector.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      isOperational: json['isOperational'] as bool?,
      usageCost: json['usageCost'] as String?,
      updatedAt: json['updatedAt'] as String?,
      countryCode: json['countryCode'] as String?,
    );

Map<String, dynamic> _$ChargingStationToJson(_ChargingStation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'operator': instance.operator,
      'lat': instance.lat,
      'lng': instance.lng,
      'dist': instance.dist,
      'address': instance.address,
      'postCode': instance.postCode,
      'place': instance.place,
      'connectors': instance.connectors.map((e) => e.toJson()).toList(),
      'totalPoints': instance.totalPoints,
      'isOperational': instance.isOperational,
      'usageCost': instance.usageCost,
      'updatedAt': instance.updatedAt,
      'countryCode': instance.countryCode,
    };

_Connector _$ConnectorFromJson(Map<String, dynamic> json) => _Connector(
  type: json['type'] as String,
  powerKW: (json['powerKW'] as num?)?.toDouble() ?? 0,
  quantity: (json['quantity'] as num?)?.toInt() ?? 0,
  currentType: json['currentType'] as String?,
  status: json['status'] as String?,
);

Map<String, dynamic> _$ConnectorToJson(_Connector instance) =>
    <String, dynamic>{
      'type': instance.type,
      'powerKW': instance.powerKW,
      'quantity': instance.quantity,
      'currentType': instance.currentType,
      'status': instance.status,
    };
