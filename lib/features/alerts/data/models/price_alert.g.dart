// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PriceAlert _$PriceAlertFromJson(Map<String, dynamic> json) => _PriceAlert(
  id: json['id'] as String,
  stationId: json['stationId'] as String,
  stationName: json['stationName'] as String,
  fuelType: $enumDecode(_$FuelTypeEnumMap, json['fuelType']),
  targetPrice: (json['targetPrice'] as num).toDouble(),
  isActive: json['isActive'] as bool? ?? true,
  lastTriggeredAt: json['lastTriggeredAt'] == null
      ? null
      : DateTime.parse(json['lastTriggeredAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$PriceAlertToJson(_PriceAlert instance) =>
    <String, dynamic>{
      'id': instance.id,
      'stationId': instance.stationId,
      'stationName': instance.stationName,
      'fuelType': _$FuelTypeEnumMap[instance.fuelType]!,
      'targetPrice': instance.targetPrice,
      'isActive': instance.isActive,
      'lastTriggeredAt': instance.lastTriggeredAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$FuelTypeEnumMap = {
  FuelType.e5: 'e5',
  FuelType.e10: 'e10',
  FuelType.e98: 'e98',
  FuelType.diesel: 'diesel',
  FuelType.dieselPremium: 'dieselPremium',
  FuelType.e85: 'e85',
  FuelType.lpg: 'lpg',
  FuelType.cng: 'cng',
  FuelType.hydrogen: 'hydrogen',
  FuelType.electric: 'electric',
  FuelType.all: 'all',
};
