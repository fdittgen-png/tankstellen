// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'traffic_signal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrafficSignal _$TrafficSignalFromJson(Map<String, dynamic> json) =>
    _TrafficSignal(
      id: json['id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      crossing: json['crossing'] as String?,
      highway: json['highway'] as String?,
    );

Map<String, dynamic> _$TrafficSignalToJson(_TrafficSignal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lat': instance.lat,
      'lng': instance.lng,
      'crossing': instance.crossing,
      'highway': instance.highway,
    };
