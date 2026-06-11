// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'opening_hours.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RegularHours _$RegularHoursFromJson(Map<String, dynamic> json) =>
    _RegularHours(
      weekday: (json['weekday'] as num).toInt(),
      periodBegin: json['periodBegin'] as String,
      periodEnd: json['periodEnd'] as String,
    );

Map<String, dynamic> _$RegularHoursToJson(_RegularHours instance) =>
    <String, dynamic>{
      'weekday': instance.weekday,
      'periodBegin': instance.periodBegin,
      'periodEnd': instance.periodEnd,
    };

_OpeningHours _$OpeningHoursFromJson(Map<String, dynamic> json) =>
    _OpeningHours(
      twentyFourSeven: json['twentyFourSeven'] as bool? ?? false,
      regularHours: json['regularHours'] == null
          ? const <RegularHours>[]
          : const RegularHoursListConverter().fromJson(
              json['regularHours'] as List,
            ),
    );

Map<String, dynamic> _$OpeningHoursToJson(_OpeningHours instance) =>
    <String, dynamic>{
      'twentyFourSeven': instance.twentyFourSeven,
      'regularHours': const RegularHoursListConverter().toJson(
        instance.regularHours,
      ),
    };
