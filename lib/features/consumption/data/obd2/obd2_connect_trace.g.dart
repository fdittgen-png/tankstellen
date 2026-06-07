// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_connect_trace.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Obd2ScannedDevice _$Obd2ScannedDeviceFromJson(Map<String, dynamic> json) =>
    _Obd2ScannedDevice(
      redactedMac: json['mac'] as String?,
      name: json['name'] as String?,
      rssi: (json['rssi'] as num?)?.toInt(),
      transport: $enumDecode(_$Obd2ConnectTransportEnumMap, json['tx']),
      matchedProfileId: json['pid'] as String?,
    );

Map<String, dynamic> _$Obd2ScannedDeviceToJson(_Obd2ScannedDevice instance) =>
    <String, dynamic>{
      'mac': instance.redactedMac,
      'name': instance.name,
      'rssi': instance.rssi,
      'tx': _$Obd2ConnectTransportEnumMap[instance.transport]!,
      'pid': instance.matchedProfileId,
    };

const _$Obd2ConnectTransportEnumMap = {
  Obd2ConnectTransport.ble: 'ble',
  Obd2ConnectTransport.classic: 'classic',
  Obd2ConnectTransport.unknown: 'unknown',
};

_Obd2ConnectStep _$Obd2ConnectStepFromJson(Map<String, dynamic> json) =>
    _Obd2ConnectStep(
      label: json['l'] as String,
      status: $enumDecode(_$Obd2ConnectStepStatusEnumMap, json['s']),
      startMs: (json['sm'] as num?)?.toInt(),
      endMs: (json['em'] as num?)?.toInt(),
      detail: json['d'] as String?,
    );

Map<String, dynamic> _$Obd2ConnectStepToJson(_Obd2ConnectStep instance) =>
    <String, dynamic>{
      'l': instance.label,
      's': _$Obd2ConnectStepStatusEnumMap[instance.status]!,
      'sm': instance.startMs,
      'em': instance.endMs,
      'd': instance.detail,
    };

const _$Obd2ConnectStepStatusEnumMap = {
  Obd2ConnectStepStatus.ok: 'ok',
  Obd2ConnectStepStatus.timeout: 'timeout',
  Obd2ConnectStepStatus.fail: 'fail',
  Obd2ConnectStepStatus.skipped: 'skipped',
};

_Obd2ConnectTrace _$Obd2ConnectTraceFromJson(
  Map<String, dynamic> json,
) => _Obd2ConnectTrace(
  attemptId: json['id'] as String,
  startedAtMs: (json['st'] as num).toInt(),
  endedAtMs: (json['et'] as num?)?.toInt(),
  totalMs: (json['tm'] as num?)?.toInt(),
  origin: $enumDecode(_$Obd2ConnectOriginEnumMap, json['or']),
  requestedMac: json['mac'] as String?,
  adapterName: json['nm'] as String?,
  requestedTransport: $enumDecode(_$Obd2ConnectTransportEnumMap, json['rtx']),
  resolvedTransport: $enumDecodeNullable(
    _$Obd2ConnectTransportEnumMap,
    json['ztx'],
  ),
  transportDecisionReason: json['tdr'] as String?,
  outcome: $enumDecodeNullable(_$Obd2ConnectOutcomeEnumMap, json['oc']),
  failureDetail: json['fd'] as String?,
  steps:
      (json['steps'] as List<dynamic>?)
          ?.map((e) => Obd2ConnectStep.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Obd2ConnectStep>[],
  scanned:
      (json['scan'] as List<dynamic>?)
          ?.map((e) => Obd2ScannedDevice.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Obd2ScannedDevice>[],
);

Map<String, dynamic> _$Obd2ConnectTraceToJson(_Obd2ConnectTrace instance) =>
    <String, dynamic>{
      'id': instance.attemptId,
      'st': instance.startedAtMs,
      'et': instance.endedAtMs,
      'tm': instance.totalMs,
      'or': _$Obd2ConnectOriginEnumMap[instance.origin]!,
      'mac': instance.requestedMac,
      'nm': instance.adapterName,
      'rtx': _$Obd2ConnectTransportEnumMap[instance.requestedTransport]!,
      'ztx': _$Obd2ConnectTransportEnumMap[instance.resolvedTransport],
      'tdr': instance.transportDecisionReason,
      'oc': _$Obd2ConnectOutcomeEnumMap[instance.outcome],
      'fd': instance.failureDetail,
      'steps': instance.steps.map((e) => e.toJson()).toList(),
      'scan': instance.scanned.map((e) => e.toJson()).toList(),
    };

const _$Obd2ConnectOriginEnumMap = {
  Obd2ConnectOrigin.selfTest: 'selfTest',
  Obd2ConnectOrigin.liveReconnect: 'liveReconnect',
  Obd2ConnectOrigin.firstConnect: 'firstConnect',
  Obd2ConnectOrigin.autoRecord: 'autoRecord',
};

const _$Obd2ConnectOutcomeEnumMap = {
  Obd2ConnectOutcome.success: 'success',
  Obd2ConnectOutcome.scanEmpty: 'scanEmpty',
  Obd2ConnectOutcome.permissionDenied: 'permissionDenied',
  Obd2ConnectOutcome.bluetoothOff: 'bluetoothOff',
  Obd2ConnectOutcome.gattTimeout: 'gattTimeout',
  Obd2ConnectOutcome.gatt133: 'gatt133',
  Obd2ConnectOutcome.serviceNotFound: 'serviceNotFound',
  Obd2ConnectOutcome.rfcommOpenFail: 'rfcommOpenFail',
  Obd2ConnectOutcome.initTimeout: 'initTimeout',
  Obd2ConnectOutcome.protocolInitFailed: 'protocolInitFailed',
  Obd2ConnectOutcome.ignitionOff: 'ignitionOff',
  Obd2ConnectOutcome.unknown: 'unknown',
};
