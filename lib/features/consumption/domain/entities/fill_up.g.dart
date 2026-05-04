// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fill_up.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FillUp _$FillUpFromJson(Map<String, dynamic> json) => _FillUp(
  id: json['id'] as String,
  date: DateTime.parse(json['date'] as String),
  liters: (json['liters'] as num).toDouble(),
  totalCost: (json['totalCost'] as num).toDouble(),
  odometerKm: (json['odometerKm'] as num).toDouble(),
  fuelType: const FuelTypeJsonConverter().fromJson(json['fuelType'] as String),
  stationId: json['stationId'] as String?,
  stationName: json['stationName'] as String?,
  notes: json['notes'] as String?,
  vehicleId: json['vehicleId'] as String?,
  linkedTripIds:
      (json['linkedTripIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  isFullTank: json['isFullTank'] as bool? ?? true,
  isCorrection: json['isCorrection'] as bool? ?? false,
  fuelLevelBeforeL: (json['fuelLevelBeforeL'] as num?)?.toDouble(),
  fuelLevelAfterL: (json['fuelLevelAfterL'] as num?)?.toDouble(),
);

Map<String, dynamic> _$FillUpToJson(_FillUp instance) => <String, dynamic>{
  'id': instance.id,
  'date': instance.date.toIso8601String(),
  'liters': instance.liters,
  'totalCost': instance.totalCost,
  'odometerKm': instance.odometerKm,
  'fuelType': const FuelTypeJsonConverter().toJson(instance.fuelType),
  'stationId': instance.stationId,
  'stationName': instance.stationName,
  'notes': instance.notes,
  'vehicleId': instance.vehicleId,
  'linkedTripIds': instance.linkedTripIds,
  'isFullTank': instance.isFullTank,
  'isCorrection': instance.isCorrection,
  'fuelLevelBeforeL': instance.fuelLevelBeforeL,
  'fuelLevelAfterL': instance.fuelLevelAfterL,
};
