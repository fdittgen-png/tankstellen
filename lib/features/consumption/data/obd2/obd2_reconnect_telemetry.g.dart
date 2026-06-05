// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_reconnect_telemetry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Obd2ReconnectAttempt _$Obd2ReconnectAttemptFromJson(
  Map<String, dynamic> json,
) => _Obd2ReconnectAttempt(
  timestampMs: (json['t'] as num?)?.toInt() ?? 0,
  reasonCode: json['rc'] as String?,
  backoffMs: (json['bo'] as num?)?.toInt() ?? 0,
  rssi: (json['r'] as num?)?.toInt(),
  latencyMs: (json['l'] as num?)?.toInt() ?? 0,
  attemptNumber: (json['n'] as num?)?.toInt() ?? 0,
  succeeded: json['s'] as bool? ?? false,
  path: json['p'] as String?,
);

Map<String, dynamic> _$Obd2ReconnectAttemptToJson(
  _Obd2ReconnectAttempt instance,
) => <String, dynamic>{
  't': instance.timestampMs,
  'rc': instance.reasonCode,
  'bo': instance.backoffMs,
  'r': instance.rssi,
  'l': instance.latencyMs,
  'n': instance.attemptNumber,
  's': instance.succeeded,
  'p': instance.path,
};

_Obd2SessionTransition _$Obd2SessionTransitionFromJson(
  Map<String, dynamic> json,
) => _Obd2SessionTransition(
  timestampMs: (json['t'] as num?)?.toInt() ?? 0,
  state: json['s'] as String? ?? '',
  detail: json['d'] as String?,
);

Map<String, dynamic> _$Obd2SessionTransitionToJson(
  _Obd2SessionTransition instance,
) => <String, dynamic>{
  't': instance.timestampMs,
  's': instance.state,
  'd': instance.detail,
};
