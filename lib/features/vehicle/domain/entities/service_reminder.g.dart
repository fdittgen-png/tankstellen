// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_reminder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServiceReminder _$ServiceReminderFromJson(Map<String, dynamic> json) =>
    _ServiceReminder(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      label: json['label'] as String,
      intervalKm: (json['intervalKm'] as num).toDouble(),
      lastServiceOdometerKm: (json['lastServiceOdometerKm'] as num?)
          ?.toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      pendingAcknowledgment: json['pendingAcknowledgment'] as bool? ?? false,
    );

Map<String, dynamic> _$ServiceReminderToJson(_ServiceReminder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vehicleId': instance.vehicleId,
      'label': instance.label,
      'intervalKm': instance.intervalKm,
      'lastServiceOdometerKm': instance.lastServiceOdometerKm,
      'isActive': instance.isActive,
      'pendingAcknowledgment': instance.pendingAcknowledgment,
    };
