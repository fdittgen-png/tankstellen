// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isolate_error_spool_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IsolateErrorSpoolEntry _$IsolateErrorSpoolEntryFromJson(
  Map<String, dynamic> json,
) => _IsolateErrorSpoolEntry(
  timestamp: DateTime.parse(json['timestamp'] as String),
  isolateTaskName: json['isolateTaskName'] as String,
  errorMessage: json['errorMessage'] as String,
  stack: json['stack'] as String,
  contextMap:
      json['contextMap'] as Map<String, dynamic>? ?? const <String, dynamic>{},
);

Map<String, dynamic> _$IsolateErrorSpoolEntryToJson(
  _IsolateErrorSpoolEntry instance,
) => <String, dynamic>{
  'timestamp': instance.timestamp.toIso8601String(),
  'isolateTaskName': instance.isolateTaskName,
  'errorMessage': instance.errorMessage,
  'stack': instance.stack,
  'contextMap': instance.contextMap,
};
