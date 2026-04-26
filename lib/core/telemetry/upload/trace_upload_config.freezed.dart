// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trace_upload_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TraceUploadConfig {

 bool get enabled; String? get serverUrl; String? get authToken;
/// Create a copy of TraceUploadConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TraceUploadConfigCopyWith<TraceUploadConfig> get copyWith => _$TraceUploadConfigCopyWithImpl<TraceUploadConfig>(this as TraceUploadConfig, _$identity);

  /// Serializes this TraceUploadConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TraceUploadConfig&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.serverUrl, serverUrl) || other.serverUrl == serverUrl)&&(identical(other.authToken, authToken) || other.authToken == authToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,serverUrl,authToken);

@override
String toString() {
  return 'TraceUploadConfig(enabled: $enabled, serverUrl: $serverUrl, authToken: $authToken)';
}


}

/// @nodoc
abstract mixin class $TraceUploadConfigCopyWith<$Res>  {
  factory $TraceUploadConfigCopyWith(TraceUploadConfig value, $Res Function(TraceUploadConfig) _then) = _$TraceUploadConfigCopyWithImpl;
@useResult
$Res call({
 bool enabled, String? serverUrl, String? authToken
});




}
/// @nodoc
class _$TraceUploadConfigCopyWithImpl<$Res>
    implements $TraceUploadConfigCopyWith<$Res> {
  _$TraceUploadConfigCopyWithImpl(this._self, this._then);

  final TraceUploadConfig _self;
  final $Res Function(TraceUploadConfig) _then;

/// Create a copy of TraceUploadConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? serverUrl = freezed,Object? authToken = freezed,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,serverUrl: freezed == serverUrl ? _self.serverUrl : serverUrl // ignore: cast_nullable_to_non_nullable
as String?,authToken: freezed == authToken ? _self.authToken : authToken // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TraceUploadConfig].
extension TraceUploadConfigPatterns on TraceUploadConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TraceUploadConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TraceUploadConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TraceUploadConfig value)  $default,){
final _that = this;
switch (_that) {
case _TraceUploadConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TraceUploadConfig value)?  $default,){
final _that = this;
switch (_that) {
case _TraceUploadConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  String? serverUrl,  String? authToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TraceUploadConfig() when $default != null:
return $default(_that.enabled,_that.serverUrl,_that.authToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  String? serverUrl,  String? authToken)  $default,) {final _that = this;
switch (_that) {
case _TraceUploadConfig():
return $default(_that.enabled,_that.serverUrl,_that.authToken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  String? serverUrl,  String? authToken)?  $default,) {final _that = this;
switch (_that) {
case _TraceUploadConfig() when $default != null:
return $default(_that.enabled,_that.serverUrl,_that.authToken);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TraceUploadConfig implements TraceUploadConfig {
  const _TraceUploadConfig({this.enabled = false, this.serverUrl, this.authToken});
  factory _TraceUploadConfig.fromJson(Map<String, dynamic> json) => _$TraceUploadConfigFromJson(json);

@override@JsonKey() final  bool enabled;
@override final  String? serverUrl;
@override final  String? authToken;

/// Create a copy of TraceUploadConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TraceUploadConfigCopyWith<_TraceUploadConfig> get copyWith => __$TraceUploadConfigCopyWithImpl<_TraceUploadConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TraceUploadConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TraceUploadConfig&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.serverUrl, serverUrl) || other.serverUrl == serverUrl)&&(identical(other.authToken, authToken) || other.authToken == authToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,serverUrl,authToken);

@override
String toString() {
  return 'TraceUploadConfig(enabled: $enabled, serverUrl: $serverUrl, authToken: $authToken)';
}


}

/// @nodoc
abstract mixin class _$TraceUploadConfigCopyWith<$Res> implements $TraceUploadConfigCopyWith<$Res> {
  factory _$TraceUploadConfigCopyWith(_TraceUploadConfig value, $Res Function(_TraceUploadConfig) _then) = __$TraceUploadConfigCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, String? serverUrl, String? authToken
});




}
/// @nodoc
class __$TraceUploadConfigCopyWithImpl<$Res>
    implements _$TraceUploadConfigCopyWith<$Res> {
  __$TraceUploadConfigCopyWithImpl(this._self, this._then);

  final _TraceUploadConfig _self;
  final $Res Function(_TraceUploadConfig) _then;

/// Create a copy of TraceUploadConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? serverUrl = freezed,Object? authToken = freezed,}) {
  return _then(_TraceUploadConfig(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,serverUrl: freezed == serverUrl ? _self.serverUrl : serverUrl // ignore: cast_nullable_to_non_nullable
as String?,authToken: freezed == authToken ? _self.authToken : authToken // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
