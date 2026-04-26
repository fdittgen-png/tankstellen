// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'error_trace.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ErrorTrace {

 String get id; DateTime get timestamp; String get timezoneOffset; ErrorCategory get category; String get errorType; String get errorMessage; String get stackTrace; DeviceInfo get deviceInfo; AppStateSnapshot get appState; ServiceChainSnapshot? get serviceChainState; NetworkSnapshot get networkState; List<Breadcrumb> get breadcrumbs;
/// Create a copy of ErrorTrace
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorTraceCopyWith<ErrorTrace> get copyWith => _$ErrorTraceCopyWithImpl<ErrorTrace>(this as ErrorTrace, _$identity);

  /// Serializes this ErrorTrace to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ErrorTrace&&(identical(other.id, id) || other.id == id)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.timezoneOffset, timezoneOffset) || other.timezoneOffset == timezoneOffset)&&(identical(other.category, category) || other.category == category)&&(identical(other.errorType, errorType) || other.errorType == errorType)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace)&&(identical(other.deviceInfo, deviceInfo) || other.deviceInfo == deviceInfo)&&(identical(other.appState, appState) || other.appState == appState)&&(identical(other.serviceChainState, serviceChainState) || other.serviceChainState == serviceChainState)&&(identical(other.networkState, networkState) || other.networkState == networkState)&&const DeepCollectionEquality().equals(other.breadcrumbs, breadcrumbs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,timestamp,timezoneOffset,category,errorType,errorMessage,stackTrace,deviceInfo,appState,serviceChainState,networkState,const DeepCollectionEquality().hash(breadcrumbs));

@override
String toString() {
  return 'ErrorTrace(id: $id, timestamp: $timestamp, timezoneOffset: $timezoneOffset, category: $category, errorType: $errorType, errorMessage: $errorMessage, stackTrace: $stackTrace, deviceInfo: $deviceInfo, appState: $appState, serviceChainState: $serviceChainState, networkState: $networkState, breadcrumbs: $breadcrumbs)';
}


}

/// @nodoc
abstract mixin class $ErrorTraceCopyWith<$Res>  {
  factory $ErrorTraceCopyWith(ErrorTrace value, $Res Function(ErrorTrace) _then) = _$ErrorTraceCopyWithImpl;
@useResult
$Res call({
 String id, DateTime timestamp, String timezoneOffset, ErrorCategory category, String errorType, String errorMessage, String stackTrace, DeviceInfo deviceInfo, AppStateSnapshot appState, ServiceChainSnapshot? serviceChainState, NetworkSnapshot networkState, List<Breadcrumb> breadcrumbs
});


$DeviceInfoCopyWith<$Res> get deviceInfo;$AppStateSnapshotCopyWith<$Res> get appState;$ServiceChainSnapshotCopyWith<$Res>? get serviceChainState;$NetworkSnapshotCopyWith<$Res> get networkState;

}
/// @nodoc
class _$ErrorTraceCopyWithImpl<$Res>
    implements $ErrorTraceCopyWith<$Res> {
  _$ErrorTraceCopyWithImpl(this._self, this._then);

  final ErrorTrace _self;
  final $Res Function(ErrorTrace) _then;

/// Create a copy of ErrorTrace
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? timestamp = null,Object? timezoneOffset = null,Object? category = null,Object? errorType = null,Object? errorMessage = null,Object? stackTrace = null,Object? deviceInfo = null,Object? appState = null,Object? serviceChainState = freezed,Object? networkState = null,Object? breadcrumbs = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,timezoneOffset: null == timezoneOffset ? _self.timezoneOffset : timezoneOffset // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ErrorCategory,errorType: null == errorType ? _self.errorType : errorType // ignore: cast_nullable_to_non_nullable
as String,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,stackTrace: null == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as String,deviceInfo: null == deviceInfo ? _self.deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as DeviceInfo,appState: null == appState ? _self.appState : appState // ignore: cast_nullable_to_non_nullable
as AppStateSnapshot,serviceChainState: freezed == serviceChainState ? _self.serviceChainState : serviceChainState // ignore: cast_nullable_to_non_nullable
as ServiceChainSnapshot?,networkState: null == networkState ? _self.networkState : networkState // ignore: cast_nullable_to_non_nullable
as NetworkSnapshot,breadcrumbs: null == breadcrumbs ? _self.breadcrumbs : breadcrumbs // ignore: cast_nullable_to_non_nullable
as List<Breadcrumb>,
  ));
}
/// Create a copy of ErrorTrace
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeviceInfoCopyWith<$Res> get deviceInfo {
  
  return $DeviceInfoCopyWith<$Res>(_self.deviceInfo, (value) {
    return _then(_self.copyWith(deviceInfo: value));
  });
}/// Create a copy of ErrorTrace
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppStateSnapshotCopyWith<$Res> get appState {
  
  return $AppStateSnapshotCopyWith<$Res>(_self.appState, (value) {
    return _then(_self.copyWith(appState: value));
  });
}/// Create a copy of ErrorTrace
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServiceChainSnapshotCopyWith<$Res>? get serviceChainState {
    if (_self.serviceChainState == null) {
    return null;
  }

  return $ServiceChainSnapshotCopyWith<$Res>(_self.serviceChainState!, (value) {
    return _then(_self.copyWith(serviceChainState: value));
  });
}/// Create a copy of ErrorTrace
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NetworkSnapshotCopyWith<$Res> get networkState {
  
  return $NetworkSnapshotCopyWith<$Res>(_self.networkState, (value) {
    return _then(_self.copyWith(networkState: value));
  });
}
}


