// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speed_consumption_histogram.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SpeedBand _$SpeedBandFromJson(Map<String, dynamic> json) => _SpeedBand(
  minKmh: (json['minKmh'] as num).toInt(),
  maxKmh: (json['maxKmh'] as num?)?.toInt(),
  sampleCount: (json['sampleCount'] as num).toInt(),
  meanLPer100km: (json['meanLPer100km'] as num).toDouble(),
  timeShareFraction: (json['timeShareFraction'] as num).toDouble(),
);

Map<String, dynamic> _$SpeedBandToJson(_SpeedBand instance) =>
    <String, dynamic>{
      'minKmh': instance.minKmh,
      'maxKmh': instance.maxKmh,
      'sampleCount': instance.sampleCount,
      'meanLPer100km': instance.meanLPer100km,
      'timeShareFraction': instance.timeShareFraction,
    };

_SpeedConsumptionHistogram _$SpeedConsumptionHistogramFromJson(
  Map<String, dynamic> json,
) => _SpeedConsumptionHistogram(
  bands:
      (json['bands'] as List<dynamic>?)
          ?.map((e) => SpeedBand.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SpeedBand>[],
);

Map<String, dynamic> _$SpeedConsumptionHistogramToJson(
  _SpeedConsumptionHistogram instance,
) => <String, dynamic>{'bands': instance.bands.map((e) => e.toJson()).toList()};
