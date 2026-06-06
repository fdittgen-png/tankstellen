// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'obd2_connect_trace.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Obd2ScannedDevice {

@JsonKey(name: 'mac') String? get redactedMac;@JsonKey(name: 'name') String? get name;@JsonKey(name: 'rssi') int? get rssi;@JsonKey(name: 'tx') Obd2ConnectTransport get transport;@JsonKey(name: 'pid') String? get matchedProfileId;
/// Create a copy of Obd2ScannedDevice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Obd2ScannedDeviceCopyWith<Obd2ScannedDevice> get copyWith => _$Obd2ScannedDeviceCopyWithImpl<Obd2ScannedDevice>(this as Obd2ScannedDevice, _$identity);

  /// Serializes this Obd2ScannedDevice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Obd2ScannedDevice&&(identical(other.redactedMac, redactedMac) || other.redactedMac == redactedMac)&&(identical(other.name, name) || other.name == name)&&(identical(other.rssi, rssi) || other.rssi == rssi)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.matchedProfileId, matchedProfileId) || other.matchedProfileId == matchedProfileId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,redactedMac,name,rssi,transport,matchedProfileId);

@override
String toString() {
  return 'Obd2ScannedDevice(redactedMac: $redactedMac, name: $name, rssi: $rssi, transport: $transport, matchedProfileId: $matchedProfileId)';
}


}

