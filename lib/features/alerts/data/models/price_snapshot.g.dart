// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PriceSnapshot _$PriceSnapshotFromJson(Map<String, dynamic> json) =>
    _PriceSnapshot(
      stationId: json['stationId'] as String,
      fuelType: json['fuelType'] as String,
      price: (json['price'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );

Map<String, dynamic> _$PriceSnapshotToJson(_PriceSnapshot instance) =>
    <String, dynamic>{
      'stationId': instance.stationId,
      'fuelType': instance.fuelType,
      'price': instance.price,
      'timestamp': instance.timestamp.toIso8601String(),
      'lat': instance.lat,
      'lng': instance.lng,
    };
