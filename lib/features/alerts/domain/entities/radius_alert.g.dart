// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radius_alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RadiusAlert _$RadiusAlertFromJson(Map<String, dynamic> json) => _RadiusAlert(
  id: json['id'] as String,
  fuelType: json['fuelType'] as String,
  threshold: (json['threshold'] as num).toDouble(),
  centerLat: (json['centerLat'] as num).toDouble(),
  centerLng: (json['centerLng'] as num).toDouble(),
  radiusKm: (json['radiusKm'] as num).toDouble(),
  label: json['label'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  enabled: json['enabled'] as bool? ?? true,
);

Map<String, dynamic> _$RadiusAlertToJson(_RadiusAlert instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fuelType': instance.fuelType,
      'threshold': instance.threshold,
      'centerLat': instance.centerLat,
      'centerLng': instance.centerLng,
      'radiusKm': instance.radiusKm,
      'label': instance.label,
      'createdAt': instance.createdAt.toIso8601String(),
      'enabled': instance.enabled,
    };