/// @nodoc
abstract mixin class $Obd2ScannedDeviceCopyWith<$Res>  {
  factory $Obd2ScannedDeviceCopyWith(Obd2ScannedDevice value, $Res Function(Obd2ScannedDevice) _then) = _$Obd2ScannedDeviceCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'mac') String? redactedMac,@JsonKey(name: 'name') String? name,@JsonKey(name: 'rssi') int? rssi,@JsonKey(name: 'tx') Obd2ConnectTransport transport,@JsonKey(name: 'pid') String? matchedProfileId
});




}
/// @nodoc
class _$Obd2ScannedDeviceCopyWithImpl<$Res>
    implements $Obd2ScannedDeviceCopyWith<$Res> {
  _$Obd2ScannedDeviceCopyWithImpl(this._self, this._then);

  final Obd2ScannedDevice _self;
  final $Res Function(Obd2ScannedDevice) _then;

/// Create a copy of Obd2ScannedDevice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? redactedMac = freezed,Object? name = freezed,Object? rssi = freezed,Object? transport = null,Object? matchedProfileId = freezed,}) {
  return _then(_self.copyWith(
redactedMac: freezed == redactedMac ? _self.redactedMac : redactedMac // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,rssi: freezed == rssi ? _self.rssi : rssi // ignore: cast_nullable_to_non_nullable
as int?,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as Obd2ConnectTransport,matchedProfileId: freezed == matchedProfileId ? _self.matchedProfileId : matchedProfileId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Obd2ScannedDevice].
extension Obd2ScannedDevicePatterns on Obd2ScannedDevice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Obd2ScannedDevice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Obd2ScannedDevice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Obd2ScannedDevice value)  $default,){
final _that = this;
switch (_that) {
case _Obd2ScannedDevice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Obd2ScannedDevice value)?  $default,){
final _that = this;
switch (_that) {
case _Obd2ScannedDevice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'mac')  String? redactedMac, @JsonKey(name: 'name')  String? name, @JsonKey(name: 'rssi')  int? rssi, @JsonKey(name: 'tx')  Obd2ConnectTransport transport, @JsonKey(name: 'pid')  String? matchedProfileId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Obd2ScannedDevice() when $default != null:
return $default(_that.redactedMac,_that.name,_that.rssi,_that.transport,_that.matchedProfileId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'mac')  String? redactedMac, @JsonKey(name: 'name')  String? name, @JsonKey(name: 'rssi')  int? rssi, @JsonKey(name: 'tx')  Obd2ConnectTransport transport, @JsonKey(name: 'pid')  String? matchedProfileId)  $default,) {final _that = this;
switch (_that) {
case _Obd2ScannedDevice():
return $default(_that.redactedMac,_that.name,_that.rssi,_that.transport,_that.matchedProfileId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'mac')  String? redactedMac, @JsonKey(name: 'name')  String? name, @JsonKey(name: 'rssi')  int? rssi, @JsonKey(name: 'tx')  Obd2ConnectTransport transport, @JsonKey(name: 'pid')  String? matchedProfileId)?  $default,) {final _that = this;
switch (_that) {
case _Obd2ScannedDevice() when $default != null:
return $default(_that.redactedMac,_that.name,_that.rssi,_that.transport,_that.matchedProfileId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Obd2ScannedDevice implements Obd2ScannedDevice {
  const _Obd2ScannedDevice({@JsonKey(name: 'mac') this.redactedMac, @JsonKey(name: 'name') this.name, @JsonKey(name: 'rssi') this.rssi, @JsonKey(name: 'tx') required this.transport, @JsonKey(name: 'pid') this.matchedProfileId});
  factory _Obd2ScannedDevice.fromJson(Map<String, dynamic> json) => _$Obd2ScannedDeviceFromJson(json);

@override@JsonKey(name: 'mac') final  String? redactedMac;
@override@JsonKey(name: 'name') final  String? name;
@override@JsonKey(name: 'rssi') final  int? rssi;
@override@JsonKey(name: 'tx') final  Obd2ConnectTransport transport;
@override@JsonKey(name: 'pid') final  String? matchedProfileId;

/// Create a copy of Obd2ScannedDevice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Obd2ScannedDeviceCopyWith<_Obd2ScannedDevice> get copyWith => __$Obd2ScannedDeviceCopyWithImpl<_Obd2ScannedDevice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Obd2ScannedDeviceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Obd2ScannedDevice&&(identical(other.redactedMac, redactedMac) || other.redactedMac == redactedMac)&&(identical(other.name, name) || other.name == name)&&(identical(other.rssi, rssi) || other.rssi == rssi)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.matchedProfileId, matchedProfileId) || other.matchedProfileId == matchedProfileId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,redactedMac,name,rssi,transport,matchedProfileId);

@override
String toString() {
  return 'Obd2ScannedDevice(redactedMac: $redactedMac, name: $name, rssi: $rssi, transport: $transport, matchedProfileId: $matchedProfileId)';
}


}

/// @nodoc
abstract mixin class _$Obd2ScannedDeviceCopyWith<$Res> implements $Obd2ScannedDeviceCopyWith<$Res> {
  factory _$Obd2ScannedDeviceCopyWith(_Obd2ScannedDevice value, $Res Function(_Obd2ScannedDevice) _then) = __$Obd2ScannedDeviceCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'mac') String? redactedMac,@JsonKey(name: 'name') String? name,@JsonKey(name: 'rssi') int? rssi,@JsonKey(name: 'tx') Obd2ConnectTransport transport,@JsonKey(name: 'pid') String? matchedProfileId
});




}
/// @nodoc
class __$Obd2ScannedDeviceCopyWithImpl<$Res>
    implements _$Obd2ScannedDeviceCopyWith<$Res> {
  __$Obd2ScannedDeviceCopyWithImpl(this._self, this._then);

  final _Obd2ScannedDevice _self;
  final $Res Function(_Obd2ScannedDevice) _then;

/// Create a copy of Obd2ScannedDevice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? redactedMac = freezed,Object? name = freezed,Object? rssi = freezed,Object? transport = null,Object? matchedProfileId = freezed,}) {
  return _then(_Obd2ScannedDevice(
redactedMac: freezed == redactedMac ? _self.redactedMac : redactedMac // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,rssi: freezed == rssi ? _self.rssi : rssi // ignore: cast_nullable_to_non_nullable
as int?,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as Obd2ConnectTransport,matchedProfileId: freezed == matchedProfileId ? _self.matchedProfileId : matchedProfileId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Obd2ConnectStep {

@JsonKey(name: 'l') String get label;@JsonKey(name: 's') Obd2ConnectStepStatus get status;@JsonKey(name: 'sm') int? get startMs;@JsonKey(name: 'em') int? get endMs;@JsonKey(name: 'd') String? get detail;
/// Create a copy of Obd2ConnectStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Obd2ConnectStepCopyWith<Obd2ConnectStep> get copyWith => _$Obd2ConnectStepCopyWithImpl<Obd2ConnectStep>(this as Obd2ConnectStep, _$identity);

  /// Serializes this Obd2ConnectStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Obd2ConnectStep&&(identical(other.label, label) || other.label == label)&&(identical(other.status, status) || other.status == status)&&(identical(other.startMs, startMs) || other.startMs == startMs)&&(identical(other.endMs, endMs) || other.endMs == endMs)&&(identical(other.detail, detail) || other.detail == detail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,status,startMs,endMs,detail);

@override
String toString() {
  return 'Obd2ConnectStep(label: $label, status: $status, startMs: $startMs, endMs: $endMs, detail: $detail)';
}


}

/// @nodoc
abstract mixin class $Obd2ConnectStepCopyWith<$Res>  {
  factory $Obd2ConnectStepCopyWith(Obd2ConnectStep value, $Res Function(Obd2ConnectStep) _then) = _$Obd2ConnectStepCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'l') String label,@JsonKey(name: 's') Obd2ConnectStepStatus status,@JsonKey(name: 'sm') int? startMs,@JsonKey(name: 'em') int? endMs,@JsonKey(name: 'd') String? detail
});




}
/// @nodoc
class _$Obd2ConnectStepCopyWithImpl<$Res>
    implements $Obd2ConnectStepCopyWith<$Res> {
  _$Obd2ConnectStepCopyWithImpl(this._self, this._then);

  final Obd2ConnectStep _self;
  final $Res Function(Obd2ConnectStep) _then;

/// Create a copy of Obd2ConnectStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? status = null,Object? startMs = freezed,Object? endMs = freezed,Object? detail = freezed,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Obd2ConnectStepStatus,startMs: freezed == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int?,endMs: freezed == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int?,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Obd2ConnectStep].
extension Obd2ConnectStepPatterns on Obd2ConnectStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Obd2ConnectStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Obd2ConnectStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Obd2ConnectStep value)  $default,){
final _that = this;
switch (_that) {
case _Obd2ConnectStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Obd2ConnectStep value)?  $default,){
final _that = this;
switch (_that) {
case _Obd2ConnectStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'l')  String label, @JsonKey(name: 's')  Obd2ConnectStepStatus status, @JsonKey(name: 'sm')  int? startMs, @JsonKey(name: 'em')  int? endMs, @JsonKey(name: 'd')  String? detail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Obd2ConnectStep() when $default != null:
return $default(_that.label,_that.status,_that.startMs,_that.endMs,_that.detail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'l')  String label, @JsonKey(name: 's')  Obd2ConnectStepStatus status, @JsonKey(name: 'sm')  int? startMs, @JsonKey(name: 'em')  int? endMs, @JsonKey(name: 'd')  String? detail)  $default,) {final _that = this;
switch (_that) {
case _Obd2ConnectStep():
return $default(_that.label,_that.status,_that.startMs,_that.endMs,_that.detail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'l')  String label, @JsonKey(name: 's')  Obd2ConnectStepStatus status, @JsonKey(name: 'sm')  int? startMs, @JsonKey(name: 'em')  int? endMs, @JsonKey(name: 'd')  String? detail)?  $default,) {final _that = this;
switch (_that) {
case _Obd2ConnectStep() when $default != null:
return $default(_that.label,_that.status,_that.startMs,_that.endMs,_that.detail);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Obd2ConnectStep implements Obd2ConnectStep {
  const _Obd2ConnectStep({@JsonKey(name: 'l') required this.label, @JsonKey(name: 's') required this.status, @JsonKey(name: 'sm') this.startMs, @JsonKey(name: 'em') this.endMs, @JsonKey(name: 'd') this.detail});
  factory _Obd2ConnectStep.fromJson(Map<String, dynamic> json) => _$Obd2ConnectStepFromJson(json);

@override@JsonKey(name: 'l') final  String label;
@override@JsonKey(name: 's') final  Obd2ConnectStepStatus status;
@override@JsonKey(name: 'sm') final  int? startMs;
@override@JsonKey(name: 'em') final  int? endMs;
@override@JsonKey(name: 'd') final  String? detail;

/// Create a copy of Obd2ConnectStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Obd2ConnectStepCopyWith<_Obd2ConnectStep> get copyWith => __$Obd2ConnectStepCopyWithImpl<_Obd2ConnectStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Obd2ConnectStepToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Obd2ConnectStep&&(identical(other.label, label) || other.label == label)&&(identical(other.status, status) || other.status == status)&&(identical(other.startMs, startMs) || other.startMs == startMs)&&(identical(other.endMs, endMs) || other.endMs == endMs)&&(identical(other.detail, detail) || other.detail == detail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,status,startMs,endMs,detail);

@override
String toString() {
  return 'Obd2ConnectStep(label: $label, status: $status, startMs: $startMs, endMs: $endMs, detail: $detail)';
}


}

/// @nodoc
abstract mixin class _$Obd2ConnectStepCopyWith<$Res> implements $Obd2ConnectStepCopyWith<$Res> {
  factory _$Obd2ConnectStepCopyWith(_Obd2ConnectStep value, $Res Function(_Obd2ConnectStep) _then) = __$Obd2ConnectStepCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'l') String label,@JsonKey(name: 's') Obd2ConnectStepStatus status,@JsonKey(name: 'sm') int? startMs,@JsonKey(name: 'em') int? endMs,@JsonKey(name: 'd') String? detail
});




}
/// @nodoc
class __$Obd2ConnectStepCopyWithImpl<$Res>
    implements _$Obd2ConnectStepCopyWith<$Res> {
  __$Obd2ConnectStepCopyWithImpl(this._self, this._then);

  final _Obd2ConnectStep _self;
  final $Res Function(_Obd2ConnectStep) _then;

/// Create a copy of Obd2ConnectStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? status = null,Object? startMs = freezed,Object? endMs = freezed,Object? detail = freezed,}) {
  return _then(_Obd2ConnectStep(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Obd2ConnectStepStatus,startMs: freezed == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int?,endMs: freezed == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int?,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Obd2ConnectTrace {

@JsonKey(name: 'id') String get attemptId;@JsonKey(name: 'st') int get startedAtMs;@JsonKey(name: 'et') int? get endedAtMs;@JsonKey(name: 'tm') int? get totalMs;@JsonKey(name: 'or') Obd2ConnectOrigin get origin;@JsonKey(name: 'mac') String? get requestedMac;@JsonKey(name: 'rtx') Obd2ConnectTransport get requestedTransport;@JsonKey(name: 'ztx') Obd2ConnectTransport? get resolvedTransport;@JsonKey(name: 'tdr') String? get transportDecisionReason;@JsonKey(name: 'oc') Obd2ConnectOutcome? get outcome;@JsonKey(name: 'fd') String? get failureDetail;@JsonKey(name: 'steps') List<Obd2ConnectStep> get steps;@JsonKey(name: 'scan') List<Obd2ScannedDevice> get scanned;
/// Create a copy of Obd2ConnectTrace
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Obd2ConnectTraceCopyWith<Obd2ConnectTrace> get copyWith => _$Obd2ConnectTraceCopyWithImpl<Obd2ConnectTrace>(this as Obd2ConnectTrace, _$identity);

  /// Serializes this Obd2ConnectTrace to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Obd2ConnectTrace&&(identical(other.attemptId, attemptId) || other.attemptId == attemptId)&&(identical(other.startedAtMs, startedAtMs) || other.startedAtMs == startedAtMs)&&(identical(other.endedAtMs, endedAtMs) || other.endedAtMs == endedAtMs)&&(identical(other.totalMs, totalMs) || other.totalMs == totalMs)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.requestedMac, requestedMac) || other.requestedMac == requestedMac)&&(identical(other.requestedTransport, requestedTransport) || other.requestedTransport == requestedTransport)&&(identical(other.resolvedTransport, resolvedTransport) || other.resolvedTransport == resolvedTransport)&&(identical(other.transportDecisionReason, transportDecisionReason) || other.transportDecisionReason == transportDecisionReason)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.failureDetail, failureDetail) || other.failureDetail == failureDetail)&&const DeepCollectionEquality().equals(other.steps, steps)&&const DeepCollectionEquality().equals(other.scanned, scanned));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,attemptId,startedAtMs,endedAtMs,totalMs,origin,requestedMac,requestedTransport,resolvedTransport,transportDecisionReason,outcome,failureDetail,const DeepCollectionEquality().hash(steps),const DeepCollectionEquality().hash(scanned));

@override
String toString() {
  return 'Obd2ConnectTrace(attemptId: $attemptId, startedAtMs: $startedAtMs, endedAtMs: $endedAtMs, totalMs: $totalMs, origin: $origin, requestedMac: $requestedMac, requestedTransport: $requestedTransport, resolvedTransport: $resolvedTransport, transportDecisionReason: $transportDecisionReason, outcome: $outcome, failureDetail: $failureDetail, steps: $steps, scanned: $scanned)';
}


}

/// @nodoc
abstract mixin class $Obd2ConnectTraceCopyWith<$Res>  {
  factory $Obd2ConnectTraceCopyWith(Obd2ConnectTrace value, $Res Function(Obd2ConnectTrace) _then) = _$Obd2ConnectTraceCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String attemptId,@JsonKey(name: 'st') int startedAtMs,@JsonKey(name: 'et') int? endedAtMs,@JsonKey(name: 'tm') int? totalMs,@JsonKey(name: 'or') Obd2ConnectOrigin origin,@JsonKey(name: 'mac') String? requestedMac,@JsonKey(name: 'rtx') Obd2ConnectTransport requestedTransport,@JsonKey(name: 'ztx') Obd2ConnectTransport? resolvedTransport,@JsonKey(name: 'tdr') String? transportDecisionReason,@JsonKey(name: 'oc') Obd2ConnectOutcome? outcome,@JsonKey(name: 'fd') String? failureDetail,@JsonKey(name: 'steps') List<Obd2ConnectStep> steps,@JsonKey(name: 'scan') List<Obd2ScannedDevice> scanned
});




}
/// @nodoc
class _$Obd2ConnectTraceCopyWithImpl<$Res>
    implements $Obd2ConnectTraceCopyWith<$Res> {
  _$Obd2ConnectTraceCopyWithImpl(this._self, this._then);

  final Obd2ConnectTrace _self;
  final $Res Function(Obd2ConnectTrace) _then;

/// Create a copy of Obd2ConnectTrace
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? attemptId = null,Object? startedAtMs = null,Object? endedAtMs = freezed,Object? totalMs = freezed,Object? origin = null,Object? requestedMac = freezed,Object? requestedTransport = null,Object? resolvedTransport = freezed,Object? transportDecisionReason = freezed,Object? outcome = freezed,Object? failureDetail = freezed,Object? steps = null,Object? scanned = null,}) {
  return _then(_self.copyWith(
attemptId: null == attemptId ? _self.attemptId : attemptId // ignore: cast_nullable_to_non_nullable
as String,startedAtMs: null == startedAtMs ? _self.startedAtMs : startedAtMs // ignore: cast_nullable_to_non_nullable
as int,endedAtMs: freezed == endedAtMs ? _self.endedAtMs : endedAtMs // ignore: cast_nullable_to_non_nullable
as int?,totalMs: freezed == totalMs ? _self.totalMs : totalMs // ignore: cast_nullable_to_non_nullable
as int?,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as Obd2ConnectOrigin,requestedMac: freezed == requestedMac ? _self.requestedMac : requestedMac // ignore: cast_nullable_to_non_nullable
as String?,requestedTransport: null == requestedTransport ? _self.requestedTransport : requestedTransport // ignore: cast_nullable_to_non_nullable
as Obd2ConnectTransport,resolvedTransport: freezed == resolvedTransport ? _self.resolvedTransport : resolvedTransport // ignore: cast_nullable_to_non_nullable
as Obd2ConnectTransport?,transportDecisionReason: freezed == transportDecisionReason ? _self.transportDecisionReason : transportDecisionReason // ignore: cast_nullable_to_non_nullable
as String?,outcome: freezed == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as Obd2ConnectOutcome?,failureDetail: freezed == failureDetail ? _self.failureDetail : failureDetail // ignore: cast_nullable_to_non_nullable
as String?,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<Obd2ConnectStep>,scanned: null == scanned ? _self.scanned : scanned // ignore: cast_nullable_to_non_nullable
as List<Obd2ScannedDevice>,
  ));
}

}


