// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'pump_gain_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PumpGainEntry _$PumpGainEntryFromJson(Map<String, dynamic> json) =>
    _PumpGainEntry(
      gain: (json['gain'] as num?)?.toDouble() ?? 1.0,
      samples: (json['samples'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$PumpGainEntryToJson(_PumpGainEntry instance) =>
    <String, dynamic>{
      'gain': instance.gain,
      'samples': instance.samples,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
