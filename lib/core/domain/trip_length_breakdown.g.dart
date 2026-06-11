// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_length_breakdown.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TripLengthBucket _$TripLengthBucketFromJson(Map<String, dynamic> json) =>
    _TripLengthBucket(
      tripCount: (json['tripCount'] as num).toInt(),
      meanLPer100km: (json['meanLPer100km'] as num).toDouble(),
      totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
      totalLitres: (json['totalLitres'] as num).toDouble(),
    );

Map<String, dynamic> _$TripLengthBucketToJson(_TripLengthBucket instance) =>
    <String, dynamic>{
      'tripCount': instance.tripCount,
      'meanLPer100km': instance.meanLPer100km,
      'totalDistanceKm': instance.totalDistanceKm,
      'totalLitres': instance.totalLitres,
    };

_TripLengthBreakdown _$TripLengthBreakdownFromJson(Map<String, dynamic> json) =>
    _TripLengthBreakdown(
      short: json['short'] == null
          ? null
          : TripLengthBucket.fromJson(json['short'] as Map<String, dynamic>),
      medium: json['medium'] == null
          ? null
          : TripLengthBucket.fromJson(json['medium'] as Map<String, dynamic>),
      long: json['long'] == null
          ? null
          : TripLengthBucket.fromJson(json['long'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TripLengthBreakdownToJson(
  _TripLengthBreakdown instance,
) => <String, dynamic>{
  'short': instance.short?.toJson(),
  'medium': instance.medium?.toJson(),
  'long': instance.long?.toJson(),
};