/// Adds pattern-matching-related methods to [ErrorTrace].
extension ErrorTracePatterns on ErrorTrace {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ErrorTrace value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ErrorTrace() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ErrorTrace value)  $default,){
final _that = this;
switch (_that) {
case _ErrorTrace():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ErrorTrace value)?  $default,){
final _that = this;
switch (_that) {
case _ErrorTrace() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime timestamp,  String timezoneOffset,  ErrorCategory category,  String errorType,  String errorMessage,  String stackTrace,  DeviceInfo deviceInfo,  AppStateSnapshot appState,  ServiceChainSnapshot? serviceChainState,  NetworkSnapshot networkState,  List<Breadcrumb> breadcrumbs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ErrorTrace() when $default != null:
return $default(_that.id,_that.timestamp,_that.timezoneOffset,_that.category,_that.errorType,_that.errorMessage,_that.stackTrace,_that.deviceInfo,_that.appState,_that.serviceChainState,_that.networkState,_that.breadcrumbs);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime timestamp,  String timezoneOffset,  ErrorCategory category,  String errorType,  String errorMessage,  String stackTrace,  DeviceInfo deviceInfo,  AppStateSnapshot appState,  ServiceChainSnapshot? serviceChainState,  NetworkSnapshot networkState,  List<Breadcrumb> breadcrumbs)  $default,) {final _that = this;
switch (_that) {
case _ErrorTrace():
return $default(_that.id,_that.timestamp,_that.timezoneOffset,_that.category,_that.errorType,_that.errorMessage,_that.stackTrace,_that.deviceInfo,_that.appState,_that.serviceChainState,_that.networkState,_that.breadcrumbs);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime timestamp,  String timezoneOffset,  ErrorCategory category,  String errorType,  String errorMessage,  String stackTrace,  DeviceInfo deviceInfo,  AppStateSnapshot appState,  ServiceChainSnapshot? serviceChainState,  NetworkSnapshot networkState,  List<Breadcrumb> breadcrumbs)?  $default,) {final _that = this;
switch (_that) {
case _ErrorTrace() when $default != null:
return $default(_that.id,_that.timestamp,_that.timezoneOffset,_that.category,_that.errorType,_that.errorMessage,_that.stackTrace,_that.deviceInfo,_that.appState,_that.serviceChainState,_that.networkState,_that.breadcrumbs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ErrorTrace implements ErrorTrace {
  const _ErrorTrace({required this.id, required this.timestamp, required this.timezoneOffset, required this.category, required this.errorType, required this.errorMessage, required this.stackTrace, required this.deviceInfo, required this.appState, this.serviceChainState, required this.networkState, final  List<Breadcrumb> breadcrumbs = const []}): _breadcrumbs = breadcrumbs;
  factory _ErrorTrace.fromJson(Map<String, dynamic> json) => _$ErrorTraceFromJson(json);

@override final  String id;
@override final  DateTime timestamp;
@override final  String timezoneOffset;
@override final  ErrorCategory category;
@override final  String errorType;
@override final  String errorMessage;
@override final  String stackTrace;
@override final  DeviceInfo deviceInfo;
@override final  AppStateSnapshot appState;
@override final  ServiceChainSnapshot? serviceChainState;
@override final  NetworkSnapshot networkState;
 final  List<Breadcrumb> _breadcrumbs;
@override@JsonKey() List<Breadcrumb> get breadcrumbs {
  if (_breadcrumbs is EqualUnmodifiableListView) return _breadcrumbs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_breadcrumbs);
}


/// Create a copy of ErrorTrace
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorTraceCopyWith<_ErrorTrace> get copyWith => __$ErrorTraceCopyWithImpl<_ErrorTrace>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ErrorTraceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ErrorTrace&&(identical(other.id, id) || other.id == id)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.timezoneOffset, timezoneOffset) || other.timezoneOffset == timezoneOffset)&&(identical(other.category, category) || other.category == category)&&(identical(other.errorType, errorType) || other.errorType == errorType)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace)&&(identical(other.deviceInfo, deviceInfo) || other.deviceInfo == deviceInfo)&&(identical(other.appState, appState) || other.appState == appState)&&(identical(other.serviceChainState, serviceChainState) || other.serviceChainState == serviceChainState)&&(identical(other.networkState, networkState) || other.networkState == networkState)&&const DeepCollectionEquality().equals(other._breadcrumbs, _breadcrumbs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,timestamp,timezoneOffset,category,errorType,errorMessage,stackTrace,deviceInfo,appState,serviceChainState,networkState,const DeepCollectionEquality().hash(_breadcrumbs));

@override
String toString() {
  return 'ErrorTrace(id: $id, timestamp: $timestamp, timezoneOffset: $timezoneOffset, category: $category, errorType: $errorType, errorMessage: $errorMessage, stackTrace: $stackTrace, deviceInfo: $deviceInfo, appState: $appState, serviceChainState: $serviceChainState, networkState: $networkState, breadcrumbs: $breadcrumbs)';
}


}

/// @nodoc
abstract mixin class _$ErrorTraceCopyWith<$Res> implements $ErrorTraceCopyWith<$Res> {
  factory _$ErrorTraceCopyWith(_ErrorTrace value, $Res Function(_ErrorTrace) _then) = __$ErrorTraceCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime timestamp, String timezoneOffset, ErrorCategory category, String errorType, String errorMessage, String stackTrace, DeviceInfo deviceInfo, AppStateSnapshot appState, ServiceChainSnapshot? serviceChainState, NetworkSnapshot networkState, List<Breadcrumb> breadcrumbs
});


