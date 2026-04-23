// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charging_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChargingLog _$ChargingLogFromJson(Map<String, dynamic> json) => _ChargingLog(
  id: json['id'] as String,
  vehicleId: json['vehicleId'] as String,
  date: DateTime.parse(json['date'] as String),
  kWh: (json['kWh'] as num).toDouble(),
  costEur: (json['costEur'] as num).toDouble(),
  chargeTimeMin: (json['chargeTimeMin'] as num).toInt(),
  odometerKm: (json['odometerKm'] as num).toInt(),
  stationName: json['stationName'] as String?,
  chargingStationId: json['chargingStationId'] as String?,
);

Map<String, dynamic> _$ChargingLogToJson(_ChargingLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vehicleId': instance.vehicleId,
      'date': instance.date.toIso8601String(),
      'kWh': instance.kWh,
      'costEur': instance.costEur,
      'chargeTimeMin': instance.chargeTimeMin,
      'odometerKm': instance.odometerKm,
      'stationName': instance.stationName,
      'chargingStationId': instance.chargingStationId,
    };
