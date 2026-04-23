// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'velocity_alert_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VelocityAlertConfig _$VelocityAlertConfigFromJson(Map<String, dynamic> json) =>
    _VelocityAlertConfig(
      fuelType: const FuelTypeJsonConverter().fromJson(
        json['fuelType'] as String,
      ),
      minDropCents: (json['minDropCents'] as num?)?.toDouble() ?? 3,
      minStations: (json['minStations'] as num?)?.toInt() ?? 2,
      radiusKm: (json['radiusKm'] as num?)?.toDouble() ?? 15,
      cooldownHours: (json['cooldownHours'] as num?)?.toInt() ?? 6,
    );

Map<String, dynamic> _$VelocityAlertConfigToJson(
  _VelocityAlertConfig instance,
) => <String, dynamic>{
  'fuelType': const FuelTypeJsonConverter().toJson(instance.fuelType),
  'minDropCents': instance.minDropCents,
  'minStations': instance.minStations,
  'radiusKm': instance.radiusKm,
  'cooldownHours': instance.cooldownHours,
};
