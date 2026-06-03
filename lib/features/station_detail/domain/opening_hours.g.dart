// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'opening_hours.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TimeRange _$TimeRangeFromJson(Map<String, dynamic> json) => _TimeRange(
  startMinutes: (json['startMinutes'] as num).toInt(),
  endMinutes: (json['endMinutes'] as num).toInt(),
);

Map<String, dynamic> _$TimeRangeToJson(_TimeRange instance) =>
    <String, dynamic>{
      'startMinutes': instance.startMinutes,
      'endMinutes': instance.endMinutes,
    };

_DayHours _$DayHoursFromJson(Map<String, dynamic> json) => _DayHours(
  day: $enumDecode(_$OpeningDayEnumMap, json['day']),
  state: $enumDecode(_$DayStateEnumMap, json['state']),
  ranges:
      (json['ranges'] as List<dynamic>?)
          ?.map((e) => TimeRange.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$DayHoursToJson(_DayHours instance) => <String, dynamic>{
  'day': _$OpeningDayEnumMap[instance.day]!,
  'state': _$DayStateEnumMap[instance.state]!,
  'ranges': instance.ranges.map((e) => e.toJson()).toList(),
};

const _$OpeningDayEnumMap = {
  OpeningDay.mon: 'mon',
  OpeningDay.tue: 'tue',
  OpeningDay.wed: 'wed',
  OpeningDay.thu: 'thu',
  OpeningDay.fri: 'fri',
  OpeningDay.sat: 'sat',
  OpeningDay.sun: 'sun',
  OpeningDay.publicHoliday: 'publicHoliday',
};

const _$DayStateEnumMap = {
  DayState.closed: 'closed',
  DayState.open24h: 'open24h',
  DayState.openRanges: 'openRanges',
  DayState.unknown: 'unknown',
};

_WeeklyOpeningHours _$WeeklyOpeningHoursFromJson(Map<String, dynamic> json) =>
    _WeeklyOpeningHours(
      days:
          (json['days'] as List<dynamic>?)
              ?.map((e) => DayHours.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      availability:
          $enumDecodeNullable(
            _$OpeningHoursAvailabilityEnumMap,
            json['availability'],
          ) ??
          OpeningHoursAvailability.notProvided,
      rawSource: json['rawSource'] as String?,
      automate24h: json['automate24h'] as bool? ?? false,
    );

Map<String, dynamic> _$WeeklyOpeningHoursToJson(_WeeklyOpeningHours instance) =>
    <String, dynamic>{
      'days': instance.days.map((e) => e.toJson()).toList(),
      'availability': _$OpeningHoursAvailabilityEnumMap[instance.availability]!,
      'rawSource': instance.rawSource,
      'automate24h': instance.automate24h,
    };

const _$OpeningHoursAvailabilityEnumMap = {
  OpeningHoursAvailability.full: 'full',
  OpeningHoursAvailability.partial: 'partial',
  OpeningHoursAvailability.notProvided: 'notProvided',
};
