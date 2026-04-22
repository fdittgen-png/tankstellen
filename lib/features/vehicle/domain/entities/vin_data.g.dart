// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vin_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VinData _$VinDataFromJson(Map<String, dynamic> json) => _VinData(
  vin: json['vin'] as String,
  make: json['make'] as String?,
  model: json['model'] as String?,
  modelYear: (json['modelYear'] as num?)?.toInt(),
  displacementL: (json['displacementL'] as num?)?.toDouble(),
  cylinderCount: (json['cylinderCount'] as num?)?.toInt(),
  fuelTypePrimary: json['fuelTypePrimary'] as String?,
  engineHp: (json['engineHp'] as num?)?.toInt(),
  gvwrLbs: (json['gvwrLbs'] as num?)?.toInt(),
  country: json['country'] as String?,
  source: json['source'] == null
      ? VinDataSource.invalid
      : const VinDataSourceJsonConverter().fromJson(json['source'] as String),
);

Map<String, dynamic> _$VinDataToJson(_VinData instance) => <String, dynamic>{
  'vin': instance.vin,
  'make': instance.make,
  'model': instance.model,
  'modelYear': instance.modelYear,
  'displacementL': instance.displacementL,
  'cylinderCount': instance.cylinderCount,
  'fuelTypePrimary': instance.fuelTypePrimary,
  'engineHp': instance.engineHp,
  'gvwrLbs': instance.gvwrLbs,
  'country': instance.country,
  'source': const VinDataSourceJsonConverter().toJson(instance.source),
};