@override $DeviceInfoCopyWith<$Res> get deviceInfo;@override $AppStateSnapshotCopyWith<$Res> get appState;@override $ServiceChainSnapshotCopyWith<$Res>? get serviceChainState;@override $NetworkSnapshotCopyWith<$Res> get networkState;

}
/// @nodoc
class __$ErrorTraceCopyWithImpl<$Res>
    implements _$ErrorTraceCopyWith<$Res> {
  __$ErrorTraceCopyWithImpl(this._self, this._then);

  final _ErrorTrace _self;
  final $Res Function(_ErrorTrace) _then;

/// Create a copy of ErrorTrace
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? timestamp = null,Object? timezoneOffset = null,Object? category = null,Object? errorType = null,Object? errorMessage = null,Object? stackTrace = null,Object? deviceInfo = null,Object? appState = null,Object? serviceChainState = freezed,Object? networkState = null,Object? breadcrumbs = null,}) {
  return _then(_ErrorTrace(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,timezoneOffset: null == timezoneOffset ? _self.timezoneOffset : timezoneOffset // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ErrorCategory,errorType: null == errorType ? _self.errorType : errorType // ignore: cast_nullable_to_non_nullable
as String,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,stackTrace: null == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as String,deviceInfo: null == deviceInfo ? _self.deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as DeviceInfo,appState: null == appState ? _self.appState : appState // ignore: cast_nullable_to_non_nullable
as AppStateSnapshot,serviceChainState: freezed == serviceChainState ? _self.serviceChainState : serviceChainState // ignore: cast_nullable_to_non_nullable
as ServiceChainSnapshot?,networkState: null == networkState ? _self.networkState : networkState // ignore: cast_nullable_to_non_nullable
as NetworkSnapshot,breadcrumbs: null == breadcrumbs ? _self._breadcrumbs : breadcrumbs // ignore: cast_nullable_to_non_nullable
as List<Breadcrumb>,
  ));
}

/// Create a copy of ErrorTrace
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeviceInfoCopyWith<$Res> get deviceInfo {
  
  return $DeviceInfoCopyWith<$Res>(_self.deviceInfo, (value) {
    return _then(_self.copyWith(deviceInfo: value));
  });
}/// Create a copy of ErrorTrace
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppStateSnapshotCopyWith<$Res> get appState {
  
  return $AppStateSnapshotCopyWith<$Res>(_self.appState, (value) {
    return _then(_self.copyWith(appState: value));
  });
}/// Create a copy of ErrorTrace
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServiceChainSnapshotCopyWith<$Res>? get serviceChainState {
    if (_self.serviceChainState == null) {
    return null;
  }

  return $ServiceChainSnapshotCopyWith<$Res>(_self.serviceChainState!, (value) {
    return _then(_self.copyWith(serviceChainState: value));
  });
}/// Create a copy of ErrorTrace
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NetworkSnapshotCopyWith<$Res> get networkState {
  
  return $NetworkSnapshotCopyWith<$Res>(_self.networkState, (value) {
    return _then(_self.copyWith(networkState: value));
  });
}
}


/// @nodoc
mixin _$DeviceInfo {

 String get os; String get osVersion; String get platform; String get locale; double get screenWidth; double get screenHeight; String get appVersion;
/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceInfoCopyWith<DeviceInfo> get copyWith => _$DeviceInfoCopyWithImpl<DeviceInfo>(this as DeviceInfo, _$identity);

  /// Serializes this DeviceInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceInfo&&(identical(other.os, os) || other.os == os)&&(identical(other.osVersion, osVersion) || other.osVersion == osVersion)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.screenWidth, screenWidth) || other.screenWidth == screenWidth)&&(identical(other.screenHeight, screenHeight) || other.screenHeight == screenHeight)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,os,osVersion,platform,locale,screenWidth,screenHeight,appVersion);

@override
String toString() {
  return 'DeviceInfo(os: $os, osVersion: $osVersion, platform: $platform, locale: $locale, screenWidth: $screenWidth, screenHeight: $screenHeight, appVersion: $appVersion)';
}


}

/// @nodoc
abstract mixin class $DeviceInfoCopyWith<$Res>  {
  factory $DeviceInfoCopyWith(DeviceInfo value, $Res Function(DeviceInfo) _then) = _$DeviceInfoCopyWithImpl;
@useResult
$Res call({
 String os, String osVersion, String platform, String locale, double screenWidth, double screenHeight, String appVersion
});




}
/// @nodoc
class _$DeviceInfoCopyWithImpl<$Res>
    implements $DeviceInfoCopyWith<$Res> {
  _$DeviceInfoCopyWithImpl(this._self, this._then);

  final DeviceInfo _self;
  final $Res Function(DeviceInfo) _then;

/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? os = null,Object? osVersion = null,Object? platform = null,Object? locale = null,Object? screenWidth = null,Object? screenHeight = null,Object? appVersion = null,}) {
  return _then(_self.copyWith(
os: null == os ? _self.os : os // ignore: cast_nullable_to_non_nullable
as String,osVersion: null == osVersion ? _self.osVersion : osVersion // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,screenWidth: null == screenWidth ? _self.screenWidth : screenWidth // ignore: cast_nullable_to_non_nullable
as double,screenHeight: null == screenHeight ? _self.screenHeight : screenHeight // ignore: cast_nullable_to_non_nullable
as double,appVersion: null == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceInfo].
extension DeviceInfoPatterns on DeviceInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceInfo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceInfo value)  $default,){
final _that = this;
switch (_that) {
case _DeviceInfo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceInfo value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceInfo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String os,  String osVersion,  String platform,  String locale,  double screenWidth,  double screenHeight,  String appVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceInfo() when $default != null:
return $default(_that.os,_that.osVersion,_that.platform,_that.locale,_that.screenWidth,_that.screenHeight,_that.appVersion);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String os,  String osVersion,  String platform,  String locale,  double screenWidth,  double screenHeight,  String appVersion)  $default,) {final _that = this;
switch (_that) {
case _DeviceInfo():
return $default(_that.os,_that.osVersion,_that.platform,_that.locale,_that.screenWidth,_that.screenHeight,_that.appVersion);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String os,  String osVersion,  String platform,  String locale,  double screenWidth,  double screenHeight,  String appVersion)?  $default,) {final _that = this;
switch (_that) {
case _DeviceInfo() when $default != null:
return $default(_that.os,_that.osVersion,_that.platform,_that.locale,_that.screenWidth,_that.screenHeight,_that.appVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceInfo implements DeviceInfo {
  const _DeviceInfo({required this.os, required this.osVersion, required this.platform, required this.locale, required this.screenWidth, required this.screenHeight, required this.appVersion});
  factory _DeviceInfo.fromJson(Map<String, dynamic> json) => _$DeviceInfoFromJson(json);

@override final  String os;
@override final  String osVersion;
@override final  String platform;
@override final  String locale;
@override final  double screenWidth;
@override final  double screenHeight;
@override final  String appVersion;

/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceInfoCopyWith<_DeviceInfo> get copyWith => __$DeviceInfoCopyWithImpl<_DeviceInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceInfo&&(identical(other.os, os) || other.os == os)&&(identical(other.osVersion, osVersion) || other.osVersion == osVersion)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.screenWidth, screenWidth) || other.screenWidth == screenWidth)&&(identical(other.screenHeight, screenHeight) || other.screenHeight == screenHeight)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,os,osVersion,platform,locale,screenWidth,screenHeight,appVersion);

@override
String toString() {
  return 'DeviceInfo(os: $os, osVersion: $osVersion, platform: $platform, locale: $locale, screenWidth: $screenWidth, screenHeight: $screenHeight, appVersion: $appVersion)';
}


}

