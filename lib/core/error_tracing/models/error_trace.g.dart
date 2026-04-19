// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_trace.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ErrorTrace _$ErrorTraceFromJson(Map<String, dynamic> json) => _ErrorTrace(
  id: json['id'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  timezoneOffset: json['timezoneOffset'] as String,
  category: $enumDecode(_$ErrorCategoryEnumMap, json['category']),
  errorType: json['errorType'] as String,
  errorMessage: json['errorMessage'] as String,
  stackTrace: json['stackTrace'] as String,
  deviceInfo: DeviceInfo.fromJson(json['deviceInfo'] as Map<String, dynamic>),
  appState: AppStateSnapshot.fromJson(json['appState'] as Map<String, dynamic>),
  serviceChainState: json['serviceChainState'] == null
      ? null
      : ServiceChainSnapshot.fromJson(
          json['serviceChainState'] as Map<String, dynamic>,
        ),
  networkState: NetworkSnapshot.fromJson(
    json['networkState'] as Map<String, dynamic>,
  ),
  breadcrumbs:
      (json['breadcrumbs'] as List<dynamic>?)
          ?.map((e) => Breadcrumb.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ErrorTraceToJson(_ErrorTrace instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'timezoneOffset': instance.timezoneOffset,
      'category': _$ErrorCategoryEnumMap[instance.category]!,
      'errorType': instance.errorType,
      'errorMessage': instance.errorMessage,
      'stackTrace': instance.stackTrace,
      'deviceInfo': instance.deviceInfo.toJson(),
      'appState': instance.appState.toJson(),
      'serviceChainState': instance.serviceChainState?.toJson(),
      'networkState': instance.networkState.toJson(),
      'breadcrumbs': instance.breadcrumbs.map((e) => e.toJson()).toList(),
    };

const _$ErrorCategoryEnumMap = {
  ErrorCategory.api: 'api',
  ErrorCategory.network: 'network',
  ErrorCategory.cache: 'cache',
  ErrorCategory.ui: 'ui',
  ErrorCategory.platform: 'platform',
  ErrorCategory.serviceChain: 'serviceChain',
  ErrorCategory.provider: 'provider',
  ErrorCategory.unknown: 'unknown',
};

_DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) => _DeviceInfo(
  os: json['os'] as String,
  osVersion: json['osVersion'] as String,
  platform: json['platform'] as String,
  locale: json['locale'] as String,
  screenWidth: (json['screenWidth'] as num).toDouble(),
  screenHeight: (json['screenHeight'] as num).toDouble(),
  appVersion: json['appVersion'] as String,
);

Map<String, dynamic> _$DeviceInfoToJson(_DeviceInfo instance) =>
    <String, dynamic>{
      'os': instance.os,
      'osVersion': instance.osVersion,
      'platform': instance.platform,
      'locale': instance.locale,
      'screenWidth': instance.screenWidth,
      'screenHeight': instance.screenHeight,
      'appVersion': instance.appVersion,
    };

_AppStateSnapshot _$AppStateSnapshotFromJson(Map<String, dynamic> json) =>
    _AppStateSnapshot(
      activeRoute: json['activeRoute'] as String?,
      activeProfileId: json['activeProfileId'] as String?,
      activeProfileName: json['activeProfileName'] as String?,
      lastApiEndpoint: json['lastApiEndpoint'] as String?,
      lastSearchParams: json['lastSearchParams'] as String?,
    );

Map<String, dynamic> _$AppStateSnapshotToJson(_AppStateSnapshot instance) =>
    <String, dynamic>{
      'activeRoute': instance.activeRoute,
      'activeProfileId': instance.activeProfileId,
      'activeProfileName': instance.activeProfileName,
      'lastApiEndpoint': instance.lastApiEndpoint,
      'lastSearchParams': instance.lastSearchParams,
    };

_ServiceChainSnapshot _$ServiceChainSnapshotFromJson(
  Map<String, dynamic> json,
) => _ServiceChainSnapshot(
  attempts:
      (json['attempts'] as List<dynamic>?)
          ?.map((e) => ServiceAttempt.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  cachedDataAge: json['cachedDataAge'] as String?,
);

Map<String, dynamic> _$ServiceChainSnapshotToJson(
  _ServiceChainSnapshot instance,
) => <String, dynamic>{
  'attempts': instance.attempts.map((e) => e.toJson()).toList(),
  'cachedDataAge': instance.cachedDataAge,
};

_ServiceAttempt _$ServiceAttemptFromJson(Map<String, dynamic> json) =>
    _ServiceAttempt(
      serviceName: json['serviceName'] as String,
      succeeded: json['succeeded'] as bool,
      errorMessage: json['errorMessage'] as String?,
      statusCode: (json['statusCode'] as num?)?.toInt(),
      attemptedAt: DateTime.parse(json['attemptedAt'] as String),
    );

Map<String, dynamic> _$ServiceAttemptToJson(_ServiceAttempt instance) =>
    <String, dynamic>{
      'serviceName': instance.serviceName,
      'succeeded': instance.succeeded,
      'errorMessage': instance.errorMessage,
      'statusCode': instance.statusCode,
      'attemptedAt': instance.attemptedAt.toIso8601String(),
    };

_NetworkSnapshot _$NetworkSnapshotFromJson(Map<String, dynamic> json) =>
    _NetworkSnapshot(
      isOnline: json['isOnline'] as bool,
      connectivityType: json['connectivityType'] as String?,
    );

Map<String, dynamic> _$NetworkSnapshotToJson(_NetworkSnapshot instance) =>
    <String, dynamic>{
      'isOnline': instance.isOnline,
      'connectivityType': instance.connectivityType,
    };

_Breadcrumb _$BreadcrumbFromJson(Map<String, dynamic> json) => _Breadcrumb(
  timestamp: DateTime.parse(json['timestamp'] as String),
  action: json['action'] as String,
  detail: json['detail'] as String?,
);

Map<String, dynamic> _$BreadcrumbToJson(_Breadcrumb instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'action': instance.action,
      'detail': instance.detail,
    };
