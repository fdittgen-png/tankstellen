// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'obd2_reconnect_telemetry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Obd2ReconnectAttempt {

/// Epoch-millisecond wall clock when the attempt was made — the
/// timeline anchor. 0 only for the const-default sentinel.
@JsonKey(name: 't') int get timestampMs;/// Low-cardinality failure reason tag for a FAILED attempt
/// ([Obd2ReconnectReason] normalised): `'rfcomm-open-fail'` /
/// `'gatt-133'` / `'device-not-connected'` / `'timeout'` / `'other'`.
/// Null when [succeeded] is true (a success has no failure reason).
@JsonKey(name: 'rc') String? get reasonCode;/// The scanner's backoff (ms) in force for THIS cycle — how long the
/// scanner waited before this attempt. 0 for the immediate first probe.
@JsonKey(name: 'bo') int get backoffMs;/// Sighting RSSI (dBm, negative) when this attempt came from the
/// scan-fallback path. Null for the direct-connect / passive path,
/// which never scans and so carries no RSSI.
@JsonKey(name: 'r') int? get rssi;/// Wall-clock latency (ms) the connect dance took this attempt
/// (success or fail). 0 when not measured.
@JsonKey(name: 'l') int get latencyMs;/// 1-based attempt ordinal within this drop episode — attempt 1 is the
/// fast first probe, then 2, 3, … as the backoff escalates.
@JsonKey(name: 'n') int get attemptNumber;/// True when this attempt established a working link. The single
/// `succeeded: true` row per episode marks the recovery; everything
/// before it failed.
@JsonKey(name: 's') bool get succeeded;/// `'direct'` / `'scan'` / `'passive'` — which connect path this
/// attempt took (#2905). Lets the export distinguish a direct-connect
/// 133 from a scan-fallback gate miss. Null when not stamped.
@JsonKey(name: 'p') String? get path;
/// Create a copy of Obd2ReconnectAttempt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Obd2ReconnectAttemptCopyWith<Obd2ReconnectAttempt> get copyWith => _$Obd2ReconnectAttemptCopyWithImpl<Obd2ReconnectAttempt>(this as Obd2ReconnectAttempt, _$identity);

  /// Serializes this Obd2ReconnectAttempt to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Obd2ReconnectAttempt&&(identical(other.timestampMs, timestampMs) || other.timestampMs == timestampMs)&&(identical(other.reasonCode, reasonCode) || other.reasonCode == reasonCode)&&(identical(other.backoffMs, backoffMs) || other.backoffMs == backoffMs)&&(identical(other.rssi, rssi) || other.rssi == rssi)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs)&&(identical(other.attemptNumber, attemptNumber) || other.attemptNumber == attemptNumber)&&(identical(other.succeeded, succeeded) || other.succeeded == succeeded)&&(identical(other.path, path) || other.path == path));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestampMs,reasonCode,backoffMs,rssi,latencyMs,attemptNumber,succeeded,path);

@override
String toString() {
  return 'Obd2ReconnectAttempt(timestampMs: $timestampMs, reasonCode: $reasonCode, backoffMs: $backoffMs, rssi: $rssi, latencyMs: $latencyMs, attemptNumber: $attemptNumber, succeeded: $succeeded, path: $path)';
}


}

