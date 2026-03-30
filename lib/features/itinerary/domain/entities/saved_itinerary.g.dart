// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_itinerary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SavedItinerary _$SavedItineraryFromJson(Map<String, dynamic> json) =>
    _SavedItinerary(
      id: json['id'] as String,
      name: json['name'] as String,
      waypoints: (json['waypoints'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      durationMinutes: (json['durationMinutes'] as num).toDouble(),
      avoidHighways: json['avoidHighways'] as bool? ?? false,
      fuelType: json['fuelType'] as String? ?? 'e10',
      selectedStationIds:
          (json['selectedStationIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SavedItineraryToJson(_SavedItinerary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'waypoints': instance.waypoints,
      'distanceKm': instance.distanceKm,
      'durationMinutes': instance.durationMinutes,
      'avoidHighways': instance.avoidHighways,
      'fuelType': instance.fuelType,
      'selectedStationIds': instance.selectedStationIds,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