/// Adds pattern-matching-related methods to [Obd2ConnectTrace].
extension Obd2ConnectTracePatterns on Obd2ConnectTrace {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Obd2ConnectTrace value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Obd2ConnectTrace() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Obd2ConnectTrace value)  $default,){
final _that = this;
switch (_that) {
case _Obd2ConnectTrace():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Obd2ConnectTrace value)?  $default,){
final _that = this;
switch (_that) {
case _Obd2ConnectTrace() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String attemptId, @JsonKey(name: 'st')  int startedAtMs, @JsonKey(name: 'et')  int? endedAtMs, @JsonKey(name: 'tm')  int? totalMs, @JsonKey(name: 'or')  Obd2ConnectOrigin origin, @JsonKey(name: 'mac')  String? requestedMac, @JsonKey(name: 'rtx')  Obd2ConnectTransport requestedTransport, @JsonKey(name: 'ztx')  Obd2ConnectTransport? resolvedTransport, @JsonKey(name: 'tdr')  String? transportDecisionReason, @JsonKey(name: 'oc')  Obd2ConnectOutcome? outcome, @JsonKey(name: 'fd')  String? failureDetail, @JsonKey(name: 'steps')  List<Obd2ConnectStep> steps, @JsonKey(name: 'scan')  List<Obd2ScannedDevice> scanned)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Obd2ConnectTrace() when $default != null:
return $default(_that.attemptId,_that.startedAtMs,_that.endedAtMs,_that.totalMs,_that.origin,_that.requestedMac,_that.requestedTransport,_that.resolvedTransport,_that.transportDecisionReason,_that.outcome,_that.failureDetail,_that.steps,_that.scanned);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String attemptId, @JsonKey(name: 'st')  int startedAtMs, @JsonKey(name: 'et')  int? endedAtMs, @JsonKey(name: 'tm')  int? totalMs, @JsonKey(name: 'or')  Obd2ConnectOrigin origin, @JsonKey(name: 'mac')  String? requestedMac, @JsonKey(name: 'rtx')  Obd2ConnectTransport requestedTransport, @JsonKey(name: 'ztx')  Obd2ConnectTransport? resolvedTransport, @JsonKey(name: 'tdr')  String? transportDecisionReason, @JsonKey(name: 'oc')  Obd2ConnectOutcome? outcome, @JsonKey(name: 'fd')  String? failureDetail, @JsonKey(name: 'steps')  List<Obd2ConnectStep> steps, @JsonKey(name: 'scan')  List<Obd2ScannedDevice> scanned)  $default,) {final _that = this;
switch (_that) {
case _Obd2ConnectTrace():
return $default(_that.attemptId,_that.startedAtMs,_that.endedAtMs,_that.totalMs,_that.origin,_that.requestedMac,_that.requestedTransport,_that.resolvedTransport,_that.transportDecisionReason,_that.outcome,_that.failureDetail,_that.steps,_that.scanned);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String attemptId, @JsonKey(name: 'st')  int startedAtMs, @JsonKey(name: 'et')  int? endedAtMs, @JsonKey(name: 'tm')  int? totalMs, @JsonKey(name: 'or')  Obd2ConnectOrigin origin, @JsonKey(name: 'mac')  String? requestedMac, @JsonKey(name: 'rtx')  Obd2ConnectTransport requestedTransport, @JsonKey(name: 'ztx')  Obd2ConnectTransport? resolvedTransport, @JsonKey(name: 'tdr')  String? transportDecisionReason, @JsonKey(name: 'oc')  Obd2ConnectOutcome? outcome, @JsonKey(name: 'fd')  String? failureDetail, @JsonKey(name: 'steps')  List<Obd2ConnectStep> steps, @JsonKey(name: 'scan')  List<Obd2ScannedDevice> scanned)?  $default,) {final _that = this;
switch (_that) {
case _Obd2ConnectTrace() when $default != null:
return $default(_that.attemptId,_that.startedAtMs,_that.endedAtMs,_that.totalMs,_that.origin,_that.requestedMac,_that.requestedTransport,_that.resolvedTransport,_that.transportDecisionReason,_that.outcome,_that.failureDetail,_that.steps,_that.scanned);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Obd2ConnectTrace implements Obd2ConnectTrace {
  const _Obd2ConnectTrace({@JsonKey(name: 'id') required this.attemptId, @JsonKey(name: 'st') required this.startedAtMs, @JsonKey(name: 'et') this.endedAtMs, @JsonKey(name: 'tm') this.totalMs, @JsonKey(name: 'or') required this.origin, @JsonKey(name: 'mac') this.requestedMac, @JsonKey(name: 'rtx') required this.requestedTransport, @JsonKey(name: 'ztx') this.resolvedTransport, @JsonKey(name: 'tdr') this.transportDecisionReason, @JsonKey(name: 'oc') this.outcome, @JsonKey(name: 'fd') this.failureDetail, @JsonKey(name: 'steps') final  List<Obd2ConnectStep> steps = const <Obd2ConnectStep>[], @JsonKey(name: 'scan') final  List<Obd2ScannedDevice> scanned = const <Obd2ScannedDevice>[]}): _steps = steps,_scanned = scanned;
  factory _Obd2ConnectTrace.fromJson(Map<String, dynamic> json) => _$Obd2ConnectTraceFromJson(json);

@override@JsonKey(name: 'id') final  String attemptId;
@override@JsonKey(name: 'st') final  int startedAtMs;
@override@JsonKey(name: 'et') final  int? endedAtMs;
@override@JsonKey(name: 'tm') final  int? totalMs;
@override@JsonKey(name: 'or') final  Obd2ConnectOrigin origin;
@override@JsonKey(name: 'mac') final  String? requestedMac;
@override@JsonKey(name: 'rtx') final  Obd2ConnectTransport requestedTransport;
@override@JsonKey(name: 'ztx') final  Obd2ConnectTransport? resolvedTransport;
@override@JsonKey(name: 'tdr') final  String? transportDecisionReason;
@override@JsonKey(name: 'oc') final  Obd2ConnectOutcome? outcome;
@override@JsonKey(name: 'fd') final  String? failureDetail;
 final  List<Obd2ConnectStep> _steps;
@override@JsonKey(name: 'steps') List<Obd2ConnectStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

 final  List<Obd2ScannedDevice> _scanned;
@override@JsonKey(name: 'scan') List<Obd2ScannedDevice> get scanned {
  if (_scanned is EqualUnmodifiableListView) return _scanned;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_scanned);
}


/// Create a copy of Obd2ConnectTrace
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Obd2ConnectTraceCopyWith<_Obd2ConnectTrace> get copyWith => __$Obd2ConnectTraceCopyWithImpl<_Obd2ConnectTrace>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Obd2ConnectTraceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Obd2ConnectTrace&&(identical(other.attemptId, attemptId) || other.attemptId == attemptId)&&(identical(other.startedAtMs, startedAtMs) || other.startedAtMs == startedAtMs)&&(identical(other.endedAtMs, endedAtMs) || other.endedAtMs == endedAtMs)&&(identical(other.totalMs, totalMs) || other.totalMs == totalMs)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.requestedMac, requestedMac) || other.requestedMac == requestedMac)&&(identical(other.requestedTransport, requestedTransport) || other.requestedTransport == requestedTransport)&&(identical(other.resolvedTransport, resolvedTransport) || other.resolvedTransport == resolvedTransport)&&(identical(other.transportDecisionReason, transportDecisionReason) || other.transportDecisionReason == transportDecisionReason)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.failureDetail, failureDetail) || other.failureDetail == failureDetail)&&const DeepCollectionEquality().equals(other._steps, _steps)&&const DeepCollectionEquality().equals(other._scanned, _scanned));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,attemptId,startedAtMs,endedAtMs,totalMs,origin,requestedMac,requestedTransport,resolvedTransport,transportDecisionReason,outcome,failureDetail,const DeepCollectionEquality().hash(_steps),const DeepCollectionEquality().hash(_scanned));