/// @nodoc
abstract mixin class $Obd2ReconnectAttemptCopyWith<$Res>  {
  factory $Obd2ReconnectAttemptCopyWith(Obd2ReconnectAttempt value, $Res Function(Obd2ReconnectAttempt) _then) = _$Obd2ReconnectAttemptCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 't') int timestampMs,@JsonKey(name: 'rc') String? reasonCode,@JsonKey(name: 'bo') int backoffMs,@JsonKey(name: 'r') int? rssi,@JsonKey(name: 'l') int latencyMs,@JsonKey(name: 'n') int attemptNumber,@JsonKey(name: 's') bool succeeded,@JsonKey(name: 'p') String? path
});




}
/// @nodoc
class _$Obd2ReconnectAttemptCopyWithImpl<$Res>
    implements $Obd2ReconnectAttemptCopyWith<$Res> {
  _$Obd2ReconnectAttemptCopyWithImpl(this._self, this._then);

  final Obd2ReconnectAttempt _self;
  final $Res Function(Obd2ReconnectAttempt) _then;

/// Create a copy of Obd2ReconnectAttempt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timestampMs = null,Object? reasonCode = freezed,Object? backoffMs = null,Object? rssi = freezed,Object? latencyMs = null,Object? attemptNumber = null,Object? succeeded = null,Object? path = freezed,}) {
  return _then(_self.copyWith(
timestampMs: null == timestampMs ? _self.timestampMs : timestampMs // ignore: cast_nullable_to_non_nullable
as int,reasonCode: freezed == reasonCode ? _self.reasonCode : reasonCode // ignore: cast_nullable_to_non_nullable
as String?,backoffMs: null == backoffMs ? _self.backoffMs : backoffMs // ignore: cast_nullable_to_non_nullable
as int,rssi: freezed == rssi ? _self.rssi : rssi // ignore: cast_nullable_to_non_nullable
as int?,latencyMs: null == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int,attemptNumber: null == attemptNumber ? _self.attemptNumber : attemptNumber // ignore: cast_nullable_to_non_nullable
as int,succeeded: null == succeeded ? _self.succeeded : succeeded // ignore: cast_nullable_to_non_nullable
as bool,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Obd2ReconnectAttempt].
extension Obd2ReconnectAttemptPatterns on Obd2ReconnectAttempt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Obd2ReconnectAttempt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Obd2ReconnectAttempt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Obd2ReconnectAttempt value)  $default,){
final _that = this;
switch (_that) {
case _Obd2ReconnectAttempt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Obd2ReconnectAttempt value)?  $default,){
final _that = this;
switch (_that) {
case _Obd2ReconnectAttempt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 't')  int timestampMs, @JsonKey(name: 'rc')  String? reasonCode, @JsonKey(name: 'bo')  int backoffMs, @JsonKey(name: 'r')  int? rssi, @JsonKey(name: 'l')  int latencyMs, @JsonKey(name: 'n')  int attemptNumber, @JsonKey(name: 's')  bool succeeded, @JsonKey(name: 'p')  String? path)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Obd2ReconnectAttempt() when $default != null:
return $default(_that.timestampMs,_that.reasonCode,_that.backoffMs,_that.rssi,_that.latencyMs,_that.attemptNumber,_that.succeeded,_that.path);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 't')  int timestampMs, @JsonKey(name: 'rc')  String? reasonCode, @JsonKey(name: 'bo')  int backoffMs, @JsonKey(name: 'r')  int? rssi, @JsonKey(name: 'l')  int latencyMs, @JsonKey(name: 'n')  int attemptNumber, @JsonKey(name: 's')  bool succeeded, @JsonKey(name: 'p')  String? path)  $default,) {final _that = this;
switch (_that) {
case _Obd2ReconnectAttempt():
return $default(_that.timestampMs,_that.reasonCode,_that.backoffMs,_that.rssi,_that.latencyMs,_that.attemptNumber,_that.succeeded,_that.path);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 't')  int timestampMs, @JsonKey(name: 'rc')  String? reasonCode, @JsonKey(name: 'bo')  int backoffMs, @JsonKey(name: 'r')  int? rssi, @JsonKey(name: 'l')  int latencyMs, @JsonKey(name: 'n')  int attemptNumber, @JsonKey(name: 's')  bool succeeded, @JsonKey(name: 'p')  String? path)?  $default,) {final _that = this;
switch (_that) {
case _Obd2ReconnectAttempt() when $default != null:
return $default(_that.timestampMs,_that.reasonCode,_that.backoffMs,_that.rssi,_that.latencyMs,_that.attemptNumber,_that.succeeded,_that.path);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Obd2ReconnectAttempt implements Obd2ReconnectAttempt {
  const _Obd2ReconnectAttempt({@JsonKey(name: 't') this.timestampMs = 0, @JsonKey(name: 'rc') this.reasonCode, @JsonKey(name: 'bo') this.backoffMs = 0, @JsonKey(name: 'r') this.rssi, @JsonKey(name: 'l') this.latencyMs = 0, @JsonKey(name: 'n') this.attemptNumber = 0, @JsonKey(name: 's') this.succeeded = false, @JsonKey(name: 'p') this.path});
  factory _Obd2ReconnectAttempt.fromJson(Map<String, dynamic> json) => _$Obd2ReconnectAttemptFromJson(json);

/// Epoch-millisecond wall clock when the attempt was made — the
/// timeline anchor. 0 only for the const-default sentinel.
@override@JsonKey(name: 't') final  int timestampMs;
/// Low-cardinality failure reason tag for a FAILED attempt
/// ([Obd2ReconnectReason] normalised): `'rfcomm-open-fail'` /
/// `'gatt-133'` / `'device-not-connected'` / `'timeout'` / `'other'`.
/// Null when [succeeded] is true (a success has no failure reason).
@override@JsonKey(name: 'rc') final  String? reasonCode;
/// The scanner's backoff (ms) in force for THIS cycle — how long the
/// scanner waited before this attempt. 0 for the immediate first probe.
@override@JsonKey(name: 'bo') final  int backoffMs;
/// Sighting RSSI (dBm, negative) when this attempt came from the
/// scan-fallback path. Null for the direct-connect / passive path,
/// which never scans and so carries no RSSI.
@override@JsonKey(name: 'r') final  int? rssi;
/// Wall-clock latency (ms) the connect dance took this attempt
/// (success or fail). 0 when not measured.
@override@JsonKey(name: 'l') final  int latencyMs;
/// 1-based attempt ordinal within this drop episode — attempt 1 is the
/// fast first probe, then 2, 3, … as the backoff escalates.
@override@JsonKey(name: 'n') final  int attemptNumber;
/// True when this attempt established a working link. The single
/// `succeeded: true` row per episode marks the recovery; everything
/// before it failed.
@override@JsonKey(name: 's') final  bool succeeded;
/// `'direct'` / `'scan'` / `'passive'` — which connect path this
/// attempt took (#2905). Lets the export distinguish a direct-connect
/// 133 from a scan-fallback gate miss. Null when not stamped.
@override@JsonKey(name: 'p') final  String? path;

/// Create a copy of Obd2ReconnectAttempt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Obd2ReconnectAttemptCopyWith<_Obd2ReconnectAttempt> get copyWith => __$Obd2ReconnectAttemptCopyWithImpl<_Obd2ReconnectAttempt>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Obd2ReconnectAttemptToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Obd2ReconnectAttempt&&(identical(other.timestampMs, timestampMs) || other.timestampMs == timestampMs)&&(identical(other.reasonCode, reasonCode) || other.reasonCode == reasonCode)&&(identical(other.backoffMs, backoffMs) || other.backoffMs == backoffMs)&&(identical(other.rssi, rssi) || other.rssi == rssi)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs)&&(identical(other.attemptNumber, attemptNumber) || other.attemptNumber == attemptNumber)&&(identical(other.succeeded, succeeded) || other.succeeded == succeeded)&&(identical(other.path, path) || other.path == path));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestampMs,reasonCode,backoffMs,rssi,latencyMs,attemptNumber,succeeded,path);

@override
String toString() {
  return 'Obd2ReconnectAttempt(timestampMs: $timestampMs, reasonCode: $reasonCode, backoffMs: $backoffMs, rssi: $rssi, latencyMs: $latencyMs, attemptNumber: $attemptNumber, succeeded: $succeeded, path: $path)';
}


}

/// @nodoc
abstract mixin class _$Obd2ReconnectAttemptCopyWith<$Res> implements $Obd2ReconnectAttemptCopyWith<$Res> {
  factory _$Obd2ReconnectAttemptCopyWith(_Obd2ReconnectAttempt value, $Res Function(_Obd2ReconnectAttempt) _then) = __$Obd2ReconnectAttemptCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 't') int timestampMs,@JsonKey(name: 'rc') String? reasonCode,@JsonKey(name: 'bo') int backoffMs,@JsonKey(name: 'r') int? rssi,@JsonKey(name: 'l') int latencyMs,@JsonKey(name: 'n') int attemptNumber,@JsonKey(name: 's') bool succeeded,@JsonKey(name: 'p') String? path
});




}
/// @nodoc
class __$Obd2ReconnectAttemptCopyWithImpl<$Res>
    implements _$Obd2ReconnectAttemptCopyWith<$Res> {
  __$Obd2ReconnectAttemptCopyWithImpl(this._self, this._then);

  final _Obd2ReconnectAttempt _self;
  final $Res Function(_Obd2ReconnectAttempt) _then;

/// Create a copy of Obd2ReconnectAttempt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timestampMs = null,Object? reasonCode = freezed,Object? backoffMs = null,Object? rssi = freezed,Object? latencyMs = null,Object? attemptNumber = null,Object? succeeded = null,Object? path = freezed,}) {
  return _then(_Obd2ReconnectAttempt(
timestampMs: null == timestampMs ? _self.timestampMs : timestampMs // ignore: cast_nullable_to_non_nullable
as int,reasonCode: freezed == reasonCode ? _self.reasonCode : reasonCode // ignore: cast_nullable_to_non_nullable
as String?,backoffMs: null == backoffMs ? _self.backoffMs : backoffMs // ignore: cast_nullable_to_non_nullable
as int,rssi: freezed == rssi ? _self.rssi : rssi // ignore: cast_nullable_to_non_nullable
as int?,latencyMs: null == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int,attemptNumber: null == attemptNumber ? _self.attemptNumber : attemptNumber // ignore: cast_nullable_to_non_nullable
as int,succeeded: null == succeeded ? _self.succeeded : succeeded // ignore: cast_nullable_to_non_nullable
as bool,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Obd2SessionTransition {

/// Epoch-millisecond wall clock of the transition. 0 only for the
/// const-default sentinel.
@JsonKey(name: 't') int get timestampMs;/// The state entered ([Obd2SessionState] name): `'connected'`,
/// `'dropped'`, `'reconnecting'`, `'reconnected'`, `'orphaned'`,
/// `'fallbackActivated'`, or `'disconnectedException'`.
@JsonKey(name: 's') String get state;/// Optional low-cardinality detail (e.g. the drop reason name
/// `'transportError'` / `'silentFailure'`, or the fallback kind). Null
/// when none.
@JsonKey(name: 'd') String? get detail;
/// Create a copy of Obd2SessionTransition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Obd2SessionTransitionCopyWith<Obd2SessionTransition> get copyWith => _$Obd2SessionTransitionCopyWithImpl<Obd2SessionTransition>(this as Obd2SessionTransition, _$identity);

  /// Serializes this Obd2SessionTransition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Obd2SessionTransition&&(identical(other.timestampMs, timestampMs) || other.timestampMs == timestampMs)&&(identical(other.state, state) || other.state == state)&&(identical(other.detail, detail) || other.detail == detail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestampMs,state,detail);

@override
String toString() {
  return 'Obd2SessionTransition(timestampMs: $timestampMs, state: $state, detail: $detail)';
}


}

/// @nodoc
abstract mixin class $Obd2SessionTransitionCopyWith<$Res>  {
  factory $Obd2SessionTransitionCopyWith(Obd2SessionTransition value, $Res Function(Obd2SessionTransition) _then) = _$Obd2SessionTransitionCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 't') int timestampMs,@JsonKey(name: 's') String state,@JsonKey(name: 'd') String? detail
});




}
/// @nodoc
class _$Obd2SessionTransitionCopyWithImpl<$Res>
    implements $Obd2SessionTransitionCopyWith<$Res> {
  _$Obd2SessionTransitionCopyWithImpl(this._self, this._then);

  final Obd2SessionTransition _self;
  final $Res Function(Obd2SessionTransition) _then;

/// Create a copy of Obd2SessionTransition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timestampMs = null,Object? state = null,Object? detail = freezed,}) {
  return _then(_self.copyWith(
timestampMs: null == timestampMs ? _self.timestampMs : timestampMs // ignore: cast_nullable_to_non_nullable
as int,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Obd2SessionTransition].
extension Obd2SessionTransitionPatterns on Obd2SessionTransition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Obd2SessionTransition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Obd2SessionTransition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Obd2SessionTransition value)  $default,){
final _that = this;
switch (_that) {
case _Obd2SessionTransition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Obd2SessionTransition value)?  $default,){
final _that = this;
switch (_that) {
case _Obd2SessionTransition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 't')  int timestampMs, @JsonKey(name: 's')  String state, @JsonKey(name: 'd')  String? detail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Obd2SessionTransition() when $default != null:
return $default(_that.timestampMs,_that.state,_that.detail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 't')  int timestampMs, @JsonKey(name: 's')  String state, @JsonKey(name: 'd')  String? detail)  $default,) {final _that = this;
switch (_that) {
case _Obd2SessionTransition():
return $default(_that.timestampMs,_that.state,_that.detail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 't')  int timestampMs, @JsonKey(name: 's')  String state, @JsonKey(name: 'd')  String? detail)?  $default,) {final _that = this;
switch (_that) {
case _Obd2SessionTransition() when $default != null:
return $default(_that.timestampMs,_that.state,_that.detail);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Obd2SessionTransition implements Obd2SessionTransition {
  const _Obd2SessionTransition({@JsonKey(name: 't') this.timestampMs = 0, @JsonKey(name: 's') this.state = '', @JsonKey(name: 'd') this.detail});
  factory _Obd2SessionTransition.fromJson(Map<String, dynamic> json) => _$Obd2SessionTransitionFromJson(json);

/// Epoch-millisecond wall clock of the transition. 0 only for the
/// const-default sentinel.
@override@JsonKey(name: 't') final  int timestampMs;
/// The state entered ([Obd2SessionState] name): `'connected'`,
/// `'dropped'`, `'reconnecting'`, `'reconnected'`, `'orphaned'`,
/// `'fallbackActivated'`, or `'disconnectedException'`.
@override@JsonKey(name: 's') final  String state;
/// Optional low-cardinality detail (e.g. the drop reason name
/// `'transportError'` / `'silentFailure'`, or the fallback kind). Null
/// when none.
@override@JsonKey(name: 'd') final  String? detail;

/// Create a copy of Obd2SessionTransition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Obd2SessionTransitionCopyWith<_Obd2SessionTransition> get copyWith => __$Obd2SessionTransitionCopyWithImpl<_Obd2SessionTransition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Obd2SessionTransitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Obd2SessionTransition&&(identical(other.timestampMs, timestampMs) || other.timestampMs == timestampMs)&&(identical(other.state, state) || other.state == state)&&(identical(other.detail, detail) || other.detail == detail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestampMs,state,detail);

@override
String toString() {
  return 'Obd2SessionTransition(timestampMs: $timestampMs, state: $state, detail: $detail)';
}


}

/// @nodoc
abstract mixin class _$Obd2SessionTransitionCopyWith<$Res> implements $Obd2SessionTransitionCopyWith<$Res> {
  factory _$Obd2SessionTransitionCopyWith(_Obd2SessionTransition value, $Res Function(_Obd2SessionTransition) _then) = __$Obd2SessionTransitionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 't') int timestampMs,@JsonKey(name: 's') String state,@JsonKey(name: 'd') String? detail
});




}
/// @nodoc
class __$Obd2SessionTransitionCopyWithImpl<$Res>
    implements _$Obd2SessionTransitionCopyWith<$Res> {
  __$Obd2SessionTransitionCopyWithImpl(this._self, this._then);

  final _Obd2SessionTransition _self;
  final $Res Function(_Obd2SessionTransition) _then;

/// Create a copy of Obd2SessionTransition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timestampMs = null,Object? state = null,Object? detail = freezed,}) {
  return _then(_Obd2SessionTransition(
timestampMs: null == timestampMs ? _self.timestampMs : timestampMs // ignore: cast_nullable_to_non_nullable
as int,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
