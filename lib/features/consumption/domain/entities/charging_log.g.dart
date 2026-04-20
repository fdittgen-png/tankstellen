// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charging_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChargingLog _$ChargingLogFromJson(Map<String, dynamic> json) => _ChargingLog(
  id: json['id'] as String,
  date: DateTime.parse(json['date'] as String),
  kwh: (json['kwh'] as num).toDouble(),
  totalCost: (json['totalCost'] as num).toDouble(),
  odometerKm: (json['odometerKm'] as num).toDouble(),
  chargeTimeMin: (json['chargeTimeMin'] as num?)?.toInt(),
  stationId: json['stationId'] as String?,
  stationName: json['stationName'] as String?,
  operator: json['operator'] as String?,
  notes: json['notes'] as String?,
  vehicleId: json['vehicleId'] as String?,
);

Map<String, dynamic> _$ChargingLogToJson(_ChargingLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'kwh': instance.kwh,
      'totalCost': instance.totalCost,
      'odometerKm': instance.odometerKm,
      'chargeTimeMin': instance.chargeTimeMin,
      'stationId': instance.stationId,
      'stationName': instance.stationName,
      'operator': instance.operator,
      'notes': instance.notes,
      'vehicleId': instance.vehicleId,
    };
