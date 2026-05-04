// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reference_vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReferenceVehicle _$ReferenceVehicleFromJson(Map<String, dynamic> json) =>
    _ReferenceVehicle(
      make: json['make'] as String,
      model: json['model'] as String,
      generation: json['generation'] as String,
      yearStart: (json['yearStart'] as num).toInt(),
      yearEnd: (json['yearEnd'] as num?)?.toInt(),
      displacementCc: (json['displacementCc'] as num).toInt(),
      fuelType: json['fuelType'] as String,
      transmission: json['transmission'] as String,
      volumetricEfficiency:
          (json['volumetricEfficiency'] as num?)?.toDouble() ?? 0.85,
      odometerPidStrategy: json['odometerPidStrategy'] as String? ?? 'stdA6',
      inductionType:
          $enumDecodeNullable(_$InductionTypeEnumMap, json['inductionType']) ??
          InductionType.naturallyAspirated,
      directInjection: json['directInjection'] as bool? ?? false,
      atkinsonCycle: json['atkinsonCycle'] as bool? ?? false,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$ReferenceVehicleToJson(_ReferenceVehicle instance) =>
    <String, dynamic>{
      'make': instance.make,
      'model': instance.model,
      'generation': instance.generation,
      'yearStart': instance.yearStart,
      'yearEnd': instance.yearEnd,
      'displacementCc': instance.displacementCc,
      'fuelType': instance.fuelType,
      'transmission': instance.transmission,
      'volumetricEfficiency': instance.volumetricEfficiency,
      'odometerPidStrategy': instance.odometerPidStrategy,
      'inductionType': _$InductionTypeEnumMap[instance.inductionType]!,
      'directInjection': instance.directInjection,
      'atkinsonCycle': instance.atkinsonCycle,
      'notes': instance.notes,
    };

const _$InductionTypeEnumMap = {
  InductionType.naturallyAspirated: 'naturallyAspirated',
  InductionType.turbocharged: 'turbocharged',
  InductionType.supercharged: 'supercharged',
  InductionType.vnt: 'vnt',
};
