// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_session_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Obd2SchedulerStats _$Obd2SchedulerStatsFromJson(Map<String, dynamic> json) =>
    _Obd2SchedulerStats(
      tickRateHz: (json['tr'] as num?)?.toDouble() ?? 0.0,
      backpressureSkips: (json['bp'] as num?)?.toInt() ?? 0,
      demotions: (json['dm'] as num?)?.toInt() ?? 0,
      ticks: (json['tk'] as num?)?.toInt() ?? 0,
      achievedReadsPerSecond: (json['rps'] as num?)?.toDouble() ?? 0.0,
      dynamicsEffectiveHz: (json['dhz'] as num?)?.toDouble() ?? 0.0,
      backedOffCount: (json['bof'] as num?)?.toInt() ?? 0,
      starved: json['st'] as bool? ?? false,
    );

Map<String, dynamic> _$Obd2SchedulerStatsToJson(_Obd2SchedulerStats instance) =>
    <String, dynamic>{
      'tr': instance.tickRateHz,
      'bp': instance.backpressureSkips,
      'dm': instance.demotions,
      'tk': instance.ticks,
      'rps': instance.achievedReadsPerSecond,
      'dhz': instance.dynamicsEffectiveHz,
      'bof': instance.backedOffCount,
      'st': instance.starved,
    };

_Obd2FuelDowngradeStats _$Obd2FuelDowngradeStatsFromJson(
  Map<String, dynamic> json,
) => _Obd2FuelDowngradeStats(
  totalSamples: (json['t'] as num?)?.toInt() ?? 0,
  suspiciousSamples: (json['s'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$Obd2FuelDowngradeStatsToJson(
  _Obd2FuelDowngradeStats instance,
) => <String, dynamic>{
  't': instance.totalSamples,
  's': instance.suspiciousSamples,
};

_Obd2CompletenessStats _$Obd2CompletenessStatsFromJson(
  Map<String, dynamic> json,
) => _Obd2CompletenessStats(
  overallPercent: (json['o'] as num?)?.toDouble() ?? 0.0,
  perTierPercent:
      (json['pt'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ) ??
      const <String, double>{},
  activeDutyCycle: (json['dc'] as num?)?.toDouble() ?? 0.0,
  emitGapDetected: json['eg'] as bool? ?? false,
);

Map<String, dynamic> _$Obd2CompletenessStatsToJson(
  _Obd2CompletenessStats instance,
) => <String, dynamic>{
  'o': instance.overallPercent,
  'pt': instance.perTierPercent,
  'dc': instance.activeDutyCycle,
  'eg': instance.emitGapDetected,
};

_Obd2FramingStats _$Obd2FramingStatsFromJson(Map<String, dynamic> json) =>
    _Obd2FramingStats(
      partialFrames: (json['pf'] as num?)?.toInt() ?? 0,
      leftoverBytes: (json['lo'] as num?)?.toInt() ?? 0,
      strayPrompts: (json['sp'] as num?)?.toInt() ?? 0,
      garbageReads: (json['gb'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$Obd2FramingStatsToJson(_Obd2FramingStats instance) =>
    <String, dynamic>{
      'pf': instance.partialFrames,
      'lo': instance.leftoverBytes,
      'sp': instance.strayPrompts,
      'gb': instance.garbageReads,
    };
