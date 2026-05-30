// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_session_diagnostic.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Obd2SessionDiagnostic _$Obd2SessionDiagnosticFromJson(
  Map<String, dynamic> json,
) => _Obd2SessionDiagnostic(
  linkKind: json['lk'] as String?,
  redactedMac: json['mac'] as String?,
  elmVersion: json['ev'] as String?,
  protocolDigit: json['pd'] as String?,
  mtu: (json['mtu'] as num?)?.toInt(),
  warmStart: json['ws'] as bool?,
  capabilityTier: json['ct'] as String?,
  initTranscript:
      (json['tx'] as List<dynamic>?)
          ?.map((e) => Obd2HandshakeLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Obd2HandshakeLine>[],
  pidStats:
      (json['pid'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, Obd2PidStat.fromJson(e as Map<String, dynamic>)),
      ) ??
      const <String, Obd2PidStat>{},
  connection: json['conn'] == null
      ? const Obd2ConnectionStats()
      : Obd2ConnectionStats.fromJson(json['conn'] as Map<String, dynamic>),
  scheduler: json['sch'] == null
      ? const Obd2SchedulerStats()
      : Obd2SchedulerStats.fromJson(json['sch'] as Map<String, dynamic>),
  framing: json['frm'] == null
      ? const Obd2FramingStats()
      : Obd2FramingStats.fromJson(json['frm'] as Map<String, dynamic>),
  fuelTierTicks:
      (json['ft'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const <String, int>{},
  expectedReads: (json['er'] as num?)?.toInt(),
  achievedReads: (json['ar'] as num?)?.toInt(),
  completenessPercent: (json['cp'] as num?)?.toDouble(),
);

Map<String, dynamic> _$Obd2SessionDiagnosticToJson(
  _Obd2SessionDiagnostic instance,
) => <String, dynamic>{
  'lk': instance.linkKind,
  'mac': instance.redactedMac,
  'ev': instance.elmVersion,
  'pd': instance.protocolDigit,
  'mtu': instance.mtu,
  'ws': instance.warmStart,
  'ct': instance.capabilityTier,
  'tx': instance.initTranscript.map((e) => e.toJson()).toList(),
  'pid': instance.pidStats.map((k, e) => MapEntry(k, e.toJson())),
  'conn': instance.connection.toJson(),
  'sch': instance.scheduler.toJson(),
  'frm': instance.framing.toJson(),
  'ft': instance.fuelTierTicks,
  'er': instance.expectedReads,
  'ar': instance.achievedReads,
  'cp': instance.completenessPercent,
};

_Obd2HandshakeLine _$Obd2HandshakeLineFromJson(Map<String, dynamic> json) =>
    _Obd2HandshakeLine(
      cmd: json['c'] as String,
      response: json['r'] as String,
      latencyMs: (json['l'] as num).toInt(),
    );

Map<String, dynamic> _$Obd2HandshakeLineToJson(_Obd2HandshakeLine instance) =>
    <String, dynamic>{
      'c': instance.cmd,
      'r': instance.response,
      'l': instance.latencyMs,
    };

_Obd2PidStat _$Obd2PidStatFromJson(Map<String, dynamic> json) => _Obd2PidStat(
  polled: (json['p'] as num?)?.toInt() ?? 0,
  ok: (json['ok'] as num?)?.toInt() ?? 0,
  noData: (json['nd'] as num?)?.toInt() ?? 0,
  timeout: (json['to'] as num?)?.toInt() ?? 0,
  error: (json['er'] as num?)?.toInt() ?? 0,
  latencyP50Ms: (json['p50'] as num?)?.toInt() ?? 0,
  latencyP95Ms: (json['p95'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$Obd2PidStatToJson(_Obd2PidStat instance) =>
    <String, dynamic>{
      'p': instance.polled,
      'ok': instance.ok,
      'nd': instance.noData,
      'to': instance.timeout,
      'er': instance.error,
      'p50': instance.latencyP50Ms,
      'p95': instance.latencyP95Ms,
    };

_Obd2ConnectionStats _$Obd2ConnectionStatsFromJson(Map<String, dynamic> json) =>
    _Obd2ConnectionStats(
      attempts: (json['at'] as num?)?.toInt() ?? 0,
      successes: (json['su'] as num?)?.toInt() ?? 0,
      failuresByReason:
          (json['fr'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const <String, int>{},
      drops: (json['dr'] as num?)?.toInt() ?? 0,
      silentReconnects: (json['sr'] as num?)?.toInt() ?? 0,
      visibleReconnects: (json['vr'] as num?)?.toInt() ?? 0,
      timeToConnectP50Ms: (json['tc'] as num?)?.toInt(),
      timeToConnectP95Ms: (json['tcp95'] as num?)?.toInt(),
      timeToReconnectP50Ms: (json['rc'] as num?)?.toInt(),
      timeToReconnectP95Ms: (json['rcp95'] as num?)?.toInt(),
    );

Map<String, dynamic> _$Obd2ConnectionStatsToJson(
  _Obd2ConnectionStats instance,
) => <String, dynamic>{
  'at': instance.attempts,
  'su': instance.successes,
  'fr': instance.failuresByReason,
  'dr': instance.drops,
  'sr': instance.silentReconnects,
  'vr': instance.visibleReconnects,
  'tc': instance.timeToConnectP50Ms,
  'tcp95': instance.timeToConnectP95Ms,
  'rc': instance.timeToReconnectP50Ms,
  'rcp95': instance.timeToReconnectP95Ms,
};

_Obd2SchedulerStats _$Obd2SchedulerStatsFromJson(Map<String, dynamic> json) =>
    _Obd2SchedulerStats(
      tickRateHz: (json['tr'] as num?)?.toDouble() ?? 0.0,
      backpressureSkips: (json['bp'] as num?)?.toInt() ?? 0,
      demotions: (json['dm'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$Obd2SchedulerStatsToJson(_Obd2SchedulerStats instance) =>
    <String, dynamic>{
      'tr': instance.tickRateHz,
      'bp': instance.backpressureSkips,
      'dm': instance.demotions,
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
