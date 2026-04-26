import 'package:freezed_annotation/freezed_annotation.dart';

part 'error_trace.freezed.dart';
part 'error_trace.g.dart';

enum ErrorCategory {
  api('API Error'),
  network('Network Error'),
  cache('Cache Error'),
  ui('UI Error'),
  platform('Platform Error'),
  serviceChain('Service Chain Error'),
  provider('Provider Error'),
  unknown('Unknown');

  final String displayName;
  const ErrorCategory(this.displayName);
}

@freezed
abstract class ErrorTrace with _$ErrorTrace {
  const factory ErrorTrace({
    required String id,
    required DateTime timestamp,
    required String timezoneOffset,
    required ErrorCategory category,
    required String errorType,
    required String errorMessage,
    required String stackTrace,
    required DeviceInfo deviceInfo,
    required AppStateSnapshot appState,
    ServiceChainSnapshot? serviceChainState,
    required NetworkSnapshot networkState,
    @Default([]) List<Breadcrumb> breadcrumbs,
  }) = _ErrorTrace;

  factory ErrorTrace.fromJson(Map<String, dynamic> json) =>
      _$ErrorTraceFromJson(json);
}

@freezed
abstract class DeviceInfo with _$DeviceInfo {
  const factory DeviceInfo({
    required String os,
    required String osVersion,
    required String platform,
    required String locale,
    required double screenWidth,
    required double screenHeight,
    required String appVersion,
  }) = _DeviceInfo;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);
}

@freezed
abstract class AppStateSnapshot with _$AppStateSnapshot {
  const factory AppStateSnapshot({
    String? activeRoute,
    String? activeProfileId,
    String? activeProfileName,
    String? lastApiEndpoint,
    String? lastSearchParams,
  }) = _AppStateSnapshot;

  factory AppStateSnapshot.fromJson(Map<String, dynamic> json) =>
      _$AppStateSnapshotFromJson(json);
}

@freezed
abstract class ServiceChainSnapshot with _$ServiceChainSnapshot {
  const factory ServiceChainSnapshot({
    @Default([]) List<ServiceAttempt> attempts,
    String? cachedDataAge,
  }) = _ServiceChainSnapshot;

  factory ServiceChainSnapshot.fromJson(Map<String, dynamic> json) =>
      _$ServiceChainSnapshotFromJson(json);
}

@freezed
abstract class ServiceAttempt with _$ServiceAttempt {
  const factory ServiceAttempt({
    required String serviceName,
    required bool succeeded,
    String? errorMessage,
    int? statusCode,
    required DateTime attemptedAt,
  }) = _ServiceAttempt;

  factory ServiceAttempt.fromJson(Map<String, dynamic> json) =>
      _$ServiceAttemptFromJson(json);
}

@freezed
abstract class NetworkSnapshot with _$NetworkSnapshot {
  const factory NetworkSnapshot({
    required bool isOnline,
    String? connectivityType,
  }) = _NetworkSnapshot;

  factory NetworkSnapshot.fromJson(Map<String, dynamic> json) =>
      _$NetworkSnapshotFromJson(json);
}

@freezed
abstract class Breadcrumb with _$Breadcrumb {
  const factory Breadcrumb({
    required DateTime timestamp,
    required String action,
    String? detail,
  }) = _Breadcrumb;

  factory Breadcrumb.fromJson(Map<String, dynamic> json) =>
      _$BreadcrumbFromJson(json);
}