/// @nodoc
abstract mixin class _$DeviceInfoCopyWith<$Res> implements $DeviceInfoCopyWith<$Res> {
  factory _$DeviceInfoCopyWith(_DeviceInfo value, $Res Function(_DeviceInfo) _then) = __$DeviceInfoCopyWithImpl;
@override @useResult
$Res call({
 String os, String osVersion, String platform, String locale, double screenWidth, double screenHeight, String appVersion
});




}
/// @nodoc
class __$DeviceInfoCopyWithImpl<$Res>
    implements _$DeviceInfoCopyWith<$Res> {
  __$DeviceInfoCopyWithImpl(this._self, this._then);

  final _DeviceInfo _self;
  final $Res Function(_DeviceInfo) _then;

/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? os = null,Object? osVersion = null,Object? platform = null,Object? locale = null,Object? screenWidth = null,Object? screenHeight = null,Object? appVersion = null,}) {
  return _then(_DeviceInfo(
os: null == os ? _self.os : os // ignore: cast_nullable_to_non_nullable
as String,osVersion: null == osVersion ? _self.osVersion : osVersion // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,screenWidth: null == screenWidth ? _self.screenWidth : screenWidth // ignore: cast_nullable_to_non_nullable
as double,screenHeight: null == screenHeight ? _self.screenHeight : screenHeight // ignore: cast_nullable_to_non_nullable
as double,appVersion: null == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AppStateSnapshot {

 String? get activeRoute; String? get activeProfileId; String? get activeProfileName; String? get lastApiEndpoint; String? get lastSearchParams;
/// Create a copy of AppStateSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppStateSnapshotCopyWith<AppStateSnapshot> get copyWith => _$AppStateSnapshotCopyWithImpl<AppStateSnapshot>(this as AppStateSnapshot, _$identity);

  /// Serializes this AppStateSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppStateSnapshot&&(identical(other.activeRoute, activeRoute) || other.activeRoute == activeRoute)&&(identical(other.activeProfileId, activeProfileId) || other.activeProfileId == activeProfileId)&&(identical(other.activeProfileName, activeProfileName) || other.activeProfileName == activeProfileName)&&(identical(other.lastApiEndpoint, lastApiEndpoint) || other.lastApiEndpoint == lastApiEndpoint)&&(identical(other.lastSearchParams, lastSearchParams) || other.lastSearchParams == lastSearchParams));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,activeRoute,activeProfileId,activeProfileName,lastApiEndpoint,lastSearchParams);

@override
String toString() {
  return 'AppStateSnapshot(activeRoute: $activeRoute, activeProfileId: $activeProfileId, activeProfileName: $activeProfileName, lastApiEndpoint: $lastApiEndpoint, lastSearchParams: $lastSearchParams)';
}


}

/// @nodoc
abstract mixin class $AppStateSnapshotCopyWith<$Res>  {
  factory $AppStateSnapshotCopyWith(AppStateSnapshot value, $Res Function(AppStateSnapshot) _then) = _$AppStateSnapshotCopyWithImpl;
@useResult
$Res call({
 String? activeRoute, String? activeProfileId, String? activeProfileName, String? lastApiEndpoint, String? lastSearchParams
});




}
/// @nodoc
class _$AppStateSnapshotCopyWithImpl<$Res>
    implements $AppStateSnapshotCopyWith<$Res> {
  _$AppStateSnapshotCopyWithImpl(this._self, this._then);

  final AppStateSnapshot _self;
  final $Res Function(AppStateSnapshot) _then;

/// Create a copy of AppStateSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activeRoute = freezed,Object? activeProfileId = freezed,Object? activeProfileName = freezed,Object? lastApiEndpoint = freezed,Object? lastSearchParams = freezed,}) {
  return _then(_self.copyWith(
activeRoute: freezed == activeRoute ? _self.activeRoute : activeRoute // ignore: cast_nullable_to_non_nullable
as String?,activeProfileId: freezed == activeProfileId ? _self.activeProfileId : activeProfileId // ignore: cast_nullable_to_non_nullable
as String?,activeProfileName: freezed == activeProfileName ? _self.activeProfileName : activeProfileName // ignore: cast_nullable_to_non_nullable
as String?,lastApiEndpoint: freezed == lastApiEndpoint ? _self.lastApiEndpoint : lastApiEndpoint // ignore: cast_nullable_to_non_nullable
as String?,lastSearchParams: freezed == lastSearchParams ? _self.lastSearchParams : lastSearchParams // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppStateSnapshot].
extension AppStateSnapshotPatterns on AppStateSnapshot {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppStateSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppStateSnapshot() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppStateSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _AppStateSnapshot():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppStateSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _AppStateSnapshot() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? activeRoute,  String? activeProfileId,  String? activeProfileName,  String? lastApiEndpoint,  String? lastSearchParams)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppStateSnapshot() when $default != null:
return $default(_that.activeRoute,_that.activeProfileId,_that.activeProfileName,_that.lastApiEndpoint,_that.lastSearchParams);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? activeRoute,  String? activeProfileId,  String? activeProfileName,  String? lastApiEndpoint,  String? lastSearchParams)  $default,) {final _that = this;
switch (_that) {
case _AppStateSnapshot():
return $default(_that.activeRoute,_that.activeProfileId,_that.activeProfileName,_that.lastApiEndpoint,_that.lastSearchParams);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? activeRoute,  String? activeProfileId,  String? activeProfileName,  String? lastApiEndpoint,  String? lastSearchParams)?  $default,) {final _that = this;
switch (_that) {
case _AppStateSnapshot() when $default != null:
return $default(_that.activeRoute,_that.activeProfileId,_that.activeProfileName,_that.lastApiEndpoint,_that.lastSearchParams);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppStateSnapshot implements AppStateSnapshot {
  const _AppStateSnapshot({this.activeRoute, this.activeProfileId, this.activeProfileName, this.lastApiEndpoint, this.lastSearchParams});
  factory _AppStateSnapshot.fromJson(Map<String, dynamic> json) => _$AppStateSnapshotFromJson(json);

@override final  String? activeRoute;
@override final  String? activeProfileId;
@override final  String? activeProfileName;
@override final  String? lastApiEndpoint;
@override final  String? lastSearchParams;

/// Create a copy of AppStateSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppStateSnapshotCopyWith<_AppStateSnapshot> get copyWith => __$AppStateSnapshotCopyWithImpl<_AppStateSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppStateSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppStateSnapshot&&(identical(other.activeRoute, activeRoute) || other.activeRoute == activeRoute)&&(identical(other.activeProfileId, activeProfileId) || other.activeProfileId == activeProfileId)&&(identical(other.activeProfileName, activeProfileName) || other.activeProfileName == activeProfileName)&&(identical(other.lastApiEndpoint, lastApiEndpoint) || other.lastApiEndpoint == lastApiEndpoint)&&(identical(other.lastSearchParams, lastSearchParams) || other.lastSearchParams == lastSearchParams));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,activeRoute,activeProfileId,activeProfileName,lastApiEndpoint,lastSearchParams);

@override
String toString() {
  return 'AppStateSnapshot(activeRoute: $activeRoute, activeProfileId: $activeProfileId, activeProfileName: $activeProfileName, lastApiEndpoint: $lastApiEndpoint, lastSearchParams: $lastSearchParams)';
}


}

/// @nodoc
abstract mixin class _$AppStateSnapshotCopyWith<$Res> implements $AppStateSnapshotCopyWith<$Res> {
  factory _$AppStateSnapshotCopyWith(_AppStateSnapshot value, $Res Function(_AppStateSnapshot) _then) = __$AppStateSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String? activeRoute, String? activeProfileId, String? activeProfileName, String? lastApiEndpoint, String? lastSearchParams
});




}
/// @nodoc
class __$AppStateSnapshotCopyWithImpl<$Res>
    implements _$AppStateSnapshotCopyWith<$Res> {
  __$AppStateSnapshotCopyWithImpl(this._self, this._then);

  final _AppStateSnapshot _self;
  final $Res Function(_AppStateSnapshot) _then;

/// Create a copy of AppStateSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activeRoute = freezed,Object? activeProfileId = freezed,Object? activeProfileName = freezed,Object? lastApiEndpoint = freezed,Object? lastSearchParams = freezed,}) {
  return _then(_AppStateSnapshot(
activeRoute: freezed == activeRoute ? _self.activeRoute : activeRoute // ignore: cast_nullable_to_non_nullable
as String?,activeProfileId: freezed == activeProfileId ? _self.activeProfileId : activeProfileId // ignore: cast_nullable_to_non_nullable
as String?,activeProfileName: freezed == activeProfileName ? _self.activeProfileName : activeProfileName // ignore: cast_nullable_to_non_nullable
as String?,lastApiEndpoint: freezed == lastApiEndpoint ? _self.lastApiEndpoint : lastApiEndpoint // ignore: cast_nullable_to_non_nullable
as String?,lastSearchParams: freezed == lastSearchParams ? _self.lastSearchParams : lastSearchParams // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ServiceChainSnapshot {

 List<ServiceAttempt> get attempts; String? get cachedDataAge;
/// Create a copy of ServiceChainSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceChainSnapshotCopyWith<ServiceChainSnapshot> get copyWith => _$ServiceChainSnapshotCopyWithImpl<ServiceChainSnapshot>(this as ServiceChainSnapshot, _$identity);

  /// Serializes this ServiceChainSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceChainSnapshot&&const DeepCollectionEquality().equals(other.attempts, attempts)&&(identical(other.cachedDataAge, cachedDataAge) || other.cachedDataAge == cachedDataAge));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(attempts),cachedDataAge);

@override
String toString() {
  return 'ServiceChainSnapshot(attempts: $attempts, cachedDataAge: $cachedDataAge)';
}


}

/// @nodoc
abstract mixin class $ServiceChainSnapshotCopyWith<$Res>  {
  factory $ServiceChainSnapshotCopyWith(ServiceChainSnapshot value, $Res Function(ServiceChainSnapshot) _then) = _$ServiceChainSnapshotCopyWithImpl;
@useResult
$Res call({
 List<ServiceAttempt> attempts, String? cachedDataAge
});




}
/// @nodoc
class _$ServiceChainSnapshotCopyWithImpl<$Res>
    implements $ServiceChainSnapshotCopyWith<$Res> {
  _$ServiceChainSnapshotCopyWithImpl(this._self, this._then);

  final ServiceChainSnapshot _self;
  final $Res Function(ServiceChainSnapshot) _then;

/// Create a copy of ServiceChainSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? attempts = null,Object? cachedDataAge = freezed,}) {
  return _then(_self.copyWith(
attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as List<ServiceAttempt>,cachedDataAge: freezed == cachedDataAge ? _self.cachedDataAge : cachedDataAge // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceChainSnapshot].
extension ServiceChainSnapshotPatterns on ServiceChainSnapshot {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceChainSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceChainSnapshot() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceChainSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _ServiceChainSnapshot():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceChainSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceChainSnapshot() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ServiceAttempt> attempts,  String? cachedDataAge)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceChainSnapshot() when $default != null:
return $default(_that.attempts,_that.cachedDataAge);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ServiceAttempt> attempts,  String? cachedDataAge)  $default,) {final _that = this;
switch (_that) {
case _ServiceChainSnapshot():
return $default(_that.attempts,_that.cachedDataAge);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ServiceAttempt> attempts,  String? cachedDataAge)?  $default,) {final _that = this;
switch (_that) {
case _ServiceChainSnapshot() when $default != null:
return $default(_that.attempts,_that.cachedDataAge);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServiceChainSnapshot implements ServiceChainSnapshot {
  const _ServiceChainSnapshot({final  List<ServiceAttempt> attempts = const [], this.cachedDataAge}): _attempts = attempts;
  factory _ServiceChainSnapshot.fromJson(Map<String, dynamic> json) => _$ServiceChainSnapshotFromJson(json);

 final  List<ServiceAttempt> _attempts;
@override@JsonKey() List<ServiceAttempt> get attempts {
  if (_attempts is EqualUnmodifiableListView) return _attempts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attempts);
}

@override final  String? cachedDataAge;

/// Create a copy of ServiceChainSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceChainSnapshotCopyWith<_ServiceChainSnapshot> get copyWith => __$ServiceChainSnapshotCopyWithImpl<_ServiceChainSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceChainSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceChainSnapshot&&const DeepCollectionEquality().equals(other._attempts, _attempts)&&(identical(other.cachedDataAge, cachedDataAge) || other.cachedDataAge == cachedDataAge));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_attempts),cachedDataAge);

@override
String toString() {
  return 'ServiceChainSnapshot(attempts: $attempts, cachedDataAge: $cachedDataAge)';
}


}

/// @nodoc
abstract mixin class _$ServiceChainSnapshotCopyWith<$Res> implements $ServiceChainSnapshotCopyWith<$Res> {
  factory _$ServiceChainSnapshotCopyWith(_ServiceChainSnapshot value, $Res Function(_ServiceChainSnapshot) _then) = __$ServiceChainSnapshotCopyWithImpl;
@override @useResult
$Res call({
 List<ServiceAttempt> attempts, String? cachedDataAge
});




}
/// @nodoc
class __$ServiceChainSnapshotCopyWithImpl<$Res>
    implements _$ServiceChainSnapshotCopyWith<$Res> {
  __$ServiceChainSnapshotCopyWithImpl(this._self, this._then);

  final _ServiceChainSnapshot _self;
  final $Res Function(_ServiceChainSnapshot) _then;

/// Create a copy of ServiceChainSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? attempts = null,Object? cachedDataAge = freezed,}) {
  return _then(_ServiceChainSnapshot(
attempts: null == attempts ? _self._attempts : attempts // ignore: cast_nullable_to_non_nullable
as List<ServiceAttempt>,cachedDataAge: freezed == cachedDataAge ? _self.cachedDataAge : cachedDataAge // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ServiceAttempt {

 String get serviceName; bool get succeeded; String? get errorMessage; int? get statusCode; DateTime get attemptedAt;
/// Create a copy of ServiceAttempt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceAttemptCopyWith<ServiceAttempt> get copyWith => _$ServiceAttemptCopyWithImpl<ServiceAttempt>(this as ServiceAttempt, _$identity);

  /// Serializes this ServiceAttempt to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceAttempt&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.succeeded, succeeded) || other.succeeded == succeeded)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.attemptedAt, attemptedAt) || other.attemptedAt == attemptedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serviceName,succeeded,errorMessage,statusCode,attemptedAt);

@override
String toString() {
  return 'ServiceAttempt(serviceName: $serviceName, succeeded: $succeeded, errorMessage: $errorMessage, statusCode: $statusCode, attemptedAt: $attemptedAt)';
}


}

/// @nodoc
abstract mixin class $ServiceAttemptCopyWith<$Res>  {
  factory $ServiceAttemptCopyWith(ServiceAttempt value, $Res Function(ServiceAttempt) _then) = _$ServiceAttemptCopyWithImpl;
@useResult
$Res call({
 String serviceName, bool succeeded, String? errorMessage, int? statusCode, DateTime attemptedAt
});




}
/// @nodoc
class _$ServiceAttemptCopyWithImpl<$Res>
    implements $ServiceAttemptCopyWith<$Res> {
  _$ServiceAttemptCopyWithImpl(this._self, this._then);

  final ServiceAttempt _self;
  final $Res Function(ServiceAttempt) _then;

/// Create a copy of ServiceAttempt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serviceName = null,Object? succeeded = null,Object? errorMessage = freezed,Object? statusCode = freezed,Object? attemptedAt = null,}) {
  return _then(_self.copyWith(
serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,succeeded: null == succeeded ? _self.succeeded : succeeded // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,statusCode: freezed == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int?,attemptedAt: null == attemptedAt ? _self.attemptedAt : attemptedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceAttempt].
extension ServiceAttemptPatterns on ServiceAttempt {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceAttempt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceAttempt() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceAttempt value)  $default,){
final _that = this;
switch (_that) {
case _ServiceAttempt():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceAttempt value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceAttempt() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String serviceName,  bool succeeded,  String? errorMessage,  int? statusCode,  DateTime attemptedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceAttempt() when $default != null:
return $default(_that.serviceName,_that.succeeded,_that.errorMessage,_that.statusCode,_that.attemptedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String serviceName,  bool succeeded,  String? errorMessage,  int? statusCode,  DateTime attemptedAt)  $default,) {final _that = this;
switch (_that) {
case _ServiceAttempt():
return $default(_that.serviceName,_that.succeeded,_that.errorMessage,_that.statusCode,_that.attemptedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String serviceName,  bool succeeded,  String? errorMessage,  int? statusCode,  DateTime attemptedAt)?  $default,) {final _that = this;
switch (_that) {
case _ServiceAttempt() when $default != null:
return $default(_that.serviceName,_that.succeeded,_that.errorMessage,_that.statusCode,_that.attemptedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServiceAttempt implements ServiceAttempt {
  const _ServiceAttempt({required this.serviceName, required this.succeeded, this.errorMessage, this.statusCode, required this.attemptedAt});
  factory _ServiceAttempt.fromJson(Map<String, dynamic> json) => _$ServiceAttemptFromJson(json);

@override final  String serviceName;
@override final  bool succeeded;
@override final  String? errorMessage;
@override final  int? statusCode;
@override final  DateTime attemptedAt;

/// Create a copy of ServiceAttempt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceAttemptCopyWith<_ServiceAttempt> get copyWith => __$ServiceAttemptCopyWithImpl<_ServiceAttempt>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceAttemptToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceAttempt&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.succeeded, succeeded) || other.succeeded == succeeded)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.attemptedAt, attemptedAt) || other.attemptedAt == attemptedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serviceName,succeeded,errorMessage,statusCode,attemptedAt);

@override
String toString() {
  return 'ServiceAttempt(serviceName: $serviceName, succeeded: $succeeded, errorMessage: $errorMessage, statusCode: $statusCode, attemptedAt: $attemptedAt)';
}


}

/// @nodoc
abstract mixin class _$ServiceAttemptCopyWith<$Res> implements $ServiceAttemptCopyWith<$Res> {
  factory _$ServiceAttemptCopyWith(_ServiceAttempt value, $Res Function(_ServiceAttempt) _then) = __$ServiceAttemptCopyWithImpl;
@override @useResult
$Res call({
 String serviceName, bool succeeded, String? errorMessage, int? statusCode, DateTime attemptedAt
});




}
/// @nodoc
class __$ServiceAttemptCopyWithImpl<$Res>
    implements _$ServiceAttemptCopyWith<$Res> {
  __$ServiceAttemptCopyWithImpl(this._self, this._then);

  final _ServiceAttempt _self;
  final $Res Function(_ServiceAttempt) _then;

/// Create a copy of ServiceAttempt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serviceName = null,Object? succeeded = null,Object? errorMessage = freezed,Object? statusCode = freezed,Object? attemptedAt = null,}) {
  return _then(_ServiceAttempt(
serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,succeeded: null == succeeded ? _self.succeeded : succeeded // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,statusCode: freezed == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int?,attemptedAt: null == attemptedAt ? _self.attemptedAt : attemptedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$NetworkSnapshot {

 bool get isOnline; String? get connectivityType;
/// Create a copy of NetworkSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkSnapshotCopyWith<NetworkSnapshot> get copyWith => _$NetworkSnapshotCopyWithImpl<NetworkSnapshot>(this as NetworkSnapshot, _$identity);

  /// Serializes this NetworkSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkSnapshot&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.connectivityType, connectivityType) || other.connectivityType == connectivityType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isOnline,connectivityType);

@override
String toString() {
  return 'NetworkSnapshot(isOnline: $isOnline, connectivityType: $connectivityType)';
}


}

/// @nodoc
abstract mixin class $NetworkSnapshotCopyWith<$Res>  {
  factory $NetworkSnapshotCopyWith(NetworkSnapshot value, $Res Function(NetworkSnapshot) _then) = _$NetworkSnapshotCopyWithImpl;
@useResult
$Res call({
 bool isOnline, String? connectivityType
});




}
/// @nodoc
class _$NetworkSnapshotCopyWithImpl<$Res>
    implements $NetworkSnapshotCopyWith<$Res> {
  _$NetworkSnapshotCopyWithImpl(this._self, this._then);

  final NetworkSnapshot _self;
  final $Res Function(NetworkSnapshot) _then;

/// Create a copy of NetworkSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isOnline = null,Object? connectivityType = freezed,}) {
  return _then(_self.copyWith(
isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,connectivityType: freezed == connectivityType ? _self.connectivityType : connectivityType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NetworkSnapshot].
extension NetworkSnapshotPatterns on NetworkSnapshot {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NetworkSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NetworkSnapshot() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NetworkSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _NetworkSnapshot():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NetworkSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _NetworkSnapshot() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isOnline,  String? connectivityType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NetworkSnapshot() when $default != null:
return $default(_that.isOnline,_that.connectivityType);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isOnline,  String? connectivityType)  $default,) {final _that = this;
switch (_that) {
case _NetworkSnapshot():
return $default(_that.isOnline,_that.connectivityType);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isOnline,  String? connectivityType)?  $default,) {final _that = this;
switch (_that) {
case _NetworkSnapshot() when $default != null:
return $default(_that.isOnline,_that.connectivityType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NetworkSnapshot implements NetworkSnapshot {
  const _NetworkSnapshot({required this.isOnline, this.connectivityType});
  factory _NetworkSnapshot.fromJson(Map<String, dynamic> json) => _$NetworkSnapshotFromJson(json);

@override final  bool isOnline;
@override final  String? connectivityType;

/// Create a copy of NetworkSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetworkSnapshotCopyWith<_NetworkSnapshot> get copyWith => __$NetworkSnapshotCopyWithImpl<_NetworkSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NetworkSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkSnapshot&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.connectivityType, connectivityType) || other.connectivityType == connectivityType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isOnline,connectivityType);

@override
String toString() {
  return 'NetworkSnapshot(isOnline: $isOnline, connectivityType: $connectivityType)';
}


}

/// @nodoc
abstract mixin class _$NetworkSnapshotCopyWith<$Res> implements $NetworkSnapshotCopyWith<$Res> {
  factory _$NetworkSnapshotCopyWith(_NetworkSnapshot value, $Res Function(_NetworkSnapshot) _then) = __$NetworkSnapshotCopyWithImpl;
@override @useResult
$Res call({
 bool isOnline, String? connectivityType
});




}
/// @nodoc
class __$NetworkSnapshotCopyWithImpl<$Res>
    implements _$NetworkSnapshotCopyWith<$Res> {
  __$NetworkSnapshotCopyWithImpl(this._self, this._then);

  final _NetworkSnapshot _self;
  final $Res Function(_NetworkSnapshot) _then;

/// Create a copy of NetworkSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isOnline = null,Object? connectivityType = freezed,}) {
  return _then(_NetworkSnapshot(
isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,connectivityType: freezed == connectivityType ? _self.connectivityType : connectivityType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Breadcrumb {

 DateTime get timestamp; String get action; String? get detail;
/// Create a copy of Breadcrumb
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BreadcrumbCopyWith<Breadcrumb> get copyWith => _$BreadcrumbCopyWithImpl<Breadcrumb>(this as Breadcrumb, _$identity);

  /// Serializes this Breadcrumb to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Breadcrumb&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.action, action) || other.action == action)&&(identical(other.detail, detail) || other.detail == detail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,action,detail);

@override
String toString() {
  return 'Breadcrumb(timestamp: $timestamp, action: $action, detail: $detail)';
}


}

/// @nodoc
abstract mixin class $BreadcrumbCopyWith<$Res>  {
  factory $BreadcrumbCopyWith(Breadcrumb value, $Res Function(Breadcrumb) _then) = _$BreadcrumbCopyWithImpl;
@useResult
$Res call({
 DateTime timestamp, String action, String? detail
});




}
/// @nodoc
class _$BreadcrumbCopyWithImpl<$Res>
    implements $BreadcrumbCopyWith<$Res> {
  _$BreadcrumbCopyWithImpl(this._self, this._then);

  final Breadcrumb _self;
  final $Res Function(Breadcrumb) _then;

/// Create a copy of Breadcrumb
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timestamp = null,Object? action = null,Object? detail = freezed,}) {
  return _then(_self.copyWith(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Breadcrumb].
extension BreadcrumbPatterns on Breadcrumb {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Breadcrumb value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Breadcrumb() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Breadcrumb value)  $default,){
final _that = this;
switch (_that) {
case _Breadcrumb():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Breadcrumb value)?  $default,){
final _that = this;
switch (_that) {
case _Breadcrumb() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime timestamp,  String action,  String? detail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Breadcrumb() when $default != null:
return $default(_that.timestamp,_that.action,_that.detail);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime timestamp,  String action,  String? detail)  $default,) {final _that = this;
switch (_that) {
case _Breadcrumb():
return $default(_that.timestamp,_that.action,_that.detail);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime timestamp,  String action,  String? detail)?  $default,) {final _that = this;
switch (_that) {
case _Breadcrumb() when $default != null:
return $default(_that.timestamp,_that.action,_that.detail);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Breadcrumb implements Breadcrumb {
  const _Breadcrumb({required this.timestamp, required this.action, this.detail});
  factory _Breadcrumb.fromJson(Map<String, dynamic> json) => _$BreadcrumbFromJson(json);

@override final  DateTime timestamp;
@override final  String action;
@override final  String? detail;

/// Create a copy of Breadcrumb
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BreadcrumbCopyWith<_Breadcrumb> get copyWith => __$BreadcrumbCopyWithImpl<_Breadcrumb>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BreadcrumbToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Breadcrumb&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.action, action) || other.action == action)&&(identical(other.detail, detail) || other.detail == detail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,action,detail);

@override
String toString() {
  return 'Breadcrumb(timestamp: $timestamp, action: $action, detail: $detail)';
}


}

/// @nodoc
abstract mixin class _$BreadcrumbCopyWith<$Res> implements $BreadcrumbCopyWith<$Res> {
  factory _$BreadcrumbCopyWith(_Breadcrumb value, $Res Function(_Breadcrumb) _then) = __$BreadcrumbCopyWithImpl;
@override @useResult
$Res call({
 DateTime timestamp, String action, String? detail
});




}
/// @nodoc
class __$BreadcrumbCopyWithImpl<$Res>
    implements _$BreadcrumbCopyWith<$Res> {
  __$BreadcrumbCopyWithImpl(this._self, this._then);

  final _Breadcrumb _self;
  final $Res Function(_Breadcrumb) _then;

/// Create a copy of Breadcrumb
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timestamp = null,Object? action = null,Object? detail = freezed,}) {
  return _then(_Breadcrumb(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