@override
String toString() {
  return 'Obd2ConnectTrace(attemptId: $attemptId, startedAtMs: $startedAtMs, endedAtMs: $endedAtMs, totalMs: $totalMs, origin: $origin, requestedMac: $requestedMac, requestedTransport: $requestedTransport, resolvedTransport: $resolvedTransport, transportDecisionReason: $transportDecisionReason, outcome: $outcome, failureDetail: $failureDetail, steps: $steps, scanned: $scanned)';
}


}

/// @nodoc
abstract mixin class _$Obd2ConnectTraceCopyWith<$Res> implements $Obd2ConnectTraceCopyWith<$Res> {
  factory _$Obd2ConnectTraceCopyWith(_Obd2ConnectTrace value, $Res Function(_Obd2ConnectTrace) _then) = __$Obd2ConnectTraceCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String attemptId,@JsonKey(name: 'st') int startedAtMs,@JsonKey(name: 'et') int? endedAtMs,@JsonKey(name: 'tm') int? totalMs,@JsonKey(name: 'or') Obd2ConnectOrigin origin,@JsonKey(name: 'mac') String? requestedMac,@JsonKey(name: 'rtx') Obd2ConnectTransport requestedTransport,@JsonKey(name: 'ztx') Obd2ConnectTransport? resolvedTransport,@JsonKey(name: 'tdr') String? transportDecisionReason,@JsonKey(name: 'oc') Obd2ConnectOutcome? outcome,@JsonKey(name: 'fd') String? failureDetail,@JsonKey(name: 'steps') List<Obd2ConnectStep> steps,@JsonKey(name: 'scan') List<Obd2ScannedDevice> scanned
});




}
/// @nodoc
class __$Obd2ConnectTraceCopyWithImpl<$Res>
    implements _$Obd2ConnectTraceCopyWith<$Res> {
  __$Obd2ConnectTraceCopyWithImpl(this._self, this._then);

  final _Obd2ConnectTrace _self;
  final $Res Function(_Obd2ConnectTrace) _then;

/// Create a copy of Obd2ConnectTrace
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? attemptId = null,Object? startedAtMs = null,Object? endedAtMs = freezed,Object? totalMs = freezed,Object? origin = null,Object? requestedMac = freezed,Object? requestedTransport = null,Object? resolvedTransport = freezed,Object? transportDecisionReason = freezed,Object? outcome = freezed,Object? failureDetail = freezed,Object? steps = null,Object? scanned = null,}) {
  return _then(_Obd2ConnectTrace(
attemptId: null == attemptId ? _self.attemptId : attemptId // ignore: cast_nullable_to_non_nullable
as String,startedAtMs: null == startedAtMs ? _self.startedAtMs : startedAtMs // ignore: cast_nullable_to_non_nullable
as int,endedAtMs: freezed == endedAtMs ? _self.endedAtMs : endedAtMs // ignore: cast_nullable_to_non_nullable
as int?,totalMs: freezed == totalMs ? _self.totalMs : totalMs // ignore: cast_nullable_to_non_nullable
as int?,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as Obd2ConnectOrigin,requestedMac: freezed == requestedMac ? _self.requestedMac : requestedMac // ignore: cast_nullable_to_non_nullable
as String?,requestedTransport: null == requestedTransport ? _self.requestedTransport : requestedTransport // ignore: cast_nullable_to_non_nullable
as Obd2ConnectTransport,resolvedTransport: freezed == resolvedTransport ? _self.resolvedTransport : resolvedTransport // ignore: cast_nullable_to_non_nullable
as Obd2ConnectTransport?,transportDecisionReason: freezed == transportDecisionReason ? _self.transportDecisionReason : transportDecisionReason // ignore: cast_nullable_to_non_nullable
as String?,outcome: freezed == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as Obd2ConnectOutcome?,failureDetail: freezed == failureDetail ? _self.failureDetail : failureDetail // ignore: cast_nullable_to_non_nullable
as String?,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<Obd2ConnectStep>,scanned: null == scanned ? _self._scanned : scanned // ignore: cast_nullable_to_non_nullable
as List<Obd2ScannedDevice>,
  ));
}


}

// dart format on
