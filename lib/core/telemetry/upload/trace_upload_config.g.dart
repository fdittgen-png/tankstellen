// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'trace_upload_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TraceUploadConfig _$TraceUploadConfigFromJson(Map<String, dynamic> json) =>
    _TraceUploadConfig(
      enabled: json['enabled'] as bool? ?? false,
      serverUrl: json['serverUrl'] as String?,
      authToken: json['authToken'] as String?,
    );

Map<String, dynamic> _$TraceUploadConfigToJson(_TraceUploadConfig instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'serverUrl': instance.serverUrl,
      'authToken': instance.authToken,
    };
