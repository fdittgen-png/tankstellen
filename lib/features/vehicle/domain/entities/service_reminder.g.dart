// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_reminder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServiceReminder _$ServiceReminderFromJson(Map<String, dynamic> json) =>
    _ServiceReminder(
      id: json['id'] as String,
      label: json['label'] as String,
      intervalKm: (json['intervalKm'] as num).toDouble(),
      lastServiceOdometerKm: (json['lastServiceOdometerKm'] as num?)
          ?.toDouble(),
    );

Map<String, dynamic> _$ServiceReminderToJson(_ServiceReminder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'intervalKm': instance.intervalKm,
      'lastServiceOdometerKm': instance.lastServiceOdometerKm,
    };
